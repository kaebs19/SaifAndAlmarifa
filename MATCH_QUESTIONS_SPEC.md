# Match Flow — Backend Specification

الأحداث المطلوبة على السيرفر من لحظة `match:found` حتى `match:ended`.

---

## 🎬 تدفّق المباراة الكامل

```
1. match:found          → كل اللاعبين يعرفوا matchId + players
2. (كلهم يرسلوا match:join)
3. match:started        → كل اللاعبين في نفس الوقت
4. match:question       → السؤال الأول
5. (كل لاعب يرسل match:answer)
6. match:answer-submitted → يُبث لكل اللاعبين
7. match:attack         → إن حصل ضرر
8. match:eliminated     → إن خرج لاعب
9. كرر 4-8 لكل سؤال
10. match:ended         → النتيجة النهائية + المكافآت
```

---

## 📨 Socket Events

### 1. `match:started` (Server → Client)
```json
{
  "matchId": "uuid",
  "startedAt": "2026-04-20T..."
}
```
يُرسل بعد ~1-2 ثانية من match:found للتجهيز.

### 2. `match:question` (Server → Client) ⭐ **الأهم**
```json
{
  "matchId": "uuid",
  "questionId": "uuid",
  "text": "ما هي عاصمة فرنسا؟",
  "options": ["لندن", "باريس", "برلين", "مدريد"],
  "index": 1,
  "total": 10,
  "timeLimit": 15
}
```

**متى يُرسل:**
- أول سؤال: بعد match:started مباشرة (~1 ثانية)
- الأسئلة التالية: بعد معالجة إجابة الجميع + 2 ثانية عرض نتائج

### 3. `match:answer` (Client → Server)
```json
{
  "matchId": "uuid",
  "questionId": "uuid",
  "answer": "1"   // index of selected answer
}
```

### 4. `match:answer-submitted` (Server → Client broadcast)
```json
{
  "matchId": "uuid",
  "questionId": "uuid",
  "userId": "uuid",
  "selectedIndex": 1,
  "correct": true,
  "correctIndex": 1,
  "newScore": 10,
  "newHP": 100,
  "attackTargetId": "opponent_uuid",  // للـ 4p
  "scores": { "user1": 10, "user2": 0 },
  "hp":     { "user1": 100, "user2": 90 }
}
```

### 5. `match:attack` (Server → Client broadcast)
```json
{
  "matchId": "uuid",
  "attackerId": "uuid",
  "targetId": "uuid",
  "damage": 10
}
```

### 6. `match:eliminated` (Server → Client broadcast)
```json
{
  "matchId": "uuid",
  "userId": "uuid"   // اللاعب اللي خرج
}
```

### 7. `match:ended` (Server → Client broadcast)
```json
{
  "matchId": "uuid",
  "winnerId": "uuid",
  "scores": { "user1": 120, "user2": 80 },
  "rewards": {
    "gold": 50,
    "xp": 120
  },
  "opponentName": "أحمد"
}
```

---

## ⚙️ Backend Logic (Node.js reference)

### Match State Machine
```js
const matches = new Map()  // matchId → MatchState

class MatchState {
  constructor({ matchId, playerIds, mode }) {
    this.matchId = matchId
    this.playerIds = playerIds
    this.mode = mode
    this.status = 'waiting'   // waiting | in_progress | finished
    this.currentQuestionIndex = 0
    this.totalQuestions = 10
    this.questions = []       // سيُحمّل من DB
    this.players = {}         // userId → { score, hp, answered: false }
    this.questionTimer = null
  }

  async start() {
    this.status = 'in_progress'
    this.questions = await Question.findRandom(this.totalQuestions, this.category)

    // تأخير 1s قبل أول سؤال
    setTimeout(() => this.sendNextQuestion(), 1000)
  }

  sendNextQuestion() {
    if (this.currentQuestionIndex >= this.totalQuestions) {
      return this.endMatch()
    }

    const q = this.questions[this.currentQuestionIndex]
    const payload = {
      matchId: this.matchId,
      questionId: q.id,
      text: q.text,
      options: q.options,
      index: this.currentQuestionIndex + 1,
      total: this.totalQuestions,
      timeLimit: 15
    }

    // Reset answered state
    for (const uid of this.playerIds) {
      this.players[uid].answered = false
    }

    io.to(`match:${this.matchId}`).emit('match:question', payload)

    // Auto-next if time up
    this.questionTimer = setTimeout(() => {
      this.handleTimeUp()
    }, 15 * 1000)
  }

  handleAnswer(userId, questionId, answerIndex) {
    const q = this.questions[this.currentQuestionIndex]
    if (q.id !== questionId) return
    if (this.players[userId].answered) return

    this.players[userId].answered = true
    const correct = parseInt(answerIndex) === q.correctIndex

    // Score (speed bonus + correctness)
    if (correct) {
      this.players[userId].score += 10
      // Attack opponent
      this.attackRandomOpponent(userId)
    } else {
      // خصم HP من نفسك
      this.players[userId].hp = Math.max(0, this.players[userId].hp - 5)
    }

    // Broadcast
    io.to(`match:${this.matchId}`).emit('match:answer-submitted', {
      matchId: this.matchId,
      questionId: q.id,
      userId,
      selectedIndex: parseInt(answerIndex),
      correct,
      correctIndex: q.correctIndex,
      newScore: this.players[userId].score,
      newHP: this.players[userId].hp,
      scores: Object.fromEntries(
        Object.entries(this.players).map(([id, p]) => [id, p.score])
      ),
      hp: Object.fromEntries(
        Object.entries(this.players).map(([id, p]) => [id, p.hp])
      )
    })

    // Check if all answered
    if (Object.values(this.players).every(p => p.answered)) {
      clearTimeout(this.questionTimer)
      setTimeout(() => {
        this.currentQuestionIndex++
        this.sendNextQuestion()
      }, 2000)  // 2s to show results
    }
  }

  attackRandomOpponent(attackerId) {
    const opponents = this.playerIds.filter(
      id => id !== attackerId && this.players[id].hp > 0
    )
    if (opponents.length === 0) return

    const targetId = opponents[Math.floor(Math.random() * opponents.length)]
    const damage = 10
    this.players[targetId].hp = Math.max(0, this.players[targetId].hp - damage)

    io.to(`match:${this.matchId}`).emit('match:attack', {
      matchId: this.matchId, attackerId, targetId, damage
    })

    if (this.players[targetId].hp === 0) {
      io.to(`match:${this.matchId}`).emit('match:eliminated', {
        matchId: this.matchId, userId: targetId
      })
    }
  }

  handleTimeUp() {
    // إجابات من لم يُجب = wrong
    for (const uid of this.playerIds) {
      if (!this.players[uid].answered) {
        this.handleAnswer(uid, this.questions[this.currentQuestionIndex].id, -1)
      }
    }
  }

  async endMatch() {
    this.status = 'finished'
    clearTimeout(this.questionTimer)

    // Determine winner
    const winnerId = Object.entries(this.players)
      .sort((a, b) => b[1].score - a[1].score)[0][0]

    // Rewards
    const rewards = { gold: 50, xp: 120 }

    // Grant
    for (const uid of this.playerIds) {
      const isWinner = uid === winnerId
      await User.increment(
        isWinner ? { gold: 50, xp: 120 } : { gold: 10, xp: 40 },
        { where: { id: uid } }
      )
    }

    // Save to history
    await Match.create({
      id: this.matchId, mode: this.mode,
      winnerId, scores: ...
    })

    io.to(`match:${this.matchId}`).emit('match:ended', {
      matchId: this.matchId,
      winnerId,
      scores: Object.fromEntries(
        Object.entries(this.players).map(([id, p]) => [id, p.score])
      ),
      rewards
    })

    matches.delete(this.matchId)
  }
}
```

---

## 🗄️ Questions Database

### Schema
```sql
CREATE TABLE Questions (
  id UUID PRIMARY KEY,
  text TEXT NOT NULL,
  options JSONB NOT NULL,        -- ["option1", "option2", ...]
  correctIndex INTEGER NOT NULL,  -- 0..3
  category VARCHAR(50),           -- "general", "history", "science", ...
  difficulty VARCHAR(20),         -- "easy", "medium", "hard"
  language VARCHAR(10) DEFAULT 'ar',
  createdAt TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_questions_category_diff ON Questions(category, difficulty);
```

### مثال بيانات
```json
[
  {
    "text": "ما هي عاصمة فرنسا؟",
    "options": ["لندن", "باريس", "برلين", "مدريد"],
    "correctIndex": 1,
    "category": "geography",
    "difficulty": "easy"
  },
  {
    "text": "من هو مؤلف رواية مدن الملح؟",
    "options": ["نجيب محفوظ", "عبدالرحمن منيف", "غازي القصيبي", "الطيب صالح"],
    "correctIndex": 1,
    "category": "literature",
    "difficulty": "medium"
  }
]
```

**توصية للبداية:** 200+ سؤال موزّعة على 5-10 تصنيفات.

---

## 🧪 اختبار سريع

افتح Terminal على الـ server وابعت sample question يدوياً:

```js
// في socket handler أو REPL
io.to(`match:${matchId}`).emit('match:question', {
  matchId: matchId,
  questionId: 'test-q-1',
  text: 'ما هي عاصمة فرنسا؟',
  options: ['لندن', 'باريس', 'برلين', 'مدريد'],
  index: 1,
  total: 10,
  timeLimit: 15
})
```

iOS **مستعد يتلقاها فوراً** ويعرضها.

---

## ⏱️ التوقيتات الموصى بها

| المرحلة | الزمن |
|---------|------|
| match:found → match:started | 1-2 ثانية |
| match:started → أول match:question | 1 ثانية |
| مدة السؤال (timeLimit) | 15 ثانية |
| بين الأسئلة (عرض النتيجة) | 2 ثواني |
| match:ended → close | 3 ثوانٍ (لشاشة النتائج) |
