# المطلوب من الـ Backend

ملخّص موحّد لكل ما يحتاجه تطبيق iOS من تحديثات على `saifiq-api`.

---

## 🔴 الأولوية 1 — حرجة (قبل الإطلاق)

### 1. IAP Verification — `POST /iap/verify`
> **لماذا:** بدونها المستخدم يدفع من App Store لكن ما يصله جواهر.
>
> **المواصفات الكاملة:** [`IAP_BACKEND_SPEC.md`](IAP_BACKEND_SPEC.md)

**مختصر:**
- التحقق من `transactionId` مع App Store Server API
- منع إعادة الاستخدام (جدول `IAPTransactions`)
- خريطة المنتجات:
  | Product ID | Gems | Bonus Gold |
  |-----------|------|------------|
  | `com.saifiq.gems.50`   | 50   | 0    |
  | `com.saifiq.gems.300`  | 300  | 0    |
  | `com.saifiq.gems.700`  | 700  | 0    |
  | `com.saifiq.gems.1500` | 1500 | 200  |
  | `com.saifiq.gems.5000` | 5000 | 1000 |

---

### 2. Admin Currency Grants
> **لماذا:** دعم فني + قدرة إضافة رصيد للمستخدمين يدوياً.
>
> **المواصفات الكاملة:** [`ADMIN_CURRENCY_SPEC.md`](ADMIN_CURRENCY_SPEC.md)

**Endpoints المطلوبة:**
- `GET /admin/users/search?q=...` — بحث عن مستخدم
- `POST /admin/users/:userId/grant` — إضافة/خصم ذهب أو جواهر + سبب
- `GET /admin/audit` — سجل التعديلات (اختياري)

**مؤقتاً للاختبار فقط:** SQL مباشر:
```sql
UPDATE Users SET gold = gold + 5000 WHERE email = '...';
```

---

## 🟡 الأولوية 2 — تحسين تجربة العشائر

### 3. Socket.io Events للعشائر
> **لماذا:** الشات حالياً polling — الرسائل ما تظهر إلا بعد سحب للتحديث.
>
> **المواصفات الكاملة:** [`CLAN_SOCKET_SPEC.md`](CLAN_SOCKET_SPEC.md)

**الأحداث المطلوبة:**

**من iOS:**
- `clan:join` — دخول غرفة عشيرة
- `clan:leave` — مغادرة الغرفة
- `clan:typing` — "يكتب الآن"

**من السيرفر (broadcast):**
- `clan:message` — رسالة جديدة
- `clan:message-deleted`
- `clan:member-joined` / `clan:member-left`
- `clan:member-role-changed`
- `clan:typing` (لباقي الأعضاء)
- `clan:updated` — تغيّرت معلومات العشيرة

**نقاط التكامل:**
بعد كل REST endpoint يغيّر بيانات العشيرة، لازم يـ `emit` الحدث المناسب لغرفة `clan:<clanId>`.

---

### 4. Pagination للشات
```
GET /clans/:id/chat?limit=30&before=<messageId>
```
- `limit` افتراضي 30، حد أقصى 100
- `before` يرجّع رسائل أقدم من هذا الـ messageId

iOS حالياً يبعث الـ query params — السيرفر بس يحتاج يدعمها.

---

## 🟢 الأولوية 3 — مستقبلية (بعد الإطلاق)

### 5. Push Notifications (APNs)
- `POST /devices/register` — المستخدم يسجّل device token
- إرسال إشعارات عند:
  - قبول طلب انضمام لعشيرة
  - ترقية لمشرف
  - طرد من عشيرة
  - إعلان جديد في عشيرتك
  - رسالة في الشات (اختياري — أو فقط @mention)

### 6. App Store Server Notifications V2
- `POST /iap/apple-notifications` — webhook لاستقبال:
  - `REFUND` → خصم الجواهر
  - `CONSUMPTION_REQUEST`

### 7. Clan Wars / حروب العشائر
- جدولة أسبوعية (2 عشيرة تتواجه)
- `GET /clan-wars/current` — الحرب الحالية
- `POST /clan-wars/submit-score`
- `GET /clan-wars/leaderboard`

### 8. Clan Perks (امتيازات بالمستوى)
- Lv.2: ذهب مكافأة يومية للأعضاء
- Lv.3: خصم 10% على المتجر
- Lv.5: شعار خاص
- تنفيذ: حقل `perks` في جدول Clans + تطبيق في الـ business logic

---

## 📂 ملفات المواصفات (في جذر المشروع)

| الملف | المحتوى |
|-------|---------|
| [`IAP_BACKEND_SPEC.md`](IAP_BACKEND_SPEC.md) | تفاصيل كاملة + Node.js reference code |
| [`ADMIN_CURRENCY_SPEC.md`](ADMIN_CURRENCY_SPEC.md) | Admin endpoints + Node.js code |
| [`CLAN_SOCKET_SPEC.md`](CLAN_SOCKET_SPEC.md) | Socket events + pagination |

كل واحد فيه:
- شكل الـ request/response بالتفصيل
- Node.js reference code جاهز للنسخ
- أمثلة أخطاء
- SQL مقترح

---

## ✅ ما هو جاهز iOS-side

iOS Client يدعم بالفعل:
- ✅ استدعاء `/iap/verify` بعد كل شراء ناجح
- ✅ الاستماع لكل أحداث Socket للعشائر
- ✅ إرسال pagination query params
- ✅ عرض رسائل الأخطاء من السيرفر كـ toast

السيرفر فقط يحتاج ينفّذ الأطراف الأخرى.
