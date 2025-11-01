# 🔧 Bus Tracking System - Troubleshooting Guide

## Table of Contents
1. [Backend Issues](#backend-issues)
2. [Driver App Issues](#driver-app-issues)
3. [User App Issues](#user-app-issues)
4. [Network Issues](#network-issues)
5. [Common Error Messages](#common-error-messages)

---

## Backend Issues

### Issue: Cannot Start Server - Port Already in Use

**Error Message:**
```
Error: That port is already in use.
```

**Solution:**
```powershell
# Find process using port 8000
netstat -ano | findstr :8000

# Note the PID (last column), then kill it:
taskkill /PID <PID> /F

# Or use a different port:
python manage.py runserver 0.0.0.0:8001
```

### Issue: ModuleNotFoundError

**Error Message:**
```
ModuleNotFoundError: No module named 'django'
```

**Solution:**
```powershell
# Make sure virtual environment is activated
.\venv\Scripts\Activate.ps1

# Reinstall dependencies
pip install -r requirements.txt

# Or install manually:
pip install django djangorestframework django-cors-headers channels daphne python-dotenv
```

### Issue: Database Migration Errors

**Error Message:**
```
django.db.migrations.exceptions.InconsistentMigrationHistory
```

**Solution:**
```powershell
# Option 1: Reset database (WARNING: Deletes all data)
Remove-Item db.sqlite3
python manage.py migrate

# Option 2: Fake migrations
python manage.py migrate --fake bus_tracking zero
python manage.py migrate bus_tracking
```

### Issue: CORS Error from Mobile Apps

**Error Message in Browser/Mobile:**
```
Access to fetch at 'http://...' has been blocked by CORS policy
```

**Solution:**

1. Check `.env` file:
```env
DEBUG=True
CORS_ALLOWED_ORIGINS=http://localhost:8000,http://127.0.0.1:8000,http://10.0.2.2:8000
```

2. Verify `settings.py`:
```python
if DEBUG:
    CORS_ALLOW_ALL_ORIGINS = True
```

3. Make sure `corsheaders` middleware is in `MIDDLEWARE` list

### Issue: WebSocket Connection Refused

**Error Message:**
```
WebSocket connection failed
```

**Solution:**

1. Check if server is running with ASGI support:
```powershell
# Use daphne instead of runserver for WebSocket support
daphne -b 0.0.0.0 -p 8000 BusTrackingSystem.asgi:application
```

2. Or use the in-memory channel layer (already configured in DEBUG mode)

3. For production, install Redis:
```powershell
# Windows: Download from https://github.com/microsoftarchive/redis/releases
# Or use Docker:
docker run -d -p 6379:6379 redis
```

---

## Driver App Issues

### Issue: Cannot Connect to Backend

**Error Message:**
```
Failed to load bus data. Status code: [error]
```

**Solutions:**

#### For Android Emulator:
```dart
// In .env file:
API_BASE_URL=http://10.0.2.2:8000/api
```

#### For iOS Simulator:
```dart
// In .env file:
API_BASE_URL=http://127.0.0.1:8000/api
```

#### For Real Device:
1. Get your computer's IP:
   ```powershell
   ipconfig
   ```

2. Update `.env`:
   ```env
   API_BASE_URL=http://192.168.1.100:8000/api
   ```

3. Make sure:
   - Device and computer are on same WiFi
   - Windows Firewall allows port 8000
   - Backend is running with `0.0.0.0:8000`

### Issue: HTTP 401 Unauthorized

**Error Message:**
```
Failed to load bus data. Status code: 401
```

**Solutions:**

1. Check if token is correct in `.env`:
```env
AUTH_TOKEN=your-actual-token-here
```

2. Create new token in Django:
```powershell
python manage.py shell
```

```python
from django.contrib.auth.models import User
from rest_framework.authtoken.models import Token

user = User.objects.get(username='driver1')
Token.objects.filter(user=user).delete()  # Delete old token
new_token = Token.objects.create(user=user)
print(f"New Token: {new_token.key}")
```

### Issue: HTTP 404 Not Found

**Error Message:**
```
Failed to load bus data. Status code: 404
```

**Solutions:**

1. Check if bus exists:
   - Visit: http://127.0.0.1:8000/admin/bus_tracking/bus/
   - Login and verify bus ID

2. Create bus in Django shell:
```python
from bus_tracking.models import Bus, BusLine, Location

line = BusLine.objects.create(
    route_id=1,
    route_name="Route 1",
    start_location="Start",
    end_location="End"
)

location = Location.objects.create(latitude=24.7136, longitude=46.6753)
bus = Bus.objects.create(
    bus_id=1,
    license_plate="ABC-123",
    bus_line=line,
    driver_name="Ahmed",
    current_location=location
)
```

### Issue: Location Not Updating

**Symptoms:**
- App shows tracking active but backend doesn't receive updates

**Solutions:**

1. Check location permissions:
   - Android: Settings → Apps → Driver App → Permissions → Location → Allow all the time

2. Check if background service started:
   - Look for notification "Tracking Active"

3. Check logs:
```powershell
flutter logs
```

4. Check backend logs for POST requests

### Issue: App Crashes on Startup

**Error Message:**
```
MissingPluginException
```

**Solutions:**

1. Clean and rebuild:
```powershell
flutter clean
flutter pub get
flutter run
```

2. For background service issues:
```powershell
cd android
./gradlew clean
cd ..
flutter run
```

---

## User App Issues

### Issue: No Buses Showing on Map

**Symptoms:**
- Map loads but no bus markers appear

**Solutions:**

1. Check if using real data:
```dart
// In lib/config/app_config.dart:
static const bool useMockData = false;
```

2. Check if token is correct:
```dart
static const String authToken = 'your-user-token-here';
```

3. Check if backend has buses:
   - Visit: http://127.0.0.1:8000/api/buses/
   - Should return list of buses

4. Check console logs:
```powershell
flutter logs
```

### Issue: WebSocket Not Connecting

**Error Message:**
```
[WebSocket] Connection failed
```

**Solutions:**

#### For Android Emulator:
```dart
static const String websocketUrl = 'ws://10.0.2.2:8000/ws/bus-locations/';
```

#### For Real Device:
```dart
static const String websocketUrl = 'ws://192.168.1.100:8000/ws/bus-locations/';
```

**Important:** 
- Use `ws://` (not `wss://`) for local development
- Use `wss://` only with proper SSL certificate in production

### Issue: Bus Marker Not Moving

**Symptoms:**
- Bus appears on map but doesn't move

**Solutions:**

1. Verify Driver App is sending updates:
   - Check backend console for POST requests
   - Should see: `POST /api/buses/1/update-location/`

2. Check WebSocket connection:
   - Backend should log: `WebSocket connected for user: user1`

3. Check if WebSocket is receiving updates:
   - Backend should log: `bus_location_update sent to group`

---

## Network Issues

### Issue: Cannot Access Backend from Real Device

**Symptoms:**
- Works on emulator but not on real device

**Checklist:**

1. **Same Network:** 
   - Device and computer must be on same WiFi network

2. **Firewall:**
   ```powershell
   # Allow port 8000 through Windows Firewall
   netsh advfirewall firewall add rule name="Django Dev Server" dir=in action=allow protocol=TCP localport=8000
   ```

3. **Server Binding:**
   - Must use `0.0.0.0:8000` not `127.0.0.1:8000`
   ```powershell
   python manage.py runserver 0.0.0.0:8000
   ```

4. **IP Address:**
   - Use actual IP, not localhost
   - Get IP: `ipconfig`

5. **Mobile Data:**
   - Disable mobile data on device
   - Use WiFi only

### Issue: Intermittent Connection Drops

**Solutions:**

1. Keep screen on during testing
2. Disable battery optimization for the apps
3. Use a WiFi extender if signal is weak
4. Check router settings (QoS, firewall)

---

## Common Error Messages

### "API configuration is missing in .env file"

**Cause:** `.env` file not loaded or missing

**Solution:**
1. Check if `.env` exists in project root
2. Make sure it has:
   ```env
   API_BASE_URL=http://10.0.2.2:8000/api
   AUTH_TOKEN=your-token-here
   ```
3. Restart app

### "Invalid JSON response from server"

**Cause:** Backend returning HTML error page instead of JSON

**Solution:**
1. Check URL is correct: `/api/buses/1/` not `/buses/1/`
2. Check if Django is running
3. Visit URL in browser to see actual error

### "Connection timeout"

**Cause:** Cannot reach backend server

**Solutions:**
1. Ping the server:
   ```powershell
   ping 10.0.2.2
   # or
   ping 192.168.1.100
   ```

2. Check if server is running
3. Check firewall
4. Check network connectivity

### "Certificate verification failed"

**Cause:** Using HTTPS without proper certificate

**Solution:**
- For development, use HTTP (not HTTPS)
- Update URLs to use `http://` instead of `https://`
- For production, use proper SSL certificate

---

## Debug Checklist

When something doesn't work, check in this order:

### Backend
- [ ] Server is running
- [ ] No error messages in console
- [ ] Can access http://127.0.0.1:8000/admin
- [ ] Buses exist in database
- [ ] Users and tokens exist

### Network
- [ ] Computer and device on same WiFi
- [ ] Firewall allows port 8000
- [ ] Can ping server from device
- [ ] Server running on `0.0.0.0:8000`

### Driver App
- [ ] `.env` file exists and is correct
- [ ] Token is valid
- [ ] Bus ID exists in database
- [ ] Location permissions granted
- [ ] Background service running

### User App
- [ ] `app_config.dart` has correct URLs
- [ ] Token is valid
- [ ] `useMockData` is false
- [ ] WebSocket URL is correct (ws:// not wss://)

---

## Still Having Issues?

1. **Enable Debug Logging:**
   - Backend: Set `LOG_LEVEL=DEBUG` in `.env`
   - Flutter: Use `flutter run --verbose`

2. **Check All Logs:**
   - Backend console
   - Flutter console
   - Android logcat: `adb logcat`

3. **Test Components Separately:**
   - Test backend API with Postman or browser
   - Test WebSocket with online tools
   - Test location permissions

4. **Start Fresh:**
   ```powershell
   # Backend
   Remove-Item db.sqlite3
   python manage.py migrate
   
   # Flutter
   flutter clean
   flutter pub get
   flutter run
   ```

---

## Quick Test Script

Use this to verify everything works:

```powershell
# 1. Test backend
curl http://127.0.0.1:8000/api/buses/

# 2. Test authentication
curl -H "Authorization: Token YOUR-TOKEN" http://127.0.0.1:8000/api/buses/

# 3. Test location update
curl -X POST http://127.0.0.1:8000/api/buses/1/update-location/ `
  -H "Authorization: Token YOUR-TOKEN" `
  -H "Content-Type: application/json" `
  -d '{\"latitude\": \"24.7136\", \"longitude\": \"46.6753\", \"speed\": \"0\"}'
```

---

**Remember:** Most issues are network or configuration related. Double-check URLs, tokens, and network connectivity first!
