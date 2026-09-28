# Auth Flow Bugs Fix - Implementation Tasks

## Overview

This tasks document outlines the implementation strategy for fixing four critical authentication bugs in the Novels Destiny Flutter application. Each bug has a corresponding set of tasks that implement the fix based on the design specifications, followed by comprehensive testing to verify both the fix and preservation of existing behavior.

The implementation follows this sequence:
1. **Bug Condition Exploration Tests** (optional, for verification): Surface counterexamples demonstrating each bug
2. **Implementation Tasks**: Apply the fixes to source code
3. **Validation Tests**: Verify fixes work correctly and preserve existing behavior

---

## Task Group 1: Bug Condition Exploration and Root Cause Verification

### Task 1.1: Write bug condition exploration property tests
- **Status**: Not Started
- **Type**: Property-Based Test (PBT)
- **Subtasks**:
  - [ ] 1.1.1 Write property tests that demonstrate Bug 1 (Google Sign-In serverClientId missing on Android)
    - Create tests that mock Android platform and verify GoogleSignIn throws clientConfigurationError
    - **Validates: Requirements 1.1**
  - [ ] 1.1.2 Write property tests that demonstrate Bug 2 (Logout navigation shows Create Account instead of Sign In)
    - Create tests that simulate logout from create account mode and verify isSignUp remains true
    - **Validates: Requirements 1.2**
  - [ ] 1.1.3 Write property tests that demonstrate Bug 3 (Error state persists across form navigation)
    - Create tests that trigger authentication error, toggle form mode, and verify error state persists
    - **Validates: Requirements 1.3**
  - [ ] 1.1.4 Write property tests that demonstrate Bug 4 (Session persistence failure on cold start)
    - Create tests that mock authenticated user, simulate cold start, and verify initial route is auth instead of shell
    - **Validates: Requirements 1.4**
- **Expected Outcome**: Tests fail on unfixed code, confirming each bug exists with specific counterexamples
- **Success Criteria**: All tests fail with expected counterexamples demonstrating the bugs

---

## Task Group 2: Bug 1 - Google Sign-In Configuration Error Fix

### Task 2.1: Implement Google Sign-In serverClientId configuration for Android
- **Status**: Not Started
- **File**: `lib/data/repositories/auth_repository_impl.dart`
- **Function**: `signInWithGoogle()`
- **Description**: Add platform detection and configure GoogleSignIn with serverClientId on Android platforms
- **Implementation Steps**:
  1. Import `dart:io` for Platform detection
  2. Extract Web Client ID from Firebase configuration (google-services.json or environment)
  3. Initialize GoogleSignIn conditionally: use serverClientId on Android, use default on iOS/Web
  4. Ensure error handling maintains user experience (no new error types introduced)
- **Expected Outcome**: GoogleSignIn successfully authenticates on Android without clientConfigurationError
- **Success Criteria**:
  - `signInWithGoogle()` initializes GoogleSignIn with serverClientId on Android
  - `signInWithGoogle()` uses default GoogleSignIn initialization on iOS and Web
  - Authentication flow completes successfully on Android
  - No new errors introduced for iOS/Web platforms

### Task 2.2: Write unit tests for Google Sign-In Android configuration
- **Status**: Not Started
- **Type**: Unit Tests
- **Description**: Test that Google Sign-In is properly configured with serverClientId on Android
- **Test Cases**:
  - [ ] Test that GoogleSignIn initializes with serverClientId on Android platform
  - [ ] Test that GoogleSignIn initializes without serverClientId on iOS platform
  - [ ] Test that GoogleSignIn initializes without serverClientId on Web platform
  - [ ] Test that Web Client ID is correctly extracted from Firebase configuration
  - [ ] Test error handling for invalid or missing serverClientId
- **Validates: Requirements 2.1**
- **Success Criteria**: All unit tests pass

### Task 2.3: Write property tests for Google Sign-In serverClientId fix
- **Status**: Not Started
- **Type**: Property-Based Test (PBT)
- **Description**: Property tests verifying the fix for Google Sign-In on Android
- **Properties**:
  - [ ] Property 1: For any platform where user clicks "Sign in with Google", the system SHALL successfully proceed without clientConfigurationError
    - **Validates: Requirements 2.1**
  - [ ] Property 2: For iOS and Web platforms, Google Sign-In SHALL function identically to the original implementation (preservation)
    - **Validates: Requirements 3.1**
- **Success Criteria**: Both properties pass on fixed code

---

## Task Group 3: Bug 2 - Logout Navigation Error Fix

### Task 3.1: Implement isSignUp state reset in signOut() method
- **Status**: Not Started
- **File**: `lib/features/auth/controllers/auth_controller.dart`
- **Function**: `signOut()`
- **Description**: Reset form state (isSignUp, isAdminMode) and clear form fields before navigation
- **Implementation Steps**:
  1. Add `isSignUp.value = false;` to reset form mode to sign-in
  2. Add `isAdminMode.value = false;` to reset admin mode
  3. Clear all form field controllers (nameController, emailController, passwordController)
  4. Ensure existing logout flow (current user reset, state update, navigation) remains unchanged
- **Expected Outcome**: Sign In screen displays after logout regardless of previous form mode
- **Success Criteria**:
  - `isSignUp.value` is false after logout
  - `isAdminMode.value` is false after logout
  - Form controllers are cleared
  - Navigation to `AppRoutes.auth` completes successfully
  - Existing authentication state is properly cleared

### Task 3.2: Write unit tests for logout navigation fix
- **Status**: Not Started
- **Type**: Unit Tests
- **Description**: Test that logout properly resets form state and displays Sign In screen
- **Test Cases**:
  - [ ] Test that `isSignUp.value` is false after logout
  - [ ] Test that `isAdminMode.value` is false after logout
  - [ ] Test that form field controllers are cleared after logout
  - [ ] Test that currentUser is set to null after logout
  - [ ] Test that state is set to Unauthenticated after logout
  - [ ] Test navigation to `AppRoutes.auth` occurs after logout
- **Validates: Requirements 2.2**
- **Success Criteria**: All unit tests pass

### Task 3.3: Write property tests for logout navigation fix
- **Status**: Not Started
- **Type**: Property-Based Test (PBT)
- **Description**: Property tests verifying logout correctly resets all state
- **Properties**:
  - [ ] Property 2: For any logout action from authenticated state, the system SHALL reset isSignUp to false and display Sign In screen
    - **Validates: Requirements 2.2**
  - [ ] Property 3: For any successful authentication followed by logout, Sign In screen SHALL be displayed on subsequent navigation (preservation)
    - **Validates: Requirements 3.3**
- **Success Criteria**: Both properties pass on fixed code

---

## Task Group 4: Bug 3 - Error State Persistence Fix

### Task 4.1: Implement error state clearing in toggleSignUpMode() method
- **Status**: Not Started
- **File**: `lib/features/auth/controllers/auth_controller.dart`
- **Function**: `toggleSignUpMode()`
- **Description**: Reset AuthState from AuthFailureState to Unauthenticated when toggling between forms
- **Implementation Steps**:
  1. Add check for `state.value is AuthFailureState`
  2. If error state exists, reset to `const Unauthenticated()`
  3. Ensure existing form toggle behavior (isSignUp toggle, form field clearing) remains unchanged
  4. Maintain admin mode state management
- **Expected Outcome**: Error messages do not persist when navigating between sign-in and create account forms
- **Success Criteria**:
  - Error state is cleared when toggling between forms
  - AuthFailureState is reset to Unauthenticated
  - Form fields are cleared as before
  - isSignUp state toggles correctly
  - Admin mode state is managed correctly

### Task 4.2: Write unit tests for error state clearing fix
- **Status**: Not Started
- **Type**: Unit Tests
- **Description**: Test that form toggle clears error state and displays clean form
- **Test Cases**:
  - [ ] Test that `toggleSignUpMode()` resets AuthFailureState to Unauthenticated
  - [ ] Test that `toggleSignUpMode()` does not affect state when no error exists
  - [ ] Test that form fields are cleared when toggling with error state
  - [ ] Test that isSignUp observable toggles correctly with error present
  - [ ] Test that error message is not rendered after toggle
- **Validates: Requirements 2.3**
- **Success Criteria**: All unit tests pass

### Task 4.3: Write property tests for error state clearing fix
- **Status**: Not Started
- **Type**: Property-Based Test (PBT)
- **Description**: Property tests verifying error state is cleared on form toggle
- **Properties**:
  - [ ] Property 3: For any form toggle when current state is AuthFailureState, the system SHALL reset state to Unauthenticated and clear error messages
    - **Validates: Requirements 2.3**
  - [ ] Property 4: For form toggle without error state, the system SHALL produce identical behavior to original implementation (preservation)
    - **Validates: Requirements 3.5**
- **Success Criteria**: Both properties pass on fixed code

---

## Task Group 5: Bug 4 - Session Persistence Failure Fix

### Task 5.1: Implement dynamic initial route selection based on authentication state
- **Status**: Not Started
- **File**: `lib/app/routes/app_pages.dart`
- **Description**: Convert static initial route to dynamic getter that checks authentication state
- **Implementation Steps**:
  1. Change `AppPages.initial` from const static to static getter
  2. Access AuthController to check currentUser value
  3. Implement routing logic:
     - If user is authenticated and role is writer with pending approval → route to `AppRoutes.writerPendingApproval`
     - If user is authenticated with other roles → route to `AppRoutes.shell`
     - If no authenticated session → route to `AppRoutes.auth`
  4. Add error handling for cases where AuthController is not yet initialized
  5. Ensure initialization order is correct (AuthController must be initialized before GetMaterialApp accesses initial route)
- **Expected Outcome**: App navigates directly to appropriate authenticated screen on cold start if session exists
- **Success Criteria**:
  - `AppPages.initial` correctly identifies authenticated user on cold start
  - Routes to `AppRoutes.shell` for authenticated readers
  - Routes to `AppRoutes.writerPendingApproval` for writers with pending approval
  - Routes to `AppRoutes.auth` when no session exists
  - Error handling prevents crashes if AuthController not initialized

### Task 5.2: Write unit tests for session persistence initialization
- **Status**: Not Started
- **Type**: Unit Tests
- **Description**: Test that initial route is determined correctly based on authentication state
- **Test Cases**:
  - [ ] Test that initial route is `AppRoutes.shell` when user is authenticated as reader
  - [ ] Test that initial route is `AppRoutes.writerPendingApproval` when user is writer with pending approval
  - [ ] Test that initial route is `AppRoutes.shell` when user is authenticated as approved writer
  - [ ] Test that initial route is `AppRoutes.auth` when no user is authenticated
  - [ ] Test error handling when AuthController not initialized
  - [ ] Test currentUser null case returns auth route
- **Validates: Requirements 2.4**
- **Success Criteria**: All unit tests pass

### Task 5.3: Write property tests for session persistence fix
- **Status**: Not Started
- **Type**: Property-Based Test (PBT)
- **Description**: Property tests verifying session persistence on app startup
- **Properties**:
  - [ ] Property 4: For any cold start with valid authenticated session (currentUser not null), the system SHALL navigate to appropriate authenticated screen instead of auth screen
    - **Validates: Requirements 2.4**
  - [ ] Property 5: For any app launch where no authenticated session exists, the system SHALL display Sign In screen as initial route (preservation)
    - **Validates: Requirements 3.2**
- **Success Criteria**: Both properties pass on fixed code

---

## Task Group 6: Comprehensive Preservation Testing

### Task 6.1: Write preservation tests for iOS/Web Google Sign-In
- **Status**: Not Started
- **Type**: Unit Tests + Property Tests
- **Description**: Verify that Google Sign-In on iOS and Web platforms continues to function identically to original implementation
- **Test Cases**:
  - [ ] Test iOS Google Sign-In authentication flow completes successfully
  - [ ] Test Web Google Sign-In authentication flow completes successfully
  - [ ] Test iOS platform does not receive serverClientId parameter
  - [ ] Test Web platform does not receive serverClientId parameter
  - [ ] Property Test: iOS/Web Google Sign-In behavior unchanged from original
- **Validates: Requirements 3.1**
- **Success Criteria**: All tests pass

### Task 6.2: Write preservation tests for error display on same screen
- **Status**: Not Started
- **Type**: Unit Tests + Property Tests
- **Description**: Verify that authentication errors continue to display on the same screen without form toggle
- **Test Cases**:
  - [ ] Test invalid credentials error displays on sign-in screen
  - [ ] Test network error displays on sign-in screen
  - [ ] Test error persists until form submission cleared
  - [ ] Test error does not clear on simple field change (non-toggle)
  - [ ] Property Test: Error display behavior unchanged for non-toggle scenarios
- **Validates: Requirements 3.4**
- **Success Criteria**: All tests pass

### Task 6.3: Write preservation tests for form toggle without error
- **Status**: Not Started
- **Type**: Unit Tests + Property Tests
- **Description**: Verify form toggle continues to work correctly when no error is present
- **Test Cases**:
  - [ ] Test form fields clear when toggling without error
  - [ ] Test isSignUp toggles correctly without error
  - [ ] Test admin mode state updates correctly on toggle
  - [ ] Test UI updates reflect form mode change
  - [ ] Property Test: Form toggle behavior unchanged when no error present
- **Validates: Requirements 3.5**
- **Success Criteria**: All tests pass

### Task 6.4: Write preservation tests for successful authentication navigation
- **Status**: Not Started
- **Type**: Unit Tests + Property Tests
- **Description**: Verify successful authentication continues to navigate based on user role and approval status
- **Test Cases**:
  - [ ] Test reader sign-in navigates to shell with reader context
  - [ ] Test writer sign-up with pending approval navigates to writer pending screen
  - [ ] Test admin sign-in navigates to appropriate admin screen
  - [ ] Test successful authentication clears form state
  - [ ] Property Test: Success navigation behavior unchanged from original
- **Validates: Requirements 3.3**
- **Success Criteria**: All tests pass

### Task 6.5: Write preservation tests for Google Sign-In user cancellation
- **Status**: Not Started
- **Type**: Unit Tests + Property Tests
- **Description**: Verify user cancellation of Google Sign-In flow continues to return to unauthenticated state
- **Test Cases**:
  - [ ] Test cancelled Google Sign-In returns to unauthenticated state
  - [ ] Test no error message displayed on cancellation
  - [ ] Test form remains ready for next authentication attempt
  - [ ] Property Test: Cancellation behavior unchanged from original
- **Validates: Requirements 3.7**
- **Success Criteria**: All tests pass

### Task 6.6: Write preservation tests for writer approval flow
- **Status**: Not Started
- **Type**: Unit Tests + Property Tests
- **Description**: Verify writer account creation and approval flow continues to function correctly
- **Test Cases**:
  - [ ] Test writer account creation sets approval status to pending
  - [ ] Test writer navigation to pending approval screen occurs
  - [ ] Test writer account creation clears form fields correctly
  - [ ] Property Test: Writer approval flow behavior unchanged from original
- **Validates: Requirements 3.8**
- **Success Criteria**: All tests pass

### Task 6.7: Write preservation tests for admin mode functionality
- **Status**: Not Started
- **Type**: Unit Tests + Property Tests
- **Description**: Verify admin mode toggle continues to work and display correct branding
- **Test Cases**:
  - [ ] Test admin mode toggle changes UI branding
  - [ ] Test admin mode authentication uses correct endpoint
  - [ ] Test admin mode toggle affects subsequent authentication attempts
  - [ ] Property Test: Admin mode behavior unchanged from original
- **Validates: Requirements 3.6**
- **Success Criteria**: All tests pass

---

## Task Group 7: Integration and Regression Testing

### Task 7.1: Run full authentication flow integration tests
- **Status**: Not Started
- **Type**: Integration Tests
- **Description**: Verify all authentication flows work together correctly after all fixes
- **Test Scenarios**:
  - [ ] Complete sign-in flow (email/password)
  - [ ] Complete sign-up flow (create account)
  - [ ] Google Sign-In flow on all platforms (Android, iOS, Web)
  - [ ] Logout flow with correct navigation
  - [ ] Session restoration on app restart
  - [ ] Error handling across all flows
  - [ ] Admin portal authentication
  - [ ] Writer approval navigation
- **Success Criteria**: All integration tests pass without errors or regressions

### Task 7.2: Verify no runtime errors or warnings
- **Status**: Not Started
- **Type**: Code Quality Check
- **Description**: Ensure all fixes compile correctly and produce no runtime errors or analyzer warnings
- **Verification Steps**:
  - [ ] Run Flutter analyzer on all modified files
  - [ ] Run build on all platforms (Android, iOS, Web)
  - [ ] Verify no new warnings introduced
  - [ ] Check console for runtime errors
- **Success Criteria**: Clean build with no errors or analyzer warnings

---

## Summary

**Total Tasks**: 7 Task Groups with 23 subtasks

**Implementation Sequence**:
1. Run Bug Condition Exploration Tests (1.1) to verify root causes
2. Implement Bug 1 fix (2.1-2.3)
3. Implement Bug 2 fix (3.1-3.3)
4. Implement Bug 3 fix (4.1-4.3)
5. Implement Bug 4 fix (5.1-5.3)
6. Run comprehensive preservation tests (6.1-6.7)
7. Run integration and regression tests (7.1-7.2)

**Expected Outcomes**:
- All four bugs fixed with proper implementation
- Comprehensive test coverage for all bugs and preservation scenarios
- No regressions in existing authentication functionality
- Clean, maintainable code following project conventions
