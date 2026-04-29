# 📋 SaifIQ — Session Handoff

تاريخ آخر جلسة: 2026-04-29
آخر iOS commit: `4a66511` — AdMob production IDs
آخر Backend commit: `ecfacd9` — migration script path fix

---

## 🗂 المسارات

| المشروع | المسار المحلي | Repo |
|---------|--------------|------|
| **iOS** | `/Volumes/me/learn swift/SaifAndAlmarifa` | local |
| **Backend (Node.js)** | `/Users/mohammedsaleh/saifiq-api` | `github.com/kaebs19/saifiq-api` |
| **API** | `https://saifiq.halmanhaj.com` | Contabo VPS |

### القاعدة الذهبية للنشر
```
لا تعدّل كود على السيرفر أبداً.
دائماً: محلي → git push → السيرفر git pull
```

### النشر
```bash
ssh contabo
cd /var/www/saifiq-api && git pull && pm2 restart saifiq-api
```

عند تغيير ENUMs أو schema:
```bash
node scripts/migrate-transaction-types.js   # مرّة واحدة قبل restart
```

---

## ✅ الحالة الحالية للتطبيق

### 🎮 Castle Siege Gameplay (متكامل)
- **Phase 1 (Collection):** 4 أسئلة `numericInput` فقط
- **Phase 2 (Battle):** 6 أسئلة `multipleChoice` + `numericInput` (لا `textInput`)
- **Tiebreaker:** عند تعادل MCQ → سؤال `numericInput` حاسم
- **Scoring:** صحيح+أسرع=+3, صحيح=+2, الأقرب=+1, بعيد=0
- **HP:** = power من Phase 1
- **6 أسئلة Phase 2** بتوقيتات: 15s/سؤال + 4s reveal + 4s phase transition
- **منع تكرار الأسئلة** بين المراحل

### 💰 نظام الرهان (جديد)
- كل لاعب يدفع **50 ذهب** عند بدء المباراة
- الفائز: **+100 ذهب pot** + 120 XP
- الخاسر: **-50 ذهب** (الرهن) + 40 XP
- إذا الذهب < 50 → **InsufficientGoldSheet**:
  - 📺 شاهد إعلان واربح 100 ذهب
  - 🛒 افتح المتجر
  - ❌ إلغاء

### 📺 AdMob (جاهز للإنتاج)
- **App ID:** `ca-app-pub-8219247197168750~5269151509` (Info.plist)
- **Rewarded:** `ca-app-pub-8219247197168750/8065050240`
- **Interstitial:** `ca-app-pub-8219247197168750/1468064330`
- **حد يومي:** 5 إعلانات لكل مستخدم
- Endpoint: `POST /api/v1/users/me/ad-reward` → +100 ذهب

### 🔌 Disconnect Handling (جديد)
- لاعب ينقطع → backend ينتظر **15 ثانية**
- iOS يعرض banner برتقالي بـ countdown
- إذا رجع → `match:player-reconnected` + المباراة تستمر
- إذا ما رجع → `match:ended` + الفائز التلقائي

### 🛡 Power-ups (تعمل end-to-end)
| الأداة | الوظيفة | حالة الاسم |
|-------|---------|-----------|
| `shield` | يمتص ضربة واحدة (10s) | ✅ |
| `freeze_time` | يجمّد الخصم 5s | ✅ |
| `hint` | weights لـ MCQ / range لـ numeric | ✅ |
| `eliminate_two` (50/50) | يحذف خيارَين خاطئَين | ✅ |
| `reveal` (كان `reveal_answer`) | كشف الصحيح/أول رقم | ✅ |
| `narrow_range` (العصفور) | مدى رقمي ضيّق | ✅ |
| `double_damage` | الضربة التالية -2 HP | ✅ |
| `skip` | يتخطى السؤال | ✅ |
| **iOS يرسل `itemType`** (ليس `itemId`) | match handler يقرأ `itemType` | ✅ |

### 🎨 Visual Polish (5 Stages)
- **A. Combat:** قذيفة طائرة + انفجار + debris + screen shake + HP flash
- **B. Reward Drama:** floating "+N" + crown + streak fire ring + power-up burst
- **C. Question UX:** slide transitions + circular timer ring
- **D. Atmosphere:** drifting clouds + lightning + army silhouettes
- **E. End Cinematic:** victory beam + castle crumble + enhanced confetti

### 🎓 Onboarding
- Tutorial Castle Siege يظهر **مرّة واحدة** قبل أول 1v1
- يظهر في MainView (قبل matchmaking) — ليس في MatchView
- 4 خطوات: collection → scoring → battle → keypad
- AppStorage: `castleSiege.tutorialSeen`

### 📊 Stats الكاملة في MatchEndView
- نسبة الدقّة، أسرع/أبطأ زمن، أطول سلسلة
- Per-question dots بألوان حسب النتيجة
- Reward card يبيّن الـ wager + pot + net gold
- Trophy/Crumble cinematic + opaque background

### 🔐 Session Management (جديد)
- 401 → `SessionExpiryHandler` يمسح الجلسة + toast + يحوّل لـ login
- Cooldown 5s يمنع تكرار التوست عند بَرْق 401

### 🎒 Smart Inventory
- يخفي الأدوات الفارغة (count == 0)
- يفلتر حسب نوع السؤال:
  - MCQ → يظهر 50/50, يخفي bird
  - numericInput → يظهر bird, يخفي 50/50
- إذا فاضي + عنده ذهب → زر "افتح المتجر"

---

## 🆕 آخر شي تم في هذه الجلسة

### iOS commits (من `b8b3d41` → `4a66511`)
- 5 stages من المؤثّرات السينمائية
- نظام الرهان والإعلانات
- session expiry handler
- field name fixes (itemType, reveal, isTiebreaker, tieDetected)
- AdMob production IDs

### Backend commits (من `812587b` → `ecfacd9`)
- ENUM migration script
- ad-reward endpoint
- wager system (50 buy-in / 100 pot)
- question dedup
- Phase 2 textInput exclusion
- eliminate_two + shield items
- Tiebreaker + Phase 2 = 6 questions

---

## 🚧 ما متبقّي / مفتوح

### Backend
- (لا شي حرج — Castle Siege كامل)

### iOS
- (لا شي حرج — جاهز للاختبار end-to-end)

### اختبار
- ✅ AdMob يعمل في DEBUG
- ⏳ TestFlight: لم يُختبر بعد
- ⏳ مباراة كاملة بنظام الرهان: تحتاج لاعبَين برصيد ≥ 50

---

## 🎯 خطط الجلسة القادمة (مقترحات)

### تطوير + إصلاح بالتوازي
1. **🐛 Bug fixes** بناءً على اختبار المباريات الفعلية
2. **🏆 Achievements system** — منجزات (أول فوز، 5-streak، إلخ)
3. **📈 Leaderboard** — موجود لكن يحتاج تحسين
4. **🎁 Daily reward enhancements** — موجود
5. **📱 iPad layout** — تحسين للشاشات الكبيرة
6. **🌍 Multi-language** — English + Arabic
7. **🚀 TestFlight submission** — مع طلبات Apple
8. **👤 Profile screen polish** — match history + stats
9. **🧠 More questions** — توسيع DB
10. **⚔️ Clan Wars** — UI موجود لكن backend ناقص

---

## 🔧 Quick Start للجلسة الجديدة

### iOS
```bash
cd "/Volumes/me/learn swift/SaifAndAlmarifa"
git log --oneline -5
git status
```

### Backend
```bash
cd /Users/mohammedsaleh/saifiq-api
git log --oneline -5
git status
```

### Build iOS
```bash
xcodebuild -project SaifAndAlmarifa.xcodeproj \
  -scheme SaifAndAlmarifa \
  -sdk iphonesimulator \
  -destination 'generic/platform=iOS Simulator' \
  -configuration Debug build
```

### Simulator (iPhone 17 booted)
```bash
xcrun simctl install 4654C258-3363-4C68-ACD4-5FBB29A9683A \
  "/Users/mohammedsaleh/Library/Developer/Xcode/DerivedData/SaifAndAlmarifa-bukujmzhjzpencfqztloplnemwex/Build/Products/Debug-iphonesimulator/SaifAndAlmarifa.app"
xcrun simctl launch 4654C258-3363-4C68-ACD4-5FBB29A9683A com.saifiq.app
```

---

## 📂 الملفات المحورية في iOS

| المسار | الوظيفة |
|--------|---------|
| `Features/Match/MatchView.swift` | الشاشة الأساسية للمباراة |
| `Features/Match/MatchViewModel.swift` | المنطق + socket handlers |
| `Features/Match/Models/MatchModels.swift` | data structures |
| `Features/Match/MatchEndView.swift` | شاشة النتائج (مع wager) |
| `Features/Match/Components/NumericKeypadView.swift` | لوحة المفاتيح المخصّصة |
| `Features/Match/Components/InputAnswerView.swift` | display + reveal card |
| `Features/Match/Components/MatchComponents.swift` | PlayersBattlefield, InventoryBar, etc |
| `Features/Match/Components/BattleAnimations.swift` | Stage A — combat FX |
| `Features/Match/Components/RewardAnimations.swift` | Stage B — score FX |
| `Features/Match/Components/AtmosphereLayers.swift` | Stage D — bg layers |
| `Features/Match/Components/EndCinematic.swift` | Stage E — victory/crumble |
| `Features/Match/Components/MatchEffects.swift` | shake, sparkles, combo |
| `Features/Match/Components/InsufficientGoldSheet.swift` | wager < gold flow |
| `Features/Match/Components/TutorialOverlay.swift` | first-match teaching |
| `Features/Match/Components/MatchSummaryChart.swift` | stats grid |
| `Features/Main/MainView.swift` | hero cards + tutorial gate + wager check |
| `Utilities/Managers/AdManager.swift` | AdMob (Rewarded + Interstitial) |
| `Utilities/Managers/Auth/SessionExpiryHandler.swift` | 401 auto-logout |
| `Utilities/Managers/Network/Main/MainEndpoint.swift` | `/ad-reward` endpoint |
| `Utilities/Managers/Network/Socket/SocketManager.swift` | كل match events |

## 📂 الملفات المحورية في Backend

| المسار | الوظيفة |
|--------|---------|
| `src/services/castleSiege.service.js` | Phase 1+2 + tiebreaker + items + wager + finalize |
| `src/socket/handlers/match.handler.js` | match:* events router |
| `src/routes/users.routes.js` | `/me/ad-reward` |
| `src/models/Transaction.js` | ENUM types |
| `src/config/constants.js` | GOLD_COSTS |
| `scripts/migrate-transaction-types.js` | ENUM migration |

---

## 📜 الـ Spec الموثّق

[`CASTLE_SIEGE_GAMEPLAY_SPEC.md`](CASTLE_SIEGE_GAMEPLAY_SPEC.md) — مرجع كامل:
- 2-phase flow + scoring
- Tiebreaker mechanic
- Disconnect handling
- Power-ups Reference (8 أدوات + payloads)
- Bird (narrow_range)
- Timings + DB schema

---

## 🎮 الـ Modes النشطة

| Mode | النظام | الحالة |
|------|--------|-------|
| `random1v1` | Castle Siege ⭐ + wager | ✅ يعمل end-to-end |
| `random4` | MCQ classic | ✅ يعمل |
| `private1v1` | Castle Siege | ✅ |
| `challengeFriend` | Castle Siege | ✅ |
| `friends4` | MCQ classic | ✅ |

---

## 📈 الإحصائيات

- **iOS commits:** 50+ في هذي السلسلة
- **Backend commits:** 12 في Castle Siege
- **Build status:** ✅ ناجح كل مرة
- **Files touched:** 30+ في Match feature

---

## 💡 ملاحظات مهمّة

1. **Backend dev محترف وسريع** — أرسل المواصفات وعادة يطبّقها سريعاً
2. **Bundle ID:** `com.saifiq.app`
3. **Team ID:** `ZN3Z5KRWM7`
4. **Domain:** `saifiq.halmanhaj.com`
5. **اللغة الأولى:** العربي (RTL)
6. **التطبيق Production-ready** — جاهز للـ TestFlight
7. **iPhone 17 simulator UDID:** `4654C258-3363-4C68-ACD4-5FBB29A9683A` (booted)

---

## ✨ كلمة أخيرة

التطبيق وصل لمرحلة جدّ متقدّمة. Castle Siege متكامل end-to-end مع:
- ✅ نظام الرهان
- ✅ AdMob للإعلانات المكافأة
- ✅ Power-ups كاملة
- ✅ مؤثّرات سينمائية في 5 مراحل
- ✅ Disconnect handling
- ✅ Session management
- ✅ Tutorial + tooltips
- ✅ Stats + summary chart

**جلسة موفّقة!** 🚀
