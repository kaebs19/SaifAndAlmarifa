# Message Reactions — Backend Spec

Toggle emoji reactions on clan chat messages.

---

## Endpoint

```
POST /api/v1/clans/:clanId/chat/:messageId/react
Authorization: Bearer <token>
Content-Type: application/json
```

**Body:**
```json
{ "emoji": "❤️" }
```

**Behavior (toggle):**
- إذا المستخدم **ما تفاعل بعد** بهذا الإيموجي → أضف تفاعل
- إذا **سبق وتفاعل** بنفس الإيموجي → احذف تفاعله
- المستخدم يقدر يتفاعل بـ 5 إيموجي مختلفة على نفس الرسالة (حد أقصى)

**Response:**
```json
{
  "success": true,
  "data": [
    { "emoji": "❤️", "count": 3, "mine": true },
    { "emoji": "🔥", "count": 1, "mine": false }
  ]
}
```

---

## Data Model

### `MessageReactions` table
```sql
CREATE TABLE MessageReactions (
  id UUID PRIMARY KEY,
  messageId UUID NOT NULL REFERENCES ClanMessages(id) ON DELETE CASCADE,
  userId UUID NOT NULL REFERENCES Users(id),
  emoji VARCHAR(10) NOT NULL,
  createdAt TIMESTAMP DEFAULT NOW(),
  UNIQUE (messageId, userId, emoji)   -- user واحد يتفاعل مرة بكل emoji
);

CREATE INDEX idx_reactions_msg ON MessageReactions(messageId);
```

### When returning messages
ضمّن حقل `reactions` مع كل رسالة:

```js
const messages = await ClanMessage.findAll({
  where: { clanId },
  include: [
    { model: User, attributes: ['id', 'username', 'avatarUrl'] },
    {
      model: MessageReaction,
      as: 'Reactions',
      attributes: ['emoji', 'userId']
    }
  ],
  order: [['createdAt', 'DESC']],
  limit
})

// Transform reactions to grouped format
const transformed = messages.map(m => {
  const grouped = {}
  for (const r of m.Reactions || []) {
    if (!grouped[r.emoji]) grouped[r.emoji] = { emoji: r.emoji, count: 0, mine: false }
    grouped[r.emoji].count += 1
    if (r.userId === req.user.id) grouped[r.emoji].mine = true
  }
  return { ...m.toJSON(), reactions: Object.values(grouped), Reactions: undefined }
})
```

---

## Toggle Logic (Node.js)

```js
app.post('/api/v1/clans/:clanId/chat/:messageId/react', requireAuth, async (req, res) => {
  const { clanId, messageId } = req.params
  const { emoji } = req.body
  const userId = req.user.id

  // تحقق من العضوية
  const member = await ClanMember.findOne({ where: { clanId, userId } })
  if (!member) return res.status(403).json({ success: false, message: 'لست عضواً' })

  // تحقق من وجود الرسالة
  const message = await ClanMessage.findOne({ where: { id: messageId, clanId } })
  if (!message) return res.status(404).json({ success: false, message: 'الرسالة غير موجودة' })

  // toggle
  const existing = await MessageReaction.findOne({ where: { messageId, userId, emoji } })
  if (existing) {
    await existing.destroy()
  } else {
    // حد أقصى 5 إيموجي مختلفة من نفس المستخدم على نفس الرسالة
    const count = await MessageReaction.count({ where: { messageId, userId } })
    if (count >= 5) {
      return res.status(400).json({ success: false, message: 'وصلت الحد الأقصى للتفاعلات' })
    }
    await MessageReaction.create({ id: uuid(), messageId, userId, emoji })
  }

  // احسب التفاعلات المحدّثة
  const all = await MessageReaction.findAll({ where: { messageId } })
  const grouped = {}
  for (const r of all) {
    if (!grouped[r.emoji]) grouped[r.emoji] = { emoji: r.emoji, count: 0, mine: false }
    grouped[r.emoji].count += 1
    if (r.userId === userId) grouped[r.emoji].mine = true
  }
  const reactions = Object.values(grouped)

  // بث للـ socket
  io.to(`clan:${clanId}`).emit('clan:message-reaction', {
    clanId,
    messageId,
    reactions
  })

  res.json({ success: true, data: reactions })
})
```

---

## Socket Event

```json
// clan:message-reaction
{
  "clanId": "uuid",
  "messageId": "uuid",
  "reactions": [
    { "emoji": "❤️", "count": 3, "mine": false },
    { "emoji": "🔥", "count": 1, "mine": false }
  ]
}
```

**ملاحظة:** `mine: false` دائماً في الـ socket payload لأن الـ socket يبث للكل — iOS يحدّثها تلقائياً حسب `userId`.

أو طريقة أنظف: إرسال broadcast مع كل الـ reactions raw:
```json
{
  "clanId": "uuid",
  "messageId": "uuid",
  "rawReactions": [
    { "emoji": "❤️", "userId": "u1" },
    { "emoji": "❤️", "userId": "u2" }
  ]
}
```
وكل client يحسب `mine` بنفسه.

(الاختيار الحالي في iOS يفترض payload جاهز — أبسط.)

---

## Quick Emoji Whitelist (اختياري)

لتحسين الأداء وتجنب emoji غريبة، السيرفر يقدر يحدد قائمة مسموحة:

```js
const ALLOWED_REACTIONS = ['❤️', '🔥', '👏', '😂', '😮', '😢']

if (!ALLOWED_REACTIONS.includes(emoji)) {
  return res.status(400).json({ success: false, message: 'إيموجي غير مسموح' })
}
```

iOS حالياً يرسل من قائمة ثابتة في `ReactionQuickPicker.quickReactions`:
```swift
["❤️", "🔥", "👏", "😂", "😮", "😢"]
```

---

## Performance Tips

- **Index** على `MessageReaction.messageId` ضروري
- **Batch load** reactions مع messages في استعلام واحد (include)
- **Cache** popular reactions per day (redis) للـ trending
