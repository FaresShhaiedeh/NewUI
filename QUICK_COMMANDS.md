# ⚡ أوامر التشغيل السريعة

**للبدء الفوري - انسخ والصق الأوامر!**

---

## 🎯 التشغيل المحلي السريع (4 Terminals)

### ✅ Terminal 1: Backend Setup & Run

```powershell
# 1. الذهاب للمجلد
cd "c:\Users\Windows.11\Desktop\final_masar\final masar\Buses_BACK_END-main"

# 2. إنشاء البيئة الافتراضية
python -m venv .venv

# 3. تفعيل البيئة
.\.venv\Scripts\Activate.ps1

# 4. تثبيت المكتبات
pip install -r requirements.txt

# 5. تشغيل الـ migrations
python manage.py migrate

# 6. تحميل البيانات التجريبية (اختياري)
python manage.py populate_database

# 7. تشغيل السيرفر
python manage.py runserver 0.0.0.0:8000
```

**النتيجة المتوقعة:**
```
Starting development server at http://127.0.0.1:8000/
```

---

### ✅ Terminal 2: اختبار الـ API

```powershell
# 1. اختبر أن السيرفر شغال
Invoke-WebRequest -Uri "http://localhost:8000/api/buses/" `
  -Headers @{'Authorization' = 'Token d1afc8c6685f541724963a55cd0ebca599dac16f'}

# أو استخدم curl إذا كان موجود:
curl http://localhost:8000/api/buses/
```

---

### ✅ Terminal 3: Driver App (السائق)

```powershell
# 1. الذهاب للمجلد
cd "c:\Users\Windows.11\Desktop\final_masar\final masar\Driver_APP-main"

# 2. تحديث الحزم
flutter pub get

# 3. التشغيل
flutter run

# أو على جهاز محدد:
# flutter devices  # لمعرفة أجهزة متاحة
# flutter run -d <device-id>

# أو بناء APK:
# flutter build apk --release
```

---

### ✅ Terminal 4: User App (المستخدم)

```powershell
# 1. الذهاب للمجلد
cd "c:\Users\Windows.11\Desktop\final_masar\final masar\user_app-main"

# 2. تحديث الحزم
flutter pub get

# 3. التشغيل
flutter run

# أو على محاكي آخر:
# flutter run -d <device-id>
```

---

## 🔍 الاختبارات السريعة

### اختبار WebSocket (Terminal جديد)

```powershell
cd "c:\Users\Windows.11\Desktop\final_masar\Buses_BACK_END-main"
.\.venv\Scripts\Activate.ps1
python listen_websocket.py
```

---

### اختبر تحديث الموقع (Terminal جديد)

```powershell
cd "c:\Users\Windows.11\Desktop\final_masar\Buses_BACK_END-main"
.\.venv\Scripts\Activate.ps1
python test_location_update.py
```

---

### فحص قاعدة البيانات (Terminal جديد)

```powershell
cd "c:\Users\Windows.11\Desktop\final_masar\Buses_BACK_END-main"
.\.venv\Scripts\Activate.ps1
python check_database.py
```

---

## 📦 بناء APK للهاتف

### Driver App APK

```powershell
cd "c:\Users\Windows.11\Desktop\final_masar\final masar\Driver_APP-main"
flutter pub get
flutter build apk --release

# الملف سيكون في:
# build/app/outputs/flutter-apk/app-release.apk
```

---

### User App APK

```powershell
cd "c:\Users\Windows.11\Desktop\final_masar\final masar\user_app-main"
flutter pub get
flutter build apk --release

# الملف سيكون في:
# build/app/outputs/flutter-apk/app-release.apk
```

---

## 🌍 نشر على الإنترنت

### Heroku (سهل ومجاني)

```powershell
# 1. تثبيت Heroku CLI من https://devcenter.heroku.com/articles/heroku-cli

# 2. تسجيل الدخول
heroku login

# 3. إنشاء تطبيق
cd "c:\Users\Windows.11\Desktop\final_masar\final masar\Buses_BACK_END-main"
heroku create bus-tracking-app

# 4. رفع الكود (بشرط وجود git)
git push heroku main

# 5. تشغيل الـ migrations
heroku run python manage.py migrate

# سيكون متاح على:
# https://bus-tracking-app.herokuapp.com
```

---

### Docker (للإنتاج المتقدم)

```powershell
# بناء Docker image
docker build -t bus-tracking:latest .

# تشغيل Container
docker run -p 8000:8000 bus-tracking:latest
```

---

## 🛠️ أوامر مساعدة

### إعادة تشغيل السيرفر

```powershell
# في Terminal 1 - اضغط Ctrl+C ثم:
python manage.py runserver 0.0.0.0:8000
```

---

### مسح البيانات وإعادة البدء

```powershell
# 1. حذف قاعدة البيانات
cd "c:\Users\Windows.11\Desktop\final_masar\Buses_BACK_END-main"
rm db.sqlite3

# 2. إنشاء جديدة
python manage.py migrate

# 3. تحميل البيانات التجريبية
python manage.py populate_database
```

---

### تثبيت متطلبات محددة

```powershell
# Django
pip install Django==5.2

# REST Framework
pip install djangorestframework==3.15.1

# Channels
pip install channels==4.1.0

# Daphne
pip install daphne==4.1.2

# SQL Server
pip install mssql-django==1.4
```

---

## 🚨 استكشاف الأخطاء

### المشكلة: Python غير مثبت

```powershell
# الحل:
python --version
# إذا لم يظهر شيء، ثبّت Python من python.org
```

---

### المشكلة: Flask لا تعرف الأوامر

```powershell
# الحل:
python -m flask --version
# استخدم python -m قبل الأوامر
```

---

### المشكلة: Flutter لا يعرف أوامر

```powershell
# الحل:
flutter doctor
flutter upgrade
```

---

### المشكلة: المنفذ 8000 مشغول

```powershell
# الحل: استخدم منفذ آخر
python manage.py runserver 0.0.0.0:8001

# أو اغلق التطبيق الذي يستخدم 8000
Get-Process -Name python | Stop-Process
```

---

## 📊 البيانات التجريبية

```
👤 المستخدم: aaa
🔑 Token: d1afc8c6685f541724963a55cd0ebca599dac16f
🚌 الحافلة: 0101465
🚏 الخطوط: زراعة مرفأ
📍 المحطات: زراعة، يمن
```

---

## ⚙️ الإعدادات المهمة

### للتطوير المحلي:
- `DEBUG = True`
- `DB = SQLite` (أسرع)
- `ALLOWED_HOSTS = ['*']`
- `HTTPS = Off` (محلي)

### للإنتاج:
- `DEBUG = False`
- `DB = SQL Server` (احترافي)
- `ALLOWED_HOSTS = ['your-domain.com']`
- `HTTPS = On` (الزامي)

---

## 🎯 الخطوات بالترتيب

```
1. انسخ أوامر Terminal 1 ✅
2. انتظر رسالة "Starting development server" ✅
3. انسخ أوامر Terminal 2 - اختبر API ✅
4. انسخ أوامر Terminal 3 - شغّل Driver ✅
5. انسخ أوامر Terminal 4 - شغّل User ✅
6. جرّب التطبيقات! 🎉
```

---

**آخر تحديث**: 28 أكتوبر 2025  
**الحالة**: ✅ جاهز للتشغيل الفوري

---

**نسخ الأوامر بسهولة:** 👆 انقر على أي أمر أعلاه واستخدم Ctrl+C للنسخ
