# bus_tracking/views.py

from rest_framework import viewsets, status
from django.shortcuts import get_object_or_404
from rest_framework.decorators import action, api_view # <-- IMPORT ADDED HERE
from rest_framework.response import Response
from django.utils import timezone
from .models import Bus, BusLine, BusStop, Location, BusLocationLog, Alert, BusLineStop
from .serializers import (BusSerializer, BusLineSerializer, BusStopSerializer,
                          LocationSerializer, BusLocationLogSerializer, AlertSerializer,
                          BusStopWithOrderSerializer)
import math
from channels.layers import get_channel_layer
from asgiref.sync import async_to_sync
from typing import List, Dict, Optional, Tuple

# --- Helper function for calculating distance ---
def haversine(lat1, lon1, lat2, lon2):
    R = 6371
    dLat = math.radians(lat2 - lat1)
    dLon = math.radians(lon2 - lon1)
    a = (math.sin(dLat / 2) ** 2 +
         math.cos(math.radians(lat1)) * math.cos(math.radians(lat2)) *
         math.sin(dLon / 2) ** 2)
    c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a))
    distance = R * c
    return distance

# --- Helper functions for ETA calculation ---
def _latest_speed_kmh(bus: Bus, default_speed_kmh: float = 30.0) -> float:
    """
    Returns the latest reported speed for a bus in km/h.
    Falls back to default_speed_kmh when missing/invalid/too low.
    """
    log = (
        BusLocationLog.objects.filter(bus=bus)
        .order_by('-timestamp')
        .first()
    )
    try:
        speed = float(log.speed) if log and log.speed is not None else default_speed_kmh
    except (TypeError, ValueError):
        speed = default_speed_kmh
    # Treat extremely low speeds as effectively stopped; use default to avoid INF ETA
    if speed < 3.0:  # km/h
        return default_speed_kmh
    return speed

def _ordered_stops_for_line(bus_line: BusLine) -> List[BusLineStop]:
    return list(BusLineStop.objects.filter(bus_line=bus_line).select_related('bus_stop__location').order_by('order'))

def _compute_cumulative_distances_from_point(lat: float, lon: float, stops: List[BusLineStop], arrival_threshold_km: float = 0.1) -> Tuple[int, List[float]]:
    """
    Given a starting point (lat, lon) and an ordered list of BusLineStop, compute cumulative
    distances (in km) from that point to each stop starting from the chosen next stop index.

    Logic:
    - Find nearest stop index by straight-line distance.
    - If within arrival_threshold_km, consider the bus as "at" that stop and start from next stop.
    - Otherwise, start from the nearest stop.
    Returns (start_index, cumulative_distances_from_start_index)
    where cumulative_distances[i] corresponds to distance to stops[start_index + i].
    """
    if not stops:
        return 0, []

    # Find nearest stop
    distances_to_stops = [
        haversine(lat, lon, s.bus_stop.location.latitude, s.bus_stop.location.longitude)
        for s in stops
    ]
    nearest_idx = int(min(range(len(stops)), key=lambda i: distances_to_stops[i]))

    # Decide start index
    if distances_to_stops[nearest_idx] <= arrival_threshold_km and nearest_idx < len(stops) - 1:
        start_idx = nearest_idx + 1
    else:
        start_idx = nearest_idx

    if start_idx >= len(stops):
        return start_idx, []

    # Build cumulative distances from current point to start_idx stop, then along route
    cum_dists: List[float] = []
    # distance from current point to the first target stop
    first_stop_loc = stops[start_idx].bus_stop.location
    total = haversine(lat, lon, first_stop_loc.latitude, first_stop_loc.longitude)
    cum_dists.append(total)

    # then distances between subsequent stops
    for i in range(start_idx + 1, len(stops)):
        prev_loc = stops[i - 1].bus_stop.location
        cur_loc = stops[i].bus_stop.location
        seg = haversine(prev_loc.latitude, prev_loc.longitude, cur_loc.latitude, cur_loc.longitude)
        total += seg
        cum_dists.append(total)

    return start_idx, cum_dists

class LocationViewSet(viewsets.ModelViewSet):
    queryset = Location.objects.all()
    serializer_class = LocationSerializer

class BusStopViewSet(viewsets.ModelViewSet):
    queryset = BusStop.objects.all()
    serializer_class = BusStopSerializer

    def create(self, request, *args, **kwargs):
        stop_name = request.data.get('stop_name')
        latitude = request.data.get('latitude')
        longitude = request.data.get('longitude')
        if not all([stop_name, latitude, longitude]):
            return Response({'error': 'stop_name, latitude, and longitude are required.'}, status=status.HTTP_400_BAD_REQUEST)
        location = Location.objects.create(latitude=latitude, longitude=longitude)
        bus_stop = BusStop.objects.create(stop_name=stop_name, location=location)
        serializer = self.get_serializer(bus_stop)
        return Response(serializer.data, status=status.HTTP_201_CREATED)

    def update(self, request, *args, **kwargs):
        instance = self.get_object()
        instance.stop_name = request.data.get('stop_name', instance.stop_name)
        latitude = request.data.get('latitude')
        longitude = request.data.get('longitude')
        if latitude and longitude:
            location = instance.location
            location.latitude = latitude
            location.longitude = longitude
            location.save()
        instance.save()
        serializer = self.get_serializer(instance)
        return Response(serializer.data)

class BusLineViewSet(viewsets.ModelViewSet):
    queryset = BusLine.objects.all()
    serializer_class = BusLineSerializer
    
    @action(detail=True, methods=['post'], url_path='add-stop')
    def add_stop(self, request, pk=None):
        bus_line = self.get_object()
        stop_id = request.data.get('stop_id')
        order = request.data.get('order')

        if not stop_id or order is None:
            return Response(
                {'detail': 'A stop_id and an order are required.'},
                status=status.HTTP_400_BAD_REQUEST
            )
        bus_stop = get_object_or_404(BusStop, stop_id=stop_id)
        BusLineStop.objects.create(
            bus_line=bus_line,
            bus_stop=bus_stop,
            order=order
        )
        return Response({'status': 'stop added successfully'}, status=status.HTTP_201_CREATED)

    @action(detail=True, methods=['get'])
    def stops_with_order(self, request, pk=None):
        try:
            bus_line = BusLine.objects.get(pk=pk)
            bus_line_stops = BusLineStop.objects.filter(bus_line=bus_line).order_by('order')
            serializer = BusStopWithOrderSerializer(bus_line_stops, many=True)
            return Response(serializer.data, status=status.HTTP_200_OK)
        except BusLine.DoesNotExist:
            return Response(status=status.HTTP_404_NOT_FOUND)

    @action(detail=True, methods=['get'], url_path='stops-with-eta')
    def stops_with_eta(self, request, pk=None):
        """
        Returns ordered stops for the route including ETA for a specific bus passed via ?bus_id=.
        If bus_id is missing or invalid, returns stops without ETA info.
        """
        try:
            bus_line = BusLine.objects.get(pk=pk)
        except BusLine.DoesNotExist:
            return Response(status=status.HTTP_404_NOT_FOUND)

        stops = _ordered_stops_for_line(bus_line)
        if not stops:
            return Response({'stops': [], 'eta_source': None}, status=status.HTTP_200_OK)

        bus_id = request.query_params.get('bus_id')
        if not bus_id:
            data = [
                {
                    'stop_id': s.bus_stop.stop_id,
                    'stop_name': s.bus_stop.stop_name,
                    'order': s.order,
                    'eta_seconds': None
                }
                for s in stops
            ]
            return Response({'stops': data, 'eta_source': None}, status=status.HTTP_200_OK)

        bus = get_object_or_404(Bus, pk=bus_id)
        if bus.bus_line_id != bus_line.route_id or not bus.current_location:
            data = [
                {
                    'stop_id': s.bus_stop.stop_id,
                    'stop_name': s.bus_stop.stop_name,
                    'order': s.order,
                    'eta_seconds': None
                }
                for s in stops
            ]
            return Response({'stops': data, 'eta_source': 'bus_mismatch_or_no_location'}, status=status.HTTP_200_OK)

        arrival_threshold_km = 0.1
        speed_kmh = _latest_speed_kmh(bus)
        lat = bus.current_location.latitude
        lon = bus.current_location.longitude
        start_idx, cum_dists_km = _compute_cumulative_distances_from_point(lat, lon, stops, arrival_threshold_km)

        def hours_to_seconds(h: float) -> int:
            return int(h * 3600)

        # Prepare baseline list with None ETAs
        data = [
            {
                'stop_id': s.bus_stop.stop_id,
                'stop_name': s.bus_stop.stop_name,
                'order': s.order,
                'eta_seconds': None
            }
            for s in stops
        ]

        # Fill ETA from start_idx onward
        for i, dist_km in enumerate(cum_dists_km):
            idx = start_idx + i
            if 0 <= idx < len(data):
                eta_seconds = hours_to_seconds(dist_km / speed_kmh) if speed_kmh > 0 else None
                data[idx]['eta_seconds'] = eta_seconds
                data[idx]['eta_minutes'] = eta_seconds / 60 if eta_seconds is not None else None

        return Response({
            'stops': data,
            'eta_source': 'latest_speed_log',
            'speed_kmh': speed_kmh,
            'arrival_threshold_km': arrival_threshold_km,
            'start_index': start_idx
        }, status=status.HTTP_200_OK)

class BusViewSet(viewsets.ModelViewSet):
    queryset = Bus.objects.all()
    serializer_class = BusSerializer

    @action(detail=True, methods=['post'], url_path='update-location')
    def update_location(self, request, pk=None):
        bus = self.get_object()
        latitude = request.data.get('latitude')
        longitude = request.data.get('longitude')
        speed = request.data.get('speed')

        if latitude is None or longitude is None:
            return Response({'error': 'Latitude and longitude are required.'}, status=status.HTTP_400_BAD_REQUEST)
        
        try:
            lat = float(latitude)
            lon = float(longitude)
        except (ValueError, TypeError):
            return Response({'error': 'Invalid latitude or longitude format.'}, status=status.HTTP_400_BAD_REQUEST)

        location = Location.objects.create(latitude=lat, longitude=lon)
        bus.current_location = location
        bus.save()
        
        BusLocationLog.objects.create(
            bus=bus, location=location, speed=speed, timestamp=timezone.now()
        )
        
        # Broadcast the location update via WebSocket
        try:
            channel_layer = get_channel_layer()
            if channel_layer:
                print(f"[WebSocket] Broadcasting location update for bus {bus.bus_id}: lat={lat}, lon={lon}")
                async_to_sync(channel_layer.group_send)(
                    'bus_locations',
                    {
                        'type': 'bus_location_update',
                        'data': {
                            'bus_id': bus.bus_id,
                            'license_plate': bus.license_plate,
                            'latitude': lat,
                            'longitude': lon,
                            'speed': speed,
                            'timestamp': timezone.now().isoformat(),
                        }
                    }
                )
                print(f"[WebSocket] Broadcast completed for bus {bus.bus_id}")
        except Exception as e:
            # Log the error but don't fail the request
            print(f"WebSocket broadcast error: {e}")
        
        # Check if bus is off route
        try:
            if bus.bus_line:
                stops_on_line = BusLineStop.objects.filter(bus_line=bus.bus_line)
                if stops_on_line.exists():
                    # Filter stops that have valid locations
                    stops_with_locations = [
                        stop for stop in stops_on_line 
                        if stop.bus_stop and stop.bus_stop.location
                    ]
                    
                    if stops_with_locations:
                        min_distance_to_route = min(
                            haversine(lat, lon, stop.bus_stop.location.latitude, stop.bus_stop.location.longitude)
                            for stop in stops_with_locations
                        )
                        
                        ALERT_DISTANCE_THRESHOLD_KM = 0.5 
                        if min_distance_to_route > ALERT_DISTANCE_THRESHOLD_KM:
                            Alert.objects.update_or_create(
                                bus=bus,
                                alert_type='OFF_ROUTE',
                                is_resolved=False,
                                defaults={
                                    'message': f'Bus {bus.license_plate} is off route. Last seen {min_distance_to_route:.2f} km away.',
                                    'timestamp': timezone.now()
                                }
                            )
                        else:
                            active_off_route_alerts = Alert.objects.filter(
                                bus=bus, 
                                alert_type='OFF_ROUTE', 
                                is_resolved=False
                            )
                            active_off_route_alerts.update(is_resolved=True)
        except Exception as e:
            # Log the error but don't fail the request
            print(f"Alert checking error: {e}")
        
        return Response({'status': f'Location updated for bus {bus.license_plate}'})

    @action(detail=True, methods=['get'], url_path='eta')
    def eta(self, request, pk=None):
        """
        Returns ETA information for the bus to its next and subsequent stops on the assigned route.
        Response shape:
        {
          "speed_kmh": float,
          "arrival_threshold_km": float,
          "next_stop": { stop_id, stop_name, order } | null,
          "eta_to_next_stop_seconds": int | null,
          "eta_to_each_stop": [ { stop_id, stop_name, order, eta_seconds } ]
        }
        """
        bus = self.get_object()
        if not bus.bus_line:
            return Response({
                'detail': 'Bus is not assigned to a route.',
                'speed_kmh': None,
                'arrival_threshold_km': None,
                'next_stop': None,
                'eta_to_next_stop_seconds': None,
                'eta_to_each_stop': []
            }, status=status.HTTP_200_OK)

        if not bus.current_location:
            return Response({
                'detail': 'Bus has no current location.',
                'speed_kmh': None,
                'arrival_threshold_km': None,
                'next_stop': None,
                'eta_to_next_stop_seconds': None,
                'eta_to_each_stop': []
            }, status=status.HTTP_200_OK)

        stops = _ordered_stops_for_line(bus.bus_line)
        if not stops:
            return Response({
                'detail': 'Route has no stops.',
                'speed_kmh': None,
                'arrival_threshold_km': None,
                'next_stop': None,
                'eta_to_next_stop_seconds': None,
                'eta_to_each_stop': []
            }, status=status.HTTP_200_OK)

        arrival_threshold_km = 0.1
        speed_kmh = _latest_speed_kmh(bus)

        lat = bus.current_location.latitude
        lon = bus.current_location.longitude

        start_idx, cum_dists_km = _compute_cumulative_distances_from_point(lat, lon, stops, arrival_threshold_km)

        if start_idx >= len(stops) or not cum_dists_km:
            # Either at/after last stop
            return Response({
                'detail': 'Bus is at the last stop or beyond route end.',
                'speed_kmh': speed_kmh,
                'arrival_threshold_km': arrival_threshold_km,
                'next_stop': None,
                'eta_to_next_stop_seconds': None,
                'eta_to_each_stop': []
            }, status=status.HTTP_200_OK)

        def hours_to_seconds(h: float) -> int:
            return int(h * 3600)

        # Build ETA list from start_idx
        eta_list = []
        for i, dist_km in enumerate(cum_dists_km):
            stop = stops[start_idx + i]
            eta_seconds = hours_to_seconds(dist_km / speed_kmh) if speed_kmh > 0 else None
            eta_minutes = eta_seconds / 60 if eta_seconds is not None else None
            eta_list.append({
                'stop_id': stop.bus_stop.stop_id,
                'stop_name': stop.bus_stop.stop_name,
                'order': stop.order,
                'eta_seconds': eta_seconds,
                'eta_minutes': eta_minutes
            })

        next_stop = stops[start_idx]
        next_eta_seconds = eta_list[0]['eta_seconds'] if eta_list else None
        next_eta_minutes = eta_list[0]['eta_minutes'] if eta_list else None

        return Response({
            'speed_kmh': speed_kmh,
            'arrival_threshold_km': arrival_threshold_km,
            'next_stop': {
                'stop_id': next_stop.bus_stop.stop_id,
                'stop_name': next_stop.bus_stop.stop_name,
                'order': next_stop.order
            },
            'eta_to_next_stop_seconds': next_eta_seconds,
            'eta_to_next_stop_minutes': next_eta_minutes,
            'eta_to_each_stop': eta_list
        }, status=status.HTTP_200_OK)

class BusLocationLogViewSet(viewsets.ModelViewSet):
    queryset = BusLocationLog.objects.all()
    serializer_class = BusLocationLogSerializer

class AlertViewSet(viewsets.ModelViewSet):
    queryset = Alert.objects.all()
    serializer_class = AlertSerializer


# --- NEW VIEW FOR GETTING ALL INITIAL DATA IN ONE REQUEST ---
@api_view(['GET'])
def initial_data_view(request):
    """
    Returns all initial data (bus stops, buses, bus lines) in a single API call.
    This reduces the number of requests from 3 to 1, helping with rate limits.
    
    OPTIMIZED FOR PRODUCTION:
    - Single database query with select_related/prefetch_related
    - Efficient serialization
    - Proper error handling
    """
    try:
        # Get all data with optimized queries
        # select_related: للعلاقات ForeignKey
        # prefetch_related: للعلاقات ManyToMany
        bus_stops = BusStop.objects.select_related('location').all()
        buses = Bus.objects.select_related('current_location', 'bus_line').all()
        bus_lines = BusLine.objects.all()  # Fixed: removed incorrect prefetch
        
        # Serialize data
        bus_stops_data = BusStopSerializer(bus_stops, many=True).data
        buses_data = BusSerializer(buses, many=True).data
        bus_lines_data = BusLineSerializer(bus_lines, many=True).data
        
        # Return combined response
        return Response({
            'bus_stops': bus_stops_data,
            'buses': buses_data,
            'bus_lines': bus_lines_data,
            'timestamp': timezone.now().isoformat(),
            'count': {
                'bus_stops': len(bus_stops_data),
                'buses': len(buses_data),
                'bus_lines': len(bus_lines_data)
            }
        }, status=status.HTTP_200_OK)
    except Exception as e:
        print(f"[ERROR] initial_data_view: {str(e)}")
        return Response({
            'error': 'Failed to load initial data',
            'detail': str(e) if request.user.is_staff else None
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


# --- NEW VIEW FOR DELETING A BUS LINE STOP ---
@api_view(['DELETE'])
def bus_line_stop_detail_view(request, pk):
    """
    Handles deleting a specific BusLineStop entry.
    """
    try:
        # Find the specific stop relationship entry by its primary key (pk)
        bus_line_stop = BusLineStop.objects.get(pk=pk)
    except BusLineStop.DoesNotExist:
        return Response(status=status.HTTP_404_NOT_FOUND)

    if request.method == 'DELETE':
        bus_line_stop.delete()
        # A 204 response means success but no content to return
        return Response(status=status.HTTP_204_NO_CONTENT)