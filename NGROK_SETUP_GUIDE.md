# 🌐 رفع النظام على الإنترنت باستخدام ngrok

**التاريخ**: 28 أكتوبر 2025  
**الحالة**: ✅ جاهز للتشغيل الشامل على الإنترنت

---

## 📝 ملخص الخطوات

| الخطوة | الوصف | الوقت | الأداة |
|--------|-------|-------|-------|
| **1** | تثبيت ngrok | 5 دقائق | PowerShell |
| **2** | تشغيل Backend محلياً | 5 دقائق | Django |
| **3** | إنشاء tunnel ngrok | 1 دقيقة | ngrok |
| **4** | تحديث إعدادات التطبيقات | 10 دقائق | Config files |
| **5** | تشغيل التطبيقات | 5 دقائق | Flutter |
| **6** | الاختبار الشامل | 15 دقيقة | Testing |

**المجموع: 40 دقيقة للتشغيل الكامل** ✨

---

## 🔥 الخطوة 1: تثبيت ngrok

### A) تنزيل ngrok

```powershell
# من الموقع الرسمي
# https://ngrok.com/download

# أو استخدم Chocolatey (إذا كان موجود):
choco install ngrok

# أو من PowerShell مباشرة:
Invoke-WebRequest -Uri "https://bin.equinox.io/c/4VmDzA7iaHg/ngrok-stable-windows-amd64.zip" -OutFile "ngrok.zip"
Expand-Archive -Path "ngrok.zip" -DestinationPath "$HOME\ngrok"
```

### B) إضافة ngrok إلى PATH

```powershell
# أضف ngrok للمتغيرات البيئية (Optional)
# أو استخدمه مباشرة من المجلد
cd "$HOME\ngrok"
./ngrok.exe --version
```

### C) إنشاء حساب ngrok (مجاني)

```
1. اذهب إلى: https://ngrok.com
2. اضغط "Sign Up" (مجاني)
3. أكمل التسجيل
4. احصل على Auth Token
5. شغّل:
   ngrok config add-authtoken YOUR_AUTH_TOKEN
```

---

## ✅ الخطوة 2: تشغيل Backend محلياً (Unchanged)

### Terminal 1: Backend Setup

```powershell
# 1. الذهاب للمجلد
cd "c:\Users\Windows.11\Desktop\final_masar\final masar\Buses_BACK_END-main"

# 2. تفعيل البيئة الافتراضية
python -m venv .venv
.\.venv\Scripts\Activate.ps1

# 3. تثبيت المكتبات
pip install -r requirements.txt

# 4. تشغيل Migrations (لو أول مرة)
python manage.py migrate

# 5. تحميل البيانات التجريبية
python manage.py populate_database

# 6. تشغيل Django
python manage.py runserver 127.0.0.1:8000
```

**النتيجة:**
```
Starting development server at http://127.0.0.1:8000/
```

---

## 🌐 الخطوة 3: تشغيل ngrok Tunnel

### Terminal 2: ngrok

```powershell
# 1. الذهاب لمجلد ngrok
cd "$HOME\ngrok"

# 2. تشغيل tunnel للمنفذ 8000
./ngrok.exe http 8000

# أو من أي مكان بعد الإعداد:
ngrok http 8000
```

**النتيجة المتوقعة:**
```
ngrok by @inconshreveable                    (Ctrl+C to quit)

Session Status         online
Account                your-email@example.com
Version                3.3.0
Region                 us (United States)
Latency                45ms
Web Interface          http://127.0.0.1:4040

Forwarding            https://xxxx-xx-xxx-xxx.ngrok.io -> http://127.0.0.1:8000

Connections           ttl     opn     rt1     rt5     p50     p95
                      0       0       0.00    0.00    0.00    0.00
```

### 🎯 أهم معلومة:

```
⭐ الـ URL الجديد: https://xxxx-xx-xxx-xxx.ngrok.io
   هذا هو عنوان سيرفرك على الإنترنت!
```

---

## 🔧 الخطوة 4: تحديث إعدادات التطبيقات

### 4.1️⃣ Backend Settings - تحديث `settings.py`

**الملف**: `Buses_BACK_END-main/BusTrackingSystem/settings.py`

**ما يجب تغييره:**

```python
# السطر 26 - أضف عنوان ngrok
ALLOWED_HOSTS = [
    'localhost',
    '127.0.0.1',
    'xxxx-xx-xxx-xxx.ngrok.io',  # 👈 أضف عنوان ngrok الخاص بك
]

# السطر 49-50 - CSRF Trusted Origins
CSRF_TRUSTED_ORIGINS = [
    'http://localhost:3000',
    'http://localhost:8000',
    'https://xxxx-xx-xxx-xxx.ngrok.io',  # 👈 أضف هنا
]

# السطر 56-57 - CORS
CORS_ALLOWED_ORIGINS = [
    'http://localhost:3000',
    'http://localhost:8000',
    'https://xxxx-xx-xxx-xxx.ngrok.io',  # 👈 أضف هنا
]
```

### 4.2️⃣ Driver App - تحديث `.env`

**الملف**: `Driver_APP-main/.env`

**السطر الأول:**
```env
# قبل:
API_BASE_URL=http://127.0.0.1:8000/api

# بعد:
API_BASE_URL=https://xxxx-xx-xxx-xxx.ngrok.io/api  # 👈 استخدم ngrok URL
AUTH_TOKEN=d1afc8c6685f541724963a55cd0ebca599dac16f
LOCATION_UPDATE_INTERVAL=5000
ENABLE_BACKGROUND_SERVICE=true
```

### 4.3️⃣ User App - تحديث `app_config.dart`

**الملف**: `user_app-main/lib/config/app_config.dart`

**ابحث عن:**
```dart
// قبل:
static const String baseUrl = kDebugMode
    ? 'http://127.0.0.1:8000'
    : 'https://api.example.com';

// بعد:
static const String baseUrl = 'https://xxxx-xx-xxx-xxx.ngrok.io';  // 👈 استخدم ngrok URL

// قبل:
static const String websocketUrl = kDebugMode
    ? 'ws://127.0.0.1:8000/ws/bus-locations/'
    : 'wss://api.example.com/ws/bus-locations/';

// بعد:
static const String websocketUrl = 'wss://xxxx-xx-xxx-xxx.ngrok.io/ws/bus-locations/';  // 👈 wss:// بدل ws://
```

---

## 🚀 الخطوة 5: تشغيل التطبيقات

### Terminal 3: Driver App

```powershell
cd "c:\Users\Windows.11\Desktop\final_masar\final masar\Driver_APP-main"

# تحديث الحزم (إذا غيرت config)
flutter pub get

# التشغيل
flutter run
```

### Terminal 4: User App

```powershell
cd "c:\Users\Windows.11\Desktop\final_masar\final masar\user_app-main"

# تحديث الحزم (إذا غيرت config)
flutter pub get

# التشغيل
flutter run
```

---

## 🧪 الخطوة 6: الاختبار الشامل

### Test 1️⃣: اختبر API من الإنترنت

```powershell
# من أي جهاز على الإنترنت:
curl https://xxxx-xx-xxx-xxx.ngrok.io/api/buses/ `
  -H "Authorization: Token d1afc8c6685f541724963a55cd0ebca599dac16f"

# أو من المتصفح:
https://xxxx-xx-xxx-xxx.ngrok.io/api/buses/
```

**النتيجة المتوقعة:**
```json
[
  {
    "bus_id": 1,
    "license_plate": "0101465",
    "bus_line": {
      "route_id": 1,
      "route_name": "زراعة مرفأ"
    }
  }
]
```

---

### Test 2️⃣: اختبر Driver App

```
1. افتح تطبيق السائق على المحاكي
2. اختر الحافلة 0101465
3. اضغط "بدء التتبع"
4. يجب أن تري: "✅ تم الإرسال بنجاح"
```

---

### Test 3️⃣: اختبر User App

```
1. افتح تطبيق المستخدم
2. يجب أن تري خريطة
3. الحافلة تتحرك على الخريطة تلقائياً
4. البيانات تتحدث في الوقت الفعلي
```

---

### Test 4️⃣: اختبر WebSocket من أي مكان

```powershell
# استخدم websocket client عام:
# أو من Python:
python
>>> import websocket
>>> ws = websocket.WebSocketApp('wss://xxxx-xx-xxx-xxx.ngrok.io/ws/bus-locations/')
>>> ws.run_forever()

# يجب أن تري التحديثات تأتي مباشرة!
```

---

## 📊 جدول الاتصالات بعد ngrok

| النقطة | من | إلى | البروتوكول | التفاصيل |
|--------|----|----|-----------|---------|
| **REST API** | Driver App | Backend | HTTPS | `https://xxxx-xx-xxx-xxx.ngrok.io/api` |
| **WebSocket** | User App | Backend | WSS | `wss://xxxx-xx-xxx-xxx.ngrok.io/ws` |
| **Admin Panel** | Browser | Backend | HTTPS | `https://xxxx-xx-xxx-xxx.ngrok.io/admin` |
| **Local API** | localhost | Backend | HTTP | `http://127.0.0.1:8000` (محلي فقط) |

---

## ⚠️ ملاحظات مهمة عن ngrok

### 1️⃣ الـ URL يتغير في كل مرة

```
❌ المشكلة: كل مرة تشغّل ngrok، الـ URL يكون مختلف
✅ الحل: استخدم Paid Plan (Pro) لثبات URL

أو قم بـ:
1. تحديث .env في Driver App
2. تحديث config في User App
3. إعادة تشغيل التطبيقات
```

### 2️⃣ الجلسة تنتهي عند إغلاق ngrok

```
❌ المشكلة: إذا أغلقت Terminal 2، توقف الـ tunnel
✅ الحل: اترك Terminal 2 مفتوح دائماً أثناء الاختبار
```

### 3️⃣ السرعة قد تكون أقل قليلاً

```
❌ المشكلة: ngrok يضيف latency بسيط (45-50ms عادي)
✅ لا مشكلة: مقبول تماماً للاختبار
```

### 4️⃣ الـ Bandwidth محدود (النسخة المجانية)

```
❌ المشكلة: 1 GB/شهر فقط في النسخة المجانية
✅ الحل: Pro Plan أو استخدام VPS دائم
```

---

## 🎯 الخطوات السريعة (Resume)

### **الملخص في سطر واحد:**

```
Terminal 1: Django يشتغل → Terminal 2: ngrok يعمل → تحديث الـ URLs → تشغيل التطبيقات → Done! ✨
```

### **أوامر نسخ والصق:**

```powershell
# Terminal 1 - Backend
cd "c:\Users\Windows.11\Desktop\final_masar\final masar\Buses_BACK_END-main"
python -m venv .venv
.\.venv\Scripts\Activate.ps1
pip install -r requirements.txt
python manage.py migrate
python manage.py populate_database
python manage.py runserver 127.0.0.1:8000

# Terminal 2 - ngrok
ngrok http 8000

# ثم انسخ الـ URL من ngrok (مثل: https://xxxx-xx-xxx-xxx.ngrok.io)

# حدّث الملفات التالية:
# 1. BusTrackingSystem/settings.py - ALLOWED_HOSTS + CSRF + CORS
# 2. Driver_APP-main/.env - API_BASE_URL
# 3. user_app-main/lib/config/app_config.dart - baseUrl + websocketUrl

# Terminal 3 - Driver App
cd "c:\Users\Windows.11\Desktop\final_masar\final masar\Driver_APP-main"
flutter pub get
flutter run

# Terminal 4 - User App
cd "c:\Users\Windows.11\Desktop\final_masar\final masar\user_app-main"
flutter pub get
flutter run
```

---

## 📱 الوصول من الهاتف الحقيقي

### على نفس الشبكة WiFi:

```
✅ Driver App: يرسل الموقع عبر ngrok
✅ User App: يستقبل التحديثات عبر ngrok
✅ Admin Panel: يمكن فتح dashboard من الهاتف

رابط الوصول من الهاتف:
https://xxxx-xx-xxx-xxx.ngrok.io
```

### من شبكة مختلفة (4G/LTE):

```
✅ يعمل بنفس الطريقة!
✅ لأن ngrok يوفر tunnel عام على الإنترنت
✅ أي جهاز في العالم يمكنه الوصول
```

---

## 🔐 الأمان مع ngrok

### ✅ ما هو آمن:

```
✅ HTTPS: كل الاتصالات مشفرة
✅ Token Auth: المصادقة محمية
✅ CORS: فقط النطاقات المسموح بها
✅ CSRF: محمي من الطلبات الوهمية
```

### ⚠️ ما يجب الانتباه له:

```
⚠️ الـ URL عام: أي شخص يعرفها يمكنه الوصول
   الحل: استخدم Strong Token + Rate Limiting

⚠️ البيانات تجريبية: استخدم بيانات حقيقية بحذر
   الحل: لا تضع بيانات حساسة

⚠️ ngrok يسجل الـ requests: للـ Paid Plan
   الحل: Pro Plan لو بتستخدمها للإنتاج
```

---

## 🚨 استكشاف الأخطاء الشائعة

### ❌ خطأ: "Connection refused"

```
السبب: Backend مو شغال
الحل:
1. تأكد من Terminal 1 يعمل
2. تأكد من الـ port 8000
3. أعد تشغيل Django
```

---

### ❌ خطأ: "Invalid hostname"

```
السبب: الـ URL في settings.py خطأ
الحل:
1. انسخ الـ URL من ngrok بدقة
2. أضفه في ALLOWED_HOSTS
3. أعد تشغيل Django
```

---

### ❌ خطأ: "WebSocket connection failed"

```
السبب: استخدام ws:// بدل wss://
الحل:
1. تأكد من استخدام wss://
2. لا تستخدم ws:// مع ngrok
3. أعد تشغيل User App
```

---

### ❌ خطأ: "CORS error"

```
السبب: الـ CORS_ALLOWED_ORIGINS ناقص
الحل:
1. أضف ngrok URL في settings.py
2. أعد تشغيل Backend
3. امسح cache من التطبيق
```

---

## 📊 مقارنة ngrok مع البدائل

| الخيار | المميزات | العيوب | التكلفة |
|--------|---------|-------|---------|
| **ngrok** | سهل، سريع، مرن | URL يتغير، محدود | مجاني |
| **Heroku** | دائم، احترافي | أبطأ قليلاً | $7+/شهر |
| **VPS** | قوي جداً، آمن | معقد الإعداد | $5+/شهر |
| **Railway** | سهل، حديث | نسخة مجانية محدودة | مجاني |

---

## 🎓 الخلاصة

```
✅ ngrok = أسرع طريقة للاختبار على الإنترنت
✅ محلي + ngrok = نظام كامل على الإنترنت
✅ 40 دقيقة = وقت التشغيل الكامل
✅ آمن + مشفر = HTTPS + Token Auth
✅ متاح الآن = بدون انتظار
```

---

## 🚀 الخطوات الآن (Resume)

```
1️⃣ شغّل Terminal 1: Django
2️⃣ شغّل Terminal 2: ngrok
3️⃣ انسخ URL من ngrok
4️⃣ حدّث الملفات الثلاث (settings.py, .env, app_config.dart)
5️⃣ شغّل Terminal 3: Driver App
6️⃣ شغّل Terminal 4: User App
7️⃣ اختبر من أي جهاز على الإنترنت
8️⃣ Done! 🎉
```

---

**هل تريد مساعدة في أي خطوة من الخطوات؟** 🤔

اختر:
- ❓ شرح أي خطوة بالتفصيل
- 📝 ملف نموذجي مكتمل
- 🧪 أوامر اختبار متقدمة
- 🔧 حل مشكلة محددة

أخبرني! 💪
