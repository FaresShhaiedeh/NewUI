# 🚀 دليل النشر للإنتاج (Production Deployment Guide)

## ✅ التحسينات المطبقة

### 🔒 1. الأمان (Security)
- ✅ **المصادقة**: تم تفعيل `IsAuthenticated` لكل الـ API endpoints
- ✅ **DEBUG**: تم تعطيل DEBUG mode في الإنتاج
- ✅ **HTTPS**: تم تفعيل SSL redirect للإنتاج
- ✅ **CORS**: تم تقييد CORS للنطاقات المسموح بها فقط
- ✅ **Secret Key**: يجب تغيير SECRET_KEY في الإنتاج

### ⚡ 2. الأداء (Performance)
- ✅ **Single Endpoint**: `/api/initial-data/` يرجع كل البيانات بطلب واحد (بدلاً من 3 طلبات)
- ✅ **Database Optimization**: استخدام `select_related()` و `prefetch_related()`
- ✅ **Rate Limiting**: حد 100 طلب/ساعة للمجهولين، 1000 للمصادقين
- ✅ **WebSocket**: التحديثات الحية عبر WebSocket (لا تحسب ضمن rate limit)

### 🎯 3. تحسينات Flutter
- ✅ **Error Handling**: معالجة أفضل للأخطاء بدون رسائل مزعجة
- ✅ **Network Errors**: رسائل واضحة للمستخدم عند فقدان الإنترنت
- ✅ **Efficient API**: استخدام endpoint واحد بدلاً من 3

---

## 📋 خطوات النشر

### 1. إعداد Backend (Django)

#### أ. إعداد ملف .env للإنتاج
```bash
cp .env.development .env
```

ثم عدّل `.env` بالقيم المناسبة:
```env
DEBUG=False
DJANGO_SECRET_KEY=your-super-secret-production-key-here
ALLOWED_HOSTS=yourdomain.com,www.yourdomain.com
DB_ENGINE=sql_server.pyodbc
DB_NAME=BusTrackingDB
DB_HOST=your-server.database.windows.net
```

#### ب. تثبيت Dependencies
```bash
pip install -r requirements.txt
```

#### ج. تجهيز قاعدة البيانات
```bash
python manage.py makemigrations
python manage.py migrate
python manage.py createsuperuser
python manage.py collectstatic --noinput
```

#### د. تشغيل السيرفر (Production)
```bash
# باستخدام Gunicorn + Daphne
daphne -b 0.0.0.0 -p 8000 BusTrackingSystem.asgi:application

# أو باستخدام systemd service (Linux)
sudo systemctl start bus-tracking
```

---

### 2. إعداد Flutter Apps

#### أ. تحديث app_config.dart
```dart
class AppConfig {
  static const String baseUrl = 'https://your-production-domain.com';
  static const String websocketUrl = 'wss://your-production-domain.com/ws/bus-locations/';
  static const String authToken = 'your-production-token-here';
  static const bool useMockData = false;
}
```

#### ب. Build للإنتاج

**User App:**
```bash
cd user_app-main
flutter build apk --release --split-per-abi  # للحصول على ملفات أصغر
# أو
flutter build appbundle  # للنشر على Google Play
```

**Driver App:**
```bash
cd Driver_APP-main
flutter build apk --release --split-per-abi
```

---

### 3. إعداد ngrok (للاختبار فقط)

⚠️ **ملاحظة**: ngrok مناسب للتطوير والاختبار فقط، ليس للإنتاج!

```bash
# تشغيل ngrok
ngrok http 8000

# الحصول على URL
# مثال: https://abc123.ngrok-free.dev
```

**للإنتاج الحقيقي، استخدم:**
- Azure App Service
- AWS EC2 + Nginx
- DigitalOcean Droplet
- أي خدمة استضافة مع domain حقيقي و SSL certificate

---

## 🔧 ملف تشغيل systemd (Linux Production)

إنشاء `/etc/systemd/system/bus-tracking.service`:

```ini
[Unit]
Description=Bus Tracking System
After=network.target

[Service]
Type=notify
User=www-data
WorkingDirectory=/var/www/bus-tracking
Environment="DJANGO_SETTINGS_MODULE=BusTrackingSystem.settings"
ExecStart=/var/www/bus-tracking/venv/bin/daphne -b 0.0.0.0 -p 8000 BusTrackingSystem.asgi:application
Restart=always

[Install]
WantedBy=multi-user.target
```

تفعيل وتشغيل:
```bash
sudo systemctl daemon-reload
sudo systemctl enable bus-tracking
sudo systemctl start bus-tracking
sudo systemctl status bus-tracking
```

---

## 🌐 إعداد Nginx (Reverse Proxy)

`/etc/nginx/sites-available/bus-tracking`:

```nginx
server {
    listen 80;
    server_name yourdomain.com www.yourdomain.com;

    location / {
        proxy_pass http://127.0.0.1:8000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    location /ws/ {
        proxy_pass http://127.0.0.1:8000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $host;
    }

    location /static/ {
        alias /var/www/bus-tracking/staticfiles/;
    }
}
```

تفعيل:
```bash
sudo ln -s /etc/nginx/sites-available/bus-tracking /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl restart nginx
```

---

## 🔐 إعداد SSL (HTTPS)

استخدام Let's Encrypt (مجاني):

```bash
sudo apt install certbot python3-certbot-nginx
sudo certbot --nginx -d yourdomain.com -d www.yourdomain.com
sudo certbot renew --dry-run  # اختبار التجديد التلقائي
```

---

## 📊 المراقبة والصيانة

### Logs
```bash
# Django logs
tail -f /var/log/bus-tracking/django.log

# Nginx logs
tail -f /var/log/nginx/access.log
tail -f /var/log/nginx/error.log

# System logs
sudo journalctl -u bus-tracking -f
```

### Database Backup
```bash
# SQLite
cp db.sqlite3 backups/db_$(date +%Y%m%d).sqlite3

# SQL Server
# استخدم أدوات SQL Server Management Studio
```

---

## ⚠️ نقاط مهمة

1. **لا ترفع ملف .env على GitHub**
   - أضفه إلى `.gitignore`
   - استخدم secrets management في الإنتاج

2. **غيّر SECRET_KEY**
   - استخدم: `python -c "from django.core.management.utils import get_random_secret_key; print(get_random_secret_key())"`

3. **استخدم HTTPS دائماً**
   - Let's Encrypt مجاني وسهل

4. **راقب الأداء**
   - استخدم أدوات مثل New Relic أو Sentry

5. **Backup منتظم**
   - قاعدة البيانات
   - الملفات الثابتة
   - التطبيقات

---

## 📱 توزيع التطبيقات

### Google Play Store
1. إنشاء حساب Google Play Developer ($25 one-time)
2. Build: `flutter build appbundle`
3. رفع على Play Console
4. ملء معلومات التطبيق
5. نشر

### APK مباشر (للمؤسسات)
1. Build: `flutter build apk --release`
2. توزيع الملف مباشرة
3. يجب على المستخدمين تفعيل "Unknown Sources"

---

## ✅ Checklist قبل النشر

- [ ] DEBUG=False في .env
- [ ] SECRET_KEY تم تغييره
- [ ] ALLOWED_HOSTS تم ضبطه
- [ ] Database backup موجود
- [ ] SSL certificate مثبت
- [ ] API authentication تعمل
- [ ] WebSocket يعمل
- [ ] اختبار الأداء
- [ ] اختبار الأمان
- [ ] مراقبة الأخطاء معدّة

---

## 📞 الدعم

في حال واجهت مشاكل:
1. تحقق من logs
2. راجع الإعدادات
3. تأكد من firewall و network settings
4. اختبر على بيئة staging أولاً

---

**آخر تحديث**: نوفمبر 2025  
**النسخة**: 1.0 Production Ready
