# Novel Editor Navigation Crash - Technical Design

## Problem Statement
When users navigate back from the "Create Novel Draft" screen, the app crashes with either:
- `_dependents.isEmpty` assertion failure
- ANR (Application Not Responding) warning
- TextField widget tree corruption

## Root Cause Analysis

### Current Flow (Broken)
```
User clicks back button
    ↓
_onBack() calls FocusScope.unfocus()
    ↓
_onBack() calls Get.back() → Widget tree starts unmounting
    ↓
GetX framework calls controller.onClose()
    ↓
onClose() IMMEDIATELY disposes TextEditingControllers
    ↓
TextFields are STILL unmounting from the widget tree
    ↓
CRASH: TextEditingController assertions or TextField dependency errors
```

### Why It Crashes
1. **TextField Unmounting**: When Get.back() is called, Flutter begins the unmount phase for TextFields
2. **Simultaneous Disposal**: onClose() fires and immediately disposes TextEditingControllers
3. **Collision**: TextFields try to call `controller.dispose()` during unmount while the controller is already disposed
4. **Result**: Assertion errors or ANR due to race condition

### Current Mitigation Attempt (Incomplete)
The current code has:
```dart
WidgetsBinding.instance.addPostFrameCallback((_) {
  if (Get.isRegistered<NovelEditorController>(tag: _tag)) {
    Get.delete<NovelEditorController>(tag: _tag, force: true);
  }
});
```

This attempts to delete the controller after the frame, but the **controller is still alive in memory with already-disposed TextEditingControllers**. The TextFields still encounter the disposed controllers during their unmount phase.

## Solution Design

### Strategy: Defer ALL Cleanup Until Safe Window

Instead of disposing TextEditingControllers in `onClose()`, we'll use a two-phase cleanup:

1. **Phase 1 (onClose)**: Set `_isDisposed = true` and stop any async operations
2. **Phase 2 (Deferred)**: Dispose TextEditingControllers after widget tree is fully unmounted

### Implementation

#### Step 1: Update `onClose()` Method

```dart
@override
void onClose() {
  _isDisposed = true;
  
  // DO NOT dispose TextEditingControllers here.
  // They may still be referenced by TextFields during unmount phase.
  
  // Defer disposal to after the widget tree finishes unmounting.
  // Using Future.microtask ensures this runs after the current event loop
  // but before rendering the next frame.
  Future.microtask(() {
    try {
      if (!_isDisposed) return; // Safety check
      titleController.dispose();
      descriptionController.dispose();
      coverUrlController.dispose();
      tagsController.dispose();
      manuscriptController.dispose();
    } catch (e) {
      // Silently ignore disposal errors in cleanup
      _logger.debug('Cleanup error during controller disposal: $e');
    }
  });
  
  super.onClose();
}
```

**Why Future.microtask?**
- Runs after current synchronous code completes
- Runs BEFORE the next frame is rendered
- Allows TextFields to completely unmount before we dispose their controllers
- Avoids ANR issues from blocking the main thread

#### Step 2: Keep Existing Safety Checks in `_onBack()`

The current `_onBack()` is already correct:
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

This ensures:
1. Text fields lose focus (no pending callbacks)
2. Navigation happens
3. Controller is deleted after frame renders (if still registered)

#### Step 3: Ensure All Async Methods Check `_isDisposed`

The controller already has this pattern. Verify it's consistent:

```dart
Future<void> loadExistingNovel(String id) async {
  try {
    isLoading.value = true;
    final novel = await _novelUseCases.getNovelById(id);
    if (_isDisposed) return;  // ✓ Safety check
    // ... rest of method
  }
}

Future<void> pickAndUploadCover() async {
  try {
    // ... pick image
    if (_isDisposed) return;  // ✓ Safety check
    // ... upload
  }
}
```

## Execution Flow (Fixed)

```
User clicks back button
    ↓
_onBack() calls FocusScope.unfocus() → Releases focus from TextFields
    ↓
_onBack() calls Get.back() → Navigation starts, widget unmount begins
    ↓
GetX framework calls controller.onClose()
    ↓
onClose() sets _isDisposed = true (stops async operations)
    ↓
onClose() schedules Future.microtask(() => dispose TextEditingControllers)
    ↓
TextFields finish unmounting (they're not touching disposed controllers now)
    ↓
Frame renders with new screen
    ↓
microtask executes → TextEditingControllers disposed SAFELY
    ↓
✓ No crash, clean navigation
```

## Key Principles

1. **Safety Flag First**: Set `_isDisposed = true` BEFORE disposing resources
2. **Async Ops Stop**: All async methods check `_isDisposed` and exit early
3. **Deferred Disposal**: TextEditingControllers disposed after widget tree unmount completes
4. **Event Loop Ordering**: Use Future.microtask for timing reliability

## Testing Strategy

### Test 1: Back Navigation Without Crash
- Open Create Novel Draft
- Type in fields
- Click back button
- Verify: No crash, smooth navigation back

### Test 2: State Freshness
- Create novel draft → Back
- Create another novel draft
- Verify: All fields are empty (fresh controller)

### Test 3: Stress Test
- Rapid back-and-forth navigation (10+ times)
- Verify: Consistent behavior, no crashes or memory buildup

### Test 4: Concurrent Operations
- Start image upload → Immediately click back
- Verify: Operation cancels gracefully due to `_isDisposed` check

## Potential Edge Cases

| Scenario | Handling |
|----------|----------|
| User navigates back during upload | `_isDisposed` check exits async callback, cleanup proceeds safely |
| Rapid successive back taps | GetX handles this; second back does nothing |
| Controller not registered at cleanup time | Check `Get.isRegistered()` before delete |
| Multiple TextEditingControllers | All handled in single deferred cleanup block |

## Performance Impact

- **Negligible**: Disposal moved to microtask instead of synchronous
- **Actually Improved**: No ANR from blocking main thread with disposal
- **Memory**: Same cleanup happens, just at a safer time

## Related Code Patterns

This follows Flutter/GetX best practices:
- GetX documentation recommends deferring cleanup in `onClose()`
- Flutter TextEditingController guidance suggests careful lifecycle management
- Similar pattern used in episode_editor (if applicable)
