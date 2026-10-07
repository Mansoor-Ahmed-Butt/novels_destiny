# Requirements: Fix Novel Editor Back Button Crash

## Problem Statement

When the user clicks the back button while on the "Create Novel Draft" screen, the app becomes stuck or crashes. This indicates a resource cleanup issue related to controller disposal and widget unmounting.

## Root Cause Analysis

The issue stems from a race condition in the navigation and cleanup sequence:

1. **TextEditingControllers** (title, description, tags, manuscript, etc.) are created in the NovelEditorController
2. **TextField widgets** reference these controllers in the UI
3. When back is pressed, the cleanup sequence has timing issues:
   - If controllers dispose before TextFields unmount: `_dependents.isEmpty` assertion error
   - If done synchronously: ANR (Application Not Responding) while main thread blocked
   - Current `addPostFrameCallback` timing may be inconsistent across Android/iOS

## Functional Requirements

### Navigation Behavior
- **Clean Exit**: User can click back button and smoothly return to previous screen
- **No Crash/Stuck State**: App must not hang, crash, or display error dialogs
- **No Data Loss**: Unsaved changes are either discarded gracefully or persisted appropriately

### Resource Cleanup
- **Focus Release**: Text input focus is released before navigation
- **Controller Disposal**: TextEditingControllers disposed AFTER TextFields unmount
- **State Cleanup**: GetX controller deleted after UI tree cleanup
- **No Async Leaks**: Pending uploads/saves handled gracefully during back navigation

### Controller Management
- **Tagged Binding**: NovelEditorController uses tag (novelId or '__new_novel__')
- **Single Instance**: Only one instance exists per novel being edited
- **Fresh State**: Next time user opens "Create Novel Draft", fresh controller is created

## Non-Functional Requirements

### Performance
- **Back Navigation**: Must complete in <500ms without ANR
- **Memory**: No TextEditingController leaks after navigation
- **Responsiveness**: UI remains responsive throughout back navigation

### Reliability  
- **Cross-Platform**: Fix works on both Android and iOS
- **Consistency**: Behavior same whether back comes from hardware button or AppBar button
- **Error Handling**: Gracefully handle edge cases (e.g., controller already deleted)

## Edge Cases to Handle

1. **Hardware Back Button** (Android): PopScope intercepts; manual cleanup needed
2. **Back Button During Upload**: Active file upload should complete or cancel gracefully
3. **Save Before Back**: If save initiated, back press should be blocked or queued
4. **Multiple Taps**: Rapid back taps should not cause double-deletion errors
5. **Controller Not Found**: Handle gracefully if controller already deleted

## Acceptance Criteria

1. ✅ User can click back button multiple times without crash/hang
2. ✅ Screen smoothly returns to writer dashboard
3. ✅ New "Create Novel Draft" opens fresh form with no stale data
4. ✅ No error dialogs, console warnings, or crash reports
5. ✅ Unsaved form data is cleared (previous edit session not preserved)
6. ✅ Any pending uploads are cancelled when back is pressed
7. ✅ Works consistently on Android and iOS hardware back buttons
8. ✅ Save-then-back flow completes without hanging

## Success Metrics

- **No Crashes**: 0 crashes in back button navigation
- **Response Time**: Back navigation completes in <500ms
- **User Feedback**: Form submission followed by back works seamlessly
