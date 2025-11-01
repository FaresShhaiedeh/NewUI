import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_marker_cluster/flutter_map_marker_cluster.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import '../routes/routes_screen.dart';
import '../complaints/complaints_screen.dart';
import '../payment_screen.dart';
import '../../models/bus.dart';
import '../../models/bus_stop.dart';
import '../../models/upcoming_stop.dart';
import '../../repositories/transport_repository.dart';
import '../../theme/app_theme.dart';
import 'widgets/bus_stop_popup.dart';
import 'widgets/upcoming_stops_widget.dart';
import 'widgets/search_bottom_sheet.dart';
import '../../config/app_config.dart';

class MainMapScreen extends StatefulWidget {
  const MainMapScreen({super.key});

  @override
  State<MainMapScreen> createState() => _MainMapScreenState();
}

enum MapStatus { loading, success, failure }

// ❌ تم حذف MapFilter enum (لم يعد مستخدماً)

class _MainMapScreenState extends State<MainMapScreen> {
  // --- Controller جديد للنوافذ المنبثقة ---
  final PopupController _popupLayerController = PopupController();

  // --- كل المتغيرات الأخرى تبقى كما هي ---
  final MapController _mapController = MapController();
  late final TransportRepository _repository;
  List<BusStop> _busStops = [];
  List<Bus> _buses = [];
  // Cached marker lists to reduce per-build allocations
  List<Marker> _cachedStopMarkers = const [];
  List<Marker> _cachedBusMarkers = const [];
  MapStatus _status = MapStatus.loading;
  String _errorMessage = '';
  StreamSubscription? _stopsSubscription;
  StreamSubscription? _busesSubscription;
  StreamSubscription? _proximitySubscription;
  Timer? _updateTimer;
  DateTime _lastUiUpdate = DateTime.fromMillisecondsSinceEpoch(0);
  // ❌ تم حذف _lastDataUpdate (لم يعد مستخدم بعد حذف تبويب آخر تحديث)
  // ❌ تم حذف متغيرات الفلاتر (_filter, _nearbyCenter, _nearbyRadiusMeters)
  Bus? _nearestBus;
  String? _estimatedTime;
  String? _nearestBusLineName;
  Bus? _selectedBus;
  BusStopInfo? _selectedBusStopInfo;
  bool _showUpcomingStops = false;

  @override
  void initState() {
    super.initState();
    _repository = Provider.of<TransportRepository>(context, listen: false);

    // Precache marker image for smoother first render
    WidgetsBinding.instance.addPostFrameCallback((_) {
      precacheImage(
        const AssetImage('lib/assets/images/thumbnail.png'),
        context,
      );
    });

    _stopsSubscription = _repository.busStopsStream.listen(
      (stops) {
        if (mounted) setState(() => _busStops = stops);
        _rebuildStopMarkers();
      },
      onError: (error) {
        if (mounted) {
          setState(() {
            _errorMessage = 'فشل في جلب بيانات المواقف';
            _status = MapStatus.failure;
          });
        }
      },
    );

    _busesSubscription = _repository.busStream.listen(
      (buses) {
        if (mounted) {
          setState(() {
            _buses = buses;
            _status = MapStatus.success;
            // ❌ تم حذف _lastDataUpdate (لم يعد مستخدم)
            _rebuildBusMarkers(); // Rebuild markers inside setState so UI updates
          });
        }
      },
      onError: (error) {
        if (mounted) {
          setState(() {
            _errorMessage = 'فشل في جلب بيانات الحافلات';
            _status = MapStatus.failure;
          });
        }
      },
    );

    // Listen for bus stop proximity notifications
    _proximitySubscription = _repository.busStopProximityStream.listen((event) {
      if (mounted) {
        final message = event['message'] as String;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message, style: const TextStyle(fontSize: 16)),
            backgroundColor: Colors.green[700],
            duration: const Duration(seconds: 4),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    });

    _repository.fetchInitialData();

    _updateTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
      final now = DateTime.now();
      // تحديث كل نصف ثانية للحصول على حركة سلسة
      if (now.difference(_lastUiUpdate).inMilliseconds < 400) return;
      _lastUiUpdate = now;
      _updateNearestBusInfo();
    });

    // 🎯 تمركز على موقع المستخدم بعد تحميل البيانات (بتأخير 2 ثانية)
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted && _status == MapStatus.success) {
        _centerOnUserLocation();
      }
    });
  }

  @override
  void dispose() {
    _mapController.dispose();
    _stopsSubscription?.cancel();
    _busesSubscription?.cancel();
    _proximitySubscription?.cancel();
    _updateTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: const LatLng(33.5138, 36.2765),
              initialZoom: 14.0,
              onTap: (tapPosition, point) {
                debugPrint(
                  '[MapTap] Map tapped at: ${point.latitude}, ${point.longitude}',
                );

                // Check if tap is near any bus
                Bus? tappedBus;
                for (final bus in _buses) {
                  final distance = const Distance().distance(
                    LatLng(bus.position.latitude, bus.position.longitude),
                    point,
                  );
                  debugPrint(
                    '[MapTap] Distance to bus ${bus.id}: ${distance.toStringAsFixed(2)}m',
                  );
                  // If tap is within 50 meters of bus position, consider it a tap on that bus
                  if (distance < 50) {
                    tappedBus = bus;
                    break;
                  }
                }

                if (tappedBus != null) {
                  // Bus was tapped
                  debugPrint('[MapTap] Bus ${tappedBus.id} detected!');
                  _onBusMarkerTapped(tappedBus);
                } else {
                  // Empty map area tapped
                  _popupLayerController.hideAllPopups();
                  // Clear any selection state
                  if (_nearestBus != null ||
                      _estimatedTime != null ||
                      _nearestBusLineName != null ||
                      _selectedBus != null) {
                    setState(() {
                      _nearestBus = null;
                      _estimatedTime = null;
                      _nearestBusLineName = null;
                      _selectedBus = null;
                      _selectedBusStopInfo = null;
                      _showUpcomingStops = false;
                    });
                  }
                }
              },
            ),
            children: [
              TileLayer(
                // 🗺️ CartoDB Positron - خريطة فاتحة ونظيفة
                urlTemplate:
                    'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}.png',
                subdomains: const ['a', 'b', 'c', 'd'],
                userAgentPackageName: 'com.example.bus_tracking_app',
              ),
              // طبقة الحافلات بدون تجميع للسماح بالنقر
              MarkerLayer(markers: _cachedBusMarkers),
              // الكود الجديد الصحيح
              RepaintBoundary(
                child: PopupMarkerLayer(
                  options: PopupMarkerLayerOptions(
                    popupController: _popupLayerController,
                    // أظهر النوافذ المنبثقة لمواقف الحافلات فقط
                    markers: _cachedStopMarkers,
                    // --- بداية الإصلاح ---
                    popupDisplayOptions: PopupDisplayOptions(
                      builder: (BuildContext context, Marker marker) {
                        // كل منطق بناء النافذة المنبثقة يأتي هنا
                        if (marker.key is ValueKey<String>) {
                          final keyString =
                              (marker.key as ValueKey<String>).value;
                          if (keyString.startsWith('stop_')) {
                            final stopId = keyString.substring(5);
                            final stop = _busStops.firstWhere(
                              (s) => s.id == stopId,
                            );
                            return BusStopPopup(
                              stop: stop,
                              allBuses: _buses,
                              allBusLines: _repository.busLines,
                              popupController: _popupLayerController,
                            );
                          }
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                    // --- نهاية الإصلاح ---
                  ),
                ),
              ),
            ],
          ),
          if (_status == MapStatus.loading)
            Container(
              color: AppColors.background.withOpacity(0.95),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: AppColors.primary),
                    const SizedBox(height: 16),
                    Text('جارٍ التحديث…', style: AppTextStyles.bodyLarge),
                  ],
                ),
              ),
            ),
          if (_status == MapStatus.failure)
            Container(
              color: AppColors.background.withOpacity(0.95),
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.error_outline_rounded,
                        color: AppColors.error,
                        size: 64,
                      ),
                      const SizedBox(height: 20),
                      Text('حدث خطأ', style: AppTextStyles.heading2),
                      const SizedBox(height: 12),
                      Text(
                        _errorMessage,
                        textAlign: TextAlign.center,
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.refresh, size: 20),
                        onPressed: () {
                          setState(() => _status = MapStatus.loading);
                          _repository.fetchInitialData();
                        },
                        label: Text(
                          'حاول مرة أخرى',
                          style: AppTextStyles.button,
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: AppColors.textOnPrimary,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 14,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: AppBorders.medium,
                          ),
                          elevation: 2,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          if (_status == MapStatus.success) ...[
            _buildFloatingSearchBar(), // ✅ إرجاع شريط البحث
            _buildLeftSideButtons(),
            _buildFloatingActionButtons(),
            _buildBottomInfoSheet(),
            if (_showUpcomingStops) _buildUpcomingStopsSheet(),
          ],
        ],
      ),
    );
  }

  List<Marker> _buildStopMarkers() {
    // ✅ عرض جميع المحطات (تم حذف الفلاتر)
    return _busStops.map((stop) {
      return Marker(
        key: ValueKey('stop_${stop.id}'),
        width: 40.0,
        height: 40.0,
        point: stop.position,
        child: Image.asset('lib/assets/images/thumbnail.png'),
      );
    }).toList();
  }

  List<Marker> _buildBusMarkers() {
    // ✅ عرض جميع الباصات بتصميم موحد مع المحطات
    return _buses.map((bus) {
      final isSelected = _selectedBus?.id == bus.id;
      return Marker(
        key: ValueKey('bus_${bus.id}'),
        width: isSelected ? 50.0 : 45.0,
        height: isSelected ? 50.0 : 45.0,
        point: bus.position,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              debugPrint('[BusTap] Raw tap detected on bus ${bus.id}');
              _onBusMarkerTapped(bus);
            },
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                border: isSelected
                    ? Border.all(color: AppColors.primary, width: 3)
                    : Border.all(color: AppColors.divider, width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                Icons.directions_bus_rounded,
                color: _getBusColor(bus.status),
                size: isSelected ? 28 : 24,
              ),
            ),
          ),
        ),
      );
    }).toList();
  }

  void _onBusMarkerTapped(Bus bus) {
    debugPrint('[BusTap] Bus ${bus.id} tapped');
    setState(() {
      if (_selectedBus?.id == bus.id) {
        // Toggle off if clicking same bus
        debugPrint('[BusTap] Deselecting bus ${bus.id}');
        _selectedBus = null;
        _selectedBusStopInfo = null;
        _showUpcomingStops = false;
      } else {
        // Select new bus and get its upcoming stops
        debugPrint('[BusTap] Selecting bus ${bus.id}, lineId: ${bus.lineId}');
        _selectedBus = bus;
        _showUpcomingStops = true;
        try {
          _selectedBusStopInfo = _repository.getUpcomingStops(bus.id);
          if (_selectedBusStopInfo != null) {
            debugPrint(
              '[BusTap] Got ${_selectedBusStopInfo!.upcomingStops.length} upcoming stops',
            );
          } else {
            debugPrint('[BusTap] No stop info available');
          }
        } catch (e) {
          debugPrint('[BusTap] Error getting upcoming stops: $e');
          _selectedBusStopInfo = null;
        }
      }
      _rebuildBusMarkers(); // Rebuild to show selection
    });
  }

  void _rebuildStopMarkers() {
    _cachedStopMarkers = _buildStopMarkers();
  }

  void _rebuildBusMarkers() {
    _cachedBusMarkers = _buildBusMarkers();
  }

  Future<void> _updateNearestBusInfo() async {
    if (_status != MapStatus.success || _buses.isEmpty) return;
    try {
      final userLocationData = await _determinePosition();
      final userLocation = LatLng(
        userLocationData.latitude,
        userLocationData.longitude,
      );
      final nearest = _findNearestBus(userLocation, _buses);
      if (nearest != null) {
        final distance = Geolocator.distanceBetween(
          userLocation.latitude,
          userLocation.longitude,
          nearest.position.latitude,
          nearest.position.longitude,
        );
        final lineName = _getLineNameById(nearest.lineId) ?? 'خط غير معروف';
        final newEta = _estimateArrivalTime(distance);
        final shouldUpdate =
            _nearestBus?.id != nearest.id ||
            _estimatedTime != newEta ||
            _nearestBusLineName != lineName;
        if (mounted && shouldUpdate) {
          setState(() {
            _nearestBus = nearest;
            _estimatedTime = newEta;
            _nearestBusLineName = lineName;
          });
        }
      }
    } catch (e) {
      debugPrint('Error updating nearest bus info: $e');
      if (mounted) setState(() => _nearestBus = null);
    }
  }

  String? _getLineNameById(String lineId) {
    try {
      return _repository.busLines.firstWhere((line) => line.id == lineId).name;
    } catch (e) {
      return null;
    }
  }

  Bus? _findNearestBus(LatLng userLocation, List<Bus> buses) {
    if (buses.isEmpty) return null;
    Bus? nearestBus;
    double smallestD2 = double.infinity;
    for (final bus in buses) {
      final d2 = _distance2(userLocation, bus.position);
      if (d2 < smallestD2) {
        smallestD2 = d2;
        nearestBus = bus;
      }
    }
    return nearestBus;
  }

  // Fast approximate squared distance in degrees (good for nearest comparisons)
  double _distance2(LatLng a, LatLng b) {
    final dx = a.latitude - b.latitude;
    final dy = a.longitude - b.longitude;
    return dx * dx + dy * dy;
  }

  String _estimateArrivalTime(double distanceInMeters) {
    const averageBusSpeedKmh = 25.0;
    final speedMps = averageBusSpeedKmh * 1000 / 3600;
    if (distanceInMeters < 50) return 'قريب جدًا';
    final timeInSeconds = distanceInMeters / speedMps;
    final timeInMinutes = (timeInSeconds / 60).ceil();
    return ' ~ $timeInMinutes دقائق';
  }

  // ❌ تم حذف دوال الفلاتر بالكامل (_applyBusFilter, _applyStopFilter, _buildFilterChips, _chip)

  Future<void> _centerOnUserLocation() async {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('جاري تحديد موقعك...'),
        duration: Duration(seconds: 2),
      ),
    );
    try {
      final position = await _determinePosition();
      _mapController.move(LatLng(position.latitude, position.longitude), 15.0);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('لا يمكن تحديد الموقع: ${e.toString()}')),
      );
    }
  }

  Future<Position> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return Future.error('خدمات تحديد الموقع معطلة.');
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied)
        return Future.error('تم رفض صلاحيات الوصول للموقع.');
    }
    if (permission == LocationPermission.deniedForever)
      return Future.error('تم رفض صلاحيات الموقع بشكل دائم.');
    return await Geolocator.getCurrentPosition();
  }

  Color _getBusColor(BusStatus status) {
    switch (status) {
      case BusStatus.IN_SERVICE:
        return Colors.lightBlue;
      case BusStatus.DELAYED:
        return Colors.orange;
      case BusStatus.NOT_IN_SERVICE:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Widget _buildCircularButton({
    required IconData icon,
    required VoidCallback onPressed,
    Color? backgroundColor,
  }) {
    // 🎨 أزرار دائرية بخلفية بيضاء وأيقونة سوداء (نمط موحد)
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: AppBorders.circular,
        child: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: const Color(0xF2FFFFFF), // خلفية بيضاء شبه شفافة
            shape: BoxShape.circle,
            boxShadow: const [
              BoxShadow(
                color: Color(0x26000000), // ظل خفيف
                blurRadius: 8,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: Icon(
            icon,
            color: const Color(0xCC000000), // أيقونة سوداء
            size: 26,
          ),
        ),
      ),
    );
  }

  /// 🎨 نمط الأزرار الموحد للخريطة (نسخة طبق الأصل من ما أرسلت)
  Widget buildMapButton(IconData icon, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: const Color(0xF2FFFFFF),
          shape: BoxShape.circle,
          boxShadow: [
            const BoxShadow(
              color: Color(0x26000000),
              blurRadius: 8,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Icon(icon, color: const Color(0xCC000000), size: 26),
      ),
    );
  }

  Widget _buildLeftSideButtons() {
    // All left side buttons removed (zoom, layers, schedule, filter)
    return const SizedBox.shrink();
  }

  // 🔍 شريط البحث العلوي - يمتد على كامل الشاشة
  Widget _buildFloatingSearchBar() {
    return Positioned(
      top: 50.0,
      left: 15.0,
      right: 15.0, // تغيير من 80 إلى 15 ليمتد على كامل الشاشة
      child: GestureDetector(
        onTap: _showSearchBottomSheet,
        child: Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: AppBorders.large,
            boxShadow: AppShadows.card,
          ),
          child: Row(
            children: [
              Icon(Icons.search, color: AppColors.primary, size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'ابحث عن محطة أو حافلة...',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textHint,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFloatingActionButtons() {
    // 🎨 الأزرار الجانبية - منزلة تحت شريط البحث
    return Positioned(
      top: 120.0, // تغيير من 100 إلى 120 لتجنب التداخل مع البحث
      right: 15.0,
      child: Column(
        children: [
          _buildCircularButton(
            icon: Icons.menu,
            onPressed: () {
              Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => const RoutesScreen()));
            },
            backgroundColor: AppColors.accent,
          ),
          const SizedBox(height: 10),
          _buildCircularButton(
            icon: Icons.my_location,
            onPressed: _centerOnUserLocation,
            backgroundColor: AppColors.primary,
          ),
          const SizedBox(height: 10),
          _buildCircularButton(
            icon: Icons.refresh,
            onPressed: _resetMapView,
            backgroundColor: AppColors.primaryDark,
          ),
          const SizedBox(height: 10),
          _buildCircularButton(
            icon: Icons.feedback_outlined,
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ComplaintsScreen()),
              );
            },
            backgroundColor: AppColors.info,
          ),
          const SizedBox(height: 10),
          _buildCircularButton(
            icon: Icons.qr_code_scanner,
            onPressed: () {
              Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => const PaymentScreen()));
            },
            backgroundColor: AppColors.success,
          ),
        ],
      ),
    );
  }

  // 🔍 عرض شاشة البحث المنبثقة
  void _showSearchBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => SearchBottomSheet(
        onLocationSelected: (location) {
          // الانتقال إلى الموقع المحدد
          _mapController.move(location, 16.0);
        },
        useMockData: AppConfig.useMockData,
        busStops: _busStops,
        buses: _buses,
        busLines: [], // يمكن إضافتها لاحقاً
      ),
    );
  }

  void _resetMapView() {
    // Try to fit all stops, fallback to initial center/zoom
    if (_busStops.isNotEmpty) {
      try {
        final latitudes = _busStops.map((s) => s.position.latitude).toList();
        final longitudes = _busStops.map((s) => s.position.longitude).toList();

        // Validate coordinates - ensure they're not NaN or Infinity
        if (latitudes.any((lat) => !lat.isFinite) ||
            longitudes.any((lng) => !lng.isFinite)) {
          // Invalid coordinates, use default view
          _mapController.move(const LatLng(33.5138, 36.2765), 14.0);
          return;
        }

        final minLat = latitudes.reduce((a, b) => a < b ? a : b);
        final maxLat = latitudes.reduce((a, b) => a > b ? a : b);
        final minLng = longitudes.reduce((a, b) => a < b ? a : b);
        final maxLng = longitudes.reduce((a, b) => a > b ? a : b);

        // Additional validation - ensure bounds are valid
        if (!minLat.isFinite ||
            !maxLat.isFinite ||
            !minLng.isFinite ||
            !maxLng.isFinite ||
            minLat == maxLat ||
            minLng == maxLng) {
          _mapController.move(const LatLng(33.5138, 36.2765), 14.0);
          return;
        }

        final bounds = LatLngBounds(
          LatLng(minLat, minLng),
          LatLng(maxLat, maxLng),
        );
        _mapController.fitCamera(
          CameraFit.bounds(bounds: bounds, padding: const EdgeInsets.all(60)),
        );
      } catch (e) {
        debugPrint('Error fitting camera to bounds: $e');
        _mapController.move(const LatLng(33.5138, 36.2765), 14.0);
      }
    } else {
      _mapController.move(const LatLng(33.5138, 36.2765), 14.0);
    }
    // Also clear popups and selection
    _popupLayerController.hideAllPopups();
    if (_nearestBus != null ||
        _estimatedTime != null ||
        _nearestBusLineName != null) {
      setState(() {
        _nearestBus = null;
        _estimatedTime = null;
        _nearestBusLineName = null;
      });
    }
  }

  Widget _buildBottomInfoSheet() {
    if (_nearestBus == null || _estimatedTime == null) {
      return const SizedBox.shrink();
    }
    return Positioned(
      bottom: 20.0,
      left: 20.0,
      right: 20.0,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 15.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15.0),
          boxShadow: [
            BoxShadow(
              color: const Color.fromARGB(26, 0, 0, 0),
              spreadRadius: 2,
              blurRadius: 8,
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _nearestBusLineName ?? '...',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            Row(
              children: [
                const Icon(Icons.directions_bus, color: Colors.grey),
                const SizedBox(width: 10),
                Text(
                  _estimatedTime!,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(width: 5),
                const Icon(Icons.access_time, color: Colors.green),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUpcomingStopsSheet() {
    return Positioned(
      bottom: 100,
      left: 0,
      right: 0,
      child: GestureDetector(
        onTap: () {}, // Prevent tap from propagating to map
        child: Container(
          constraints: const BoxConstraints(maxHeight: 400),
          child: SingleChildScrollView(
            child: UpcomingStopsWidget(busStopInfo: _selectedBusStopInfo),
          ),
        ),
      ),
    );
  }
}
