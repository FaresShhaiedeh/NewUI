# 🚌 Bus Tracking System - Architecture & Configuration
**تطبيق تتبع الحافلات - العمارة والتكوين**

---

## 📋 نظرة عامة على المشروع

المشروع مقسم إلى ثلاثة أجزاء رئيسية:

```
┌─────────────────────────────────────────────────────────────┐
│                    Bus Tracking System                      │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  Driver App (Flutter)      Server (Django)     User App    │
│  ┌─────────────────────┐   ┌──────────────┐   ┌─────────────┐
│  │ Buses_BACK_END-main│   │ Driver HTTPS │   │ WebSocket  │
│  │ Location Tracking  ├──→│   (REST API) ├──→│ (wss://)   │
│  │ HTTPS Secure       │   │              │   │            │
│  └─────────────────────┘   └──────────────┘   └─────────────┘
│        Driver APP              BACKEND             USER APP
│      (Flutter)              (Django+Channels)      (Flutter)
│     tls://https                SQL Server         wss://secure
```

---

## 🔐 نقاط الاتصال (Connections)

### 1️⃣ Driver App ↔ Backend: **HTTPS** (تطبيق السائق)
- **بروتوكول**: `https://`
- **الغرض**: تطبيق السائق يرسل مواقعه الحالية
- **المصادقة**: Token-based (Bearer token)
- **الملف**: `Buses_BACK_END-main/BusTrackingSystem/settings.py`
  - `SECURE_SSL_REDIRECT = True`
  - `SESSION_COOKIE_SECURE = True`
  - `CSRF_COOKIE_SECURE = True`

### 2️⃣ Backend: **SQL Server** (قاعدة البيانات)
- **محرك DB**: MSSQL / SQL Server
- **التكوين**: متغيرات البيئة في `.env`
  - `DB_ENGINE=mssql`
  - `DB_HOST=your-sql-server-host`
  - `DB_NAME=BusTrackingDB`
- **التشفير**: `Encrypt: yes` للاتصال الآمن

### 3️⃣ User App ↔ Backend: **WebSocket الآمن (wss://)** (تطبيق المستخدم)
- **بروتوكول**: `wss://` (Secure WebSocket)
- **الغرض**: تحديثات حقيقية لمواقع الحافلات
- **المصادقة**: Token-based في WebSocket handshake
- **الملف**: `Buses_BACK_END-main/BusTrackingSystem/settings.py`
  ```python
  CHANNEL_LAYERS = {
      'default': {
          'BACKEND': 'channels_redis.core.RedisChannelLayer',
          'CONFIG': {
              'hosts': [REDIS_URL],
          },
      },
  }
  ```

---

## 🗂️ هيكل المشروع

```
final_masar/
├── Buses_BACK_END-main/                    # Django Backend
│   ├── BusTrackingSystem/
│   │   ├── settings.py                     # ✅ محدّث: HTTPS, SQL Server, Redis
│   │   ├── asgi.py                         # Django Channels ASGI
│   │   ├── urls.py
│   │   └── wsgi.py
│   ├── bus_tracking/
│   │   ├── consumers.py                    # ✅ محدّث: Async + Auth + wss://
│   │   ├── routing.py                      # ✅ محدّث: WebSocket routing
│   │   ├── views.py                        # REST API endpoints
│   │   ├── models.py
│   │   ├── serializers.py
│   │   └── migrations/
│   ├── requirements.txt                    # ✅ محدّث: mssql-django, channels-redis
│   ├── .env.example                        # ✅ نموذج متغيرات البيئة
│   ├── manage.py
│   └── db.sqlite3
│
├── Driver_APP-main/                        # Driver Mobile App (Flutter)
│   ├── lib/
│   │   ├── main.dart                       # ✅ محدّث: HTTPS + SSL handling
│   │   ├── map_screen.dart
│   │   ├── login_screen.dart
│   │   ├── background_service.dart         # Location tracking
│   │   └── location_point.dart
│   ├── .env.example                        # ✅ محدّث: https:// + token config
│   ├── pubspec.yaml
│   └── test/
│
├── user_app-main/                          # User Mobile App (Flutter)
│   ├── lib/
│   │   ├── main.dart
│   │   ├── config/
│   │   │   └── app_config.dart            # ✅ محدّث: wss:// + HTTPS
│   │   ├── services/
│   │   │   └── tracking_service.dart      # ✅ محدّث: Secure WebSocket
│   │   ├── screens/
│   │   │   └── main_map/
│   │   │       └── main_map_screen.dart
│   │   └── models/
│   ├── pubspec.yaml
│   └── test/
│
└── README.md
```

---

## 🚀 التشغيل والنشر

### Backend Setup (Windows)

#### 1. تثبيت المتطلبات
```powershell
cd "Buses_BACK_END-main"
python -m venv .venv
.\.venv\Scripts\Activate.ps1
pip install -r requirements.txt
```

#### 2. إعداد متغيرات البيئة
```powershell
# نسخ النموذج وتعديله
Copy-Item .env.example .env

# تحرير .env وأضف:
# DB_ENGINE=mssql
# DB_NAME=BusTrackingDB
# DB_HOST=your-sql-server\SQLEXPRESS
# REDIS_URL=redis://localhost:6379/0
# DJANGO_SECRET_KEY=your-secure-key-here
# DEBUG=False
```

#### 3. تشغيل Migrations
```powershell
python manage.py makemigrations
python manage.py migrate
```

#### 4. تشغيل الخادم
```powershell
# خادم ASGI (للـ WebSockets)
daphne -b 0.0.0.0 -p 8000 BusTrackingSystem.asgi:application

# أو استخدم Windows batch script:
# START_ASGI_SERVER.bat
```

#### 5. تشغيل Redis (للـ WebSocket Channels)
```powershell
# على Windows: استخدم WSL أو Docker
# أو حمّل Redis من: https://github.com/microsoftarchive/redis/releases

redis-server
```

### Driver App Setup (Flutter)

#### 1. تحضير المشروع
```bash
cd "Driver_APP-main"
flutter pub get
```

#### 2. إعداد `.env`
```bash
cp .env.example .env
# ثم عدّل:
# API_BASE_URL=https://your-server.com/api
# AUTH_TOKEN=your-driver-token
```

#### 3. التشغيل
```bash
# على emulator
flutter run

# على جهاز حقيقي
flutter run -d <device-id>
```

### User App Setup (Flutter)

#### 1. تحضير المشروع
```bash
cd "user_app-main"
flutter pub get
```

#### 2. تحديث `app_config.dart`
```dart
// lib/config/app_config.dart
static const String baseUrl = kDebugMode
    ? 'https://10.0.2.2:8000'      // emulator
    : 'https://api.example.com';   // production

static const String websocketUrl = kDebugMode
    ? 'wss://10.0.2.2:8000/ws/bus-locations/'      // emulator
    : 'wss://api.example.com/ws/bus-locations/';   // production
```

#### 3. التشغيل
```bash
flutter run
```

---

## 🔒 إجراءات الأمان

### Backend Security (Django)

✅ **تم تطبيقه:**
- HTTPS enforcement (`SECURE_SSL_REDIRECT=True`)
- HSTS headers (1 year expiry)
- Secure cookies (`SESSION_COOKIE_SECURE=True`)
- CSRF protection
- Token-based authentication (DRF)
- WebSocket authentication (Token-based)
- SQL Server encrypted connection

### Driver App Security

✅ **تم تطبيقه:**
- HTTPS-only communication
- Token-based auth in headers
- SSL certificate validation (production)
- No hardcoded secrets (use .env)

### User App Security

✅ **تم تطبيقه:**
- WSS (Secure WebSocket) only
- Token-based auth for WebSocket
- HTTPS for REST API calls
- Heartbeat mechanism to keep connection alive

---

## 📊 اعتماديات مهمة

### Backend
- `Django==5.2` - Web framework
- `channels==4.1.0` - WebSocket support
- `channels-redis==4.2.0` - Redis backend for Channels
- `daphne==4.1.2` - ASGI server
- `mssql-django==1.4` - SQL Server support
- `djangorestframework==3.15.1` - REST API
- `django-cors-headers==4.4.0` - CORS handling

### Driver App (Flutter)
- `http==0.13.6` - HTTP requests
- `geolocator==14.0.2` - Location services
- `flutter_background_service==5.1.0` - Background tracking
- `flutter_dotenv==6.0.0` - .env support

### User App (Flutter)
- `web_socket_channel==3.0.3` - WebSocket client
- `http==1.1.0` - HTTP requests
- `flutter_map==8.2.2` - Mapping
- `provider==6.1.2` - State management

---

## 🔧 استكشاف الأخطاء

### WebSocket Connection Issues
```
❌ Problem: wss:// connection refused
✅ Solution:
   1. تأكد من تشغيل Redis
   2. تحقق من رابط wss:// في app_config.dart
   3. في debug، قد تحتاج لتخطي SSL validation
```

### SQL Server Connection Issues
```
❌ Problem: ODBC Driver 17 not found
✅ Solution:
   1. ثبّت ODBC Driver from Microsoft
   2. تحقق من DB_HOST في .env
   3. تأكد من تشغيل SQL Server service
```

### Token Authentication Failed
```
❌ Problem: 401 Unauthorized
✅ Solution:
   1. تحقق من AUTH_TOKEN في .env
   2. تأكد من إنشاء Token في Django admin
   3. استخدم: python manage.py drf_create_token <username>
```

---

## 📝 ملاحظات مهمة

1. **متغيرات البيئة**: أضف `.env` إلى `.gitignore` (لا تحفظ الأسرار)
2. **Redis**: مطلوب لـ production WebSocket channels
3. **SSL Certificates**: استخدم شهادات موثوقة في production
4. **CORS**: حدّد origins مسموح بها في production
5. **Database**: لا تستخدم SQLite في production (استخدم SQL Server)

---

## 📞 الدعم والمساعدة

للمزيد من التفاصيل، راجع:
- `Buses_BACK_END-main/.env.example` - متغيرات البيئة
- `Buses_BACK_END-main/BusTrackingSystem/settings.py` - إعدادات Django
- `Driver_APP-main/.env.example` - إعدادات تطبيق السائق
- `user_app-main/lib/config/app_config.dart` - إعدادات تطبيق المستخدم

---

**آخر تحديث**: 28 أكتوبر 2025
