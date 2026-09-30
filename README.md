# Security Headers Core: Agent Skill

An Agent Skill for AI coding assistants (Antigravity, Claude Code, Cursor, Gemini, Copilot). It enforces production-grade, zero-trust HTTP security headers, **Content Security Policy (CSP Level 3 with Nonces & Strict-Dynamic)**, **Cross-Origin Isolation (COOP / COEP / CORP)**, **Permissions-Policy**, and **Hardened Cookie Security (`__Host-` prefixes)** across major web servers and frameworks.

مهارة معيارية لوكلاء الذكاء الاصطناعي البرمجية لفرض أفضل الممارسات الهندسية للترويسات الأمنية في العمق `(Defense-in-Depth HTTP Security Headers)`، وتأمين سياسات المحتوى `(CSP)`، وعزل المصادر المتقاطعة، وحماية ملفات الكوكيز عبر خوادم الويب وأطر العمل.

---

## Installation / التثبيت

### 1. Interactive Installation via `skills` CLI (Recommended)

Run the following command in your terminal:

شغّل الأمر التالي في الطرفية لاختيار الوكيل ونطاق التثبيت:

```bash
npx skills add MosaabGalmod/security-headers-core
```

For non-interactive global installation across all detected agents:

للتثبيت العام المباشر لكافة الوكلاء المكتشفة:

```bash
npx skills add MosaabGalmod/security-headers-core -g -y
```

---

### 2. Antigravity & Gemini CLI

Copy this skill directory into your global Antigravity/Gemini configuration:

انسخ مجلد المهارة إلى مجلد إعدادات `Antigravity` العام:

```powershell
# Windows PowerShell
Copy-Item -Recurse -Force security-headers-core "$HOME\.gemini\config\skills\"
```

```bash
# Linux / macOS
cp -r security-headers-core ~/.gemini/config/skills/
```

---

### 3. Claude Code

Add this directory to your Claude skills:

أضف هذا المجلد إلى مهارات `Claude Code`:

```bash
cp -r security-headers-core ~/.claude/skills/
```

---

### 4. Cursor / Windsurf

Copy `SKILL.md` to your project's rules:

انسخ ملف `SKILL.md` إلى مجلد قواعد المشروع:

```bash
cp security-headers-core/SKILL.md .cursor/rules/security-headers-core.mdc
```

---

## The 3 Security Profiles / مستويات الحماية الثلاثة

1. **Development & Report-Only Profile**:
   * Uses `Content-Security-Policy-Report-Only` with reporting endpoints for non-breaking audits during active development.
2. **Standard Balanced Production Profile**:
   * Strict `HSTS` (`max-age=63072000; includeSubDomains; preload`).
   * `X-Content-Type-Options: nosniff`.
   * `X-Frame-Options: DENY` (and `frame-ancestors 'none'`).
   * `Referrer-Policy: strict-origin-when-cross-origin`.
   * `Permissions-Policy`: hardware and sensor lockdown.
   * Balanced CSP Level 3.
3. **Paranoid / Zero-Trust Profile**:
   * Complete Cross-Origin Isolation (`COOP: same-origin`, `COEP: require-corp`, `CORP: same-origin`).
   * Cryptographic Nonce-based CSP with `'strict-dynamic'`.
   * Trusted Types enforcement (`require-trusted-types-for 'script'`).
   * Session flushing via `Clear-Site-Data: "cache", "cookies", "storage"`.

---

## Repository Structure / هيكلية المستودع

```
security-headers-core/
├── SKILL.md                          # Main skill instructions and fast reference
├── README.md                         # Documentation and install guide
├── LICENSE                           # MIT License
└── reference/
    ├── csp-deep-dive.md              # CSP Level 3, Nonces, Hashes, GTM/Stripe recipes
    ├── isolation-and-cookies.md      # COOP, COEP, CORP, Permissions-Policy, __Host-
    └── server-configs.md             # Nginx, Cloudflare, Caddy, Apache, Next.js, Laravel
```

---

## License

MIT License © 2026 Mosaab Galmod
