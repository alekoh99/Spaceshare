# SpaceShare Messaging Feature - Improvement Roadmap

## Current Status Analysis

✅ **Implemented:**
- Basic text messaging
- Conversation management
- Read/unread status tracking
- Message deletion
- Image attachment support (partial)
- Pagination support
- Firebase Cloud Messaging integration

❌ **Missing / Incomplete:**
- Voice & video calling
- Typing indicators
- Message search
- Message editing
- Group messaging
- Auto-delete messages
- End-to-end encryption setup
- Rich media (documents, videos)
- Message reactions/emojis
- Quoted replies
- Message forwarding
- User presence/status indicators

---

## Priority 1: Core Features (High Impact)

### 1.1 Typing Indicators
**Why:** Shows conversation is active; matches user expectations from WhatsApp/Telegram
**Frontend:** Display "typing..." when user is composing
**Backend:** 
- POST `/api/messaging/typing` - broadcast typing status
- Real-time listeners via WebSocket or Firebase listeners

**Implementation:**
```dart
// lib/screens/messaging/chat_screen.dart - Add typing indicator
// Show "User is typing..." above message input
// Send typing event every keystroke
```

### 1.2 Message Search
**Why:** Users need to find old messages quickly
**Features:**
- Search by keyword/phrase
- Filter by sender/date
- Full-text search capability

```javascript
// backend/routes/messaging.js
GET /api/messaging/conversations/:conversationId/search?q=keyword
// Returns matching messages with context
```

### 1.3 Message Editing
**Why:** Correct typos, update information
**Frontend:** Long-press message → Edit option
**Backend:**
```javascript
PUT /api/messaging/messages/:messageId
{
  "text": "edited message",
  "editedAt": "2026-02-16T10:00:00Z"
}
```

### 1.4 Message Reactions
**Why:** Quick feedback without typing new message
**Implement:** Add emoji reactions (👍 ❤️ 😂 😮 😢 🔥)

```dart
// Add reaction UI to message bubble
// POST /api/messaging/messages/:messageId/reactions
```

---

## Priority 2: Enhanced Messaging (Medium Impact)

### 2.1 Quoted Replies
**Why:** Easy conversation context reference
**Features:**
- Reply to specific message
- Show quoted message above reply
- Thread-like behavior

```dart
// Message model addition
String? quotedMessageId;
String? quotedMessageText;
String? quotedMessageAuthor;
```

### 2.2 Rich Media Support
**Why:** Share documents, videos, files (like Telegram: "no limits")
**Supported Types:**
- Documents (PDF, DOC, XLS)
- Videos
- Audio files
- GIFs

```javascript
// Enhanced attachment handling
POST /api/messaging/upload-attachment
{
  "fileType": "document|video|audio|gif",
  "fileSize": 52428800, // 50MB example
  "fileName": "presentation.pdf"
}
```

### 2.3 Message Forwarding
**Why:** Share important messages with other contacts
**Features:**
- Forward single/multiple messages
- "Forwarded from..." label shown
- Works across conversations

### 2.4 User Presence & Status
**Why:** Know when contacts are online
**States:**
- Online (last seen: now)
- Away (idle > 5 min)
- Offline (closed app)
- Custom status message

```dart
// Add to Message model
String? senderStatus; // 'online', 'away', 'offline'
DateTime? lastSeen;

// Add to Conversation model
String? participantStatus;
```

---

## Priority 3: Advanced Features (Lower Priority but High Polish)

### 3.1 Voice & Video Calls
**Why:** Core communication feature (critical for dating app)
**Tools:** Consider:
- Agora.io SDK
- Twilio
- Firebase Real-time Database for call signaling

**Features:**
- 1-on-1 audio/video calls
- Screen sharing
- Call history logging
- Decline/miss call tracking

### 3.2 Auto-Delete Messages
**Why:** Privacy feature like Telegram/Signal
**Options:**
- 30 sec, 1 min, 1 hour, 24 hours, 7 days, 30 days
- "DM" style (disappear after read on both sides)

```dart
// Message model addition
int? expiresIn; // milliseconds
bool? deleteAfterRead;
DateTime? deletedAt;
```

### 3.3 Message Grouping
**Why:** Better UX when multiple messages from same person
**Show:** Combine consecutive messages from same sender in timeline
**Timestamps:** Show time only between message groups

### 3.4 Conversation Pinning
**Why:** Quick access to important chats
**Features:**
- Pin/unpin conversation
- Pinned conversations stay at top
- Local preference (per device)

### 3.5 Blocking & Muting
**Why:** User safety and convenience
**Block:**
- Prevent messages from specific user
- Hide blocked user's profile
- 
**Mute:**
- Disable notifications for conversation
- Still receive messages (not visible in notifications)

```javascript
POST /api/messaging/block/:userId
POST /api/messaging/mute/:conversationId
```

---

## Priority 4: Encryption & Security

### 4.1 End-to-End Encryption (E2EE)
**Why:** Privacy; matches WhatsApp/Telegram standard
**Implementation:**
- Use TweetNaCl.js (JavaScript)
- Use Pointy Castle (Dart)
- Server never has access to plaintext

**Keys:**
- Generate keypair per conversation
- Exchange public keys securely
- Store encrypted messages on server

### 4.2 Self-Destructing Messages
**Why:** Telegram feature; temporary privacy
**Implementation:**
- Message deletes from both devices after X time
- Shows countdown timer
- Cannot be screenshot (app-level protection)

---

## Priority 5: UI/UX Polish

### 5.1 Message Indicators
```
✓   = Sent
✓✓  = Delivered
✓✓  = Read (blue checkmarks)
⏱   = Sending
⚠️  = Failed to send (with retry option)
```

### 5.2 Chat List Enhancements
- **Last message preview** with sender name
- **Unread badge count**
- **Muted notification icon**
- **Search chat quick filter**
- **Swipe actions** (archive, delete, mute)

### 5.3 Message Timestamps
- Smart timestamps (just now, 5 min ago, Today, Yesterday, Date)
- Hover/tap to show full timestamp
- Group by date

### 5.4 Notification Improvements
- Sound notification per conversation
- Vibration pattern options
- DND (Do Not Disturb) mode

---

## Implementation Priority Order

```
Phase 1 (Week 1-2):
□ Typing indicators
□ Message editing
□ Message search
□ Read receipts improvement

Phase 2 (Week 3-4):
□ Message reactions
□ Quoted replies
□ Presence/status indicators
□ Rich media (documents, videos)

Phase 3 (Week 5-6):
□ Voice/video calls integration
□ Message forwarding
□ Better notification system
□ Auto-delete messages

Phase 4 (Week 7-8):
□ E2EE implementation
□ Advanced features (blocking, muting)
□ Performance optimization
```

---

## Code Organization Recommendations

```
lib/
├── services/
│   ├── messaging_service.dart (EXPAND)
│   ├── typing_indicator_service.dart (NEW)
│   ├── presence_service.dart (NEW)
│   ├── encryption_service.dart (NEW)
│   ├── voice_call_service.dart (NEW)
│   └── message_search_service.dart (NEW)
│
├── providers/
│   ├── messaging_controller.dart (EXPAND)
│   ├── typing_controller.dart (NEW)
│   └── presence_controller.dart (NEW)
│
├── screens/
│   ├── messaging/
│   │   ├── chat_screen.dart (ENHANCE)
│   │   ├── conversations_screen.dart (ENHANCE)
│   │   ├── message_search_screen.dart (NEW)
│   │   └── call_screen.dart (NEW)
│   │
│   └── widgets/
│       ├── message_bubble.dart (ENHANCE)
│       ├── typing_indicator.dart (NEW)
│       ├── message_reactions.dart (NEW)
│       └── voice_call_widget.dart (NEW)
│
└── models/
    ├── message_model.dart (EXPAND)
    └── call_model.dart (NEW)

backend/
├── services/
│   ├── MessageService.js (CREATE/ENHANCE)
│   ├── TypingService.js (NEW)
│   ├── PresenceService.js (NEW)
│   ├── EncryptionService.js (NEW)
│   └── VoiceCallService.js (NEW)
│
└── routes/
    ├── messaging.js (EXPAND with all endpoints)
    ├── typing.js (NEW)
    ├── presence.js (NEW)
    └── calls.js (NEW)
```

---

## Critical Fixes Needed

From build analysis, fix these errors first:
1. **Fix `MessagingService` syntax errors** (line 98-105)
2. **Implement actual backend endpoints** (currently all return mock data)
3. **Complete attachment service** (ServiceException undefined)
4. **Implement real-time streams** (currently return null)
5. **Add proper error handling** for all operations

---

## Database Schema Updates

```
conversations/
├── {conversationId}
│   ├── conversationId
│   ├── user1Id
│   ├── user2Id
│   ├── matchId
│   ├── lastMessage
│   ├── lastMessageSenderId
│   ├── lastMessageAt
│   ├── isPinned (NEW)
│   ├── isMuted (NEW)
│   ├── isBlocked (NEW)
│   ├── createdAt
│   └── updatedAt

messages/
├── {conversationId}
│   ├── {messageId}
│   │   ├── messageId
│   │   ├── conversationId
│   │   ├── senderId
│   │   ├── text
│   │   ├── editedText (NEW)
│   │   ├── isRead
│   │   ├── readAt
│   │   ├── sentAt
│   │   ├── quotedMessageId (NEW)
│   │   ├── reactions: {userId: emoji} (NEW)
│   │   ├── attachments[]
│   │   ├── expiresAt (NEW)
│   │   └── status: 'sending'|'sent'|'delivered'|'read'|'failed'

typing_indicators/
├── {conversationId}
│   └── {userId}: {isTyping, lastTypedAt}

presence/
├── {userId}
│   ├── status: 'online'|'away'|'offline'
│   ├── lastSeen
│   └── customStatus
```

---

## Performance Considerations

1. **Message Pagination:** Always limit to 50 messages per load (already implemented)
2. **Lazy Loading:** Load older messages on scroll up
3. **Real-time Sync:** Use Firebase listeners instead of polling
4. **Caching:** Cache conversation list locally
5. **Image Optimization:** Compress attachments before upload
6. **Indexing:** Index messages by conversationId, senderId, date for search

---

## Testing Recommendations

```
Unit Tests:
- Message CRUD operations
- Encryption/Decryption
- Typing indicator logic
- Search algorithm

Integration Tests:
- End-to-end message flow
- Read receipt propagation
- Real-time synchronization
- File upload/download

UI Tests:
- Message display formatting
- Scroll performance
- Image loading
- Notification handling
```

---

## References
- [Telegram Features](https://www.telegram.org/features)
- [WhatsApp Features](https://www.whatsapp.com/features/)
- [Firebase Realtime Database](https://firebase.google.com/docs/database)
- [WebSocket for Real-time Updates](https://socket.io/)
- [Message Encryption: TweetNaCl](https://tweetnacl.org/)
