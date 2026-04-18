# Advanced Clan Features — Backend Specification

يحتوي على: Push Notifications • Treasury • History Feed • Perks • Clan Wars

---

## 🔔 1) Push Notifications (APNs)

### Xcode Setup (iOS)
1. Signing & Capabilities → + Capability → **Push Notifications**
2. Signing & Capabilities → + Capability → **Background Modes** → Remote notifications ✓
3. في Apple Developer: إنشاء APNs Key (.p8) → حمّله لمنصة الـ backend

### Endpoints

```
POST /api/v1/devices/register
Body: { "deviceToken": "hex-token", "platform": "ios" }
```

```
POST /api/v1/devices/unregister
```

### DB Schema
```sql
CREATE TABLE Devices (
  id UUID PRIMARY KEY,
  userId UUID REFERENCES Users(id) ON DELETE CASCADE,
  deviceToken TEXT NOT NULL,
  platform VARCHAR(10) NOT NULL,
  updatedAt TIMESTAMP DEFAULT NOW(),
  UNIQUE (deviceToken)
);
```

### Notification Triggers + Payload

كل إشعار له `type` والـ iOS يستخدمه للـ deep linking.

| Trigger | type | Additional Fields |
|---------|------|-------------------|
| رسالة جديدة (if user disabled from clan) | `clan_message` | `clanId`, `messageId` |
| @mention | `clan_mention` | `clanId`, `messageId` |
| ترقية/تنزيل | `clan_role_change` | `clanId`, `newRole` |
| قبول طلب انضمام | `clan_request_accepted` | `clanId` |
| طرد | `clan_kicked` | `clanId` |
| كتم | `clan_muted` | `clanId`, `mutedUntil` |
| حرب جديدة | `clan_war_started` | `clanId`, `warId` |
| نهاية حرب | `clan_war_ended` | `clanId`, `warId`, `won` |

### مثال Payload APNs
```json
{
  "aps": {
    "alert": {
      "title": "@جود ذكرك",
      "body": "محمد: @جود تعال نلعب"
    },
    "badge": 1,
    "sound": "default"
  },
  "type": "clan_mention",
  "clanId": "uuid",
  "messageId": "uuid"
}
```

### Node.js Integration (apn package)
```js
import apn from 'apn'

const apnProvider = new apn.Provider({
  token: {
    key: './AuthKey_XXXXXXXXXX.p8',
    keyId: process.env.APNS_KEY_ID,
    teamId: process.env.APPLE_TEAM_ID
  },
  production: process.env.NODE_ENV === 'production'
})

async function sendPush(userId, { title, body, type, data = {} }) {
  const devices = await Device.findAll({ where: { userId } })
  const notification = new apn.Notification({
    alert: { title, body },
    badge: 1,
    sound: 'default',
    topic: 'com.saifiq.SaifAndAlmarifa',
    payload: { type, ...data }
  })
  for (const d of devices) {
    const result = await apnProvider.send(notification, d.deviceToken)
    if (result.failed.length > 0) {
      // حذف token فاشل
      await Device.destroy({ where: { deviceToken: d.deviceToken } })
    }
  }
}
```

---

## 💰 2) Treasury (خزينة العشيرة)

### Schema
```sql
ALTER TABLE Clans ADD COLUMN treasury INTEGER DEFAULT 0;

CREATE TABLE TreasuryTransactions (
  id UUID PRIMARY KEY,
  clanId UUID REFERENCES Clans(id) ON DELETE CASCADE,
  userId UUID REFERENCES Users(id),
  type VARCHAR(20) NOT NULL,  -- 'donation' | 'withdraw' | 'war_reward'
  amount INTEGER NOT NULL,
  note TEXT,
  createdAt TIMESTAMP DEFAULT NOW()
);
```

### Endpoints

```
POST /api/v1/clans/:clanId/treasury/donate
Body: { "amount": 100 }
```

**Logic:**
1. تحقق من عضوية المستخدم
2. `user.gold >= amount`
3. `user.gold -= amount`
4. `clan.treasury += amount`
5. سجّل TreasuryTransaction
6. أضف ClanEvent `treasury_donation`

**Response:**
```json
{
  "success": true,
  "data": {
    "amount": 100,
    "newTreasury": 1250,
    "newUserGold": 400
  }
}
```

```
GET /api/v1/clans/:clanId/treasury/history
```

**Response:**
```json
{
  "success": true,
  "data": [
    {
      "id": "uuid",
      "type": "donation",
      "amount": 100,
      "user": { "id": "uuid", "username": "جود", "avatarUrl": "..." },
      "note": null,
      "createdAt": "..."
    }
  ]
}
```

### Future: Withdraw / Upgrade
لاحقاً ممكن تضيف endpoints للزعيم ليصرف من الخزينة لترقية العشيرة.

---

## 📜 3) History / Events Feed

### Schema
```sql
CREATE TABLE ClanEvents (
  id UUID PRIMARY KEY,
  clanId UUID REFERENCES Clans(id) ON DELETE CASCADE,
  type VARCHAR(40) NOT NULL,
  actorId UUID REFERENCES Users(id),
  targetId UUID REFERENCES Users(id),
  metadata JSONB DEFAULT '{}',
  createdAt TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_events_clan_time ON ClanEvents(clanId, createdAt DESC);
```

### Event Types (يطابقون `ClanEvent.EventType` في iOS)
```
member_joined, member_left, member_kicked,
member_promoted, member_demoted,
member_muted, member_unmuted,
clan_created, clan_updated, owner_transferred,
level_up, war_won, war_lost, treasury_donation
```

### Endpoint

```
GET /api/v1/clans/:clanId/events?limit=50
```

**Response:**
```json
{
  "success": true,
  "data": [
    {
      "id": "uuid",
      "type": "member_joined",
      "actor": { "id": "u1", "username": "محمد", "avatarUrl": "..." },
      "target": null,
      "metadata": {},
      "createdAt": "..."
    },
    {
      "id": "uuid",
      "type": "level_up",
      "actor": null,
      "target": null,
      "metadata": { "level": "3" },
      "createdAt": "..."
    }
  ]
}
```

### Helper function
في كل endpoint يغيّر العشيرة، أضف:
```js
await ClanEvent.create({
  id: uuid(),
  clanId,
  type: 'member_kicked',
  actorId: req.user.id,
  targetId: kickedUser.id,
  metadata: {}
})
```

---

## 🏅 4) Clan Perks

### Logic (لا يحتاج جداول جديدة)
الامتيازات **مشتقة من clan.level**. iOS يعرضها. السيرفر يطبّق التأثير:

| Level | Perk | Backend Effect |
|-------|------|----------------|
| 1 | 30 members | `maxMembers = 30` (افتراضي) |
| 2 | Daily gold | كل يوم في cron: كل عضو `+10` ذهب |
| 2 | 10% store discount | عند `POST /store/items/:type/buy` — احسب `goldCost * 0.9` لو عضو عشيرة Lv.2+ |
| 3 | 50 members | `maxMembers = 50` |
| 3 | Exclusive badge | لون ذهبي خاص في الـ badge |

### Cron Job (الذهب اليومي)
```js
// يومياً الساعة 00:00
cron.schedule('0 0 * * *', async () => {
  const clans = await Clan.findAll({ where: { level: { [Op.gte]: 2 } } })
  for (const clan of clans) {
    const members = await ClanMember.findAll({ where: { clanId: clan.id } })
    for (const m of members) {
      await User.increment('gold', { by: 10, where: { id: m.userId } })
    }
  }
})
```

### Store Discount
```js
// في POST /store/items/:type/buy
const myClan = await ClanMember.findOne({ 
  where: { userId: req.user.id },
  include: [Clan]
})
let cost = item.goldCost
if (myClan?.Clan.level >= 2) {
  cost = Math.floor(cost * 0.9)
}
```

---

## ⚔️ 5) Clan Wars

### Schema
```sql
CREATE TABLE ClanWars (
  id UUID PRIMARY KEY,
  clanAId UUID REFERENCES Clans(id),
  clanBId UUID REFERENCES Clans(id),
  clanAScore INTEGER DEFAULT 0,
  clanBScore INTEGER DEFAULT 0,
  status VARCHAR(20) NOT NULL,  -- 'scheduled' | 'active' | 'ended'
  winnerClanId UUID REFERENCES Clans(id),
  startAt TIMESTAMP,
  endAt TIMESTAMP,
  createdAt TIMESTAMP DEFAULT NOW()
);
```

### Endpoint

```
GET /api/v1/clans/:clanId/wars/current
```

**Response:**
```json
{
  "success": true,
  "data": {
    "id": "uuid",
    "status": "active",
    "startAt": "...",
    "endAt": "...",
    "myClan": {
      "clanId": "uuid",
      "name": "الصقور",
      "badge": "eagle",
      "color": "FFD700",
      "score": 1250
    },
    "enemyClan": {
      "clanId": "uuid",
      "name": "النمور",
      "badge": "lion",
      "color": "EF4444",
      "score": 980
    },
    "winnerClanId": null
  }
}
```

إذا ما في حرب حالياً، أرجع `404` — iOS يعرض "لا توجد حرب".

### Matchmaking (weekly cron)
كل أسبوع (مثلاً الخميس 6PM):
1. اختر العشائر المتقاربة في الـ `weeklyPoints`
2. أنشئ `ClanWar` جديدة بينهم (status = scheduled)
3. بعد ساعة → status = active
4. بعد 48 ساعة → احسب winner، status = ended

### Scoring
كل فوز في مباراة لعضو في الحرب → `clan.weeklyPoints += 10` و `war.clanXScore += 10`.

### Rewards
عند انتهاء الحرب:
- العشيرة الفائزة: `+500` ذهب للخزينة
- إشعار push لكل الأعضاء

---

## 🚀 Priority for Implementation

1. **Push Notifications foundation** — الأول لأنه يخدم كل الميزات الثانية
2. **Treasury + History Feed** — سريعة، تستخدم ما عندك
3. **Clan Perks (cron + discount)** — تطبيق قواعد بسيطة
4. **Clan Wars** — الأكبر، يحتاج matchmaking state machine

---

## iOS Side — جاهز الآن

- ✅ كل الـ endpoints معرّفة
- ✅ الـ UI للتابات الجديدة (حرب، خزينة، امتيازات، سجل) موجودة
- ✅ تبرّع للخزينة يشتغل كسلة (form)
- ✅ Push Notifications Manager scaffold كامل
- ✅ Models كاملة (ClanEvent, TreasuryTransaction, ClanWar, MessageReaction)

لما الـ backend يضيف الـ endpoints، كل شي يشتغل تلقائياً.
