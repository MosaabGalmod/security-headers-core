# مرجع عزل المصادر وتأمين ملفات تعريف الارتباط `(Isolation & Cookies Reference)`

مرجع هندسي شامل لسياسات عزل العمليات المتقاطعة `(Cross-Origin Isolation)`، وقاموس صلاحيات العتاد `(Permissions-Policy)`، وتأمين ملفات الجلسات عبر بادئات الكوكيز المعيارية.

---

## 1. عزل المصادر المتقاطعة `(Cross-Origin Isolation)`

تعد سياسات العزل شرطاً أساسياً للمتصفحات لتفعيل ميزات الأداء المتقدمة مثل `SharedArrayBuffer` ومؤقتات الدقة العالية `performance.now()`، مع حماية العمليات في الذاكرة من هجمات تسريب القنوات الجانبية (مثل `Spectre`).

### الثلاثي المعماري للعزل:

1. **`Cross-Origin-Opener-Policy (COOP)`**:
   * يعزل نافذة المتصفح عن النوافذ المنبثقة أو الصفحات التي تفتح التطبيق في علامة تبويب جديدة.
   * القيمة الصارمة الموصى بها:
```http
Cross-Origin-Opener-Policy: same-origin
```

2. **`Cross-Origin-Embedder-Policy (COEP)`**:
   * يمنع الصفحة من تحميل أي مورد خارجي (صورة، سكربت، فيديو) ما لم يوافق المورد صراحة على التضمين عبر ترويسة `CORP` أو `CORS`.
   * القيم المتاحة:
```http
# Strict option: requires CORP header on all cross-origin resources
Cross-Origin-Embedder-Policy: require-corp

# Flexible option: fetches cross-origin resources without credentials
Cross-Origin-Embedder-Policy: credentialless
```

3. **`Cross-Origin-Resource-Policy (CORP)`**:
   * ترويسة يرسلها الخادم مع الملفات والوسائط لحمايتها من التحميل غير المصرح به من مواقع أخرى.
```http
Cross-Origin-Resource-Policy: same-origin
```

> **ملاحظة تطبيقية**: عند تفعيل `COEP: require-corp`، يجب إضافة سمة `crossorigin="anonymous"` على وسوم الصور `<img crossorigin="anonymous">` والخطوط المحملة من مصادر خارجية `(CDNs)`.

---

## 2. قاموس سياسة الصلاحيات `(Permissions-Policy Catalog)`

تحدد ترويسة `Permissions-Policy` واجهات برمجة المتصفح `(APIs)` ومستشعرات العتاد المسموح للصفحة أو الإطارات `(iframes)` الوصول إليها:

### الترويسة الإنتاجية الموصى بها `(Strict Default)`:
```http
Permissions-Policy: accelerometer=(), autoplay=(self), camera=(), display-capture=(), encrypted-media=(self), fullscreen=(self), geolocation=(), gyroscope=(), magnetometer=(), microphone=(), midi=(), payment=(), picture-in-picture=(self), publickey-credentials-get=(self), screen-wake-lock=(), sync-xhr=(), usb=(), xr-spatial-tracking=()
```

### قواعد التوجيهات:
* قيمة `()`: تعطيل الصلاحية تماماً للصفحة وكافة الإطارات التابعة لها.
* قيمة `(self)`: السماح للمصدر الحالي فقط بالوصول لهذه الميزة، وحظرها عن أي إطار خارجي.
* قيمة `("https://trusted-partner.com")`: السماح لمصدر خارجي محدد حصراً.

---

## 3. معايير تأمين ملفات الكوكيز والجلسات `(Cookie Security Standards)`

لحماية ملفات تعريف الارتباط من هجمات الحقن `(XSS)` وتزوير الطلبات `(CSRF)` وتسميم الجلسات `(Session Fixation)`:

### أ) الخصائص الإلزامية في ترويسة `Set-Cookie`:
```http
Set-Cookie: session_token=secret_val; Path=/; Secure; HttpOnly; SameSite=Lax; Max-Age=86400
```
* خاصية `Secure`: حظر إرسال الكوكي عبر اتصالات `HTTP` غير المشفرة.
* خاصية `HttpOnly`: حظر وصول شيفرات جافاسكربت `(document.cookie)` تماماً.
* قيمة `SameSite=Lax`: التوازن الأمثل لمواقع الويب؛ يُرسل الكوكي فقط عند الانتقال المباشر بين الروابط من مواقع خارجية، ويُحظر في طلبات `POST` و `Fetch` الخارجية.
* قيمة `SameSite=Strict`: الحماية القصوى للوحات الحساسة؛ لا يُرسل الكوكي مطلقاً إذا جاء الطلب من أي موقع خارجي.

### ب) بادئات العزل التلقائي `(Cookie Prefixes)`:
تفرض المتصفحات الحديثة قيوداً صارمة لا يمكن تجاوزها بمجرد وجود هذه البادئات في اسم الكوكي:

1. **البادئة `__Host-` (أعلى درجات الحماية)**:
   * يجب أن يحمل الكوكي سمة `Secure`.
   * **يُحظر** وجود سمة `Domain` (مما يمنع النطاقات الفرعية من قراءة أو استبدال الكوكي).
   * يجب أن يكون المسار `Path=/`.
```http
Set-Cookie: __Host-AuthToken=XYZ123; Path=/; Secure; HttpOnly; SameSite=Strict
```

2. **البادئة `__Secure-`**:
   * يجب أن يحمل سمة `Secure` (يُسمح بتحديد نطاقات فرعية عبر سمة `Domain`).
```http
Set-Cookie: __Secure-UserPref=Dark; Path=/; Domain=.example.com; Secure; SameSite=Lax
```

---

## 4. تطهير البيانات عند تسجيل الخروج `(Clear-Site-Data)`

عند تسجيل خروج المستخدم أو إنهاء الجلسة، يجب إرسال ترويسة `Clear-Site-Data` في استجابة نقطة نهاية الخروج `(/logout)` لحذف كافة المخلفات المخزنة محلياً في متصفح العميل:

```http
Clear-Site-Data: "cache", "cookies", "storage"
```
* خيار `"cache"`: مسح الكاش المحلي لصفحات المستخدم.
* خيار `"cookies"`: حذف كافة كوكيز النطاق.
* خيار `"storage"`: مسح التخزين المحلي `(localStorage)`، وجلسة التخزين `(sessionStorage)`، وقواعد `(IndexedDB)`.
