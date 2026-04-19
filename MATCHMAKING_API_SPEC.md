# Matchmaking & Rooms — Backend API Specification

هذه الوثيقة تغطي **كل** ما يحتاجه الـ backend لدعم شاشة اللعب الموحّدة في iOS.

الأوضاع الخمسة:
1. `random1v1` — طابور عشوائي 2 لاعب
2. `random4` — طابور عشوائي 4 لاعبين
3. `private1v1` — غرفة خاصة 2 لاعب بكود
4. `challengeFriend` — غرفة خاصة 2 لاعب + دعوة صديق
5. `friends4` — غرفة خاصة 4 لاعبين + دعوة أصدقاء

---

## 📡 Socket.io Events

### 🔍 Queue (طابور عشوائي)

#### Client → Server

```js
// دخول الطابور
socket.emit('queue:join', { mode: '1v1' | '4player' })

// الخروج من الطابور
socket.emit('queue:leave')
```

#### Server → Client

```js
// نجح الانضمام للطابور
socket.on('queue:joined', () => {})

// غادر الطابور
socket.on('queue:left', () => {})

// خطأ
socket.on('queue:error', { message: string })

// تم إيجاد مباراة (لكل اللاعبين في المباراة)
socket.on('match:found', { matchId: string })
```

**Logic:** عند وصول 2 أو 4 لاعبين في طابور `mode` معيّن → أنشئ match وابعث `match:found` لكل اللاعبين.

---

### 🏠 Private Room (غرفة خاصة)

#### Client → Server

```js
// إنشاء غرفة
socket.emit('room:create', { mode: '1v1' | '4player' })

// الانضمام بكود
socket.emit('room:join', { code: 'ABC123' })

// دعوة صديق
socket.emit('room:invite', { code: 'ABC123', friendId: 'uuid' })

// مغادرة الغرفة
socket.emit('room:leave')
```

#### Server → Client

```js
// الغرفة أُنشئت (للمنشئ فقط)
socket.on('room:created', {
  code: 'ABC123',
  mode: '1v1' | '4player',
  host: { id: 'uuid', username: 'محمد', avatarUrl: '/uploads/...' }
})

// لاعب جديد انضم (لكل من في الغرفة)
socket.on('room:player-joined', {
  code: 'ABC123',
  player: {
    id: 'uuid',
    username: 'أحمد',
    avatarUrl: '/uploads/...',
    level: 5
  }
})

// لاعب غادر
socket.on('room:player-left', {
  code: 'ABC123',
  userId: 'uuid',
  username: 'أحمد'   // للعرض في الـ UI
})

// الغرفة تفكّكت (الهوست غادر)
socket.on('room:disbanded', { code: 'ABC123', reason: string })

// خطأ
socket.on('room:error', { message: 'الكود غير صحيح' })

// أنت مدعوّ لغرفة (لمن تمت دعوته)
socket.on('room:invited', {
  code: 'ABC123',
  fromUser: { id, username, avatarUrl },
  mode: '1v1' | '4player'
})
```

**ملاحظة مهمة:** iOS حالياً يتعامل مع `room:player-joined.username` كسلسلة نصية بسيطة. لكن لتحسين الـ UI (عرض الأفاتار + المستوى)، استخدم `player` object بدل string مباشر. iOS سيدعمه بعد التحديث.

---

### 🎮 Match Flow (بعد إيجاد/بدء المباراة)

```js
// انضم لغرفة السوكت الخاصة بالمباراة
socket.emit('match:join', { matchId: 'uuid' })

// بدأت المباراة
socket.on('match:started', { matchId: 'uuid' })

// سؤال جديد
socket.on('match:question', { ... })

// المستخدم يُرسل إجابة
socket.emit('match:answer', { matchId, questionId, answer })

// تأكيد الإجابة
socket.on('match:answer-submitted', { ... })

// استخدام عنصر (درع، تلميح، إلخ)
socket.emit('match:use-item', { matchId, itemId })
socket.on('match:item-used', { ... })
socket.on('match:item-effect', { ... })

// هجوم
socket.on('match:attack', { ... })

// لاعب أُخرج
socket.on('match:eliminated', { ... })

// انتهت المباراة
socket.on('match:ended', {
  matchId,
  winner: { id, username, ... },
  scores: [...],
  rewards: { gold, xp }
})
```

---

## 🔗 REST Endpoints

### الانضمام من الـ Clan Chat
هذا موجود بالفعل:
```
POST /api/v1/clans/:clanId/chat/game-code
Body: { "roomCode": "ABC123" }
```

الـ response يُرجع `ClanMessage` مع `type: "game_code"` و `roomCode`. iOS يعرضها كبطاقة قابلة للضغط في الشات.

**iOS flow:** عندما يضغط المستخدم على بطاقة `game_code` في شات العشيرة → سيتم استدعاء `socket.emit('room:join', { code })` تلقائياً.

---

## 🔔 Push Notifications

### `room_invite` — دعوة لغرفة خاصة

عندما يستقبل السيرفر `room:invite`، يرسل FCM push للصديق:

```json
{
  "notification": {
    "title": "محمد يدعوك للعب!",
    "body": "انضم لمباراة 1v1 الآن"
  },
  "data": {
    "type": "room_invite",
    "roomCode": "ABC123",
    "mode": "1v1",
    "fromUserId": "uuid",
    "fromUsername": "محمد"
  }
}
```

**iOS behavior:** عند اللمس → يفتح شاشة join room بالكود مُعبّأ مسبقاً.

---

## 📋 Data Contracts — ما يحتاجه iOS

### Player Object (في `room:player-joined`, `room:created.host`)
**مطلوب:**
- `id: string`
- `username: string`
- `avatarUrl: string` (مسار نسبي مقبول — iOS يحوّله)

**اختياري (لكن موصى به):**
- `level: number`
- `isOnline: boolean`

### Room Object (في `room:created`)
```json
{
  "code": "ABC123",
  "mode": "1v1",
  "host": { Player },
  "players": [ Player ],
  "createdAt": "2026-04-15T..."
}
```

### Match Found Event
```json
{
  "matchId": "uuid",
  "mode": "1v1",
  "players": [
    { "id": "uuid", "username": "...", "avatarUrl": "...", "level": 5 }
  ]
}
```

---

## ⚙️ Backend Logic Highlights

### Queue Matchmaking
```js
// في socket handler
const queues = { '1v1': [], '4player': [] }

socket.on('queue:join', ({ mode }) => {
  queues[mode].push(socket)
  socket.emit('queue:joined')

  const required = mode === '1v1' ? 2 : 4
  if (queues[mode].length >= required) {
    const players = queues[mode].splice(0, required)
    const match = createMatch(mode, players.map(s => s.userId))
    players.forEach(p => p.emit('match:found', { matchId: match.id }))
  }
})
```

### Room Creation
```js
socket.on('room:create', ({ mode }) => {
  const code = generateCode(6)  // ABC123
  const room = { 
    code, mode, 
    hostId: socket.userId, 
    players: [socket.userId],
    createdAt: new Date()
  }
  await rooms.save(code, room)
  socket.join(`room:${code}`)
  socket.emit('room:created', { 
    code, 
    mode, 
    host: await User.findByPk(socket.userId, {
      attributes: ['id', 'username', 'avatarUrl']
    })
  })
})
```

### Invite Friend (مع Push)
```js
socket.on('room:invite', async ({ code, friendId }) => {
  const friend = await User.findByPk(friendId)
  const fromUser = await User.findByPk(socket.userId)
  
  // إذا الصديق متصل بالسوكت الآن
  const friendSocket = getSocketByUserId(friendId)
  if (friendSocket) {
    friendSocket.emit('room:invited', {
      code, mode: room.mode,
      fromUser: { id: fromUser.id, username: fromUser.username, avatarUrl: fromUser.avatarUrl }
    })
  }

  // ابعث push notification دائماً (لو التطبيق مقفل)
  await sendPush(friendId, {
    title: `${fromUser.username} يدعوك للعب!`,
    body: `انضم لمباراة ${room.mode} الآن`,
    type: 'room_invite',
    data: { roomCode: code, mode: room.mode, fromUsername: fromUser.username }
  })
})
```

---

## 🎯 Summary — ما ينقص الآن

بناءً على الكود الحالي في iOS، الـ backend يحتاج:

| # | الميزة | الحالة |
|---|--------|--------|
| 1 | `queue:join` / `match:found` | ✅ موجود (افتراض) |
| 2 | `room:create` / `room:created` | ✅ موجود (افتراض) |
| 3 | `room:player-joined` **مع Player object** | ⚠️ قد يحتاج تحديث |
| 4 | `room:invite` → push notification | 🔴 يحتاج إضافة push |
| 5 | `room:invited` (socket) | ⚠️ تحقق |
| 6 | `room_invite` notification type | 🔴 جديد |
| 7 | `POST /clans/:id/chat/game-code` | ✅ موجود |

**الأولوية:**
1. التأكد من `room:player-joined` يرجع player object كامل (لعرض الأفاتار في iOS)
2. إضافة push notification عند `room:invite` مع `type: "room_invite"`

---

## 🧪 اختبار

**أبسط سيناريو للاختبار:**
1. User A يفتح `private1v1` → ينشأ كود ABC123
2. User A يضغط "مشاركة لعشيرتي" → الكود يصل للشات
3. User B (في نفس العشيرة) يرى البطاقة ويضغطها → socket emits `room:join { code }`
4. السيرفر يضيف User B للغرفة → يبث `room:player-joined` لـ User A
5. بعد إضافة كل اللاعبين، يبث `match:started`

**iOS جاهز لهذا السيناريو كاملاً** — فقط الـ backend يحتاج يطبّق الـ events.
