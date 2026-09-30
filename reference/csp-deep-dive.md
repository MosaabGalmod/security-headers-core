# الدليل الميداني الشامل لسياسة أمان المحتوى `(CSP Level 3 Deep Dive)`

مرجع هندسي تفصيلي لبناء وصيانة سياسات أمان المحتوى `(Content Security Policy)`، واستخدام القيم العشوائية `(Nonces)` والبصمات التشفيرية `(Hashes)`، والدمج الآمن للخدمات الشائعة مثل `(Analytics)`، و `(Stripe)`، و `(GTM)`.

---

## 1. التوجيهات الأساسية في `CSP Level 3`

| التوجيه | الوظيفة | القيمة الموصى بها في بيئة الإنتاج |
| :--- | :--- | :--- |
| `default-src` | المرجع الاحتياطي لكافة الموارد | `'self'` أو `'none'` |
| `script-src` | مصادر تنفيذ شيفرات جافاسكربت | `'self' 'nonce-{RANDOM}' 'strict-dynamic'` |
| `style-src` | مصادر ملفات وتنسيقات `CSS` | `'self' 'nonce-{RANDOM}'` أو `'self' 'unsafe-inline'` |
| `img-src` | مصادر تحميل الصور والوسائط | `'self' data: https:` |
| `connect-src` | مصادر اتصالات `Fetch`، و `XHR`، و `WebSockets` | `'self' https://api.example.com` |
| `font-src` | مصادر تحميل الخطوط | `'self' data: https:` |
| `object-src` | المكونات الإضافية القديمة مثل `Flash` و `Java` | `'none'` (إلزامي) |
| `base-uri` | تقييد وسم `<base>` لمنع هجمات التوجيه | `'self'` أو `'none'` (إلزامي) |
| `form-action` | الوجهات المسموح إرسال نماذج `HTML` إليها | `'self'` |
| `frame-ancestors` | النطاقات المسموح لها بتضمين الصفحة في `iframe` | `'none'` (أو `'self'` عند الحاجة) |
| `upgrade-insecure-requests` | ترقية روابط `HTTP` إلى `HTTPS` تلقائياً | توجيه إلزامي |

---

## 2. هندسة السياسة المعتمدة على `Nonce` مع `'strict-dynamic'`

تعتبر طريقة **`Nonce + 'strict-dynamic'`** المعيار الذهبي الموصى به من فريق أمان `Google` لـ `CSP` الحديثة:

### كيف تعمل؟
1. يقوم الخادم بتوليد قيمة عشوائية تشفيرية جديدة لكل طلب `(Request)` لا تقل عن 16 بايت مشفرة بصيغة `Base64`:
```javascript
const nonce = Buffer.from(crypto.randomUUID()).toString('base64');
```
2. يرسل الخادم الترويسة:
```http
Content-Security-Policy: script-src 'nonce-rAnd0m123' 'strict-dynamic' https: 'unsafe-inline'; object-src 'none'; base-uri 'none';
```
3. يتم وسم كل سكربت في الصفحة بهذه القيمة:
```html
<script nonce="rAnd0m123" src="/main.js"></script>
<script nonce="rAnd0m123">
  console.log("السكربت مصادق عليه وسيعمل بأمان");
</script>
```
4. **سحر `'strict-dynamic'`**: يخبر المتصفحات الحديثة بالسماح لأي سكربت موثوق (يحمل الـ `nonce`) بتحميل سكربتات فرعية إضافية برمجياً، مع تجاهل `'unsafe-inline'` والنطاقات الصريحة `https:` التي كُتبت فقط للمتصفحات القديمة غير الداعمة لـ `CSP3`!

---

## 3. التكامل الآمن مع الخدمات الخارجية الشائعة

### أ) جوجل أناليتكس وإدارة العلامات `(Google Tag Manager & GA4)`
لدمج `GTM` و `GA4` بدون التنازل عن أمان المتصفح:
1. تمرير قيمة الـ `nonce` إلى وسم استدعاء `gtm.js`.
2. إضافة نطاقات الاتصال الصريحة في `connect-src`:
```http
connect-src 'self' https://*.google-analytics.com https://*.analytics.google.com https://*.googletagmanager.com;
img-src 'self' data: https://*.google-analytics.com https://*.googletagmanager.com;
```

### ب) بوابة الدفع `Stripe` `(Stripe Elements & Checkout)`
تتطلب مكتبة `Stripe` إدراج نطاقاتها في السكربتات والإطارات والاتصالات:
```http
script-src 'self' 'nonce-{RANDOM}' 'strict-dynamic' https://js.stripe.com;
frame-src 'self' https://js.stripe.com https://hooks.stripe.com;
connect-src 'self' https://api.stripe.com;
```

---

## 4. السياسة المعتمدة على البصمات `(Hash-Based CSP)` للمواقع الثابتة `(Static SPAs)`

في المواقع الثابتة `(Static Sites / SSG)` التي لا تملك خادماً ديناميكياً يولد `nonce` في كل طلب، نستخدم بصمة التشفير `SHA-256` للسكربتات المضمنة:

1. حساب بصمة محتوى السكربت المضمن:
```bash
echo -n "console.log('محتوى ثابت');" | openssl dgst -sha256 -binary | openssl base64
# Expected output hash: qn4/L03v0Zq5k...=
```
2. وضع البصمة في ترويسة `CSP`:
```http
Content-Security-Policy: script-src 'self' 'sha256-qn4/L03v0Zq5k...=';
```

---

## 5. منظومة استقبال البلاغات `(Reporting & Monitoring)`

### الترويسة الحديثة `(Reporting API)`:
```http
Reporting-Endpoints: csp-endpoint="https://example.com/api/csp-violations"
Content-Security-Policy: ...; report-to csp-endpoint;
```

### الترويسة المتوافقة مع المتصفحات القديمة:
```http
Content-Security-Policy: ...; report-uri /api/csp-violations;
```

### عينة من تقرير الانتهاك بصيغة `JSON` المستقبل من المتصفح:
```json
{
  "csp-report": {
    "document-uri": "https://example.com/checkout",
    "referrer": "https://example.com/cart",
    "violated-directive": "script-src-elem",
    "effective-directive": "script-src",
    "original-policy": "default-src 'self'; script-src 'nonce-...'",
    "disposition": "enforce",
    "blocked-uri": "inline",
    "line-number": 42,
    "source-file": "https://example.com/checkout",
    "status-code": 200
  }
}
```
