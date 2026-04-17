# Admin Currency Management

Endpoints for admin dashboard to grant/deduct gold & gems to users.

All endpoints require `role: "admin"` (check `req.user.role === 'admin'`).
Return `403` for non-admins.

---

## 1. Search for a user

```
GET /api/v1/admin/users/search?q=<query>&limit=20
Authorization: Bearer <admin_token>
```

`q` matches against `username`, `email`, or `friendCode`.

**Response:**
```json
{
  "success": true,
  "data": [
    {
      "id": "uuid",
      "username": "player1",
      "email": "a@b.com",
      "friendCode": "482951",
      "avatarUrl": "/uploads/...",
      "gold": 120,
      "gems": 0,
      "level": 3,
      "role": "player"
    }
  ]
}
```

---

## 2. Grant currency

```
POST /api/v1/admin/users/:userId/grant
Authorization: Bearer <admin_token>
Content-Type: application/json
```

**Request:**
```json
{
  "currency": "gold",   // "gold" | "gems"
  "amount": 500,         // positive = add, negative = deduct
  "reason": "دعم فني"   // free-text, logged in audit
}
```

**Response:**
```json
{
  "success": true,
  "message": "تمت إضافة 500 ذهب",
  "data": {
    "userId": "uuid",
    "currency": "gold",
    "amount": 500,
    "newBalance": 620
  }
}
```

**Errors:**
- 400 — invalid currency, amount is 0, or deduction would result in negative balance
- 403 — user is not admin
- 404 — userId not found

---

## 3. Audit log (optional)

```
GET /api/v1/admin/audit?userId=<uuid>&limit=50
```

Returns all admin actions for a user (grants, role changes, bans).

---

## Backend logic (Node.js reference)

```js
app.post('/api/v1/admin/users/:userId/grant', requireAdmin, async (req, res) => {
  const { currency, amount, reason } = req.body
  const { userId } = req.params

  if (!['gold', 'gems'].includes(currency))
    return res.status(400).json({ success: false, message: 'عملة غير صالحة' })

  if (!Number.isInteger(amount) || amount === 0)
    return res.status(400).json({ success: false, message: 'الكمية غير صالحة' })

  const user = await User.findByPk(userId)
  if (!user) return res.status(404).json({ success: false, message: 'المستخدم غير موجود' })

  const current = currency === 'gold' ? user.gold : user.gems
  const newBalance = current + amount
  if (newBalance < 0)
    return res.status(400).json({ success: false, message: 'الرصيد غير كافٍ' })

  // حدّث الرصيد
  user[currency] = newBalance
  await user.save()

  // سجّل المعاملة
  await Transaction.create({
    userId,
    amount,
    type: 'admin_grant',
    currency,
    description: `Admin: ${reason || 'بدون سبب'}`
  })

  // Audit log (اختياري — جدول AdminActions)
  await AdminAction.create({
    adminId: req.user.id,
    targetUserId: userId,
    action: 'grant',
    metadata: { currency, amount, reason }
  })

  res.json({
    success: true,
    message: `تمت ${amount > 0 ? 'إضافة' : 'خصم'} ${Math.abs(amount)} ${currency === 'gold' ? 'ذهب' : 'جوهرة'}`,
    data: { userId, currency, amount, newBalance }
  })
})

// Middleware
function requireAdmin(req, res, next) {
  if (req.user?.role !== 'admin')
    return res.status(403).json({ success: false, message: 'صلاحية أدمن مطلوبة' })
  next()
}
```

---

## Making yourself admin (one-time, via DB)

Since you don't have this endpoint yet, run on the server:

```sql
UPDATE Users SET role = 'admin' WHERE email = 'your@email.com';
```

Or via your existing admin console if you have one.

---

## Admin Dashboard UI (suggestion)

Your existing web admin panel (if any) should add:

1. **Users page** — list + search by name/email/friendCode
2. **User detail** — show balances + "منح ذهب" / "منح جواهر" buttons
3. **Modal** — amount + reason → calls `POST /admin/users/:id/grant`
4. **Audit log page** — history of all admin grants

---

## For immediate testing

If you want to get 500 gold now without building the admin UI:

**SSH into server + run SQL:**
```sql
UPDATE Users SET gold = gold + 500 WHERE email = 'your@email.com';
```

Or add a one-liner temporary endpoint (delete after use):
```js
// ⚠️ احذف بعد الاختبار!
app.post('/api/v1/dev/me/grant-gold', requireAuth, async (req, res) => {
  const user = await User.findByPk(req.user.id)
  user.gold += 500
  await user.save()
  res.json({ success: true, data: { newGold: user.gold } })
})
```
