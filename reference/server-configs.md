# قوالب تكوين خوادم الويب والبرمجيات الوسيطة `(Server & Framework Configs)`

قوالب إنتاجية جاهزة للنسخ المباشر لتفعيل الترويسات الأمنية عبر خوادم الويب مثل `(Nginx)` و `(Caddy)` و `(Apache)` و `(Cloudflare)` وأطر العمل مثل `(Next.js)` و `(Laravel)`.

---

## 1. خادم `Nginx` (مع الحماية من فخ التوارث)

> [!CAUTION]
> **فخ توارث ترويسات `Nginx` الشهير**:  
> في خادم `Nginx`، إذا قمت بكتابة توجيه `add_header` واحد داخل كتلة فرعية (مثل `location /api { add_header X-Custom ...; }`)، فإن `Nginx` **يلغي ويتجاهل تلقائياً كافة ترويسات `add_header` المعرفة في الكتلة الأب `server` أو `http`**!  
> **الحل الهندسي**: وضع الترويسات في ملف مستقل واستدعاؤه عبر `include`.

### أ) إنشاء ملف الترويسات الموحد `(/etc/nginx/snippets/security-headers.conf)`:

```nginx
# Hide server version
server_tokens off;

# HTTP Strict Transport Security (HSTS)
add_header Strict-Transport-Security "max-age=63072000; includeSubDomains; preload" always;

# Prevent MIME sniffing
add_header X-Content-Type-Options "nosniff" always;

# Clickjacking protection
add_header X-Frame-Options "DENY" always;

# Referrer Policy
add_header Referrer-Policy "strict-origin-when-cross-origin" always;

# Permissions Policy
add_header Permissions-Policy "camera=(), microphone=(), geolocation=(), payment=(), usb=()" always;

# Balanced Content Security Policy
add_header Content-Security-Policy "default-src 'self'; script-src 'self' 'unsafe-inline' https:; style-src 'self' 'unsafe-inline' https:; img-src 'self' data: https:; font-src 'self' data: https:; connect-src 'self' https:; object-src 'none'; base-uri 'self'; form-action 'self'; frame-ancestors 'none'; upgrade-insecure-requests;" always;
```

### ب) استدعاء الترويسات في تكوين الموقع `(/etc/nginx/sites-available/example.com)`:

```nginx
server {
    listen 443 ssl http2;
    server_name example.com;

    # SSL Certificates
    ssl_certificate /etc/letsencrypt/live/example.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/example.com/privkey.pem;

    # Include security headers in main server block
    include /etc/nginx/snippets/security-headers.conf;

    location / {
        try_files $uri $uri/ /index.php?$query_string;
    }

    # Re-include security headers inside location blocks to prevent inheritance drops
    location /api/ {
        include /etc/nginx/snippets/security-headers.conf;
        add_header X-API-Version "1.0" always;
        proxy_pass http://api_backend;
    }
}
```

---

## 2. منصة `Cloudflare` `(Cloudflare Transform Rules & _headers)`

### أ) ملف الترويسات لـ `Cloudflare Pages` `(public/_headers)`:

```http
/*
  Strict-Transport-Security: max-age=63072000; includeSubDomains; preload
  X-Content-Type-Options: nosniff
  X-Frame-Options: DENY
  Referrer-Policy: strict-origin-when-cross-origin
  Permissions-Policy: camera=(), microphone=(), geolocation=(), payment=(), usb=()
  Content-Security-Policy: default-src 'self'; script-src 'self' https:; style-src 'self' 'unsafe-inline'; img-src 'self' data: https:; font-src 'self' data:; object-src 'none'; frame-ancestors 'none'; upgrade-insecure-requests;
```

---

## 3. خادم `Caddy` `(Caddyfile)`

```caddyfile
example.com {
    encode gzip zstd

    # Security headers
    header {
        Strict-Transport-Security "max-age=63072000; includeSubDomains; preload"
        X-Content-Type-Options "nosniff"
        X-Frame-Options "DENY"
        Referrer-Policy "strict-origin-when-cross-origin"
        Permissions-Policy "camera=(), microphone=(), geolocation=(), payment=(), usb=()"
        Content-Security-Policy "default-src 'self'; script-src 'self' https:; style-src 'self' 'unsafe-inline'; object-src 'none'; frame-ancestors 'none'; upgrade-insecure-requests;"
        -Server
    }

    reverse_proxy localhost:3000
}
```

---

## 4. خادم `Apache` `(.htaccess أو VirtualHost)`

```apache
<IfModule mod_headers.c>
    # HSTS
    Header always set Strict-Transport-Security "max-age=63072000; includeSubDomains; preload"
    
    # MIME sniffing
    Header always set X-Content-Type-Options "nosniff"
    
    # Clickjacking
    Header always set X-Frame-Options "DENY"
    
    # Referrer
    Header always set Referrer-Policy "strict-origin-when-cross-origin"
    
    # Permissions
    Header always set Permissions-Policy "camera=(), microphone=(), geolocation=(), payment=(), usb=()"
    
    # CSP
    Header always set Content-Security-Policy "default-src 'self'; script-src 'self' https:; style-src 'self' 'unsafe-inline'; img-src 'self' data: https:; object-src 'none'; frame-ancestors 'none'; upgrade-insecure-requests;"
</IfModule>
```

---

## 5. تطبيق `Next.js` `(Middleware مع توليد Nonce)`

في ملف `middleware.ts` في جذر مشروع `Next.js`:

```typescript
import { NextRequest, NextResponse } from 'next/server';

export function middleware(request: NextRequest) {
  // Generate cryptographically secure random nonce per request
  const nonce = Buffer.from(crypto.randomUUID()).toString('base64');
  
  // Build CSP policy using generated nonce
  const cspHeader = `
    default-src 'self';
    script-src 'self' 'nonce-${nonce}' 'strict-dynamic' https:;
    style-src 'self' 'nonce-${nonce}' 'unsafe-inline';
    img-src 'self' blob: data: https:;
    font-src 'self' data:;
    object-src 'none';
    base-uri 'self';
    form-action 'self';
    frame-ancestors 'none';
    upgrade-insecure-requests;
  `.replace(/\s{2,}/g, ' ').trim();

  // Pass nonce to request headers for frontend components
  const requestHeaders = new Headers(request.headers);
  requestHeaders.set('x-nonce', nonce);
  requestHeaders.set('Content-Security-Policy', cspHeader);

  const response = NextResponse.next({
    request: {
      headers: requestHeaders,
    },
  });

  // Set response security headers
  response.headers.set('Content-Security-Policy', cspHeader);
  response.headers.set('Strict-Transport-Security', 'max-age=63072000; includeSubDomains; preload');
  response.headers.set('X-Content-Type-Options', 'nosniff');
  response.headers.set('X-Frame-Options', 'DENY');
  response.headers.set('Referrer-Policy', 'strict-origin-when-cross-origin');
  response.headers.set('Permissions-Policy', 'camera=(), microphone=(), geolocation=(), payment=(), usb=()');

  return response;
}

export const config = {
  matcher: [
    /*
     * Apply middleware to all routes except static assets and images
     */
    {
      source: '/((?!api|_next/static|_next/image|favicon.ico).*)',
      missing: [
        { type: 'header', key: 'next-router-prefetch' },
        { type: 'header', key: 'purpose', value: 'prefetch' },
      ],
    },
  ],
};
```

---

## 6. تطبيق `Laravel` `(Security Headers Middleware)`

### إنشاء البرمجية الوسيطة `(app/Http/Middleware/SecurityHeadersMiddleware.php)`:

```php
<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

class SecurityHeadersMiddleware
{
    public function handle(Request $request, Closure $next): Response
    {
        $response = $next($request);

        // Standard security headers
        $response->headers->set('Strict-Transport-Security', 'max-age=63072000; includeSubDomains; preload');
        $response->headers->set('X-Content-Type-Options', 'nosniff');
        $response->headers->set('X-Frame-Options', 'DENY');
        $response->headers->set('Referrer-Policy', 'strict-origin-when-cross-origin');
        $response->headers->set('Permissions-Policy', 'camera=(), microphone=(), geolocation=(), payment=(), usb=()');

        // Balanced CSP header
        $csp = "default-src 'self'; script-src 'self' 'unsafe-inline' https:; style-src 'self' 'unsafe-inline' https:; img-src 'self' data: https:; font-src 'self' data: https:; object-src 'none'; frame-ancestors 'none'; upgrade-insecure-requests;";
        $response->headers->set('Content-Security-Policy', $csp);

        return $response;
    }
}
```
