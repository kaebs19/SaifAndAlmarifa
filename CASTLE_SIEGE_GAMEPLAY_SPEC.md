# Castle Siege Gameplay — Backend Specification

طريقة لعب جديدة تستبدل النظام السابق (multiple choice).

---

## 🎮 الفكرة العامة

### مرحلتان لكل مباراة 1v1:

**المرحلة 1 — تجميع القوة (Collection)**
- **4 أسئلة** من نوع `numericInput` **فقط** (أرقام/أعداد)
- اللاعب يكتب الرقم (مثال: "في أي عام تأسست Apple؟" → "1976")
- Scoring: صحيح=**+2** · صحيح+أسرع=**+3** · خطأ+أقرب=**+1** · بعيد=0
- القوة المتراكمة = HP قلعته في المرحلة 2

**المرحلة 2 — المواجهة (Battle)** — تنافسية
- 10 أسئلة: **`multipleChoice` (4 خيارات)** أو **`numericInput`** فقط
- ❌ **ممنوع `textInput` كلياً** في المرحلة 2 (تجربة المستخدم تفشل بدون keyboard)
- iOS يعرض UI مناسب لكل سؤال حسب `answerType`
- كل إجابة صحيحة = ضربة على قلعة الخصم (-1 HP)
- HP لكل لاعب = القوة من المرحلة 1
- **الفائز: من يهدم قلعة الخصم أولاً**
- إذا انتهت الأسئلة: أعلى HP متبقي يفوز

---

## 📊 قواعد Scoring (المرحلة 1)

| الحالة | النقاط |
|--------|--------|
| ✅ صحيح **+ الأسرع** | **+3** |
| ✅ صحيح فقط (مش الأسرع) | **+2** |
| 🎯 خطأ + الأقرب من بين الخاطئين | **+1** |
| ❌ خطأ + بعيد | 0 |

> الأسرع يأخذ bonus +1 على الإجابة الصحيحة. كل لاعب يبدأ بـ `power = 2` ابتدائياً.

### أمثلة

**سؤال:** "متى كانت الحرب العالمية الأولى؟" (الصحيح: 1914)

| اللاعب | الإجابة | الزمن | الحالة | النقاط |
|--------|--------|------|--------|--------|
| A | 1914 | 3 ث | ✅ صحيح + أسرع | **+3** |
| B | 1914 | 5 ث | ✅ صحيح فقط | **+2** |

**سيناريو ثاني:**
| اللاعب | الإجابة | الزمن | الحالة | النقاط |
|--------|--------|------|--------|--------|
| A | 1911 | 3 ث | ❌ خطأ + بعيد | 0 |
| B | 1913 | 5 ث | 🎯 خطأ + أقرب | **+1** |

**سيناريو ثالث:**
| اللاعب | الإجابة | الزمن | الحالة | النقاط |
|--------|--------|------|--------|--------|
| A | 1914 | 4 ث | ✅ صحيح + أسرع | **+3** |
| B | 1900 | 6 ث | ❌ خطأ + بعيد | 0 |

بعد 4 أسئلة، كل لاعب يحصل على مجموع قوة (مثلاً A=10، B=5).

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
  "answerType": "numericInput", // "numericInput" | "textInput" | "multipleChoice"
  "text": "متى كانت الحرب العالمية الأولى؟",
  "options": [],                 // فارغة للـ input، 4 خيارات للـ multipleChoice
  "index": 1,
  "total": 4,                    // 4 للـ collection، 10 للـ battle
  "timeLimit": 15
}
```

**ملاحظة:**
- المرحلة 1: `numericInput` **فقط** (4 أسئلة) — iOS يعرض لوحة مفاتيح رقمية مخصّصة.
- المرحلة 2: `multipleChoice` (مع `options`) أو `numericInput` (10 أسئلة).

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
  "value": "1913",                  // ما أدخل (نص للـ input، أو index كنص للـ MCQ)
  "correct": false,                 // لو exact match
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

═══ المرحلة 1: COLLECTION (4 أسئلة input) ═══
4. match:phase { phase: "collection" }
5. match:question [1] { phase: "collection", answerType: "numericInput" | "textInput" }
6. (كل اللاعبين يرسلوا match:answer أو 15 ثانية)
7. match:answer-submitted (للكل)
   - تحدّد closest + fastest + pointsAwarded
8. (انتظر 2.5 ثانية لعرض النتيجة)
9. match:question [2]
10. ... (4 أسئلة كاملة)

═══ TRANSITION ═══
11. match:phase-result { powers: {u1:6, u2:4} }
    → iOS يعرض PhaseTransitionView لـ ~3 ثوان
12. match:phase { phase: "battle" }

═══ المرحلة 2: BATTLE (10 أسئلة متنوّعة) ═══
13. ابدأ HP لكل لاعب من powers
14. match:question [1] { phase: "battle", answerType: "numericInput" | "textInput" | "multipleChoice", options?: [...] }
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
    // المرحلة 1: 4 أسئلة numericInput فقط
    this.collectionQuestions = await Question.findRandom(4, {
      answerType: 'numericInput'
    })
    // المرحلة 2: 10 أسئلة — MCQ + numericInput فقط (textInput ممنوع كلياً)
    this.battleQuestions = await Question.findRandom(10, {
      answerType: { $in: ['multipleChoice', 'numericInput'] }
    })
    // ⚠️ تأكّد أن أسئلة العواصم/الأسماء تكون multipleChoice — لا textInput

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
      answerType: q.answerType,  // "numericInput" | "textInput" | "multipleChoice"
      text: q.text,
      options: q.answerType === 'multipleChoice' ? q.options : [],
      index: this.currentIdx + 1,
      total: list.length,         // 4 للـ collection، 10 للـ battle
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
        // iOS يبعث الأرقام إنجليزية دائماً (يحوّل عربي/فارسي تلقائياً)
        const num = parseFloat(ans)
        const correctNum = parseFloat(correct)
        if (!isNaN(num)) {
          diff = Math.abs(num - correctNum)
          isExact = (num === correctNum)
        }
      } else if (q.answerType === 'multipleChoice') {
        // ans = index كنص ("0".."3")
        const selectedIdx = parseInt(ans)
        isExact = selectedIdx === q.correctIndex
        diff = isExact ? 0 : 999
      } else {
        isExact = ans.trim().toLowerCase() === correct.trim().toLowerCase()
        diff = isExact ? 0 : 999
      }

      return { userId: id, ans, diff, timeMs: p.currentTimeMs ?? Infinity, isExact }
    })

    // المرحلة 1: scoring جديد — صحيح=+2، صحيح+أسرع=+3، خطأ+أقرب=+1
    if (this.phase === 'collection') {
      const exacts = results.filter(r => r.isExact)
      const fastestExact = exacts.sort((a, b) => a.timeMs - b.timeMs)[0]

      for (const r of results) {
        let pts = 0
        let isClosest = false, isFastest = false
        if (r.isExact) {
          // ✅ صحيح: +2 أساس + 1 bonus لو الأسرع
          pts = (r === fastestExact) ? 3 : 2
          isFastest = (r === fastestExact)
        } else {
          // 🎯 الأقرب من بين الخاطئين: +1
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
- **المرحلة 1:** `numericInput` (سنوات، أعداد) أو `textInput` قصير (اسم/مكان) — مع closeness scoring
- **المرحلة 2:** `multipleChoice` + `numericInput` (لا `textInput` للسرعة)

---

## 🎮 الأوضاع والأيتمز

| Mode | النظام | الأيتمز |
|------|--------|---------|
| **1v1** (random / private / challenge) | Castle Siege (input, 2 phases) | ❌ **معطّلة** |
| **4-player** (random / friends) | MCQ classic | ✅ متاحة |

⚠️ **iOS يخفي InventoryBar كلياً في 1v1** — لا حاجة لإرسال `match:item-error` من backend لمنع الاستخدام، لكن الـ backend يجب يرفض أي `match:use-item` يصل خلال match مود 1v1 (دفاعياً).

---

## ⚔️ Power-ups Reference (الكامل)

كل أداة تُرسَل من iOS عبر `match:use-item { matchId, itemId }`. Backend يطبّق المنطق ويردّ بـ `match:item-effect` على المستخدم أو `match:item-used` (broadcast).

| Item ID | الأثر المطلوب | متى تعمل |
|---------|--------------|----------|
| `hint` | **MCQ:** يبيّن نسبة احتمال صحّة كل خيار (مثلاً 70% لخيار B). **numericInput:** نص إرشادي عام. | كلا النوعَين |
| `eliminate_two` | **MCQ:** backend يحذف خيارَين خاطئَين عشوائياً. لا يعمل على numericInput. | MCQ فقط |
| `reveal_answer` | **MCQ:** يعرض الخيار الصحيح (يفوز إذا ضغطه). **numericInput:** يكشف رقماً واحداً من الإجابة (مثل أول رقم). | كلا النوعَين |
| `double_damage` | الإجابة الصحيحة التالية تضرّ الخصم بـ -2 HP (بدلاً من -1). يعمل في battle phase فقط. | Phase 2 |
| `freeze_time` | **يجمّد وقت الخصم 5 ثوانٍ** (الخصم لا يستطيع الإجابة، يرى overlay ❄️ تجميد). | كلا النوعَين |
| `narrow_range` | يضيّق المدى الرقمي (راجع قسم العصفور أدناه). | numericInput |
| `shield` | يبلوك الضربة التالية على المستخدم (يستخدم في battle). | Phase 2 |
| `skip` | يتخطّى السؤال الحالي (إجابة فارغة، 0 نقاط). | كلا النوعَين |

### Backend payloads

**`hint` على MCQ:**
```json
{ "itemType": "hint", "userId": "u1",
  "optionWeights": { "0": 5, "1": 70, "2": 15, "3": 10 } }
```

**`eliminate_two` على MCQ:**
```json
{ "itemType": "eliminate_two", "userId": "u1", "disabledIndices": [1, 3] }
```

**`reveal_answer` على MCQ:**
```json
{ "itemType": "reveal_answer", "userId": "u1", "correctIndex": 2 }
```

**`reveal_answer` على numericInput:**
```json
{ "itemType": "reveal_answer", "userId": "u1", "revealedDigit": "1", "position": 0 }
```

**`freeze_time` (للخصم):**
```json
{ "itemType": "freeze_time", "userId": "<targetId>", "frozen": true, "duration": 5 }
```

**`double_damage` (state على session):**
```json
{ "itemType": "double_damage", "userId": "u1", "active": true }
```
الضربة التالية في `match:attack` يجب أن تحوي `damage: 2`.

---

## 🐦 Power-up: العصفور (narrow_range)

يضيّق المدى الرقمي للسؤال — يعمل فقط في `numericInput`.

### Client → Server
```json
event: match:use-item
payload: { "matchId": "...", "itemId": "narrow_range" }
```

### Server → Client (للاستخدام نفسه)
```json
event: match:item-effect
payload: {
  "matchId": "...",
  "userId": "u1",
  "itemType": "narrow_range",
  "rangeHint": { "min": 1900, "max": 1925 }
}
```

### Backend Logic
```js
case 'narrow_range': {
  const q = currentQuestion
  if (q.answerType !== 'numericInput') {
    return socket.emit('match:item-error', { reason: 'numeric_only' })
  }
  const correct = parseFloat(q.correctAnswer)
  // مدى ±10% أو ±5 وحدات (أيهما أوسع) — مع noise بسيط
  const tolerance = Math.max(Math.abs(correct) * 0.10, 5)
  const offsetLo = Math.random() * tolerance * 0.5
  const offsetHi = Math.random() * tolerance * 0.5
  const min = Math.floor(correct - tolerance + offsetLo)
  const max = Math.ceil(correct + tolerance - offsetHi)

  io.to(userId).emit('match:item-effect', {
    matchId,
    userId,
    itemType: 'narrow_range',
    rangeHint: { min, max }
  })
}
```

### iOS Behavior
- يعرض banner ذهبي `🐦 العصفور يهمس... [min ↔ max]` لمدّة 8 ثوانٍ
- يختفي تلقائياً عند سؤال جديد

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
- ✅ `match:question` بـ `answerType` + `phase` + `options`
- ✅ `match:answer` يرسل `answer` كنص + `timeMs`
- ✅ `match:answer-submitted` يقرأ `closest`, `fastest`, `pointsAwarded`, `correctAnswer`
- ✅ `match:phase-result` يعرض PhaseTransitionView (4 ثوان)
- ✅ `match:phase` يحدّد UI الحالي
- ✅ `match:attack` بـ `targetHp` للـ battle phase
- ✅ `match:ended` بنفس الشكل القديم

### تحسينات iOS للإدخال
- لوحة مفاتيح **`.numberPad`** للـ `numericInput` (أرقام إنجليزية فقط)
- تحويل تلقائي عربي/فارسي → إنجليزي (٠-٩ / ۰-۹ → 0-9) قبل الإرسال
- المرحلة 2 المختلطة: `MatchView` يبدّل تلقائياً بين `InputAnswerView` و `AnswerButton` حسب `answerType`

iOS سيعمل تلقائياً بمجرد ما الـ backend يطبّق هذي الـ logic الجديدة.
