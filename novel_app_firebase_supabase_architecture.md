# Novel App Backend & Integration Blueprint
## Firebase Auth + Cloud Firestore + Supabase Storage + FCM + AdMob

> **Purpose:** This document is the implementation blueprint for the existing Flutter Novel Reader application.
>
> **Important:** The existing UI, theme, navigation, state-management approach, folder structure, naming conventions, reusable widgets, and coding style should be preserved. Do **not** rebuild the UI or introduce a second architecture just to implement the backend.
>
> **Primary principle:** Backend integration must fit the architecture that already exists in the project.

---

# 1. Product Overview

The application is a novel-reading platform with three roles:

### Reader
- Register/login
- Browse novels
- Open novels and episodes
- Read text content
- View images
- Open/read PDF episodes
- Bookmark novels/episodes
- Save reading progress
- Follow novels
- Receive push notifications
- Tap a notification and open the exact episode

### Writer
- Register/login
- Create/manage own novels
- Create/manage episodes
- Upload images/PDFs
- Write episode text
- Publish episodes according to the application's workflow
- Receive notifications

### Admin
- Manage users/content
- Create/upload novels and episodes
- Review writer content if approval is required
- Publish/archive content
- Manage platform content
- Receive notifications

---

# 2. Backend Architecture

Use a hybrid backend:

```text
                         FLUTTER APP
                              |
             +----------------+----------------+
             |                |                |
             v                v                v
       Firebase Auth     Cloud Firestore   Supabase Storage
           AUTH               DATA              FILES
             |                |                |
       Login/Signup       Users/Novels      Images/PDFs
       User identity      Episodes          Covers
       Roles              Blocks            Uploads
                              |
                              v
                         Firebase FCM
                       Push Notifications
                              |
                 +------------+------------+
                 |            |            |
               Reader       Writer       Admin
                 |
                 v
          Open exact episode
```

### Service responsibilities

| Service | Responsibility |
|---|---|
| Firebase Auth | Login, signup, identity |
| Firestore | Application/database records |
| Supabase Storage | Images, PDFs, files |
| Firebase FCM | Push notifications |
| AdMob | Monetization |
| Flutter | UI, state management, navigation |

---

# 3. Do Not Mix Responsibilities

### Firestore should NOT store:
- Large image binary data
- PDF binary data
- Large video/audio files

### Supabase Storage should NOT become the application's main database.

Store the file in Supabase and store its path/reference in Firestore.

Example:

```text
Supabase:
novels/novel_001/episodes/episode_027/image_001.jpg

Firestore:
storagePath:
novels/novel_001/episodes/episode_027/image_001.jpg
```

---

# 4. Existing Flutter Architecture

## Critical rule

Before creating new folders/classes:

1. Inspect the existing project.
2. Identify the current architecture.
3. Identify whether the project uses GetX, Bloc, Provider, Riverpod, etc.
4. Identify existing:
   - routes
   - controllers/blocs
   - repositories
   - services
   - models
   - dependency injection
   - theme
   - constants
   - reusable widgets
5. Extend the existing architecture.

### If the existing project uses GetX

Use the existing GetX conventions.

For example, if the current project follows:

```text
features/
  auth/
    data/
    domain/
    presentation/
```

continue using that structure.

If it already uses:

```text
controllers/
services/
views/
widgets/
models/
```

continue that convention instead.

### Do NOT

- Introduce Bloc only for the backend
- Introduce Riverpod only for notifications
- Create a second navigation system
- Create a second theme
- Rewrite existing UI
- Duplicate services
- Put Firebase/Supabase code directly into widgets

---

# 5. Recommended Dependency Set

The project already has Firebase dependencies.

Keep:

```yaml
firebase_core:
firebase_auth:
cloud_firestore:
firebase_messaging:
```

Add:

```yaml
supabase_flutter:
```

For file selection:

```yaml
image_picker:
file_picker:
```

For PDF viewing, use the PDF package already selected by the project if one exists. Otherwise select a maintained package compatible with the project's Flutter/Dart version.

For AdMob:

```yaml
google_mobile_ads:
```

For local notification presentation, only add/use:

```yaml
flutter_local_notifications:
```

if the existing project needs foreground notification display or local notification handling.

### Do not use

```yaml
firebase_storage:
```

because Supabase Storage is handling uploaded files.

### Important

Use `flutter pub add <package>` and verify package compatibility rather than blindly copying version numbers from this document.

---

# 6. Firebase Initialization

Initialize Firebase before using Firebase services.

Preferred structure:

```dart
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await Supabase.initialize(
    url: AppConstants.supabaseUrl,
    anonKey: AppConstants.supabaseAnonKey,
  );

  runApp(const MyApp());
}
```

Adapt this to the project's existing bootstrap/dependency-injection structure.

Do not initialize services repeatedly from individual screens.

---

# 7. Secrets and Security

## Never put these in the Flutter application

- Firebase service-account private keys
- Firebase Admin SDK private credentials
- Supabase `service_role` key
- Private backend API secrets

The mobile application is a client and anything shipped inside it can potentially be extracted.

The Supabase client application may use the public/anonymous client key, but **Storage policies must protect the data**.

Firebase Firestore Security Rules must protect Firestore.

---

# 8. Authentication Architecture

Firebase Auth is responsible for identity.

Flow:

```text
Signup
  |
  v
Firebase Auth creates user
  |
  v
Firebase UID
  |
  v
Create users/{uid} in Firestore
```

Example:

```text
users/{uid}

{
  uid: "firebase_uid",
  name: "Mansoor",
  email: "user@example.com",
  role: "reader",
  photoUrl: null,
  createdAt: Timestamp,
  updatedAt: Timestamp
}
```

Possible roles:

```text
reader
writer
admin
```

## Important security rule

Do not rely on:

```text
role == "admin"
```

inside Flutter for security.

Flutter can hide/show UI, but authorization must be enforced by backend rules.

For high-privilege operations, use Firebase custom claims and/or trusted backend code.

---

# 9. Firestore Data Model

Recommended collections:

```text
users
novels
episodes
reading_progress
bookmarks
novel_followers
device_tokens
notifications
ad_config
```

Optional later:

```text
reports
comments
likes
categories
genres
```

---

# 10. Users

Path:

```text
users/{uid}
```

Example:

```json
{
  "uid": "abc123",
  "name": "Mansoor",
  "email": "mansoor@example.com",
  "role": "reader",
  "photoUrl": null,
  "createdAt": "serverTimestamp",
  "updatedAt": "serverTimestamp"
}
```

Use the Firebase Auth UID as the document ID.

---

# 11. Novels

Path:

```text
novels/{novelId}
```

Example:

```json
{
  "title": "The Last Kingdom",
  "description": "A fantasy novel...",
  "authorId": "writer_uid",
  "coverImagePath": "novels/novel_001/cover.jpg",
  "status": "published",
  "createdAt": "serverTimestamp",
  "updatedAt": "serverTimestamp",
  "publishedAt": "serverTimestamp"
}
```

Possible status:

```text
draft
pending_review
published
archived
```

Do not put every episode inside the novel document.

---

# 12. Episodes

Path:

```text
episodes/{episodeId}
```

Example:

```json
{
  "novelId": "novel_001",
  "title": "Episode 27",
  "episodeNumber": 27,
  "authorId": "writer_uid",
  "status": "published",
  "createdAt": "serverTimestamp",
  "updatedAt": "serverTimestamp",
  "publishedAt": "serverTimestamp"
}
```

Useful queries:

```text
episodes where novelId == novel_001
orderBy episodeNumber
```

For published episodes:

```text
novelId == novel_001
status == published
orderBy episodeNumber
```

Firestore may require composite indexes for certain combinations.

---

# 13. Episode Content: Use Blocks

This is one of the most important decisions in the architecture.

Do NOT store an episode only as:

```text
content: "a huge string..."
```

because the application will later need:

- Images inside episodes
- PDF content
- Ads between paragraphs
- Different content types
- Future rich formatting

Use ordered content blocks.

Recommended:

```text
episodes/{episodeId}/blocks/{blockId}
```

Each block:

```json
{
  "type": "text",
  "order": 1,
  "content": "The night was unusually quiet..."
}
```

Supported types:

```text
text
image
pdf
ad
```

Example episode:

```text
Episode 27

Block 1 -> text
Block 2 -> text
Block 3 -> image
Block 4 -> text
Block 5 -> ad
Block 6 -> text
Block 7 -> pdf
Block 8 -> text
```

This allows the reader to render the episode sequentially.

---

# 14. Text Block

```json
{
  "type": "text",
  "order": 1,
  "content": "The night was unusually quiet..."
}
```

If rich text is needed later, use a structured representation compatible with the editor/reader rather than creating one massive HTML/string field.

---

# 15. Image Block

```json
{
  "type": "image",
  "order": 3,
  "storagePath": "novels/novel_001/episodes/episode_027/image_001.jpg",
  "caption": "The old castle"
}
```

Actual file:

```text
Supabase Storage
novel-files/
  novels/novel_001/
    episodes/episode_027/
      image_001.jpg
```

---

# 16. PDF Block

```json
{
  "type": "pdf",
  "order": 7,
  "storagePath": "novels/novel_001/episodes/episode_027/episode.pdf",
  "fileName": "episode_027.pdf"
}
```

Actual PDF stays in Supabase Storage.

---

# 17. Ad Block

An ad block can be represented as:

```json
{
  "type": "ad",
  "order": 5,
  "placement": "inline"
}
```

Do not hard-code ad positions into every episode.

Better:

```text
Episode blocks
      |
      +-- text
      +-- text
      +-- image
      +-- text
      +-- ad
      +-- text
```

Later the application can support configurable rules such as:

```text
Ad after N paragraphs
Ad between selected blocks
Ad between episodes
```

Always implement ads according to current Google AdMob policies.

---

# 18. Supabase Storage

Create a bucket:

```text
novel-files
```

Recommended structure:

```text
novels/
  {novelId}/
    cover.jpg

    episodes/
      {episodeId}/
        image_001.jpg
        image_002.jpg
        episode.pdf
```

Example:

```text
novel-files/
  novels/
    novel_001/
      cover.jpg
      episodes/
        episode_027/
          image_001.jpg
          image_002.jpg
          episode.pdf
```

---

# 19. Upload Flow

Writer/Admin:

```text
Select image/PDF
      |
      v
Validate file
      |
      v
Generate deterministic storage path
      |
      v
Upload to Supabase Storage
      |
      v
Get storage path/URL
      |
      v
Save metadata in Firestore
```

Recommended:

```text
Upload file first
       |
       v
Create/update Firestore block
```

If Firestore fails after the upload, the implementation should have cleanup/retry handling so orphaned files do not accumulate.

---

# 20. Storage Security

Do not make all files publicly writable.

Use Supabase Storage policies/RLS according to the application's roles.

Conceptually:

### Reader

```text
READ published files
NO WRITE
NO DELETE
```

### Writer

```text
READ permitted files
UPLOAD own content
UPDATE/delete own draft files
```

### Admin

```text
READ
UPLOAD
UPDATE
DELETE
```

The exact policy should be based on how Firebase identity is connected to Supabase authorization.

Do not assume that a Flutter-side `role` variable is enough to secure Supabase Storage.

---

# 21. Important Hybrid Authentication Consideration

Firebase Auth and Supabase Auth are separate authentication systems.

Because this application uses:

```text
Firebase Auth
+
Supabase Storage
```

do not assume that Supabase Storage automatically knows the Firebase user's role.

There are two practical approaches.

## Approach A — Public read bucket + controlled upload through trusted backend

Good for a simple MVP.

```text
Flutter
  |
  | Firebase Auth
  v
Authenticated user
  |
  v
Trusted backend operation
  |
  v
Supabase Storage
```

This is safer for writer/admin uploads.

## Approach B — Integrate Firebase JWT with Supabase authorization

This is more advanced and should be implemented only after understanding Supabase JWT/RLS integration.

For the first version, keep the security design simple and test it thoroughly.

---

# 22. Reading Progress

Collection:

```text
reading_progress/{uid_episodeId}
```

Example:

```json
{
  "userId": "reader_uid",
  "novelId": "novel_001",
  "episodeId": "episode_027",
  "blockId": "block_006",
  "progressPercent": 63,
  "updatedAt": "serverTimestamp"
}
```

The reader can resume from approximately the same location.

For long episodes, do not write to Firestore on every scroll event.

Instead:

```text
Scroll
  |
  v
Update local state
  |
  v
Debounce/throttle
  |
  v
Save progress periodically
```

---

# 23. Bookmarks

Collection:

```text
bookmarks/{bookmarkId}
```

Example:

```json
{
  "userId": "reader_uid",
  "novelId": "novel_001",
  "episodeId": "episode_027",
  "blockId": "block_006",
  "createdAt": "serverTimestamp"
}
```

If the application only needs episode-level bookmarks, omit `blockId`.

---

# 24. Novel Followers

Collection:

```text
novel_followers/{followerId}
```

Example:

```json
{
  "userId": "reader_uid",
  "novelId": "novel_001",
  "createdAt": "serverTimestamp"
}
```

This allows:

```text
Reader follows Novel A
       |
       v
Episode published
       |
       v
Notify followers of Novel A
```

This is better than sending every novel notification to every user.

---

# 25. FCM Device Tokens

Collection:

```text
device_tokens/{tokenId}
```

Example:

```json
{
  "userId": "user_uid",
  "token": "FCM_DEVICE_TOKEN",
  "platform": "android",
  "updatedAt": "serverTimestamp"
}
```

One user can have multiple devices:

```text
User
 ├── Android phone
 ├── Tablet
 └── Other phone
```

Therefore do not model it as one token per user.

On login/app start:

```text
Get FCM token
      |
      v
Save/update token in Firestore
```

Also handle token refresh.

---

# 26. Notification Architecture

Recommended notification flow:

```text
Writer/Admin publishes episode
             |
             v
Trusted backend/server logic
             |
             v
Find intended recipients
             |
             v
FCM
             |
             v
Reader/Writer/Admin devices
```

Do NOT send FCM messages directly from the Flutter client using privileged credentials.

---

# 27. Notification Payload

Use a data payload that identifies the exact destination.

Example:

```json
{
  "type": "new_episode",
  "novelId": "novel_001",
  "episodeId": "episode_027"
}
```

Notification text:

```text
Title:
New Episode Released

Body:
The Last Kingdom — Episode 27 is now available.
```

---

# 28. Notification Tap Navigation

The key flow:

```text
User taps notification
        |
        v
FCM returns data
        |
        v
type = new_episode
novelId = novel_001
episodeId = episode_027
        |
        v
Existing app router/navigation
        |
        v
Novel/Episode Reader Page
        |
        v
Load episode_027
```

Use the application's existing navigation architecture.

If the project uses GetX:

```text
Get.to(...)
Get.off(...)
Get.toNamed(...)
```

only if that matches the existing routing convention.

If the project uses GoRouter, use its existing route system.

Do not introduce another navigation library.

---

# 29. Notification States

FCM handling must account for:

### Foreground

App is open.

```text
FCM message
   |
   v
App receives message
   |
   v
Show appropriate in-app/local notification
```

### Background

App is running in background.

```text
Notification
   |
   v
User taps
   |
   v
Read payload
   |
   v
Navigate to episode
```

### Terminated

App was completely closed.

```text
User taps notification
   |
   v
App starts
   |
   v
Read initial notification message
   |
   v
Wait until dependencies/navigation are ready
   |
   v
Navigate to exact episode
```

Test all three states.

---

# 30. Notification Collection

Firestore can keep an in-app notification history:

```text
notifications/{notificationId}
```

Example:

```json
{
  "userId": "reader_uid",
  "type": "new_episode",
  "title": "New Episode Released",
  "body": "The Last Kingdom — Episode 27 is now available.",
  "novelId": "novel_001",
  "episodeId": "episode_027",
  "isRead": false,
  "createdAt": "serverTimestamp"
}
```

FCM is the delivery mechanism.

Firestore is the persistent notification history.

They have different purposes.

---

# 31. How to Trigger Notifications Safely

Recommended production flow:

```text
Episode published
       |
       v
Trusted backend
       |
       +--> Create notification records
       |
       +--> Determine recipients
       |
       +--> Send FCM
```

Possible trusted backend options:

```text
Firebase Cloud Functions
OR
another secure backend/server
```

Do not put FCM server credentials in Flutter.

---

# 32. Publishing Workflow

Recommended:

```text
Writer creates episode
        |
        v
Draft
        |
        v
Upload text/images/PDF
        |
        v
Save blocks
        |
        v
Pending review (optional)
        |
        v
Admin approves
        |
        v
Published
        |
        v
Trusted backend triggers FCM
        |
        v
Followers receive notification
```

If the product does not require review:

```text
Writer
  |
  v
Publish
  |
  v
FCM notification
```

---

# 33. Reader Screen Rendering

The reader should receive ordered blocks:

```text
episode
   |
   +-- block 1
   +-- block 2
   +-- block 3
   +-- block 4
```

Pseudo-logic:

```text
for block in blocks:

    if block.type == text:
        render paragraph

    if block.type == image:
        load Supabase image

    if block.type == pdf:
        open PDF viewer

    if block.type == ad:
        render configured AdMob placement
```

This keeps the reader flexible.

---

# 34. AdMob Architecture

AdMob should be isolated behind an application service/repository instead of being initialized from random screens.

Conceptually:

```text
AdService
   |
   +-- initialize()
   +-- loadBanner()
   +-- showInterstitial()
   +-- dispose()
```

Use the existing dependency/service architecture.

---

# 35. Recommended Ad Placement

For a novel reader, prioritize reading experience.

Possible placements:

```text
Novel list
   |
   +-- Banner

Episode reader
   |
   +-- Content
   +-- controlled inline ad
   +-- Content

After episode
   |
   +-- optional interstitial
   +-- next episode
```

Avoid:

```text
Paragraph
Ad
Paragraph
Ad
Paragraph
Ad
```

because it destroys readability and may create policy/user-experience problems.

---

# 36. Dynamic Ad Configuration

Do not hard-code every ad decision.

A Firestore configuration can eventually look like:

```text
ad_config/global
```

Example:

```json
{
  "adsEnabled": true,
  "inlineAdsEnabled": true,
  "interstitialEnabled": true,
  "paragraphInterval": 8
}
```

The app can read configuration and apply it.

However, the final implementation must still comply with AdMob policies.

---

# 37. Ad Strategy Recommendation

For the first release:

```text
Version 1:
- Banner ads
- Conservative interstitials
```

Later:

```text
Version 2:
- Better inline placement
- Remote configuration
- User subscription/ad-free option if desired
```

Do not build an overly complicated ad engine before the core reading experience is stable.

---

# 38. End-to-End: Writer Uploads a Text Episode

```text
Writer
  |
  v
Create Episode
  |
  v
Write paragraphs
  |
  v
Create text blocks
  |
  v
Save Firestore
  |
  v
Publish
  |
  v
Trusted backend
  |
  v
FCM
  |
  v
Followers receive notification
  |
  v
Tap notification
  |
  v
Episode Reader
```

---

# 39. End-to-End: Writer Uploads Image/PDF

```text
Writer
  |
  v
Select image/PDF
  |
  v
Flutter validates file
  |
  v
Supabase Storage upload
  |
  v
Receive storage path
  |
  v
Create Firestore block
  |
  v
Publish episode
  |
  v
FCM notification
```

---

# 40. End-to-End: Reader Opens Episode

```text
Notification
    |
    v
FCM data:
episodeId
novelId
    |
    v
Existing Flutter router
    |
    v
Episode Reader
    |
    v
Firestore:
episode metadata + blocks
    |
    +--> text
    |
    +--> Supabase image
    |
    +--> Supabase PDF
    |
    +--> AdMob
```

---

# 41. Recommended Flutter Layering

Adapt to the project's current architecture.

A clean logical separation is:

```text
Presentation
    |
    v
Controller / Bloc / ViewModel
    |
    v
Repository
    |
    +--> Firebase Auth datasource
    +--> Firestore datasource
    +--> Supabase datasource
    +--> FCM service
    +--> Ad service
```

The UI should not directly contain:

```dart
FirebaseFirestore.instance.collection(...)
```

everywhere.

Instead:

```text
UI
 ↓
Controller/Bloc
 ↓
Repository
 ↓
Data source/service
 ↓
Firebase/Supabase
```

This makes testing and future changes easier.

---

# 42. Suggested Feature Organization

If the existing project already has a feature-based architecture, extend it approximately like this:

```text
lib/
  core/
    constants/
    errors/
    services/
      notification_service.dart
      supabase_storage_service.dart
      ad_service.dart
    utils/

  features/
    auth/
      data/
      domain/
      presentation/

    novels/
      data/
      domain/
      presentation/

    episodes/
      data/
      domain/
      presentation/

    reader/
      data/
      domain/
      presentation/

    writer/
      data/
      domain/
      presentation/

    admin/
      data/
      domain/
      presentation/

    notifications/
      data/
      domain/
      presentation/
```

**Do not copy this blindly.** If the existing application uses a different structure, preserve that structure.

---

# 43. Models

Recommended models:

```text
UserModel
NovelModel
EpisodeModel
EpisodeBlockModel
ReadingProgressModel
BookmarkModel
NovelFollowerModel
DeviceTokenModel
NotificationModel
AdConfigModel
```

For blocks, use a discriminated type:

```text
EpisodeBlock
   |
   +-- TextBlock
   +-- ImageBlock
   +-- PdfBlock
   +-- AdBlock
```

If the existing project does not use sealed classes/freezed, keep the model style consistent with the existing codebase.

---

# 44. Error Handling

Handle separately:

```text
Firebase Auth error
Firestore error
Supabase upload error
File picker error
Network error
FCM error
AdMob error
PDF loading error
```

The user should not see raw exception messages.

Example:

```text
Upload failed.
Please check your internet connection and try again.
```

Log technical details through the project's existing logging approach.

---

# 45. Offline and Network Behavior

The reader should handle temporary network failure gracefully.

Recommended:

```text
Firestore cache
+
local state
+
retry
```

For uploaded files:

```text
Upload
  |
  +-- success -> save metadata
  |
  +-- failure -> show retry
```

Do not mark an episode as successfully published if required file uploads failed.

---

# 46. Atomic Publishing Concept

Publishing should be treated as a controlled operation.

Bad flow:

```text
Publish
  |
  v
Set status = published
  |
  v
Upload files
```

This can produce broken published episodes.

Better:

```text
Validate content
      |
      v
Upload required files
      |
      v
Create/update blocks
      |
      v
Validate episode
      |
      v
Set status = published
      |
      v
Trigger notification
```

---

# 47. File Validation

Before upload:

### Images

Check:

```text
file type
file size
extension
```

### PDFs

Check:

```text
file type
file size
extension
```

Set reasonable limits.

Example policy (adjust for the actual product):

```text
Image: maximum 10 MB
PDF: maximum 25–50 MB
```

Do not trust only the file extension. Validate MIME/type where possible.

---

# 48. File Naming

Avoid user-provided names directly as paths.

Prefer deterministic paths:

```text
novels/{novelId}/cover.jpg
novels/{novelId}/episodes/{episodeId}/image_{index}.jpg
novels/{novelId}/episodes/{episodeId}/episode.pdf
```

This prevents confusing storage structures and makes cleanup easier.

---

# 49. Security Rules Concept

## Firestore

Readers:

```text
READ published novels/episodes
READ own progress/bookmarks
WRITE own progress/bookmarks
```

Writers:

```text
READ published content
CREATE own novels
UPDATE own novels
CREATE/update own draft episodes
```

Admins:

```text
MANAGE platform content
```

Exact Firestore rules must be implemented based on the final schema.

## Supabase

Readers:

```text
READ permitted files
```

Writers:

```text
UPLOAD/manage own permitted files
```

Admins:

```text
FULL content management
```

Never rely on client-side role checks alone.

---

# 50. Role Management

The UI can use:

```text
role = reader
role = writer
role = admin
```

to decide what screens to display.

But security must exist independently:

```text
Flutter UI
     |
     | client-side convenience
     v
Show/hide features

Backend rules
     |
     | actual security
     v
Allow/deny operation
```

---

# 51. Admin Security

Admin accounts should NOT be created by allowing any user to select:

```text
role = admin
```

during signup.

Recommended:

```text
User signs up
     |
     v
role = reader
     |
     v
Trusted admin process promotes user
```

For production, consider Firebase custom claims for privileged authorization.

---

# 52. Notification Recipient Strategy

Do not permanently send every episode notification to every user.

Recommended:

```text
Reader follows novel
       |
       v
novel_followers
       |
       v
Episode published
       |
       v
Find followers
       |
       v
FCM
```

For global announcements:

```text
Admin announcement
       |
       v
FCM topic or targeted recipients
```

Topics can be useful for public subscription groups.

---

# 53. Notification Data Must Be Deep-Link Friendly

Every notification should contain enough information to reach the destination.

For a new episode:

```json
{
  "type": "new_episode",
  "novelId": "novel_001",
  "episodeId": "episode_027"
}
```

For a novel:

```json
{
  "type": "novel",
  "novelId": "novel_001"
}
```

For an admin announcement:

```json
{
  "type": "announcement",
  "notificationId": "notification_123"
}
```

---

# 54. Deep-Link/Navigation Handler

Create one central notification navigation handler rather than writing navigation logic in every screen.

Concept:

```text
NotificationService
      |
      v
NotificationRouter
      |
      +-- new_episode -> EpisodeReader
      +-- novel -> NovelDetails
      +-- announcement -> NotificationDetails
```

This avoids duplicated navigation code.

---

# 55. App Startup Sequence

Recommended:

```text
App starts
   |
   v
WidgetsFlutterBinding
   |
   v
Firebase initialization
   |
   v
Supabase initialization
   |
   v
Dependency injection
   |
   v
FCM initialization
   |
   v
Auth state check
   |
   v
Existing router decides initial page
```

If a notification launched the app:

```text
App starts
   |
   v
Capture notification payload
   |
   v
Wait for app/router initialization
   |
   v
Navigate to destination
```

Do not navigate before the navigation system is ready.

---

# 56. Development Phases

Do not implement everything at once.

## Phase 1 — Backend foundation

Implement:

```text
Firebase initialization
Supabase initialization
Firebase Auth
Firestore
```

Verify:

```text
Signup
Login
Logout
User document
Role
```

---

## Phase 2 — Novel management

Implement:

```text
Create novel
Update novel
Novel list
Novel details
Cover upload
```

---

## Phase 3 — Episode system

Implement:

```text
Create episode
Draft
Text blocks
Image blocks
PDF blocks
Episode list
Episode reader
```

---

## Phase 4 — Supabase Storage

Implement:

```text
Image upload
PDF upload
File validation
Storage paths
Cleanup on failed operation
```

---

## Phase 5 — Reading features

Implement:

```text
Reading progress
Bookmarks
Novel following
```

---

## Phase 6 — FCM

Implement:

```text
Permission request
FCM token
Token storage
Foreground handling
Background handling
Terminated-state handling
Notification tap navigation
```

---

## Phase 7 — Publishing notifications

Implement trusted backend logic:

```text
Episode published
       |
       v
Find recipients
       |
       v
Create notification records
       |
       v
Send FCM
```

---

## Phase 8 — AdMob

Only after the reader experience is stable:

```text
AdMob initialization
Banner
Interstitial
Controlled inline placement
Remote configuration if needed
```

---

# 57. Testing Checklist

## Authentication

- [ ] Signup
- [ ] Login
- [ ] Logout
- [ ] Password reset
- [ ] Auth state persistence
- [ ] Correct role
- [ ] Unauthorized operations blocked

## Novels

- [ ] Create
- [ ] Update
- [ ] Publish
- [ ] Archive
- [ ] Cover upload

## Episodes

- [ ] Create draft
- [ ] Add text
- [ ] Add image
- [ ] Add PDF
- [ ] Reorder blocks
- [ ] Publish
- [ ] Reader can open

## Storage

- [ ] Upload image
- [ ] Upload PDF
- [ ] Invalid file rejected
- [ ] Large file rejected
- [ ] Unauthorized upload blocked
- [ ] Failed upload cleaned up

## Reader

- [ ] Text renders
- [ ] Images render
- [ ] PDFs open
- [ ] Progress saves
- [ ] Bookmark works
- [ ] Follow/unfollow works

## FCM

- [ ] Permission
- [ ] Token creation
- [ ] Token refresh
- [ ] Foreground notification
- [ ] Background notification
- [ ] Terminated notification
- [ ] Notification tap
- [ ] Exact episode opens

## AdMob

- [ ] Test ads during development
- [ ] Banner
- [ ] Interstitial
- [ ] Ad failure doesn't break reader
- [ ] Placement doesn't obstruct content
- [ ] Production ad IDs configured only for release

---

# 58. Important Production Rules

1. Never ship Firebase service-account credentials.
2. Never ship a Supabase service-role key.
3. Never trust client-side admin checks.
4. Never put large files directly in Firestore.
5. Never send FCM using server credentials from Flutter.
6. Never mark an episode published before required files/content are ready.
7. Do not save reading progress on every scroll event.
8. Handle multiple FCM tokens per user.
9. Handle notification taps when the app is foreground, background, and terminated.
10. Use test AdMob ads during development.
11. Keep the existing app theme/UI unchanged unless a feature genuinely requires a UI addition.
12. Follow the existing project architecture and naming conventions.

---

# 59. Recommended Final Architecture

```text
                           FLUTTER APP
                                |
       +------------------------+------------------------+
       |                        |                        |
       v                        v                        v
 Firebase Auth             Firestore              Supabase Storage
       |                        |                        |
       |                   +----+----+                   |
       |                   |         |                   |
       |                 Novels   Episodes               |
       |                           |                     |
       |                         Blocks                  |
       |                           |                     |
       |                      Progress                   |
       |                      Bookmarks                  |
       |                      Followers                  |
       |                      Tokens                     |
       |                      Notifications              |
       |                                                  |
       |                                                  |
       +-------------------------+------------------------+
                                 |
                                 v
                           Backend Logic
                       Firebase Functions /
                         secure backend
                                 |
                    +------------+------------+
                    |                         |
                    v                         v
                  FCM                      AdMob
                    |
                    v
           Reader / Writer / Admin
                    |
                    v
             Exact episode page
```

---

# 60. Example Complete Episode

Firestore:

```text
episodes/episode_027
```

```json
{
  "novelId": "novel_001",
  "title": "The Last Kingdom",
  "episodeNumber": 27,
  "authorId": "writer_123",
  "status": "published",
  "publishedAt": "serverTimestamp"
}
```

Blocks:

```text
episodes/episode_027/blocks/001

{
  "type": "text",
  "order": 1,
  "content": "The night was unusually quiet..."
}
```

```text
episodes/episode_027/blocks/002

{
  "type": "text",
  "order": 2,
  "content": "He slowly walked toward the door..."
}
```

```text
episodes/episode_027/blocks/003

{
  "type": "image",
  "order": 3,
  "storagePath": "novels/novel_001/episodes/episode_027/image_001.jpg"
}
```

```text
episodes/episode_027/blocks/004

{
  "type": "text",
  "order": 4,
  "content": "A strange sound came from outside..."
}
```

```text
episodes/episode_027/blocks/005

{
  "type": "ad",
  "order": 5,
  "placement": "inline"
}
```

```text
episodes/episode_027/blocks/006

{
  "type": "text",
  "order": 6,
  "content": "He opened the door..."
}
```

Supabase:

```text
novel-files/
  novels/
    novel_001/
      episodes/
        episode_027/
          image_001.jpg
          episode.pdf
```

Notification:

```json
{
  "type": "new_episode",
  "novelId": "novel_001",
  "episodeId": "episode_027"
}
```

The reader taps the notification and the application opens:

```text
Novel Details
     |
     v
The Last Kingdom
     |
     v
Episode 27
     |
     v
Reader
```

---

# 61. Implementation Instruction for the Coding Model

When implementing this document in the existing Flutter project:

### FIRST

Inspect the existing source code and determine:

```text
- Architecture
- State management
- Routing
- Dependency injection
- Theme
- Models
- Services
- Existing Firebase setup
- Existing UI
```

### SECOND

Do not replace the existing architecture.

Extend it.

### THIRD

Implement in this order:

```text
1. Firebase initialization
2. Supabase initialization
3. Auth integration
4. Firestore repositories
5. Supabase storage service
6. Novel models/repositories
7. Episode models/repositories
8. Content block system
9. Reader integration
10. Progress/bookmarks/following
11. FCM service
12. Notification routing
13. Secure backend notification trigger
14. AdMob service
15. Ad placement
16. Security rules/policies
17. Testing
```

### FOURTH

After every major feature:

```text
Run analyzer
Run tests
Run on Android device
Verify Firebase/Supabase data
Verify security behavior
```

### FIFTH

Do not modify existing screens unnecessarily.

If a new backend feature needs a UI change, integrate it into the existing theme and reusable components.

---

# 62. Final Design Principle

The application should behave as if it has one backend from the Flutter developer's perspective:

```text
Flutter
  |
  v
Repositories / Services
  |
  +--> Firebase Auth
  +--> Firestore
  +--> Supabase Storage
  +--> FCM
  +--> AdMob
```

The user should never need to know which backend service stores which piece of information.

The architecture should remain:

```text
Simple
Secure
Testable
Scalable
Consistent with the existing project
```

The most important data design decision is:

```text
Firestore = metadata + structured application data
Supabase = actual files
FCM = delivery of push notifications
AdMob = advertising
Firebase Auth = identity
```

And the most important content design decision is:

```text
Episode
   |
   +-- ordered text block
   +-- ordered image block
   +-- ordered PDF block
   +-- ordered ad block
```

That structure supports the current requirements while leaving room for future features without rebuilding the reader system.
