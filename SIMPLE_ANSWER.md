# 🎯 الإجابة البسيطة (للعجلة)

**في 2 دقيقة - كل اللي احتاجه!**

---

## ❓ سؤالك:
"كيف أرفع النظام على الإنترنت بـ ngrok؟"

## ✅ الجواب:
**40 دقيقة + 5 ملفات توثيق = نظام كامل على الإنترنت**

---

## 🚀 الخطوات (5 خطوات فقط):

### 1️⃣ تشغيل Django
```powershell
cd Buses_BACK_END-main
python -m venv .venv
.\.venv\Scripts\Activate.ps1
pip install -r requirements.txt
python manage.py migrate
python manage.py populate_database
python manage.py runserver 127.0.0.1:8000
```

### 2️⃣ تشغيل ngrok
```powershell
ngrok http 8000
# 👈 احفظ الـ URL (مثل: https://xxxx-xx-xxx-xxx.ngrok.io)
```

### 3️⃣ حدّث 3 ملفات
```
settings.py:        أضف ngrok URL في ALLOWED_HOSTS
.env (Driver App):  غيّر API_BASE_URL
app_config.dart:    غيّر baseUrl + websocketUrl (wss://)
```

### 4️⃣ شغّل التطبيقات
```powershell
# Terminal 3
cd Driver_APP-main
flutter pub get
flutter run

# Terminal 4
cd user_app-main
flutter pub get
flutter run
```

### 5️⃣ اختبر
```
https://xxxx-xx-xxx-xxx.ngrok.io/api/buses/
```

---

## 📚 الملفات المتاحة

| الملف | الاستخدام |
|------|----------|
| **NGROK_QUICK_START.md** | أوامر جاهزة (اختره إذا بتبدأ الآن) |
| **NGROK_SETUP_GUIDE.md** | شرح مفصّل (اختره لو بتبدأ من الصفر) |
| **NGROK_CONFIG_EXAMPLES.md** | أمثلة الملفات (اختره لو بتحتاج أمثلة) |
| **NGROK_FINAL_SUMMARY.md** | ملخص شامل (اختره للتفاصيل) |
| **NGROK_QUICK_REFERENCE.md** | مرجع للطباعة (اختره للـ reference) |

---

## ⏱️ الوقت

```
15 دقيقة:  تثبيت وتشغيل
10 دقائق:  تحديث الملفات
15 دقيقة:  الاختبار
────────────
40 دقيقة:  نظام كامل على الإنترنت! 🎉
```

---

## 🎯 اختر ملفك

- **إذا بتبدأ الآن:** NGROK_QUICK_START.md
- **إذا أول مرة:** NGROK_SETUP_GUIDE.md
- **إذا بتحتاج أمثلة:** NGROK_CONFIG_EXAMPLES.md
- **إذا بتريد كل شيء:** NGROK_FINAL_SUMMARY.md

---

**الآن يا سلام!** 🚀
