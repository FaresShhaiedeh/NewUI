# Bus Tracking System - Ready to Run ✅

## Status: All Components Ready

### Backend (Django + SQL Server) ✅
- **Status**: Running on port 8000
- **Database**: SQL Server (LAPTOP-KG0UACBH\SQLEXPRESS)
- **Database Name**: BusTrackingDB
- **Test Data**: 
  - 1 Bus (ID: 3)
  - 1 Route (ID: 1)
  - 4 Users
  - 3 Authentication Tokens
- **APIs Available**:
  - POST `/api/location-updates/` - Driver app sends location
  - WebSocket `/ws/bus-locations/` - User app receives real-time updates

### Driver App (Flutter) ✅
- **Status**: Dependencies installed, no errors
- **Configuration**: 
  - API URL: `http://10.0.2.2:8000/api` (for Android emulator)
  - Uses HTTP POST to send location updates
  - Background service for continuous tracking
- **Location**: `Driver_APP-main/`

### User App (Flutter) ✅
- **Status**: Dependencies installed, no errors
- **Configuration**:
  - API URL: `http://10.0.2.2:8000`
  - WebSocket URL: `ws://10.0.2.2:8000/ws/bus-locations/`
  - Real-time bus tracking with flutter_map
- **Location**: `user_app-main/`

## Fixed Issues

### Issue 1: 1365 Errors (Missing Flutter Dependencies)
- **Problem**: Flutter packages not installed
- **Solution**: Ran `flutter pub get` for both apps
- **Result**: All dependencies installed successfully

### Issue 2: Flutter Map Package Version Conflicts
- **Problem**: flutter_map ^8.2.2 incompatible with flutter_map_marker_cluster and flutter_map_marker_popup
- **Solution**: Downgraded flutter_map to ^7.0.2 to match compatible versions
- **Result**: All packages now work together correctly

### Issue 3: SQL Server Connection
- **Problem**: Originally configured for SQLite
- **Solution**: Updated to use SQL Server with Windows Authentication
- **Result**: Database connected and migrations applied

## How to Run the System

### Step 1: Start Backend Server
The backend is already running. If you need to restart it:
```powershell
cd "c:\Users\Fares\Desktop\New folder (12)\final-main\Buses_BACK_END-main"
python manage.py runserver 0.0.0.0:8000
```

### Step 2: Run Driver App
```powershell
cd "c:\Users\Fares\Desktop\New folder (12)\final-main\Driver_APP-main"
flutter run
```

**Important**: Before running, update the `.env` file with a valid auth token from the database.

### Step 3: Run User App
```powershell
cd "c:\Users\Fares\Desktop\New folder (12)\final-main\user_app-main"
flutter run
```

## Testing the System

1. **Login to Driver App**:
   - Use credentials from the database users table
   - Select the bus (ID: 3)
   - Start tracking

2. **Open User App**:
   - The map will show the route
   - Bus location will update in real-time via WebSocket
   - You can see bus stops and estimated arrival times

3. **Verify Real-time Updates**:
   - Driver app sends location every few seconds
   - User app receives updates via WebSocket
   - Map updates automatically

## Configuration Files

### Backend `.env`
```env
DB_ENGINE=mssql
DB_HOST=LAPTOP-KG0UACBH\SQLEXPRESS
DB_NAME=BusTrackingDB
DB_USER=
DB_PASSWORD=
DEBUG=True
SECRET_KEY=your-secret-key-here
CORS_ALLOW_ALL_ORIGINS=True
```

### Driver App `.env`
```env
API_BASE_URL=http://10.0.2.2:8000/api
AUTH_TOKEN=<get-from-database-tokens>
```

### User App `app_config.dart`
```dart
static const String baseUrl = 'http://10.0.2.2:8000';
static const String websocketUrl = 'ws://10.0.2.2:8000/ws/bus-locations/';
```

## Available Authentication Tokens

From the database:
1. Token: `666af57b...` (user: fares)
2. Token: `201014c3...` (user: test)
3. Token: `f6a3e11b...` (user: qweqwe)

Use any of these tokens in the Driver app `.env` file.

## Network Configuration

- **For Android Emulator**: Use `10.0.2.2` (special alias for host machine)
- **For Physical Device**: Replace with your computer's local IP address (e.g., `192.168.1.x`)
- **Protocol**: HTTP (not HTTPS) and WS (not WSS) for local development

## Package Versions Used

### User App Key Packages
- flutter_map: ^7.0.2
- flutter_map_marker_cluster: ^1.3.6
- flutter_map_marker_popup: ^7.0.0
- flutter_bloc: ^9.1.1
- web_socket_channel: ^3.0.3
- geolocator: ^14.0.2

### Driver App Key Packages
- flutter_background_service: ^5.1.0
- geolocator: ^14.0.2
- hive: ^2.2.3
- http: ^0.13.6

## Next Steps

All components are ready to run. Simply:
1. ✅ Backend is running
2. 🚀 Launch Driver app on an emulator/device
3. 🚀 Launch User app on another emulator/device
4. ✅ Test the real-time tracking

**Note**: Make sure to add a valid auth token to the Driver app `.env` file before running it.
