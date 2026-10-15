# Novels Destiny - Task Tracker & Project Status

**Last Updated:** 2026-10-14  
**Project:** Novels Destiny (Flutter Novel Reading & Publishing App)  
**Backend:** Firebase (Auth, Firestore, FCM) + Supabase (Storage)

---

## 📌 Executive Summary
This document tracks the tasks, bug fixes, architecture decisions, and remaining steps so any developer or AI assistant can immediately understand project state without re-scanning all directories.

---

## ✅ Completed Tasks

### 1. Fix Discover Tab GetX Red Screen (`HomePage`)
- **Problem:** Tapping "Discover" tab displayed a red error screen: `[Get] the improper use of a GetX has been detected`.
- **Root Cause:** Redundant nested `Obx(() => ...)` wrappers inside `HomePage` (lines 91–136). The entire `body` was already enclosed in a top-level `Obx`. Nested reactive observables triggered GetX's assertion guard.
- **Resolution:** Removed inner `Obx` wrappers, replaced them with clean Dart conditionals (`if/else if/else`) and collection-if spreads (`...[ ... ]`).
- **File Modified:** [`lib/features/home/pages/home_page.dart`](file:///c:/apps/novels_destiny/lib/features/home/pages/home_page.dart)
- **Status:** **VERIFIED & PASSING** (Widget tests pass).

---

### 2. Episode Images & PDF Upload Pipeline (Supabase + Firestore)
- **Problem:** Published episodes with images or PDFs showed empty placeholder boxes to readers on other devices.
- **Root Cause:**
  1. The Supabase storage bucket (`novel-files`) had not been created.
  2. The code had a `try/catch` fallback that caught upload errors and silently saved the local device path (e.g. `/data/user/0/.../cache/image_picker_...`) into Firestore.
  3. When other users opened the episode, that local path did not exist on their phones, causing images to fail and show placeholder boxes.
- **Resolution:**
  - **`SupabaseStorageService`**:
    - All upload methods now throw clear errors (`Bucket not found`, `RLS unauthorized`) instead of silently returning local paths.
    - Validates returned URL is `http://` or `https://`.
    - Added fallback URL builder (`https://kzouhytgrcujmqmznpqt.supabase.co/storage/v1/object/public/novel-files/$cleanPath`) when client is null.
  - **`EpisodeEditorController` & `NovelEditorController`**:
    - Removed silent fallback `try/catch`. Added clear 6-second snackbar errors.
    - Added pre-publish validation: blocks publishing if any block contains a local path or lacks a cloud URL / storage path.
  - **`ContentBlockUrlResolver` & Models (`ContentBlockModel`, `NovelModel`)**:
    - Automatic healing: if Firestore contains an old local path but has `storagePath`, `fromJson` automatically derives the canonical Supabase public HTTPS URL.
- **Files Modified:**
  - [`lib/core/services/supabase_storage_service.dart`](file:///c:/apps/novels_destiny/lib/core/services/supabase_storage_service.dart)
  - [`lib/features/episode_editor/controllers/episode_editor_controller.dart`](file:///c:/apps/novels_destiny/lib/features/episode_editor/controllers/episode_editor_controller.dart)
  - [`lib/features/novel_editor/controllers/novel_editor_controller.dart`](file:///c:/apps/novels_destiny/lib/features/novel_editor/controllers/novel_editor_controller.dart)
  - [`lib/core/utils/content_block_url_resolver.dart`](file:///c:/apps/novels_destiny/lib/core/utils/content_block_url_resolver.dart)
  - [`lib/data/models/content_block_model.dart`](file:///c:/apps/novels_destiny/lib/data/models/content_block_model.dart)
  - [`lib/data/models/novel_model.dart`](file:///c:/apps/novels_destiny/lib/data/models/novel_model.dart)
- **Status:** **CODE COMPLETED & CLEAN**.

---

## ⏳ Pending User Action: Create Supabase Storage Bucket

Because the app uses **Firebase Auth** for login and **Supabase** exclusively for storage via the publishable `anon` key, Supabase sees all app uploads as the `anon` role.

### Required Bucket Specification:
| Setting | Value | Why |
|---|---|---|
| **Bucket Name** | `novel-files` | Hardcoded in `SupabaseStorageService.novelBucket` |
| **Public Bucket** | **Enabled (ON)** | Readers must view images/PDFs without login tokens |
| **File Size Limit** | `50MB` (or leave empty) | Supports high-res novel covers & multi-page PDFs |
| **Allowed MIME types** | Empty (all) or `image/*, application/pdf` | Images and documents |

### Storage Paths Used in Project:
- Novel Covers: `novels/{novelId}/cover.{ext}`
- Novel Gallery: `novels/{novelId}/gallery/image_{timestamp}.{ext}`
- Novel Complete PDF: `novels/{novelId}/documents/{fileName}`
- Episode Images: `novels/{novelId}/episodes/{episodeId}/image_{timestamp}.{ext}`
- Episode PDFs: `novels/{novelId}/episodes/{episodeId}/{fileName}`

### Supabase Setup Instructions:
1. Open **[Supabase Dashboard](https://supabase.com/dashboard)** -> Select your project (`kzouhytgrcujmqmznpqt`).
2. Navigate to **Storage** -> Click **New bucket**.
3. Name: `novel-files`.
4. Turn **Public bucket** toggle **ON**.
5. Click **Save**.
6. Go to **SQL Editor** in the left sidebar and run this script to configure permissions (RLS):

```sql
-- Allow anyone (public/readers) to view and download files
CREATE POLICY "Public Read Access"
ON storage.objects FOR SELECT
USING (bucket_id = 'novel-files');

-- Allow app clients (using anon key) to upload files
CREATE POLICY "Public Insert Access"
ON storage.objects FOR INSERT
WITH CHECK (bucket_id = 'novel-files');

-- Allow app clients to update/replace existing files (covers, etc.)
CREATE POLICY "Public Update Access"
ON storage.objects FOR UPDATE
USING (bucket_id = 'novel-files');

-- Allow app clients to delete files if needed
CREATE POLICY "Public Delete Access"
ON storage.objects FOR DELETE
USING (bucket_id = 'novel-files');
```

---

## 📋 Remaining Tasks & Verification Checklist

- [x] Fix Discover tab GetX red screen
- [x] Remove unused imports and resolve analyzer warnings
- [x] Harden Supabase Storage Service to reject local paths & throw helpful errors
- [x] Add pre-publish validation to Episode Editor & Novel Editor
- [x] Add self-healing deserialization in ContentBlockModel & NovelModel
- [ ] User creates `novel-files` bucket in Supabase Dashboard with public RLS policies
- [ ] User publishes a test episode with an image & PDF
- [ ] Verify reader device loads the image from Supabase HTTPS URL without errors
