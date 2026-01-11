# Offline/Online Technology Choice Analysis

## Context
Analysis of whether to use Firebase or continue with the current SQLite + Google Sheets architecture for "My Purchase" app - a free, offline-first purchase management system.

## Question
How does Firebase help with offline capabilities and online sync, and should we use it instead of our current approach?

## Firebase Offline Capabilities & Sync

### How Firebase Works

**Firebase Firestore** provides built-in offline support:

#### Offline Capabilities
- **Automatic local caching**: Firestore caches data locally in SQLite/IndexedDB
- **Offline reads**: All queries work offline using cached data
- **Offline writes**: Changes are queued and persisted locally
- **Persistence enabled by default** on mobile (Flutter/Android/iOS)

#### Online Sync
- **Automatic synchronization**: When connection restores, queued writes sync to cloud
- **Real-time listeners**: Subscribe to data changes, updates pushed to all clients
- **Conflict resolution**: Server timestamp and last-write-wins strategy
- **Optimistic updates**: UI updates immediately with local data

#### Code Example (Flutter)
```dart
// Enable offline persistence (enabled by default on mobile)
FirebaseFirestore.instance.settings = const Settings(
  persistenceEnabled: true,
  cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
);

// Query works offline automatically
final snapshot = await FirebaseFirestore.instance
  .collection('purchases')
  .get();

// Real-time sync
FirebaseFirestore.instance
  .collection('purchases')
  .snapshots()
  .listen((snapshot) {
    // Automatically updates when online/offline changes sync
  });
```

## Current Architecture

### Technology Stack
- **SQLite** for offline storage (via sqflite package)
- **Google Sheets** as backend database
- **Google Apps Script** for backend logic
- **Custom delta sync** implementation
- **Google Sign-In** for authentication

### Key Features
- 100% offline functionality
- Manual sync to Google Sheets for backup
- Users own their data in their Google account
- Zero infrastructure costs
- Full transparency (data visible in spreadsheet)

## Cost Analysis

### Google Sheets Approach (Current)
- **Storage**: Free (15GB quota across Google Drive)
- **API calls**: Free (generous quota for personal use)
- **Apps Script**: Free
- **Total cost**: $0 for most users

### Firebase Firestore
- **Free tier**: 
  - 1GB storage
  - 50,000 reads/day
  - 20,000 writes/day
  - 20,000 deletes/day
- **Paid tier** (when exceeded):
  - $0.18/GB storage/month
  - $0.06 per 100,000 reads
  - $0.18 per 100,000 writes
  - $0.02 per 100,000 deletes
- **Estimated cost for active user**: $5-20/month at scale

## Decision: Why Current Architecture is Better

### Core Requirements
1. **Free for all users** - No cost involved in storage
2. **Self-service** - Anyone can help themselves
3. **Offline-first** - Full functionality without internet
4. **Data ownership** - Users control their data

### Advantages of Current Approach

✅ **Zero Cost**
- No recurring fees
- No surprise bills when limits exceeded
- Scales with user's Google account quota

✅ **Complete Data Ownership**
- Users own their Google Sheet
- Can view/edit data directly in familiar spreadsheet interface
- Easy data export/import via CSV
- No vendor lock-in

✅ **Superior Offline Capabilities**
- Works 100% offline, no internet dependency
- Full compute power on device
- All features available offline (filtering, calculations, reports)
- Sync is optional, not required

✅ **Transparency & Control**
- Backend code visible in Apps Script
- Users can debug/modify their own backend
- Easy to understand data structure
- Can manually fix data if needed

✅ **Privacy & Security**
- No third-party data storage
- User's Google account security
- No additional privacy policies needed

### Trade-offs (Acceptable for Use Case)

⚠️ **Limitations**:
- No real-time multi-device sync (must manually sync)
- Google Sheets API quota limits (but generous for personal use)
- No built-in conflict resolution (last-write-wins with delta sync)
- Requires Google account

✅ **Why These Are Acceptable**:
- Target users: Individual/small business purchasers
- Primary use: Single device, occasional backup
- Manual sync is intentional design choice
- Google account is widely available

### When Firebase Would Make Sense

Firebase would be appropriate if:
- Need real-time collaboration across multiple users simultaneously
- Building a multi-tenant SaaS application
- Require complex role-based access control
- Have budget for infrastructure costs
- Need guaranteed uptime SLA

**None of these apply to "My Purchase" app.**

## Conclusion

The current **SQLite + Google Sheets** architecture is **optimal** for this application because:

1. **Aligns with core values**: Free, self-service, offline-first
2. **Zero cost**: Sustainable for unlimited users
3. **User empowerment**: Complete data ownership and control
4. **Technical excellence**: Superior offline capabilities
5. **Privacy-respecting**: User data stays in their Google account

Firebase would add:
- Monthly costs ($5-20+ per user)
- Cloud dependency
- Vendor lock-in
- Additional complexity

Without providing meaningful benefits for the target use case.

## Recommendation

**Continue with current architecture.** It perfectly serves the mission of providing a free, offline-first, self-service purchase management tool.

The only consideration for future: If users request real-time multi-device collaboration, evaluate peer-to-peer sync solutions (like CRDTs with WebRTC) before considering cloud services, to maintain the zero-cost model.

---

**Date**: January 9, 2026  
**Decision**: Confirmed - SQLite + Google Sheets architecture
