# Implementation Plan & Task Progress

This document tracks all 6 bug fixes and feature enhancements requested by the user.

---

## Task 1: Novel Details Delete Loader & Navigation
- **File**: `lib/features/novels/pages/novel_details_page.dart` & `lib/features/novels/controllers/novel_details_controller.dart`
- **Issue**:
  When clicking "Delete Novel" -> "Delete Novel & Files", the novel gets deleted in the background, but the user remains stuck on the same page with no visual feedback.
- **Requirement**:
  1. Display a visible circular progress indicator / loading state while deletion is in progress.
  2. Once deleted, navigate back cleanly (or navigate to Writer Dashboard / pop back to previous screen).
  3. Ensure any active controllers (HomeController, WriterDashboardController, AdminDashboardController) are notified so the deleted novel is purged from their lists immediately.
- **Status**: [Completed]

---

## Task 2: Admin Dashboard Novel Deletion Loading State
- **File**: `lib/features/admin_dashboard/pages/admin_dashboard_page.dart` & `lib/features/admin_dashboard/controllers/admin_dashboard_controller.dart`
- **Issue**:
  When an admin clicks "Delete" -> "Delete Novel & Files", the popup closes immediately, but the screen has no progress indicator while Supabase storage and Firestore documents are being removed. The deletion takes several seconds.
- **Requirement**:
  Display a circular indicator overlay / loading state while `deleteNovel` is working until the list and analytics have completely refreshed.
- **Status**: [Completed]

---

## Task 3: Profile Sign Out Loader
- **File**: `lib/features/profile/pages/profile_page.dart` & `lib/features/profile/controllers/profile_controller.dart`
- **Issue**:
  When clicking "sign_out_of_account", there is no loading indicator while Firebase/Google sign out runs and authentication state transitions.
- **Requirement**:
  Display a loading indicator / loader overlay until sign out completes and navigation to Auth screen is complete.
- **Status**: [Completed]

---

## Task 4: Restore Speech Dictation (Speak & Listen: English & Urdu) in Novel Editor / Writer Flow
- **File**: `lib/features/novel_editor/pages/novel_editor_page.dart`
- **Issue**:
  The `VoiceDictationButton` was previously present for "The Hook" (blurb/description) and "Full Novel Story" (manuscript), allowing writers and admins to toggle between English (`EN`) and Urdu (`اردو`) and speak to auto-type in the selected language. It was accidentally omitted in a recent commit.
- **Requirement**:
  Restore `VoiceDictationButton` to "The Hook" and "Full Novel Story" with English/Urdu toggle and pulsing microphone indicator, matching the user's screenshot and `episode_editor_page.dart`.
- **Status**: [Completed]

---

## Task 5: Fix Double API Call / Screen Refresh When Publishing Episode
- **File**: `lib/features/episode_editor/controllers/episode_editor_controller.dart` & `lib/features/writer_dashboard/controllers/writer_dashboard_controller.dart`
- **Issue**:
  When publishing an episode:
  1. `EpisodeEditorController.saveEpisode` called `Get.find<WriterDashboardController>().loadDashboard()`.
  2. Then `Get.back()` popped the screen.
  3. Then the awaiting method `createEpisode` in `WriterDashboardController` called `loadDashboard()` again.
  This caused 2 back-to-back API calls, 2 screen refreshes, and flickering loaders.
- **Requirement**:
  Streamline the refresh so `loadDashboard()` is triggered exactly once upon return, eliminating redundant network calls and double screen redraws.
- **Status**: [Completed]

---

## Task 6: Discover Screen Stale Novels After Deletion
- **File**: `lib/features/main_shell/main_shell_page.dart`, `lib/features/home/controllers/home_controller.dart`, `lib/features/home/pages/home_page.dart`
- **Issue**:
  After deleting novels, visiting the Discover screen still showed the deleted novels until the user manually dragged down to pull-to-refresh.
  Root causes:
  1. `MainShellPage._triggerTabRefresh` did not include `/home` (Discover tab).
  2. `HomeController.openNovel` did not await returning to refresh data.
  3. `HomeController` was not invalidated/updated when a novel was deleted anywhere in the app.
- **Requirement**:
  1. Add `/home` to `MainShellPage._triggerTabRefresh` so selecting the Discover tab always ensures fresh data.
  2. In `HomeController.openNovel`, await the details page and reload upon return.
  3. Whenever a novel is deleted (from Admin, Writer, or Novel Details), immediately remove it from `HomeController`'s in-memory lists (`featuredNovels`, `trendingNovels`, `genreNovels`, etc.) and/or trigger a background reload so the user never sees deleted stories.
- **Status**: [Completed]
