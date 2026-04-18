# Clan Admin Tools — Backend Specification

Endpoints for clan moderation tools used by iOS admin UI.

All endpoints require `Authorization: Bearer <token>`.
Permission model:
- `owner` — كل الصلاحيات
- `admin` — كل الصلاحيات عدا: حذف العشيرة، نقل الزعامة، Read-only toggle, clear chat
- `member` — فقط حذف رسائله، التبليغ

---

## 1. Delete Message

```
DELETE /api/v1/clans/:clanId/chat/:messageId
```

**Permission:** كاتب الرسالة نفسه أو `admin/owner`.

**Response:**
```json
{ "success": true, "message": "تم حذف الرسالة" }
```

**Socket emit:** `clan:message-deleted` → `{ clanId, messageId }`

---

## 2. Clear All Chat

```
DELETE /api/v1/clans/:clanId/chat
```

**Permission:** `owner` فقط.

**Effect:** حذف جميع رسائل العشيرة (أو soft-delete).

**Response:**
```json
{ "success": true, "message": "تم مسح الشات" }
```

**Socket emit:** `clan:chat-cleared` → `{ clanId }` (اختياري — iOS يمسح محلياً)

---

## 3. Report Message

```
POST /api/v1/clans/:clanId/chat/:messageId/report
Body: { "reason": "spam أو إعلانات" }
```

**Permission:** أي عضو.

**Logic:**
- سجّل في جدول `MessageReports { id, messageId, reporterId, reason, createdAt }`
- لا ترسل للـ reporter إشعار أن رسالته أُبلغ عنها
- Admin dashboard يشوف البلاغات المعلّقة

**Response:**
```json
{ "success": true, "message": "تم استلام البلاغ" }
```

---

## 4. Mute Member

```
POST /api/v1/clans/:clanId/members/:userId/mute
Body: { "durationMinutes": 60 }
```

**Permission:** `admin/owner` — لا يقدر يكتم أعلى منه.

**Logic:**
- حدّث `ClanMember.mutedUntil = now + duration`
- لو العضو حاول يرسل رسالة → رفض HTTP 403 مع رسالة "أنت مكتوم حتى ..."
- تلقائياً ينتهي الكتم بعد المدة (تحقق من `mutedUntil > now` عند الإرسال)

**Response:**
```json
{ "success": true, "message": "تم الكتم", "data": { "mutedUntil": "..." } }
```

**Socket emit:** `clan:member-role-changed` → iOS يعيد تحميل الأعضاء

---

## 5. Unmute Member

```
POST /api/v1/clans/:clanId/members/:userId/unmute
```

**Permission:** `admin/owner`.

**Logic:** `ClanMember.mutedUntil = null`

**Response:**
```json
{ "success": true, "message": "تم رفع الكتم" }
```

---

## 6. Read-Only Mode (Announcements only)

```
PATCH /api/v1/clans/:clanId
Body: { "readOnly": true }
```

**Permission:** `owner` فقط.

**Logic:**
- لو `clan.readOnly = true` → رفض إرسال رسائل من `role: member`
- `admin/owner` يقدروا يرسلوا (عادة كـ announcement)

**Response:**
```json
{ "success": true, "data": { ...clan, "readOnly": true } }
```

**Socket emit:** `clan:updated` → iOS يعيد تحميل

---

## Model Changes

### `Clan` table
أضف:
```sql
ALTER TABLE Clans ADD COLUMN readOnly BOOLEAN DEFAULT false;
```

### `ClanMember` table
أضف:
```sql
ALTER TABLE ClanMembers ADD COLUMN mutedUntil TIMESTAMP NULL;
```

### New table `MessageReports`
```sql
CREATE TABLE MessageReports (
  id UUID PRIMARY KEY,
  messageId UUID NOT NULL REFERENCES ClanMessages(id) ON DELETE CASCADE,
  reporterId UUID NOT NULL REFERENCES Users(id),
  reason TEXT,
  status ENUM('pending', 'reviewed', 'dismissed') DEFAULT 'pending',
  createdAt TIMESTAMP DEFAULT NOW()
);
```

### `ClanMessage` table
أضف للـ reply/quote:
```sql
ALTER TABLE ClanMessages ADD COLUMN replyToId UUID NULL REFERENCES ClanMessages(id);
```

وعند إرجاع الرسائل، ضمّن `replyToSnippet` و `replyToUsername`:
```js
const message = await ClanMessage.findByPk(id, {
  include: [{ 
    model: ClanMessage, as: 'replyTo',
    include: [{ model: User, attributes: ['username'] }]
  }]
})
return {
  ...message.toJSON(),
  replyToSnippet: message.replyTo?.content.slice(0, 80),
  replyToUsername: message.replyTo?.User?.username
}
```

---

## Word Filter (Server-side recommended)

iOS يطبّق فلتر محلي بسيط في `WordFilter.swift`، لكن السيرفر يجب يطبّق فلتر أقوى:

1. قائمة كلمات محظورة كاملة (في DB أو ملف config)
2. قبل حفظ الرسالة، تحقق
3. لو فيها كلمة محظورة → HTTP 400 مع `{ "message": "محتوى غير مسموح" }`
4. اختياري: استبدل الكلمة بـ `***` بدل الرفض الكامل

---

## Middleware for Chat Send

عند `POST /clans/:id/chat`:

```js
app.post('/api/v1/clans/:id/chat', requireAuth, async (req, res) => {
  const { id } = req.params
  const member = await ClanMember.findOne({ where: { clanId: id, userId: req.user.id } })
  if (!member) return res.status(403).json({ success: false, message: 'لست عضواً' })

  // تحقق من الكتم
  if (member.mutedUntil && new Date(member.mutedUntil) > new Date()) {
    return res.status(403).json({ 
      success: false, 
      message: `أنت مكتوم حتى ${member.mutedUntil}`
    })
  }

  // تحقق من Read-only
  const clan = await Clan.findByPk(id)
  if (clan.readOnly && member.role === 'member') {
    return res.status(403).json({ 
      success: false, 
      message: 'الشات في وضع الإعلانات فقط'
    })
  }

  // تحقق من الكلمات
  if (containsBannedWord(req.body.content)) {
    return res.status(400).json({ 
      success: false, 
      message: 'المحتوى يحتوي كلمات غير مسموحة'
    })
  }

  // احفظ واحفظ الرد
  // ...
})
```

---

## Admin Dashboard Pages (Web)

توصيات لتضاف في لوحة الويب:

1. **Reports Queue** — قائمة البلاغات `status = pending`
2. **Muted Members** — قائمة الأعضاء المكتومين حالياً
3. **Clan Activity** — سجل الأحداث (mute/unmute/kick/clear)
