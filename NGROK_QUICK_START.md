# ⚡ أوامر ngrok الكاملة - Copy & Paste

**تاريخ**: 28 أكتوبر 2025

---

## 🎯 البدء الفوري (Copy Everything)

### Terminal 1: Backend Django

```powershell
cd "c:\Users\Windows.11\Desktop\final_masar\final masar\Buses_BACK_END-main"
python -m venv .venv
.\.venv\Scripts\Activate.ps1
pip install -r requirements.txt
python manage.py migrate
python manage.py populate_database
python manage.py runserver 127.0.0.1:8000
```

**انتظر رسالة:**
```
Starting development server at http://127.0.0.1:8000/
```

---

### Terminal 2: ngrok

```powershell
# تشغيل ngrok (أول مرة)
ngrok http 8000

# أو إذا كان ngrok في مجلد محدد:
cd "$HOME\ngrok"
./ngrok.exe http 8000
```

**انسخ هذا الـ URL:**
```
Forwarding: https://xxxx-xx-xxx-xxx.ngrok.io -> http://127.0.0.1:8000
                ↑
             استبدل هذا في الملفات!
```

---

## 📝 الملفات التي تحتاج تحديث

### ملف 1: `BusTrackingSystem/settings.py`

**افتح الملف وغيّر:**

```python
# السطر ~26
ALLOWED_HOSTS = ['localhost', '127.0.0.1', 'xxxx-xx-xxx-xxx.ngrok.io']

# السطر ~49-50
CSRF_TRUSTED_ORIGINS = [
    'http://localhost:8000',
    'https://localhost:8000',
    'https://xxxx-xx-xxx-xxx.ngrok.io',
]

# السطر ~56-57
CORS_ALLOWED_ORIGINS = [
    'http://localhost:8000',
    'https://localhost:8000',
    'https://xxxx-xx-xxx-xxx.ngrok.io',
]
```

**بعد التحديث:**
```powershell
# أعد تشغيل Django (اضغط Ctrl+C ثم شغّل من جديد)
python manage.py runserver 127.0.0.1:8000
```

---

### ملف 2: `Driver_APP-main/.env`

**افتح الملف وغيّر السطر الأول:**

```env
API_BASE_URL=https://xxxx-xx-xxx-xxx.ngrok.io/api
AUTH_TOKEN=d1afc8c6685f541724963a55cd0ebca599dac16f
LOCATION_UPDATE_INTERVAL=5000
ENABLE_BACKGROUND_SERVICE=true
```

---

### ملف 3: `user_app-main/lib/config/app_config.dart`

**افتح الملف وغيّر السطور 26-54:**

```dart
static const String baseUrl = 'https://xxxx-xx-xxx-xxx.ngrok.io';
static const String websocketUrl = 'wss://xxxx-xx-xxx-xxx.ngrok.io/ws/bus-locations/';
```

---

## 🚀 Terminal 3: Driver App

```powershell
cd "c:\Users\Windows.11\Desktop\final_masar\final masar\Driver_APP-main"
flutter pub get
flutter run
```

---

## 🚀 Terminal 4: User App

```powershell
cd "c:\Users\Windows.11\Desktop\final_masar\final masar\user_app-main"
flutter pub get
flutter run
```

---

## 🧪 Terminal 5: الاختبارات

### اختبر API من PowerShell

```powershell
# 1. اختبر من الإنترنت
$headers = @{
    'Authorization' = 'Token d1afc8c6685f541724963a55cd0ebca599dac16f'
}

Invoke-WebRequest -Uri 'https://xxxx-xx-xxx-xxx.ngrok.io/api/buses/' `
  -Headers $headers

# يجب ترى JSON response!
```

### اختبر من المتصفح

```
افتح: https://xxxx-xx-xxx-xxx.ngrok.io/api/buses/
```

### اختبر WebSocket

```python
# قم بحفظ هذا كملف: test_ws.py
import websocket

def on_message(ws, message):
    print(f"📍 موقع جديد: {message}")

def on_open(ws):
    print("✅ متصل بـ WebSocket")

def on_error(ws, error):
    print(f"❌ خطأ: {error}")

ws = websocket.WebSocketApp(
    "wss://xxxx-xx-xxx-xxx.ngrok.io/ws/bus-locations/",
    on_message=on_message,
    on_open=on_open,
    on_error=on_error
)

ws.run_forever()
```

**تشغيل:**
```powershell
pip install websocket-client
python test_ws.py
```

---

## 📊 قائمة التحقق النهائية

### ✅ قبل البدء:

- [ ] ngrok مثبت (`ngrok --version`)
- [ ] Python مثبت (`python --version`)
- [ ] Flutter مثبت (`flutter --version`)
- [ ] مفتاح ngrok (`ngrok config show`)

### ✅ أثناء التشغيل:

- [ ] Terminal 1: Django يعمل
- [ ] Terminal 2: ngrok tunnel نشط
- [ ] Terminal 3: Driver App تم تحميله
- [ ] Terminal 4: User App تم تحميله

### ✅ بعد البدء:

- [ ] API يرد على الطلبات
- [ ] WebSocket متصل
- [ ] Locations تتحدث تلقائياً
- [ ] الخريطة تظهر الحافلة

---

## 🔍 استكشاف الأخطاء السريع

### خطأ: `Connection refused`
```powershell
# تأكد Django يعمل في Terminal 1
python manage.py runserver 127.0.0.1:8000
```

### خطأ: `Invalid hostname`
```python
# تأكد أن الـ URL في settings.py صحيح
# استبدل xxxx-xx-xxx-xxx بـ الـ URL الحقيقي من ngrok
```

### خطأ: `CORS error`
```python
# تأكد أن CORS_ALLOWED_ORIGINS يحتوي على الـ ngrok URL
# أعد تشغيل Django بعد التعديل
```

### خطأ: `WebSocket connection failed`
```dart
// تأكد من استخدام wss:// وليس ws://
static const String websocketUrl = 'wss://xxxx-xx-xxx-xxx.ngrok.io/ws/bus-locations/';
```

---

## 📱 اختبر من الهاتف الحقيقي

### 1. متصفح الهاتف:
```
https://xxxx-xx-xxx-xxx.ngrok.io/api/buses/
```

### 2. من تطبيق السائق:
```
1. شغّل التطبيق
2. اختر الحافلة
3. اضغط Start Tracking
4. يجب ترى "✅ Success"
```

### 3. من تطبيق المستخدم:
```
1. شغّل التطبيق
2. شوف الخريطة
3. الحافلة تتحرك تلقائياً
```

---

## ⏱️ الوقت المتوقع

```
ngrok setup:        2 دقيقة
Backend setup:      3 دقائق
تحديث الملفات:      5 دقائق
تشغيل التطبيقات:   5 دقائق
الاختبار:          15 دقيقة
───────────────────────
المجموع:           30 دقيقة ✨
```

---

## 🎉 بعد إتمام كل شيء

```
✅ النظام يعمل على الإنترنت عبر ngrok
✅ أي جهاز على الإنترنت يمكنه الوصول
✅ البيانات تتحدث في الوقت الفعلي
✅ كل شيء جاهز للاختبار الشامل
✅ الآن تقدر تأخذ screenshots و videos للعرض! 📸
```

---

## 💡 نصائح ذهبية

1. **احفظ الـ ngrok URL في ملف نصي** - عشان قد يتغير
2. **اترك Terminal 2 مفتوح دائماً** - لو أغلقته، الـ tunnel بتنقطع
3. **استخدم Paid Plan لو في مشروع احترافي** - URL ثابت
4. **اختبر من أجهزة مختلفة** - للتأكد من الاتصال

---

## 🚀 الخطوة التالية

```
بعد التشغيل الناجح:
1. خذ screenshots
2. سجّل فيديو
3. اعرض على الفريق
4. اطلب feedback
5. قرّر: هل ngrok + Local أم Full Hosting؟
```

---

## 📞 إذا حصلت مشكلة

```
✅ اقرأ: NGROK_SETUP_GUIDE.md
✅ اقرأ: NGROK_CONFIG_EXAMPLES.md
✅ استكشف الأخطاء أعلاه
✅ أعد تشغيل من البداية
✅ اسأل في المجتمع: stackoverflow.com
```

---

**كل الأوامر جاهزة - انسخ والصق وابدأ!** 🎯

**الآن يا سلام!** 💪✨
