# 🎯 خطوات سريعة للبدء

## ✅ ما تم إعداده:

### 📊 قاعدة البيانات
- ✅ حافلة واحدة: **0101465**
- ✅ خط: **زراعة مرفأ**
- ✅ محطتين: زراعة، يمن
- ✅ Token: `d1afc8c6685f541724963a55cd0ebca599dac16f`

### 🌐 الإعدادات
- ✅ IP الحالي: **192.168.0.166**
- ✅ Driver App: محدّث بـ IP الجديد
- ✅ User App: محدّث بـ IP الجديد + useMockData = false
- ✅ Django: ALLOWED_HOSTS = ['*']

---

## 🚀 البدء السريع

### 1️⃣ تشغيل السيرفر

```powershell
cd "c:\Users\Windows.11\Desktop\final masar\Buses_BACK_END-main"
START_SERVER_NETWORK.bat
```

أو:
```powershell
py manage.py runserver 0.0.0.0:8000
```

### 2️⃣ بناء تطبيق السائق (APK)

```powershell
cd "c:\Users\Windows.11\Desktop\final masar\Driver_APP-main"
flutter build apk --release
```

الملف سيكون في:
```
Driver_APP-main\build\app\outputs\flutter-apk\app-release.apk
```

### 3️⃣ تثبيت APK على الهاتف

**الطريقة الأولى - USB:**
```powershell
flutter install
```

**الطريقة الثانية - يدوياً:**
1. انسخ `app-release.apk` للهاتف
2. افتحه على الهاتف
3. اسمح بالتثبيت من مصادر غير معروفة

### 4️⃣ اختبار من الهاتف

افتح المتصفح على الهاتف وجرب:
```
http://192.168.0.166:8000/api/buses/
```

يجب أن ترى:
```json
[{"bus_id":1,"license_plate":"0101465",...}]
```

### 5️⃣ تشغيل تطبيق السائق

1. افتح التطبيق
2. سجل دخول (إذا مطلوب)
3. اختر الحافلة "0101465"
4. اضغط "بدء التتبع"
5. يجب أن ترى: "تم الإرسال بنجاح ✅"

### 6️⃣ مراقبة WebSocket

```powershell
cd "c:\Users\Windows.11\Desktop\final masar\Buses_BACK_END-main"
py listen_websocket.py
```

يجب أن ترى رسائل تحديث الموقع!

### 7️⃣ تشغيل تطبيق المستخدم

```powershell
cd "c:\Users\Windows.11\Desktop\final masar\user_app-main"
flutter run
```

---

## 🔧 إذا تغيّر IP الخاص بك

### افحص IP الجديد:
```powershell
ipconfig | findstr IPv4
```

### حدّث الملفات التالية:

1. **Driver_APP-main\.env**
   ```
   API_BASE_URL=http://NEW_IP:8000/api
   ```

2. **user_app-main\lib\config\app_config.dart**
   ```dart
   static const String baseUrl = 'http://NEW_IP:8000';
   static const String websocketUrl = 'ws://NEW_IP:8000/ws/bus-locations/';
   ```

---

## 📱 اختبار سريع

### اختبار 1: API
```
http://192.168.0.166:8000/api/buses/
```

### اختبار 2: Admin Panel
```
http://192.168.0.166:8000/admin
```
- Username: `aaa`
- Password: (كلمة المرور اللي حطيتها)

### اختبار 3: WebSocket Test Page
```
http://192.168.0.166:8000/websocket-test/
```

---

## 🆘 حل المشاكل

### "Cannot connect to server"
1. تأكد السيرفر شغال
2. تأكد الهاتف والجهاز على نفس WiFi
3. جرب ping:
   ```powershell
   ping 192.168.0.166
   ```

### "Location permission denied"
- روح Settings > Apps > Driver App > Permissions
- فعّل Location (Always Allow)

### Firewall يمنع الاتصال
```powershell
# السماح لـ port 8000
netsh advfirewall firewall add rule name="Django Server" dir=in action=allow protocol=TCP localport=8000
```

---

## 📝 ملاحظات

- ⚠️ التطبيق يستهلك بطارية لأنه يستخدم GPS باستمرار
- 📍 الموقع يتم إرساله كل 5 ثوانٍ
- 🔒 ALLOWED_HOSTS = ['*'] للتطوير فقط، غيّره في الإنتاج
- 📡 بعض الشبكات تمنع الاتصال بين الأجهزة (AP Isolation)

---

## ✨ الخطوات التالية

1. ✅ شغّل السيرفر
2. ✅ ابني APK
3. ✅ نزّله على الهاتف
4. ✅ جرّب!

🎉 **كل شي جاهز الآن!**
