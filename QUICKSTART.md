# 🚀 Quick Start Guide - دليل البدء السريع

## بدء التطبيق محلياً (Windows PowerShell)

### الخطوة 1️⃣: تشغيل Backend

```powershell
# افتح Terminal 1: Backend Setup
cd "C:\Users\Windows.11\Desktop\final_masar\final masar\Buses_BACK_END-main"

# إنشاء virtual environment
python -m venv .venv
.\.venv\Scripts\Activate.ps1

# تثبيت المتطلبات
pip install -r requirements.txt

# إعداد .env (انسخ من .env.example وعدّل القيم)
# للتطوير المحلي:
# DB_ENGINE=sqlite  (يمكن تركه على SQLite للاختبار السريع)
# REDIS_URL=redis://localhost:6379/0
# DEBUG=True
# ALLOWED_HOSTS=localhost,127.0.0.1

# تشغيل Migrations
python manage.py migrate

# تحميل البيانات الأولية (اختياري)
python manage.py populate_database
```

### الخطوة 2️⃣: تشغيل Redis

```powershell
# افتح Terminal 2: Redis
# على Windows، قم بتحميل Redis من:
# https://github.com/microsoftarchive/redis/releases

# أو استخدم WSL:
wsl
redis-server

# أو Docker:
docker run -d -p 6379:6379 redis:latest
```

### الخطوة 3️⃣: تشغيل Django Channels Server

```powershell
# في Terminal 1 (Backend)
# تأكد من تفعيل virtual environment:
.\.venv\Scripts\Activate.ps1

# تشغيل daphne (ASGI server)
daphne -b 0.0.0.0 -p 8000 BusTrackingSystem.asgi:application

# سيظهر:
# Starting server process [PID]
# HTTP/2 support enabled
# Listening on TCP address 0.0.0.0:8000
```

### الخطوة 4️⃣: تشغيل Driver App (Flutter)

```powershell
# افتح Terminal 3: Driver App
cd "C:\Users\Windows.11\Desktop\final_masar\final masar\Driver_APP-main"

# تحديث dependencies
flutter pub get

# إعداد .env
# API_BASE_URL=https://127.0.0.1:8000/api  (في dev مع http://)
# AUTH_TOKEN=your-token-here

# التشغيل على emulator
flutter run

# أو على جهاز محدد:
flutter devices  # لمعرفة ID الجهاز
flutter run -d <device-id>
```

### الخطوة 5️⃣: تشغيل User App (Flutter)

```powershell
# افتح Terminal 4: User App
cd "C:\Users\Windows.11\Desktop\final_masar\final masar\user_app-main"

# تحديث dependencies
flutter pub get

# عدّل lib/config/app_config.dart:
# baseUrl = 'http://127.0.0.1:8000'    (في dev)
# websocketUrl = 'ws://127.0.0.1:8000/ws/bus-locations/'  (في dev)

# التشغيل
flutter run
```

---

## 🔧 الإعدادات للتطوير المحلي

### Backend .env (Development)
```bash
DEBUG=True
ALLOWED_HOSTS=localhost,127.0.0.1,10.0.2.2
CSRF_TRUSTED_ORIGINS=http://localhost:3000,http://127.0.0.1:8000

# Database (SQLite للتطوير السريع)
DB_ENGINE=sqlite

# Redis
REDIS_URL=redis://localhost:6379/0

# API
API_TIMEOUT=30
```

### Driver App .env
```bash
API_BASE_URL=http://127.0.0.1:8000/api
AUTH_TOKEN=your-driver-token-here
LOCATION_UPDATE_INTERVAL=5000
ENABLE_BACKGROUND_SERVICE=true
```

### User App config/app_config.dart
```dart
static const String baseUrl = 'http://127.0.0.1:8000';
static const String websocketUrl = 'ws://127.0.0.1:8000/ws/bus-locations/';
static const String authToken = 'your-user-token-here';
static const bool useMockData = false;
```

---

## 📋 اختبار الاتصالات

### 1. اختبار REST API
```powershell
# في PowerShell:
$headers = @{
    'Authorization' = 'Token your-token-here'
    'Content-Type' = 'application/json'
}

Invoke-WebRequest `
    -Uri 'http://localhost:8000/api/buses/' `
    -Headers $headers
```

### 2. اختبار WebSocket
```bash
# استخدام wscat أو أي WebSocket client:
npm install -g wscat

wscat -c ws://localhost:8000/ws/bus-locations/
# ثم أرسل: {"type": "heartbeat"}
```

### 3. اختبار Database
```powershell
# في PowerShell (من مجلد Backend):
python manage.py shell

# في Python shell:
from bus_tracking.models import Bus
Bus.objects.all()
```

---

## 🐛 حل المشاكل الشائعة

### ❌ "Redis connection refused"
```powershell
# ✅ الحل:
# 1. تأكد من تشغيل Redis
redis-server

# 2. أو استخدم Docker:
docker run -d -p 6379:6379 redis:latest

# 3. تحقق من REDIS_URL في .env
# يجب أن تكون: redis://localhost:6379/0
```

### ❌ "WebSocket connection timeout"
```powershell
# ✅ الحل:
# 1. تأكد من تشغيل daphne
daphne -b 0.0.0.0 -p 8000 BusTrackingSystem.asgi:application

# 2. تأكد من URL:
# - في development: ws://127.0.0.1:8000/ws/...
# - في production: wss://api.example.com/ws/...
```

### ❌ "CORS error"
```
✅ الحل: تحقق من ALLOWED_ORIGINS في settings.py
```

### ❌ "Token authentication failed"
```powershell
# ✅ الحل:
# 1. أنشئ token جديد:
python manage.py drf_create_token <username>

# 2. أو من Django shell:
from rest_framework.authtoken.models import Token
from django.contrib.auth.models import User

user = User.objects.get(username='driver')
token, created = Token.objects.get_or_create(user=user)
print(token.key)
```

---

## 🎯 الاختبارات السريعة

### اختبار 1: تحميل بيانات المحاكاة
```powershell
python manage.py populate_database
```

### اختبار 2: تشغيل الاختبارات
```powershell
python manage.py test bus_tracking
```

### اختبار 3: اختبار WebSocket
```powershell
python test_websocket.py
```

### اختبار 4: اختبار تحديث الموقع
```powershell
python test_location_update.py
```

---

## 📊 معلومات الأداء

### الأداء المتوقع:
- **REST API**: ~50ms latency
- **WebSocket**: ~100ms per update
- **Database**: <100ms queries
- **Redis**: <5ms lookup

### حدود التخفيف:
- **Rate limits**: 100/hour (anonymous), 1000/hour (authenticated)
- **WebSocket capacity**: 1500 messages
- **Reconnect delay**: 5 seconds

---

## 🔐 نصائح الأمان للتطوير

1. ✅ أضف `.env` إلى `.gitignore`
2. ✅ لا تستخدم نفس TOKEN في المستودع
3. ✅ في Production: استخدم HTTPS و WSS
4. ✅ في Production: غيّر SECRET_KEY و DEBUG

---

## 📚 مراجع إضافية

- `ARCHITECTURE.md` - وثائق شاملة
- `IMPLEMENTATION_SUMMARY.md` - ملخص التغييرات
- `Buses_BACK_END-main/.env.example` - متغيرات البيئة
- `Buses_BACK_END-main/BusTrackingSystem/settings.py` - إعدادات Django

---

**آخر تحديث**: 28 أكتوبر 2025
**الحالة**: ✅ جاهز للاستخدام
