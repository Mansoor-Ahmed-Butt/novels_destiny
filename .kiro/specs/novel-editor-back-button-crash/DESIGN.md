# Design: Fix Novel Editor Back Button Crash

## Solution Overview

Fix the race condition in controller disposal by:
1. Using `WillPopScope` (or `PopScope` in Flutter 3.22+) to intercept back navigation
2. Implementing a strict cleanup sequence: Focus → Navigation → Delayed Controller Deletion
3. Adding proper state guards (`_isDisposed` flag) to prevent async callbacks touching disposed resources
4. Ensuring consistent behavior across Android/iOS by using platform-agnostic `PopScope`

## Technical Architecture

### 1. Navigation Flow Sequence

```
Back Button Pressed
    ↓
PopScope.onPopInvokedWithResult fires
    ↓
_onBack() executes:
  1. FocusScope.of(context).unfocus()
  2. Get.back() ← Starts widget unmounting
  3. WidgetsBinding.addPostFrameCallback() ← Scheduled AFTER frame renders
    └─ Check if controller registered
    └─ Get.delete(tag: _tag, force: true)
    └─ Mark _isDisposed = true (prevent async callbacks)
    ↓
Navigation completes
    ↓
TextFields fully unmounted
    ↓
Post-frame callback fires → controller deleted safely
```

### 2. Controller State Guard Pattern

The controller uses `_isDisposed` flag to prevent async operations from touching disposed resources:

```dart
Future<void> pickAndUploadCover() async {
  try {
    // ... picker logic
    if (_isDisposed) return; // ← Guard point 1
    
    isUploadingCover.value = true;
    final url = await _storageService.uploadNovelCover(...);
    
    if (_isDisposed) return; // ← Guard point 2 (after await)
    
    coverUrlController.text = url; // Safe - controller not disposed
    isUploadingCover.value = false;
  } catch (e) {
    if (_isDisposed) return; // ← Guard point 3 (exception path)
    // Handle error
  }
}
```

### 3. Focus Management

Focus must be released before navigation to prevent issues:

```dart
void _onBack() {
  FocusScope.of(context).unfocus(); // Release keyboard & focus
  Get.back();
  // Then cleanup...
}
```

### 4. Controller Deletion Timing

**Why `addPostFrameCallback`?**
- Standard `Future.delayed(Duration.zero)` (microtask) fires too early
- TextFields still in tree → accessing disposed TextEditingControllers causes crash
- `addPostFrameCallback` fires after full frame render → TextFields already unmounted

**Implementation:**
```dart
WidgetsBinding.instance.addPostFrameCallback((_) {
  if (Get.isRegistered<NovelEditorController>(tag: _tag)) {
    Get.delete<NovelEditorController>(tag: _tag, force: true);
  }
});
```

### 5. Graceful Upload Handling

When back is pressed during active upload:

1. Controller deletion signals all futures to guard-check `_isDisposed`
2. Active uploads continue in background (do not block UI)
3. Async callbacks check `_isDisposed` and exit early
4. No attempt to update UI after controller gone

## Implementation Details

### Files Modified

1. **novel_editor_page.dart**
   - Enhance `_onBack()` with proper sequence
   - Verify `PopScope` intercepts both hardware & AppBar buttons
   - Add comments explaining timing requirements

2. **novel_editor_controller.dart**
   - Ensure all async methods guard with `_isDisposed` checks
   - Verify `onClose()` sets `_isDisposed = true` first
   - Add guards around all reactive observable updates

3. **novel_editor_binding.dart**
   - Ensure proper tag usage (no issues here, but verify)

### Key Code Patterns

**Pattern 1: Guard async operations**
```dart
Future<void> asyncMethod() async {
  if (_isDisposed) return;
  final result = await expensiveOperation();
  if (_isDisposed) return; // After await
  updateUI(result);
  if (_isDisposed) return; // In catch blocks too
}
```

**Pattern 2: Cleanup in onClose**
```dart
@override
void onClose() {
  _isDisposed = true; // First!
  titleController.dispose();
  // ... dispose other controllers
  super.onClose();
}
```

**Pattern 3: Back navigation**
```dart
void _onBack() {
  FocusScope.of(context).unfocus();
  Get.back();
  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (Get.isRegistered<NovelEditorController>(tag: _tag)) {
      Get.delete<NovelEditorController>(tag: _tag, force: true);
    }
  });
}
```

## Edge Case Handling

### Case 1: Multiple Back Presses
- First back: `Get.back()` + schedule deletion
- Second back: Already deleted, `Get.isRegistered()` returns false → skip deletion
- Result: No double-delete error ✓

### Case 2: Back During Upload
- Upload continues asynchronously
- Controller deleted after frame render
- Upload callback checks `_isDisposed` and exits
- Result: No attempt to update disposed UI ✓

### Case 3: Save Then Back
- User clicks "Save Novel" → `isSaving = true`
- Form validates, saves data, triggers sync
- After save completes, back navigation happens
- Same cleanup sequence applies
- Result: Smooth transition to dashboard ✓

### Case 4: Rapid Save + Back
- User clicks "Save Novel", then immediately back
- If `Get.back()` happens mid-save, async operations guard with `_isDisposed`
- If save completes first, then back follows normal path
- Result: No race condition ✓

## Why This Works

1. **Unfocus First**: Releases text input, keyboard, focus scope cleanly
2. **Navigate Second**: Starts widget unmounting immediately
3. **Delete Last**: Uses `addPostFrameCallback` to ensure TextFields already unmounted
4. **Guard Everywhere**: Async operations check `_isDisposed` after every await point
5. **Tag-Based**: Each novel editor session has isolated controller → no cross-contamination
6. **PopScope**: Handles both hardware back and AppBar back consistently

## Testing Strategy

### Manual Testing
1. Create new novel draft → navigate back → no crash
2. Edit existing novel → navigate back → no crash
3. Rapid back presses → no double-deletion errors
4. Upload cover image → press back during upload → no crash
5. Save then back → completes smoothly

### Automated Testing
- Unit test: `_isDisposed` flag prevents async updates
- Integration test: Back navigation completes without exceptions
- E2E test: Full create-draft → back flow, 100 iterations on emulator

## Rollout Plan

1. Merge changes to main branch
2. Test on Android and iOS devices
3. Monitor crash reports for regression
4. If issues arise, rollback and iterate
