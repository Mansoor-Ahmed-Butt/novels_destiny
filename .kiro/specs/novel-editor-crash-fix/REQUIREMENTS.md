# Novel Editor Navigation Crash - Requirements

## Problem Statement
The app crashes when the user navigates back from the "Create Novel Draft" screen. The crash occurs due to a race condition between TextEditingController disposal and the widget unmount lifecycle.

## User Story
As a writer creating a new novel,
I want to click the back button to cancel my draft creation,
So that I can return to the previous screen without the app crashing.

## Current Behavior
- User taps "Create Novel Draft" button
- User sees the form with input fields
- User taps back button (AppBar back or Android back gesture)
- **Result**: App crashes with assertion error or hangs with ANR

## Expected Behavior
- User taps "Create Novel Draft" button
- User sees the form with input fields
- User taps back button
- **Result**: Smooth navigation back to previous screen, no crash

## Requirements

### Functional Requirements
1. **FR-1**: Back button must navigate cleanly from Create Novel Draft screen
2. **FR-2**: Unsaved form data should be discarded (no persistence on back)
3. **FR-3**: Multiple back-and-forth cycles must work without issues
4. **FR-4**: Fresh controller state on each screen open
5. **FR-5**: Async operations (image upload, etc.) must gracefully cancel on back navigation

### Non-Functional Requirements
1. **NFR-1**: No crashes or assertions during back navigation
2. **NFR-2**: No ANR (Application Not Responding) warnings
3. **NFR-3**: No memory leaks from deferred cleanup
4. **NFR-4**: Navigation must complete within 300ms
5. **NFR-5**: Solution must not require user code changes in other screens

### Constraints
1. Must use existing GetX framework (no migration)
2. Must maintain current form structure and widgets
3. Must not introduce new dependencies
4. Must work on both Android and iOS
5. Solution must be reversible if issues arise

## Acceptance Criteria

### AC-1: Back Navigation Doesn't Crash
- **Given** user is on Create Novel Draft screen with form data
- **When** user taps back button
- **Then** app navigates smoothly back without crash

### AC-2: Controller is Cleaned Properly
- **Given** back navigation completed successfully
- **When** user opens Create Novel Draft again
- **Then** all form fields are empty (fresh state)

### AC-3: Multiple Cycles Work
- **Given** user cycles through create-back multiple times (10+ iterations)
- **When** each cycle completes
- **Then** no crashes or performance degradation observed

### AC-4: Concurrent Operations Handle Gracefully
- **Given** user starts image upload
- **When** user immediately taps back before upload completes
- **Then** operation cancels gracefully and doesn't cause crashes

### AC-5: No Android Back Gesture Issues
- **Given** user is on Create Novel Draft screen
- **When** user uses Android hardware back button or back gesture
- **Then** same behavior as app back button (clean navigation)

## Scope

### In Scope
- Fix novel_editor_controller.dart disposal logic
- Fix novel_editor_page.dart back button handling
- Ensure TextEditingController lifecycle is correct
- Add safety checks for async operations

### Out of Scope
- Changes to other features' navigation
- Changes to GetX framework configuration
- UI/UX modifications
- New features for the Create Novel Draft screen

## Dependencies
- GetX framework (already in project)
- Flutter TextEditingController API
- NovelEditorController state management

## Success Metrics
1. **Crash Rate**: Zero crashes on back navigation (100% success rate)
2. **User Experience**: Smooth, immediate response to back button
3. **Code Quality**: No warnings or lint errors
4. **Memory**: No memory leaks from repeated cycles
5. **Reliability**: 100% pass rate on automated navigation tests

## Open Questions / Risks

### Q1: Are there other screens with similar TextEditingController issues?
**Answer**: Should investigate episode_editor and similar screens for the same pattern.

### Q2: Can we use safer disposal patterns?
**Answer**: Yes - the Future.microtask approach is the recommended Flutter pattern for deferred cleanup.

### Q3: What if the controller is deleted before disposal completes?
**Answer**: The deferred disposal is wrapped in try-catch and checks `_isDisposed` flag.

## Implementation Timeline
- Task 1 (Fix Controller): ~15 minutes
- Task 2 (Testing): ~10 minutes
- Total: ~25 minutes

## Rollback Plan
If issues arise after implementation:
1. Revert to previous commit
2. Check for any related issues in other screens
3. Consider alternative approaches (e.g., using lifecycle aware disposal)
