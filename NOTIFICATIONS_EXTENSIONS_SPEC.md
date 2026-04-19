# Notification Extensions — Backend Spec

توسعة لـ FCM + Socket لدعم الميزات الجديدة.

---

## 🌐 Online Players Count

### Socket Event
السيرفر يبث دورياً (كل 30 ثانية) لكل الـ clients المتصلين:

```
event: stats:online
payload: { "count": 1247 }
```

### Backend Logic (Node.js)
```js
// يعمل كل 30 ثانية على عدد الـ socket connections
setInterval(() => {
  const count = io.engine.clientsCount
  io.emit('stats:online', { count })
}, 30_000)
```

أو إذا تبغى عدد مميّز (distinct users):
```js
const uniqueUsers = new Set()
io.of('/').sockets.forEach(socket => {
  if (socket.userId) uniqueUsers.add(socket.userId)
})
io.emit('stats:online', { count: uniqueUsers.size })
```

---

## 🔔 Notification Types — إضافات

### Personal Achievements

#### `level_up` — صعد مستوى اللاعب
```json
{
  "notification": {
    "title": "🎉 وصلت للمستوى 10!",
    "body": "فتحت ميزات جديدة في اللعبة"
  },
  "data": {
    "type": "level_up",
    "newLevel": "10"
  }
}
```

**iOS:** يفتح PlayerCard popup

#### `achievement_unlocked` — إنجاز جديد
```json
{
  "notification": {
    "title": "🏆 إنجاز جديد!",
    "body": "100 فوز متتالي"
  },
  "data": {
    "type": "achievement_unlocked",
    "achievementId": "streak_100"
  }
}
```

### Clan Personal Notifications

#### `clan_mvp_of_week` — أنت نجم الأسبوع
```json
{
  "notification": {
    "title": "👑 أنت نجم الأسبوع!",
    "body": "حصلت على أعلى نقاط في عشيرتك"
  },
  "data": {
    "type": "clan_mvp_of_week",
    "clanId": "uuid",
    "points": "1250"
  }
}
```

**iOS:** يفتح Clan Detail (تاب الإحصائيات)

#### `clan_level_up` — العشيرة ترقّت
ينرسل لكل الأعضاء:
```json
{
  "notification": {
    "title": "🚀 عشيرتك وصلت Lv.3!",
    "body": "فتحتم ميزات جديدة — تعال شوف"
  },
  "data": {
    "type": "clan_level_up",
    "clanId": "uuid",
    "newLevel": "3"
  }
}
```

---

## 📅 Trigger Logic

### MVP of the week (cron weekly)
```js
// السبت 00:00
cron.schedule('0 0 * * 6', async () => {
  const clans = await Clan.findAll()
  for (const clan of clans) {
    const top = await ClanMember.findOne({
      where: { clanId: clan.id },
      order: [['weeklyPoints', 'DESC']],
      limit: 1
    })
    if (top && top.weeklyPoints > 0) {
      await sendPush(top.userId, {
        title: '👑 أنت نجم الأسبوع!',
        body: 'حصلت على أعلى نقاط في عشيرتك',
        type: 'clan_mvp_of_week',
        data: { clanId: clan.id, points: String(top.weeklyPoints) }
      })
    }
  }
})
```

### Level up (عند أي زيادة نقاط)
```js
// في الـ user service بعد زيادة points
if (newLevel > oldLevel) {
  await sendPush(userId, {
    title: `🎉 وصلت للمستوى ${newLevel}!`,
    body: 'فتحت ميزات جديدة',
    type: 'level_up',
    data: { newLevel: String(newLevel) }
  })
}
```

### Clan level up (عند وصول weeklyPoints للعتبة)
```js
// في الـ clan points service
const thresholds = { 2: 5000, 3: 15000 }
if (clan.weeklyPoints >= thresholds[clan.level + 1]) {
  clan.level += 1
  await clan.save()
  
  // بلّغ كل الأعضاء
  const members = await ClanMember.findAll({ where: { clanId: clan.id } })
  for (const m of members) {
    await sendPush(m.userId, {
      title: `🚀 عشيرتك وصلت Lv.${clan.level}!`,
      body: 'فتحتم ميزات جديدة — تعال شوف',
      type: 'clan_level_up',
      data: { clanId: clan.id, newLevel: String(clan.level) }
    })
  }

  // سجّل في الـ events
  await ClanEvent.create({
    clanId: clan.id,
    type: 'level_up',
    metadata: { level: String(clan.level) }
  })
}
```

---

## ⚠️ iOS — جاهز تلقائياً

كل هذي الأنواع مُضافة في `PushNotificationsManager.NotificationType` enum.
لما يرسل السيرفر `type` مطابق، iOS:
- يفتح الشاشة الصحيحة عند اللمس
- يعرض toast عند الاستلام
- ينظّف badge

---

## 📊 Summary للمطور

| النوع | المُرسل إلى | السيناريو |
|-------|------------|-----------|
| `stats:online` (socket) | الكل | كل 30ث |
| `level_up` (push) | اللاعب نفسه | عند صعود مستوى |
| `achievement_unlocked` (push) | اللاعب نفسه | عند فتح إنجاز |
| `clan_mvp_of_week` (push) | نجم العشيرة | أسبوعي |
| `clan_level_up` (push) | كل أعضاء العشيرة | عند ترقية العشيرة |
