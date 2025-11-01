# 🚌 Bus Tracking System - Complete Setup Guide

## Overview

This system has 3 main components:
1. **Backend (Django)** - Handles API requests and WebSocket connections
2. **Driver App (Flutter)** - Sends location updates via HTTP POST
3. **User App (Flutter)** - Receives real-time location updates via WebSocket

## Architecture

```
Driver App (Flutter) 
    ↓ HTTP POST (location updates)
Backend (Django Server)
    ↓ WebSocket (real-time broadcast)
User App (Flutter)
```

---

## 📋 Prerequisites

### Backend Requirements
- Python 3.8 or higher
- pip (Python package manager)

### Mobile Apps Requirements
- Flutter SDK 3.0 or higher
- Android Studio or VS Code with Flutter extensions
- Android Emulator or physical device

---

## 🔧 Step 1: Backend Setup

### 1.1 Navigate to Backend Directory

```powershell
cd "c:\Users\Fares\Desktop\New folder (12)\final-main\Buses_BACK_END-main"
```

### 1.2 Create Virtual Environment

```powershell
python -m venv venv
.\venv\Scripts\Activate.ps1
```

If you get an execution policy error, run:
```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

### 1.3 Install Dependencies

```powershell
pip install -r requirements.txt
```

If requirements.txt is missing packages, install manually:
```powershell
pip install django djangorestframework django-cors-headers channels channels-redis daphne python-dotenv
```

### 1.4 Configure Environment Variables

The `.env` file has been created for you. Verify it exists:
```powershell
Get-Content .env
```

### 1.5 Apply Database Migrations

```powershell
python manage.py makemigrations
python manage.py migrate
```

### 1.6 Create Superuser (Admin Account)

```powershell
python manage.py createsuperuser
```

Enter your desired username, email, and password.

### 1.7 Create Authentication Tokens

Start the Django shell:
```powershell
python manage.py shell
```

Create tokens for both apps:
```python
from django.contrib.auth.models import User
from rest_framework.authtoken.models import Token

# Create a user for the driver app
driver_user = User.objects.create_user(username='driver1', password='driver123')
driver_token = Token.objects.create(user=driver_user)
print(f"Driver Token: {driver_token.key}")

# Create a user for the user app
user_user = User.objects.create_user(username='user1', password='user123')
user_token = Token.objects.create(user=user_user)
print(f"User Token: {user_token.key}")

exit()
```

**IMPORTANT:** Copy both tokens! You'll need them for the mobile apps.

### 1.8 Create Sample Data

```powershell
python manage.py shell
```

```python
from bus_tracking.models import Bus, BusLine, BusStop, Location

# Create a bus line
line = BusLine.objects.create(
    route_id=1,
    route_name="Route 1",
    start_location="City Center",
    end_location="University"
)

# Create a bus
location = Location.objects.create(latitude=24.7136, longitude=46.6753)
bus = Bus.objects.create(
    bus_id=1,
    license_plate="ABC-123",
    bus_line=line,
    driver_name="Ahmed",
    current_location=location
)

print(f"Created Bus ID: {bus.bus_id}")
print(f"Created Route ID: {line.route_id}")

exit()
```

### 1.9 Get Your Computer's IP Address

You need this for testing on real devices:

```powershell
ipconfig
```

Look for "IPv4 Address" under your active network adapter (WiFi or Ethernet).
Example: `192.168.1.100`

### 1.10 Start the Server

```powershell
python manage.py runserver 0.0.0.0:8000
```

The server should now be running at:
- Local: http://127.0.0.1:8000
- Network: http://YOUR-IP:8000

Test it by visiting: http://127.0.0.1:8000/admin

---

## 📱 Step 2: Driver App Setup

### 2.1 Navigate to Driver App Directory

```powershell
cd "c:\Users\Fares\Desktop\New folder (12)\final-main\Driver_APP-main"
```

### 2.2 Install Flutter Dependencies

```powershell
flutter pub get
```

### 2.3 Update .env File

The `.env` file has been created. Update it with your values:

```powershell
notepad .env
```

Update these lines:
```env
# For Android Emulator (default):
API_BASE_URL=http://10.0.2.2:8000/api

# For Real Device, replace with your computer's IP:
# API_BASE_URL=http://192.168.1.100:8000/api

# Paste the driver token you created earlier:
AUTH_TOKEN=your-driver-token-here
```

### 2.4 Update API Service (if needed)

The `api_service.dart` has been configured to use the `.env` file.

### 2.5 Run the Driver App

**For Android Emulator:**
```powershell
flutter run
```

**For Real Device:**
1. Connect device via USB
2. Enable USB debugging
3. Update `.env` with your computer's IP address
4. Run: `flutter run`

### 2.6 Test Driver App

1. Open the app
2. Login with:
   - Bus ID: `1` (or the ID you created)
   - Line ID: `1` (or the line ID you created)
3. Start tracking
4. Check the backend console - you should see location updates

---

## 📱 Step 3: User App Setup

### 3.1 Navigate to User App Directory

```powershell
cd "c:\Users\Fares\Desktop\New folder (12)\final-main\user_app-main"
```

### 3.2 Install Flutter Dependencies

```powershell
flutter pub get
```

### 3.3 Update Configuration

Edit the config file:
```powershell
notepad lib\config\app_config.dart
```

Update these values:

```dart
// For Android Emulator (default):
static const String baseUrl = 'http://10.0.2.2:8000';
static const String websocketUrl = 'ws://10.0.2.2:8000/ws/bus-locations/';

// For Real Device, replace with your computer's IP:
// static const String baseUrl = 'http://192.168.1.100:8000';
// static const String websocketUrl = 'ws://192.168.1.100:8000/ws/bus-locations/';

// Paste the user token you created earlier:
static const String authToken = 'your-user-token-here';
```

### 3.4 Update Mock Data Setting

In the same file, make sure to use real data:
```dart
static const bool useMockData = false;
```

### 3.5 Run the User App

```powershell
flutter run
```

---

## ✅ Step 4: Testing the Complete System

### 4.1 Start All Components

1. **Backend**: Make sure Django server is running
   ```powershell
   cd Buses_BACK_END-main
   python manage.py runserver 0.0.0.0:8000
   ```

2. **Driver App**: Launch on emulator/device
   - Login with Bus ID and Line ID
   - Start tracking

3. **User App**: Launch on another emulator/device
   - You should see the bus on the map
   - Location should update in real-time

### 4.2 Verify Communication

**Check Backend Logs:**
You should see:
- POST requests from Driver App: `POST /api/buses/1/update-location/`
- WebSocket connection from User App: `WebSocket connected for user: user1`

**Check Driver App:**
- Should show "Tracking Active" screen
- Timer should be running

**Check User App:**
- Should show bus marker on map
- Bus marker should move as driver moves

---

## 🐛 Troubleshooting

### Backend Issues

#### Port Already in Use
```powershell
# Find process using port 8000
netstat -ano | findstr :8000

# Kill the process (replace PID with actual number)
taskkill /PID <PID> /F
```

#### Database Errors
```powershell
# Reset database
Remove-Item db.sqlite3
python manage.py migrate
```

#### CORS Errors
Check `.env` file - make sure `DEBUG=True` for development

### Driver App Issues

#### Cannot Connect to Server
1. Check if backend is running
2. For emulator: Use `10.0.2.2` instead of `localhost`
3. For real device: Use computer's IP address and ensure both are on same WiFi

#### HTTP Error 401 (Unauthorized)
- Token is incorrect or expired
- Create a new token in Django shell

#### HTTP Error 404 (Not Found)
- Bus ID doesn't exist in database
- Check admin panel: http://127.0.0.1:8000/admin

### User App Issues

#### WebSocket Connection Failed
1. Backend must be running with Channels support
2. Check if Redis is installed (or using in-memory channel layer)
3. Verify WebSocket URL is correct

#### No Buses Showing on Map
1. Check if Driver App is sending location updates
2. Verify authToken is correct in `app_config.dart`
3. Check backend logs for errors

#### Bus Not Moving
1. Driver App must be actively tracking
2. Check WebSocket connection status
3. Verify location permissions are granted

---

## 🔑 Important Notes

### Security
- **Never commit tokens to Git!** Keep `.env` files private
- For production, use HTTPS/WSS (secure connections)
- Change `DEBUG=False` in production

### Performance
- WebSocket connections require active server
- For production, deploy Redis for channel layers
- Consider using production ASGI server like Daphne or Uvicorn

### Network Configuration
- **Android Emulator**: `10.0.2.2` maps to host machine
- **iOS Simulator**: Use `127.0.0.1`
- **Real Devices**: Must be on same WiFi network as backend server

---

## 📝 Quick Reference

### Backend URLs
- Admin Panel: http://127.0.0.1:8000/admin
- API Root: http://127.0.0.1:8000/api/
- Buses List: http://127.0.0.1:8000/api/buses/
- WebSocket: ws://127.0.0.1:8000/ws/bus-locations/

### Common Commands

**Backend:**
```powershell
# Start server
python manage.py runserver 0.0.0.0:8000

# Create migrations
python manage.py makemigrations

# Apply migrations
python manage.py migrate

# Access shell
python manage.py shell
```

**Flutter:**
```powershell
# Get dependencies
flutter pub get

# Run app
flutter run

# Clean build
flutter clean

# Check devices
flutter devices
```

---

## 🎯 Next Steps

After getting everything working:

1. **Add More Buses**: Create additional buses in Django admin
2. **Add Bus Stops**: Create stops and assign them to routes
3. **Test on Real Devices**: Deploy to physical phones
4. **Enhance Security**: Implement proper authentication
5. **Production Deployment**: Use Heroku, AWS, or DigitalOcean

---

## 💡 Tips

- Use Django admin panel to manage data easily
- Check backend console for all API requests
- Use Flutter DevTools for debugging mobile apps
- Keep backend, driver app, and user app running simultaneously for testing
- Make sure all devices are on the same network

---

## ❓ Need Help?

If you encounter issues:
1. Check the logs (backend console, Flutter console)
2. Verify all URLs and tokens are correct
3. Ensure all dependencies are installed
4. Check network connectivity
5. Try restarting all components

---

## 📚 Additional Resources

- [Django Documentation](https://docs.djangoproject.com/)
- [Django REST Framework](https://www.django-rest-framework.org/)
- [Django Channels](https://channels.readthedocs.io/)
- [Flutter Documentation](https://flutter.dev/docs)

---

**Good Luck! 🚀**
