# Clan Socket.io Events

Events the iOS client emits and listens for. Backend must match these names.

Authentication is already handled by the existing socket handshake (JWT via `extraHeaders` / `connectParams.token`).

---

## Client → Server (emit)

| Event | Payload | When |
|-------|---------|------|
| `clan:join`  | `{ clanId }`            | User opens clan detail screen |
| `clan:leave` | `{ clanId }`            | User leaves clan detail screen |
| `clan:typing`| `{ clanId }`            | User types (throttled to 1/2s) |

Server should put the user's socket in a room like `clan:<clanId>` for broadcasting.

---

## Server → Client (emit to room)

### `clan:message`
Broadcast when any member sends a message (REST or socket).
```json
{
  "clanId": "uuid",
  "message": {
    "id": "uuid",
    "type": "text",
    "content": "مرحبا",
    "isPinned": false,
    "roomCode": null,
    "User": {
      "id": "uuid",
      "username": "player1",
      "avatarUrl": "/uploads/..."
    },
    "createdAt": "2026-04-15T10:00:00Z"
  }
}
```

Same shape for `type: "announcement"` or `"game_code"` (include `roomCode` for game code messages).

### `clan:message-deleted`
```json
{ "clanId": "uuid", "messageId": "uuid" }
```

### `clan:member-joined`
```json
{ "clanId": "uuid", "user": { "id": "uuid", "username": "..." } }
```

### `clan:member-left`
```json
{ "clanId": "uuid", "userId": "uuid" }
```

### `clan:member-role-changed`
```json
{ "clanId": "uuid", "userId": "uuid", "newRole": "admin" }
```

### `clan:typing`
Broadcast to others in the room (exclude sender).
```json
{ "clanId": "uuid", "userId": "uuid", "username": "player1" }
```

iOS auto-hides typing indicator after 3 seconds.

### `clan:updated`
When clan meta (name, badge, color, isOpen, level) changes.
```json
{ "clanId": "uuid" }
```

iOS re-fetches detail via REST.

---

## Integration points in your backend

1. **On REST `POST /clans/:id/chat`** → after saving message:
   ```js
   io.to(`clan:${clanId}`).emit('clan:message', { clanId, message })
   ```

2. **On REST `POST /clans/:id/join`** (accepted) / `POST /clans/:id/leave`:
   ```js
   io.to(`clan:${clanId}`).emit('clan:member-joined', { clanId, user })
   ```

3. **On REST promote/demote**:
   ```js
   io.to(`clan:${clanId}`).emit('clan:member-role-changed', { clanId, userId, newRole })
   ```

4. **On REST PATCH `/clans/:id`**:
   ```js
   io.to(`clan:${clanId}`).emit('clan:updated', { clanId })
   ```

5. **Handle `clan:join` socket event**:
   ```js
   socket.on('clan:join', async ({ clanId }) => {
     // Verify user is member
     const isMember = await ClanMember.findOne({ where: { clanId, userId: socket.userId } })
     if (!isMember) return
     socket.join(`clan:${clanId}`)
   })
   ```

6. **Handle `clan:typing`** (broadcast to others):
   ```js
   socket.on('clan:typing', ({ clanId }) => {
     socket.to(`clan:${clanId}`).emit('clan:typing', {
       clanId,
       userId: socket.userId,
       username: socket.user.username
     })
   })
   ```

---

## Pagination (REST)

Update `GET /clans/:id/chat` to support query params:

```
GET /clans/:id/chat?limit=30&before=<messageId>
```

- `limit` — default 30, max 100
- `before` — cursor (messageId). Returns messages older than this one.

SQL:
```sql
SELECT * FROM ClanMessages
WHERE clanId = :id
  AND (:before IS NULL OR createdAt < (SELECT createdAt FROM ClanMessages WHERE id = :before))
ORDER BY createdAt DESC
LIMIT :limit
```

iOS loads 30 per page and triggers load-more when scrolling to the top.
