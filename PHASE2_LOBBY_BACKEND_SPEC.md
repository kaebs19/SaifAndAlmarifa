# Phase 2 Lobby — Backend Specification

5 ميزات جديدة تحتاج backend support:
1. Search users by username
2. Ready check in rooms
3. Kick player
4. Room chat
5. Universal Links (`apple-app-site-association`)

---

## 1️⃣ Search Users by Username

### Endpoint

```
GET /api/v1/users/search?q=<query>&limit=20
Authorization: Bearer <token>
```

### Response
```json
{
  "success": true,
  "data": [
    {
      "id": "uuid",
      "username": "محمد",
      "avatarUrl": "/uploads/avatars/...",
      "level": 5,
      "country": "SA"
    }
  ]
}
```

### Logic
- يشمل كل المستخدمين (ليس فقط الأصدقاء)
- يستثني المستخدم الحالي من النتائج
- limit افتراضي 20، حد أقصى 50
- بحث case-insensitive في `username`

```js
app.get('/api/v1/users/search', requireAuth, async (req, res) => {
  const { q } = req.query
  if (!q || q.length < 2) return res.json({ success: true, data: [] })
  
  const users = await User.findAll({
    where: {
      username: { [Op.iLike]: `%${q}%` },
      id: { [Op.ne]: req.user.id }  // استثنِ نفسي
    },
    attributes: ['id', 'username', 'avatarUrl', 'level', 'country'],
    limit: Math.min(parseInt(req.query.limit) || 20, 50)
  })
  res.json({ success: true, data: users })
})
```

---

## 2️⃣ Ready Check

### Client → Server

```js
socket.emit('room:ready', { ready: true | false })
```

### Server → Client (broadcast لكل الغرفة)

```js
// بعد أي تحديث
socket.on('room:ready-state', {
  code: '123456',
  readyUserIds: ['uuid1', 'uuid3']   // من جاهز فقط
})

// عند جهوزية الجميع
socket.on('room:all-ready', { code: '123456' })
```

### Backend Logic

```js
// in-memory per room
const readyState = new Map()  // code → Set<userId>

socket.on('room:ready', ({ ready }) => {
  const roomCode = getUserRoom(socket.userId)
  if (!roomCode) return
  
  const set = readyState.get(roomCode) ?? new Set()
  if (ready) set.add(socket.userId)
  else set.delete(socket.userId)
  readyState.set(roomCode, set)
  
  // بث لكل الغرفة
  io.to(`room:${roomCode}`).emit('room:ready-state', {
    code: roomCode,
    readyUserIds: Array.from(set)
  })
  
  // تحقق: كل اللاعبين جاهزين؟
  const room = rooms.get(roomCode)
  if (room.players.every(p => set.has(p.id))) {
    io.to(`room:${roomCode}`).emit('room:all-ready', { code: roomCode })
    // بعد ثانية، ابدأ المباراة تلقائياً
    setTimeout(() => startMatch(roomCode), 1000)
  }
})

// عند مغادرة لاعب، احذفه من readyState
socket.on('disconnect', () => {
  for (const [code, set] of readyState) {
    set.delete(socket.userId)
  }
})
```

---

## 3️⃣ Kick Player

### Client → Server

```js
socket.emit('room:kick', { userId: '<uuid>' })
```

### Server → Client

يبث `room:player-left` للكل (موجود بالفعل) + event خاص للمطرود:

```js
// لمن تم طرده فقط
socket.on('room:kicked', {
  code: '123456',
  reason: 'تم طردك من الغرفة'
})
```

### Backend Logic

```js
socket.on('room:kick', async ({ userId }) => {
  const roomCode = getUserRoom(socket.userId)
  if (!roomCode) return
  
  const room = rooms.get(roomCode)
  // فقط الـ host يقدر يطرد
  if (room.hostId !== socket.userId) {
    return socket.emit('room:error', { message: 'فقط الهوست يطرد' })
  }
  
  const kickedSocket = getSocketByUserId(userId)
  if (kickedSocket) {
    kickedSocket.emit('room:kicked', { code: roomCode, reason: 'تم طردك من الغرفة' })
    kickedSocket.leave(`room:${roomCode}`)
  }
  
  // احذفه من الغرفة
  room.players = room.players.filter(p => p.id !== userId)
  
  // بث للغرفة
  io.to(`room:${roomCode}`).emit('room:player-left', {
    code: roomCode,
    userId,
    players: room.players
  })
})
```

---

## 4️⃣ Room Chat

### Client → Server

```js
socket.emit('room:chat-message', { content: 'مرحبا' })
```

### Server → Client (broadcast)

```js
socket.on('room:chat-message', {
  code: '123456',
  message: {
    id: 'uuid',
    userId: 'uuid',
    username: 'محمد',
    avatarUrl: '/uploads/...',
    content: 'مرحبا',
    createdAt: '2026-04-15T...'
  }
})
```

### Backend Logic

```js
socket.on('room:chat-message', async ({ content }) => {
  const roomCode = getUserRoom(socket.userId)
  if (!roomCode || !content?.trim()) return
  
  // تحقق من memberhip
  const room = rooms.get(roomCode)
  if (!room.players.some(p => p.id === socket.userId)) return
  
  // محتوى قصير (حد 200 حرف)
  const trimmed = content.trim().slice(0, 200)
  
  const user = await User.findByPk(socket.userId, {
    attributes: ['id', 'username', 'avatarUrl']
  })
  
  const message = {
    id: uuid(),
    userId: user.id,
    username: user.username,
    avatarUrl: user.avatarUrl,
    content: trimmed,
    createdAt: new Date()
  }
  
  io.to(`room:${roomCode}`).emit('room:chat-message', {
    code: roomCode,
    message
  })
})
```

**ملاحظات:**
- الرسائل ليست persistent — تُحذف عند انتهاء الغرفة
- لا يحتاج database — in-memory كافٍ
- Rate limit: 5 رسائل / ثانية (اختياري)

---

## 5️⃣ Universal Links

### الملف المطلوب على السيرفر

```
https://saifiq.halmanhaj.com/.well-known/apple-app-site-association
```

### المحتوى (JSON — بدون .json extension)

```json
{
  "applinks": {
    "apps": [],
    "details": [
      {
        "appID": "XXXXXXXXXX.com.saifiq.app",
        "paths": [
          "/join/*",
          "/clan/*"
        ]
      }
    ]
  }
}
```

> **استبدل** `XXXXXXXXXX` بـ **Team ID** من Apple Developer Portal.

### Headers على السيرفر
```
Content-Type: application/json
```

### الـ URLs المدعومة

| URL | يفتح | في iOS |
|-----|------|--------|
| `https://saifiq.halmanhaj.com/join/123456` | لوبي غرفة (code=123456) | ✅ `MainView.joinRoom` |
| `https://saifiq.halmanhaj.com/clan/uuid` | شاشة العشيرة | ✅ `directClanId` |

### Express route (مثال Node.js)

```js
app.get('/.well-known/apple-app-site-association', (req, res) => {
  res.setHeader('Content-Type', 'application/json')
  res.json({
    applinks: {
      apps: [],
      details: [
        {
          appID: `${process.env.APPLE_TEAM_ID}.com.saifiq.app`,
          paths: ['/join/*', '/clan/*']
        }
      ]
    }
  })
})
```

### Web Fallback (اختياري لكن موصى به)

لو المستخدم فتح الرابط بدون التطبيق، اعرض صفحة بسيطة:

```
https://saifiq.halmanhaj.com/join/123456

→ HTML page: "انضم للعبة — حمّل التطبيق"
              [App Store badge]
              الكود: 123456
```

### Update for sharing
عند `room:invite`، استخدم الرابط في الـ push:

```js
shareLink: `https://saifiq.halmanhaj.com/join/${code}`
```

iOS بالفعل يعرضه في الـ iOS Share Sheet.

---

## 📋 Summary — Priority Order

| الميزة | نوع العمل | مدة |
|--------|-----------|------|
| Universal Links | serve JSON file | 10 دقائق |
| Search users | endpoint واحد | 20 دقيقة |
| Kick player | socket event | 15 دقيقة |
| Ready check | 2 socket events | 30 دقيقة |
| Room chat | socket event + rate limit | 30 دقيقة |

**المجموع: ~2 ساعة** للـ backend.

---

## iOS Side — كله جاهز ✅

كل ال endpoints + events مربوطة في iOS. بمجرد ما السيرفر يطبّقها، الميزات تشتغل فوراً بدون تعديل iOS.

### Features ready in iOS:
- ✅ Search users tab في InviteFriendsSheet
- ✅ Ready button في اللوبي + badge يتغيّر لكل لاعب
- ✅ Kick menu (ellipsis) للهوست على كل لاعب
- ✅ RoomChatBar expandable مع typing + send
- ✅ DeepLinkManager يلتقط Universal Links تلقائياً
- ✅ Associated Domains capability مضافة
