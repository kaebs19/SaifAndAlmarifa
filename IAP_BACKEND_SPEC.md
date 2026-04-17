# IAP Backend Specification — `/iap/verify`

Required backend endpoint for the iOS in-app purchase system (StoreKit 2).

---

## Endpoint

```
POST /api/v1/iap/verify
Authorization: Bearer <token>
Content-Type: application/json
```

## Request

```json
{
  "productId": "com.saifiq.gems.50",
  "transactionId": "2000000987654321"
}
```

## Response (success)

```json
{
  "success": true,
  "message": "تم التحقق من الشراء",
  "data": {
    "gemsAdded": 50,
    "goldAdded": 0,
    "newGems": 150
  }
}
```

---

## Product Catalog

| Product ID | Gems | Bonus Gold |
|-----------|------|------------|
| `com.saifiq.gems.50`   | 50   | 0    |
| `com.saifiq.gems.300`  | 300  | 0    |
| `com.saifiq.gems.700`  | 700  | 0    |
| `com.saifiq.gems.1500` | 1500 | 200  |
| `com.saifiq.gems.5000` | 5000 | 1000 |

---

## Verification Logic

1. **Authenticate request** (Bearer token → userId)

2. **Verify with Apple App Store Server API**
   - Endpoint (Production): `https://api.storekit.itunes.apple.com/inApps/v1/transactions/{transactionId}`
   - Endpoint (Sandbox): `https://api.storekit-sandbox.itunes.apple.com/inApps/v1/transactions/{transactionId}`
   - Use **JWT** signed with your App Store Connect key
   - Verify: `bundleId == "com.saifiq.SaifAndAlmarifa"` (or current), `productId` matches, not revoked

3. **Prevent replay**
   - Store processed `transactionId` in DB (`IAPTransactions` table)
   - Columns: `id` (transactionId), `userId`, `productId`, `gemsGranted`, `goldGranted`, `verifiedAt`
   - If already exists → reject with HTTP 409 or return cached result

4. **Credit user**
   - Look up `productId` in catalog
   - `user.gems += gems`
   - `user.gold += bonusGold`
   - Create `Transactions` record with `type: "iap"`, `currency: "gems"`, `amount: gems`

5. **Return response** with `gemsAdded`, `goldAdded`, `newGems` (total)

---

## Error Responses

| Status | Case |
|--------|------|
| 400 | Invalid productId (not in catalog) |
| 401 | Missing/invalid token |
| 409 | transactionId already processed (duplicate) |
| 422 | Apple verification failed (transaction invalid/revoked) |
| 500 | Internal error |

Error format:
```json
{ "success": false, "message": "رسالة الخطأ بالعربي" }
```

---

## Optional: Server-to-Server Notifications V2

**Endpoint:** `POST /api/v1/iap/apple-notifications`

Receives webhooks from Apple for:
- `REFUND` — revert gems (set user.gems -= granted)
- `CONSUMPTION_REQUEST` — respond to refund inquiry
- `SUBSCRIBED` / `DID_RENEW` — if you add subscriptions later

Configure in App Store Connect → App Information → App Store Server Notifications.

---

## Required Secrets (environment)

```
APPLE_KEY_ID=XXXXXXXXXX
APPLE_ISSUER_ID=xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
APPLE_PRIVATE_KEY_PATH=/path/to/AuthKey_XXXXXXXXXX.p8
APPLE_BUNDLE_ID=com.saifiq.SaifAndAlmarifa
APPLE_USE_SANDBOX=true   # switch to false in production
```

Generate the key at: App Store Connect → Users and Access → Keys → In-App Purchase

---

## Node.js Reference Implementation

```js
import { SignJWT } from 'jose'
import { readFileSync } from 'fs'

const CATALOG = {
  'com.saifiq.gems.50':   { gems: 50,   gold: 0 },
  'com.saifiq.gems.300':  { gems: 300,  gold: 0 },
  'com.saifiq.gems.700':  { gems: 700,  gold: 0 },
  'com.saifiq.gems.1500': { gems: 1500, gold: 200 },
  'com.saifiq.gems.5000': { gems: 5000, gold: 1000 },
}

async function signAppleJWT() {
  const key = readFileSync(process.env.APPLE_PRIVATE_KEY_PATH, 'utf8')
  return await new SignJWT({ bid: process.env.APPLE_BUNDLE_ID })
    .setProtectedHeader({ alg: 'ES256', kid: process.env.APPLE_KEY_ID, typ: 'JWT' })
    .setIssuer(process.env.APPLE_ISSUER_ID)
    .setIssuedAt()
    .setExpirationTime('1h')
    .setAudience('appstoreconnect-v1')
    .sign(privateKey)
}

app.post('/api/v1/iap/verify', requireAuth, async (req, res) => {
  const { productId, transactionId } = req.body
  const userId = req.user.id

  const product = CATALOG[productId]
  if (!product) return res.status(400).json({ success: false, message: 'منتج غير معروف' })

  // منع التكرار
  const existing = await IAPTransaction.findByPk(transactionId)
  if (existing) return res.status(409).json({ success: false, message: 'تم تسجيل هذه العملية مسبقاً' })

  // التحقق مع Apple
  const jwt = await signAppleJWT()
  const baseUrl = process.env.APPLE_USE_SANDBOX === 'true'
    ? 'https://api.storekit-sandbox.itunes.apple.com'
    : 'https://api.storekit.itunes.apple.com'
  const resp = await fetch(`${baseUrl}/inApps/v1/transactions/${transactionId}`, {
    headers: { Authorization: `Bearer ${jwt}` }
  })
  if (!resp.ok) return res.status(422).json({ success: false, message: 'تعذّر التحقق من المعاملة' })

  const { signedTransactionInfo } = await resp.json()
  const tx = decodeJWT(signedTransactionInfo) // استخدم jose.decodeJwt

  if (tx.productId !== productId) return res.status(422).json({ success: false, message: 'المنتج لا يطابق' })
  if (tx.bundleId !== process.env.APPLE_BUNDLE_ID) return res.status(422).json({ success: false, message: 'Bundle غير صحيح' })

  // إضافة الرصيد
  const user = await User.findByPk(userId)
  user.gems += product.gems
  user.gold += product.gold
  await user.save()

  await IAPTransaction.create({
    id: transactionId,
    userId,
    productId,
    gemsGranted: product.gems,
    goldGranted: product.gold,
    verifiedAt: new Date()
  })

  await Transaction.create({
    userId,
    amount: product.gems,
    type: 'iap',
    currency: 'gems',
    description: `شراء ${product.gems} جوهرة`
  })

  res.json({
    success: true,
    message: 'تم الشراء',
    data: {
      gemsAdded: product.gems,
      goldAdded: product.gold,
      newGems: user.gems
    }
  })
})
```

---

## Testing

1. Create **Sandbox Tester** in App Store Connect → Users and Access
2. Sign out of App Store on iPhone → Settings → App Store → Sign Out
3. Install app via Xcode → tap purchase → use sandbox credentials
4. iOS client sends `transactionId` to this endpoint
5. Verify DB rows created, gems credited
