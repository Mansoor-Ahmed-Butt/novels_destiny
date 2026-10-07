# Implementation Plan: Fix Novel Editor Back Button Crash

## Overview

This implementation plan addresses the race condition that causes the app to crash or hang when navigating back from the Novel Editor screen. The fix involves adding proper disposal guards, sequencing focus release before navigation, and using `addPostFrameCallback` for safe controller cleanup.

## Tasks

- [ ] 1. add-disposal-guards: Add disposal guards to all async operations in NovelEditorController. Add `_isDisposed` checks after every `await` point in async methods (pickAndUploadCover, pickAndAddGalleryImage, pickAndUploadPdf, saveNovel, loadExistingNovel).

- [ ] 2. fix-onclose-disposal-order: Update onClose() to set _isDisposed=true first. Ensure `_isDisposed` is set to true at the very start of `onClose()` before any controller disposal.

- [ ] 3. verify-back-navigation: Verify novel_editor_page.dart _onBack() implementation. Confirm proper sequence: FocusScope.unfocus() → Get.back() → addPostFrameCallback for safe controller deletion.

- [ ] 4. write-disposal-test: Write property-based test for disposal safety. Create test verifying async operations handle `_isDisposed` correctly with random timing variations.

- [ ] 5. test-android-device: Manual testing on Android device. Test hardware back button 10 times, upload + back 5 times. Verify no crashes/hang.

- [ ] 6. test-ios-device: Manual testing on iOS device. Test back swipe/button 10 times, upload + back 5 times. Verify no crashes/hang.

## Task Dependency Graph

```json
{
  "waves": [
    {
      "parallel": [
        "fix-onclose-disposal-order",
        "verify-back-navigation",
        "add-disposal-guards"
      ]
    },
    {
      "parallel": [
        "write-disposal-test"
      ]
    },
    {
      "parallel": [
        "test-android-device",
        "test-ios-device"
      ]
    }
  ]
}
```

## Notes

- Tasks 1, 2, and 3 can be completed in parallel (wave 1)
- Task 4 depends on Task 1 and runs in wave 2
- Tasks 5 and 6 depend on Tasks 2 and 3 and run in wave 3
- Manual testing tasks require physical devices
