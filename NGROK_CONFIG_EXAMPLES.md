# ⚙️ نموذج settings.py معدّل لـ ngrok

**ملف النموذج - انسخ وعدّل حسب احتياجاتك**

---

## 📝 الخطوات

1. افتح: `Buses_BACK_END-main/BusTrackingSystem/settings.py`
2. ابحث عن السطور المشار إليها بـ "👈"
3. غيّر `xxxx-xx-xxx-xxx.ngrok.io` بـ الـ URL الحقيقي من ngrok

---

## ✏️ التغييرات المطلوبة

### 1️⃣ ALLOWED_HOSTS (السطر ~26)

**قبل:**
```python
ALLOWED_HOSTS = os.getenv('ALLOWED_HOSTS', 'localhost,127.0.0.1').split(',')
```

**بعد:**
```python
ALLOWED_HOSTS = os.getenv('ALLOWED_HOSTS', 'localhost,127.0.0.1').split(',')
# أضف ngrok URL:
if 'NGROK_URL' in os.environ:
    ALLOWED_HOSTS.append(os.getenv('NGROK_URL'))

# أو مباشرة:
# ALLOWED_HOSTS = [
#     'localhost',
#     '127.0.0.1',
#     'xxxx-xx-xxx-xxx.ngrok.io',  # 👈 استبدل بـ URL الحقيقي
# ]
```

---

### 2️⃣ CSRF_TRUSTED_ORIGINS (السطر ~49)

**قبل:**
```python
CSRF_TRUSTED_ORIGINS = os.getenv(
    'CSRF_TRUSTED_ORIGINS',
    'https://localhost:3000,https://localhost:8000'
).split(',')
```

**بعد:**
```python
CSRF_TRUSTED_ORIGINS = [
    'http://localhost:3000',
    'http://localhost:8000',
    'https://localhost:3000',
    'https://localhost:8000',
    'https://xxxx-xx-xxx-xxx.ngrok.io',  # 👈 استبدل بـ URL الحقيقي
]
```

---

### 3️⃣ CORS_ALLOWED_ORIGINS (السطر ~56)

**قبل:**
```python
CORS_ALLOWED_ORIGINS = os.getenv(
    'CORS_ALLOWED_ORIGINS',
    'https://localhost:3000,https://localhost:8000'
).split(',')
```

**بعد:**
```python
CORS_ALLOWED_ORIGINS = [
    'http://localhost:3000',
    'http://localhost:8000',
    'https://localhost:3000',
    'https://localhost:8000',
    'https://xxxx-xx-xxx-xxx.ngrok.io',  # 👈 استبدل بـ URL الحقيقي
]
```

---

### 4️⃣ (اختياري) إضافة متغير بيئة

**في `.env` file:**
```bash
NGROK_URL=xxxx-xx-xxx-xxx.ngrok.io
```

**في `settings.py`:**
```python
NGROK_URL = os.getenv('NGROK_URL', None)
if NGROK_URL:
    ALLOWED_HOSTS.append(NGROK_URL)
    CSRF_TRUSTED_ORIGINS.append(f'https://{NGROK_URL}')
    CORS_ALLOWED_ORIGINS.append(f'https://{NGROK_URL}')
```

---

## 📱 نموذج `.env` للـ Driver App

**الملف**: `Driver_APP-main/.env`

```env
# 👈 استبدل xxxx-xx-xxx-xxx بـ URL الحقيقي
API_BASE_URL=https://xxxx-xx-xxx-xxx.ngrok.io/api
AUTH_TOKEN=d1afc8c6685f541724963a55cd0ebca599dac16f
LOCATION_UPDATE_INTERVAL=5000
ENABLE_BACKGROUND_SERVICE=true
ENABLE_CERTIFICATE_PINNING=false
```

---

## 🎨 نموذج `app_config.dart` للـ User App

**الملف**: `user_app-main/lib/config/app_config.dart`

**السطور 26-54:**
```dart
/// عنوان URL الأساسي للـ API
/// استبدل xxxx-xx-xxx-xxx بـ URL الحقيقي من ngrok
static const String baseUrl = 'https://xxxx-xx-xxx-xxx.ngrok.io';

/// عنوان WebSocket الآمن (wss://)
/// استبدل xxxx-xx-xxx-xxx بـ URL الحقيقي من ngrok
static const String websocketUrl = 'wss://xxxx-xx-xxx-xxx.ngrok.io/ws/bus-locations/';
```

---

## 🧪 ملف اختبار سريع

**ملف**: `test_ngrok.py`

```python
import requests
import json

# استبدل بـ URL الحقيقي
NGROK_URL = "https://xxxx-xx-xxx-xxx.ngrok.io"
TOKEN = "d1afc8c6685f541724963a55cd0ebca599dac16f"

headers = {
    'Authorization': f'Token {TOKEN}',
    'Content-Type': 'application/json'
}

# اختبر 1: الحافلات
print("🧪 اختبار 1: الحافلات")
response = requests.get(f"{NGROK_URL}/api/buses/", headers=headers)
print(f"Status: {response.status_code}")
print(f"Response: {json.dumps(response.json(), indent=2)}\n")

# اختبر 2: الخطوط
print("🧪 اختبار 2: الخطوط")
response = requests.get(f"{NGROK_URL}/api/bus-lines/", headers=headers)
print(f"Status: {response.status_code}")
print(f"Response: {json.dumps(response.json(), indent=2)}\n")

# اختبر 3: المحطات
print("🧪 اختبار 3: المحطات")
response = requests.get(f"{NGROK_URL}/api/bus-stops/", headers=headers)
print(f"Status: {response.status_code}")
print(f"Response: {json.dumps(response.json(), indent=2)}\n")

# اختبر 4: سجل المواقع
print("🧪 اختبار 4: سجل المواقع")
response = requests.get(f"{NGROK_URL}/api/location-logs/", headers=headers)
print(f"Status: {response.status_code}")
print(f"Response: {response.json()[:2]}")  # أول عنصرين فقط

print("\n✅ جميع الاختبارات نجحت!")
```

**كيفية التشغيل:**
```powershell
cd "Buses_BACK_END-main"
pip install requests
python test_ngrok.py
```

---

## 📋 checklist التحضير

قبل البدء، تأكد من:

- [ ] ngrok مثبت على جهازك
- [ ] لديك حساب ngrok مجاني
- [ ] Django شغّال محلياً على `127.0.0.1:8000`
- [ ] عندك الـ ngrok URL من Terminal 2
- [ ] حدّثت `settings.py` بـ ALLOWED_HOSTS
- [ ] حدّثت `.env` في Driver App
- [ ] حدّثت `app_config.dart` في User App
- [ ] شغّلت `flutter pub get` في كلا التطبيقات
- [ ] اختبرت API من المتصفح

---

## 🔄 دورة التطوير مع ngrok

```
1. كل مرة تشغّل ngrok:
   → قد يتغير الـ URL
   → حدّث الملفات الثلاث

2. أو استخدم متغير بيئة:
   → NGROK_URL في .env
   → يقلل التحديثات اليدوية

3. أو استخدم Paid Plan:
   → URL ثابت
   → أفضل للإنتاج المؤقتة
```

---

## 📊 الملفات التي تحتاج تحديث

| الملف | الموقع | التغيير |
|------|---------|---------|
| **settings.py** | `Buses_BACK_END-main/BusTrackingSystem/` | 3 أماكن |
| **.env** | `Driver_APP-main/` | API_BASE_URL |
| **app_config.dart** | `user_app-main/lib/config/` | baseUrl + websocketUrl |

---

## ✅ بعد التحديث

```
1. أعد تشغيل Django (أغلق وشغّل من جديد)
2. شغّل flutter pub get في كلا التطبيقات
3. أعد تشغيل التطبيقات
4. اختبر الاتصال
```

---

**كل شيء تمام؟ انتقل لخطوة الاختبار!** ✨
