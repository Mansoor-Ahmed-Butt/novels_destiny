# Novel Editor Navigation Crash Fix

## Overview
Fix the app crash that occurs when navigating back from the Create Novel Draft screen. The issue is caused by a race condition between TextEditingController disposal and navigation lifecycle.

## Implementation Plan:

This spec fixes a critical crash when users navigate back from the "Create Novel Draft" screen. The root cause is a timing collision between TextEditingController disposal in `onClose()` and TextFields unmounting from the widget tree. The solution defers TextEditingController disposal using `Future.microtask()` to ensure the widget tree completes unmounting first.

### Key Changes
- Modify `NovelEditorController.onClose()` to defer TextEditingController disposal
- Use `Future.microtask()` for safe timing after widget unmount
- Keep existing `_isDisposed` safety checks in async methods
- Ensure all async operations properly check the disposed flag

### Files Modified
- `lib/features/novel_editor/controllers/novel_editor_controller.dart`

## Task Dependency Graph

```json
{
  "waves": [
    {
      "tasks": ["1"]
    },
    {
      "tasks": ["2"]
    }
  ]
}
```

## Tasks

- [x] 1. Fix Novel Editor Controller Disposal (implementation)
  - **Required**: Yes
  - **Description**: Modify the `onClose()` method to defer TextEditingController disposal using `Future.microtask()`, preventing race conditions with widget unmounting during navigation.
  - **File(s)**: `lib/features/novel_editor/controllers/novel_editor_controller.dart`
  - **Requires**: N/A
  - **Validates**: TextEditingController lifecycle, back button functionality, no assertions on dispose

- [ ] 2. Verify Navigation State Management (testing)
  - **Required**: Yes
  - **Description**: Test that multiple create-draft-and-back cycles work smoothly with fresh controller state each time, and that async operations gracefully cancel on navigation.
  - **File(s)**: Create Novel Draft screen (navigation testing)
  - **Requires**: Task 1
  - **Validates**: No crash on back navigation, fresh state on each open, concurrent operations handle gracefully

## Notes

### Why This Fix Works
The crash occurs because TextFields try to access their TextEditingController during widget unmount, but the controller is already disposed synchronously in `onClose()`. By deferring disposal to after the widget unmount completes, we prevent this collision.

### Testing Approach
1. Create novel draft, fill some fields
2. Click back button - should navigate smoothly
3. Open Create Novel Draft again - fields should be empty
4. Repeat 10+ times - should have no issues
5. Try uploading image then clicking back immediately - should cancel gracefully

### Related Issues
This pattern may exist in other screens with similar TextEditingController usage (episode_editor, etc.). Consider scanning for similar patterns after this fix is verified.
