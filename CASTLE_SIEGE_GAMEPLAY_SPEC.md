# Castle Siege Gameplay — Backend Specification

طريقة لعب جديدة تستبدل النظام السابق (multiple choice).

---

## 🎮 الفكرة العامة

### مرحلتان لكل مباراة 1v1:

**المرحلة 1 — تجميع القوة (Collection)**
- 4 أسئلة من نوع **إدخال نصي/رقمي**
- المثال: "متى كانت الحرب العالمية الأولى؟" → اللاعب يكتب الإجابة
- الفائز: **الأقرب للإجابة الصحيحة + الأسرع**
- كل لاعب يحصل على "قوة" تتراكم

**المرحلة 2 — المواجهة (Battle)**
- N سؤال (مثلاً 10)
- نفس النوع — إدخال
- كل إجابة صحيحة = ضربة على قلعة الخصم (-1 HP)
- HP لكل لاعب = القوة المتجمّعة في المرحلة 1
- **الفائز: من يهدم قلعة الخصم أولاً**
- إذا انتهت الأسئلة: أعلى HP متبقي يفوز

---

## 📊 أمثلة Scoring

### المرحلة 1 — كل لاعب يبدأ بـ HP = 2 (default)

**سؤال:** "متى كانت الحرب العالمية الأولى؟" (الصحيح: 1914)

| اللاعب | الإجابة | الزمن | الفرق | النتيجة |
|--------|--------|------|------|---------|
| A | 1914 | 3 ث | 0 | ✅ صحيح + أسرع → +2 قوة |
| B | 1913 | 5 ث | 1 | 🎯 الأقرب (مش صحيح) → +0 أو +1 |

**سيناريو ثاني:**
| اللاعب | الإجابة | الزمن | النتيجة |
|--------|--------|------|---------|
| A | 1911 | 3 ث | بعيد → 0 |
| B | 1913 | 5 ث | أقرب → +1 |

**القاعدة المقترحة:**
- إجابة صحيحة + أسرع → **+2 قوة**
- إجابة صحيحة (لكن مش أسرع) → **+1 قوة**
- الأقرب من بين الإجابات الخاطئة → **+1 قوة**
- إجابة خاطئة وبعيدة → **0**

بعد 4 أسئلة، كل لاعب عنده مجموع قوة (مثلاً A=6، B=4).

### المرحلة 2 — battle

- HP الابتدائي = القوة من المرحلة 1
- مثال: A.hp = 6, B.hp = 4
- B يحتاج 6 إجابات صحيحة لهدم قلعة A
- A يحتاج 4 إجابات صحيحة لهدم قلعة B
- A عنده ميزة كبيرة!

---

## 📡 Socket Events

### `match:question` (Server → Client) — مع نوع الإدخال

```json
{
  "matchId": "uuid",
  "questionId": "uuid",
  "phase": "collection",        // أو "battle"
  "answerType": "numericInput", // أو "textInput"
  "text": "متى كانت الحرب العالمية الأولى؟",
  "index": 1,
  "total": 4,                    // 4 للـ collection، 10 للـ battle
  "timeLimit": 15
}
```

**ملاحظة:** `options` غير موجودة (لأنه input).

### `match:answer` (Client → Server)

```json
{
  "matchId": "uuid",
  "answer": "1913",   // النص المكتوب
  "timeMs": 5000
}
```

### `match:answer-submitted` (Server → Client broadcast)

```json
{
  "matchId": "uuid",
  "questionId": "uuid",
  "userId": "u1",
  "value": "1913",                  // ما أدخل
  "correct": false,                 // لو exact match (عادة المرحلة 2)
  "closest": true,                  // الأقرب (المرحلة 1)
  "fastest": false,                 // الأسرع
  "pointsAwarded": 1,               // قوة محصّلة (المرحلة 1) أو ضرر (المرحلة 2)
  "correctAnswer": "1914",          // النص الصحيح (للكشف)
  "newScore": 1,
  "newHP": 100,                     // HP الجديد
  "scores": { "u1": 1, "u2": 0 },
  "hp":     { "u1": 100, "u2": 90 }
}
```

### `match:phase` ⭐ (Server → Client) — تغيّر المرحلة

```json
{
  "matchId": "uuid",
  "phase": "battle"   // "collection" | "battle" | "ended"
}
```

### `match:phase-result` ⭐ (Server → Client) — نتيجة المرحلة 1

```json
{
  "matchId": "uuid",
  "phase": "collection",
  "powers": { "u1": 6, "u2": 4 },   // userId → قوة (= HP المرحلة 2)
  "nextPhase": "battle"
}
```

iOS يستقبل هذا → يعرض شاشة Phase Transition (3-4 ثواني) → استعد للمرحلة 2.

---

## 🔄 Match Flow الكامل

```
1. match:found
2. match:join (×2)
3. match:started

═══ المرحلة 1: COLLECTION ═══
4. match:phase { phase: "collection" }
5. match:question [1] { phase: "collection", answerType: "numericInput" }
6. (كل اللاعبين يرسلوا match:answer أو 15 ثانية)
7. match:answer-submitted (للكل)
   - تحدّد closest + fastest + pointsAwarded
8. (انتظر 2 ثانية لعرض النتيجة)
9. match:question [2]
10. ... (4 أسئلة كاملة)

═══ TRANSITION ═══
11. match:phase-result { powers: {u1:6, u2:4} }
    → iOS يعرض PhaseTransitionView لـ ~3 ثوان
12. match:phase { phase: "battle" }

═══ المرحلة 2: BATTLE ═══
13. ابدأ HP لكل لاعب من powers
14. match:question [1] { phase: "battle", answerType: "numericInput" }
15. match:answer من اللاعبين
16. match:answer-submitted
    - exact match = correct
    - أول من يجيب صح يضرب قلعة الخصم (-1 HP)
17. match:attack { attackerId, targetId, damage:1, targetHp: X }
18. إذا targetHp = 0 → match:eliminated → match:ended (فوز فوري)
19. وإلا، match:question [2] ...
20. بعد 10 أسئلة (أو هدم قلعة):
    match:ended { winnerId, scores, hp, rewards }
```

---

## ⚙️ Backend Logic (Node.js reference)

```js
class CastleSiegeMatch {
  constructor({ matchId, playerIds }) {
    this.matchId = matchId
    this.playerIds = playerIds
    this.phase = 'collection'
    this.players = {}
    for (const id of playerIds) {
      this.players[id] = {
        score: 0,         // نقاط (للترتيب)
        power: 2,         // قوة المرحلة 1 (تتراكم)
        hp: 0,            // HP المرحلة 2 (يساوي power عند البدء)
        answered: false,
        currentAnswer: null,
        currentTimeMs: null
      }
    }
    this.collectionQuestions = []  // 4
    this.battleQuestions = []      // 10
    this.currentIdx = 0
  }

  async start() {
    this.collectionQuestions = await Question.findRandom(4, { type: 'input' })
    this.battleQuestions = await Question.findRandom(10, { type: 'input' })

    io.emit('match:started', { matchId: this.matchId })
    setTimeout(() => this.startCollectionPhase(), 1000)
  }

  startCollectionPhase() {
    this.phase = 'collection'
    io.emit('match:phase', { matchId: this.matchId, phase: 'collection' })
    setTimeout(() => this.sendNextQuestion(), 500)
  }

  sendNextQuestion() {
    const list = this.phase === 'collection' ? this.collectionQuestions : this.battleQuestions
    if (this.currentIdx >= list.length) {
      return this.transitionOrEnd()
    }

    const q = list[this.currentIdx]
    for (const id of this.playerIds) {
      this.players[id].answered = false
      this.players[id].currentAnswer = null
      this.players[id].currentTimeMs = null
    }

    io.emit('match:question', {
      matchId: this.matchId,
      questionId: q.id,
      phase: this.phase,
      answerType: q.answerType,  // "numericInput" | "textInput"
      text: q.text,
      index: this.currentIdx + 1,
      total: list.length,
      timeLimit: 15
    })

    this.questionTimer = setTimeout(() => this.handleQuestionEnd(), 15_000)
  }

  handleAnswer(userId, value, timeMs) {
    if (this.players[userId].answered) return
    this.players[userId].answered = true
    this.players[userId].currentAnswer = value
    this.players[userId].currentTimeMs = timeMs

    // إذا كل اللاعبين أجابوا، أنهِ السؤال مبكراً + 2 ثانية
    if (this.playerIds.every(id => this.players[id].answered)) {
      clearTimeout(this.questionTimer)
      setTimeout(() => this.handleQuestionEnd(), 1000)
    }
  }

  handleQuestionEnd() {
    const list = this.phase === 'collection' ? this.collectionQuestions : this.battleQuestions
    const q = list[this.currentIdx]
    const correct = q.correctAnswer  // "1914"

    // احسب النتائج
    const results = this.playerIds.map(id => {
      const p = this.players[id]
      const ans = p.currentAnswer ?? ''
      let diff = Infinity
      let isExact = false

      if (q.answerType === 'numericInput') {
        const num = parseFloat(ans)
        const correctNum = parseFloat(correct)
        if (!isNaN(num)) {
          diff = Math.abs(num - correctNum)
          isExact = (num === correctNum)
        }
      } else {
        isExact = ans.trim().toLowerCase() === correct.trim().toLowerCase()
        diff = isExact ? 0 : 999
      }

      return { userId: id, ans, diff, timeMs: p.currentTimeMs ?? Infinity, isExact }
    })

    // المرحلة 1: closeness + speed
    if (this.phase === 'collection') {
      const exacts = results.filter(r => r.isExact)
      const fastestExact = exacts.sort((a, b) => a.timeMs - b.timeMs)[0]

      for (const r of results) {
        let pts = 0
        let isClosest = false, isFastest = false
        if (r.isExact) {
          pts = (r === fastestExact) ? 2 : 1
          isFastest = (r === fastestExact)
        } else {
          // الأقرب من بين الخاطئين
          const wrongs = results.filter(x => !x.isExact)
          const closest = wrongs.sort((a, b) => a.diff - b.diff || a.timeMs - b.timeMs)[0]
          if (r === closest && r.diff < 999) {
            pts = 1
            isClosest = true
          }
        }
        this.players[r.userId].power += pts
        this.players[r.userId].score += pts

        io.emit('match:answer-submitted', {
          matchId: this.matchId,
          questionId: q.id,
          userId: r.userId,
          value: r.ans,
          correct: r.isExact,
          closest: isClosest,
          fastest: isFastest,
          pointsAwarded: pts,
          correctAnswer: correct,
          newScore: this.players[r.userId].score,
          scores: Object.fromEntries(
            Object.entries(this.players).map(([id, p]) => [id, p.score])
          )
        })
      }

      this.currentIdx++
      setTimeout(() => this.sendNextQuestion(), 2500)
    } else {
      // المرحلة 2: battle — أول من يجيب صح يضرب الخصم
      const correctOnes = results.filter(r => r.isExact).sort((a, b) => a.timeMs - b.timeMs)
      const winner = correctOnes[0]

      // كل لاعب يستقبل result
      for (const r of results) {
        io.emit('match:answer-submitted', { ... })
      }

      // الفائز يضرب الباقين
      if (winner) {
        for (const id of this.playerIds) {
          if (id === winner.userId) continue
          this.players[id].hp = Math.max(0, this.players[id].hp - 1)
          io.emit('match:attack', {
            matchId: this.matchId,
            attackerId: winner.userId,
            targetId: id,
            damage: 1,
            targetHp: this.players[id].hp
          })

          if (this.players[id].hp === 0) {
            io.emit('match:eliminated', { matchId: this.matchId, userId: id })
            return this.endMatch(winner.userId)
          }
        }
      }

      this.currentIdx++
      setTimeout(() => this.sendNextQuestion(), 2500)
    }
  }

  transitionOrEnd() {
    if (this.phase === 'collection') {
      // انقل للمرحلة 2
      const powers = {}
      for (const id of this.playerIds) {
        this.players[id].hp = this.players[id].power
        powers[id] = this.players[id].power
      }

      io.emit('match:phase-result', {
        matchId: this.matchId,
        phase: 'collection',
        powers,
        nextPhase: 'battle'
      })

      // انتظر 4 ثوان لشاشة الـ transition في iOS
      setTimeout(() => {
        this.phase = 'battle'
        this.currentIdx = 0
        io.emit('match:phase', { matchId: this.matchId, phase: 'battle' })
        setTimeout(() => this.sendNextQuestion(), 500)
      }, 4000)
    } else {
      // انتهت كل أسئلة المرحلة 2 — أعلى HP يفوز
      const winner = this.playerIds.sort(
        (a, b) => this.players[b].hp - this.players[a].hp
      )[0]
      this.endMatch(winner)
    }
  }

  endMatch(winnerId) {
    io.emit('match:ended', {
      matchId: this.matchId,
      winnerId,
      scores: Object.fromEntries(
        Object.entries(this.players).map(([id, p]) => [id, p.score])
      ),
      hp: Object.fromEntries(
        Object.entries(this.players).map(([id, p]) => [id, p.hp])
      ),
      rewards: { gold: 50, xp: 120 }
    })
  }
}
```

---

## 🗄️ Questions Database — تحديثات

### Schema تعديل
```sql
-- أضف نوع الإجابة
ALTER TABLE Questions ADD COLUMN answerType VARCHAR(20) DEFAULT 'multipleChoice';
ALTER TABLE Questions ADD COLUMN correctAnswer TEXT;

-- options قد تكون NULL للأسئلة input
ALTER TABLE Questions MODIFY COLUMN options JSONB;
```

### قيم answerType:
- `numericInput` — رقم (سنة، عدد، نسبة...)
- `textInput` — نص (اسم، مكان...)
- `multipleChoice` — احتياط (قد لا نستخدمه)

### بيانات نموذجية:
```json
[
  {
    "text": "متى كانت الحرب العالمية الأولى؟",
    "answerType": "numericInput",
    "correctAnswer": "1914",
    "category": "history"
  },
  {
    "text": "كم عدد سور القرآن الكريم؟",
    "answerType": "numericInput",
    "correctAnswer": "114",
    "category": "religion"
  },
  {
    "text": "ما عاصمة فرنسا؟",
    "answerType": "textInput",
    "correctAnswer": "باريس",
    "category": "geography"
  }
]
```

**توصية:**
- **المرحلة 1:** أسئلة رقمية تسمح بالـ "أقرب" (سنوات، أعداد، إلخ)
- **المرحلة 2:** خليط — رقم + نص (للسرعة)

---

## ⏱️ التوقيتات الموصى بها

| المرحلة | الزمن |
|---------|-------|
| match:found → match:started | 1 ثانية |
| match:started → أول match:question | 0.5 ثانية |
| مدة كل سؤال | 15 ثانية |
| بين الأسئلة (عرض النتيجة) | 2.5 ثانية |
| match:phase-result → match:phase(battle) | 4 ثوان (لشاشة transition) |
| match:ended → close | 3 ثوان (لشاشة النتائج) |

---

## ✅ iOS Side — جاهز

كل الـ events المذكورة مربوطة في iOS:
- ✅ `match:question` بـ `answerType` + `phase`
- ✅ `match:answer` يرسل `answer` كنص + `timeMs`
- ✅ `match:answer-submitted` يقرأ `closest`, `fastest`, `pointsAwarded`, `correctAnswer`
- ✅ `match:phase-result` يعرض PhaseTransitionView (4 ثوان)
- ✅ `match:phase` يحدّد UI الحالي
- ✅ `match:attack` بـ `targetHp` للـ battle phase
- ✅ `match:ended` بنفس الشكل القديم

iOS سيعمل تلقائياً بمجرد ما الـ backend يطبّق هذي الـ logic الجديدة.
