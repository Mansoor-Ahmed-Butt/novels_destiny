# Auth Flow Bugs Fix - Bugfix Design

## Overview

This design addresses four critical authentication bugs in the Novels Destiny Flutter application that impact user experience and authentication reliability. The bugs include: (1) Google Sign-In configuration error on Android due to missing serverClientId, (2) incorrect navigation after logout that shows Create Account screen instead of Sign In screen, (3) error state persistence when navigating between sign-in and create account forms, and (4) lack of session persistence that forces users to re-authenticate after closing the app. The fix approach involves configuring Google Sign-In with proper serverClientId for Android, correcting the navigation route in the signOut method, clearing error state during form mode toggles, and implementing automatic session restoration on app startup.

## Glossary

- **Bug_Condition (C)**: The conditions that trigger each of the four bugs in the authentication flow
- **Property (P)**: The desired correct behavior when the bug conditions occur
- **Preservation**: Existing authentication behaviors that must remain unchanged by the fixes
- **AuthController**: The controller in `lib/features/auth/controllers/auth_controller.dart` that manages authentication state and navigation
- **AuthRepositoryImpl**: The repository in `lib/data/repositories/auth_repository_impl.dart` that implements Google Sign-In and session management
- **toggleSignUpMode()**: The method in AuthController that switches between sign-in and sign-up forms
- **signOut()**: The method in AuthController that logs out the user and navigates to the auth screen
- **signInWithGoogle()**: The method in AuthRepositoryImpl that implements Google authentication
- **AppPages.initial**: The initial route constant in `lib/app/routes/app_pages.dart` that determines the app's startup screen
- **serverClientId**: The OAuth 2.0 web client ID required by GoogleSignIn on Android to authenticate with Firebase
- **AuthState**: The reactive state in AuthController that holds authentication status (AuthInitial, AuthLoading, Authenticated, Unauthenticated, AuthFailureState)

## Bug Details

### Bug Condition 1: Google Sign-In Configuration Error (Android)

The bug manifests when a user clicks the "Sign in with Google" button on an Android device. The GoogleSignIn package is not configured with the required serverClientId parameter, causing the authentication flow to fail immediately with a clientConfigurationError.

**Formal Specification:**
```
FUNCTION isBugCondition1(input)
  INPUT: input of type { platform: String, action: String }
  OUTPUT: boolean
  
  RETURN input.platform == 'Android'
         AND input.action == 'signInWithGoogle'
         AND serverClientIdNotConfigured()
END FUNCTION
```

### Bug Condition 2: Logout Navigation Error

The bug manifests when a user logs out from any authenticated state. The `signOut()` method in AuthController navigates to `AppRoutes.auth`, but the AuthPage displays either sign-in or create account form based on the `isSignUp` observable state, which retains its previous value after logout.

**Formal Specification:**
```
FUNCTION isBugCondition2(input)
  INPUT: input of type { currentState: AuthState, action: String, previousFormMode: String }
  OUTPUT: boolean
  
  RETURN input.currentState == Authenticated
         AND input.action == 'signOut'
         AND input.previousFormMode == 'createAccount'
END FUNCTION
```

### Bug Condition 3: Error State Persistence Across Navigation

The bug manifests when a user encounters an authentication error (wrong credentials) and then navigates to a different form (toggles between sign-in and create account). The `toggleSignUpMode()` method clears form field values but does NOT reset the AuthState, leaving the error message visible on the new form.

**Formal Specification:**
```
FUNCTION isBugCondition3(input)
  INPUT: input of type { currentState: AuthState, action: String }
  OUTPUT: boolean
  
  RETURN input.currentState IS AuthFailureState
         AND input.action == 'toggleSignUpMode'
         AND errorMessageStillDisplayed()
END FUNCTION
```

### Bug Condition 4: Session Persistence Failure

The bug manifests when a user has previously authenticated, closes the app completely, and reopens it later. The app always navigates to the auth screen (`AppPages.initial = AppRoutes.auth`) without checking for an existing authenticated session, even though the AuthController's `_initAuthListener()` correctly identifies the current user.

**Formal Specification:**
```
FUNCTION isBugCondition4(input)
  INPUT: input of type { appLaunchType: String, sessionExists: Boolean }
  OUTPUT: boolean
  
  RETURN input.appLaunchType == 'coldStart'
         AND input.sessionExists == true
         AND currentRouteCheckNotPerformed()
END FUNCTION
```

### Examples

**Bug 1 - Google Sign-In on Android:**
- User clicks "Sign in with Google" button on Android device
- Expected: Google account picker appears, user selects account, signs in successfully
- Actual: GoogleSignInException with error code `clientConfigurationError` and message "serverClientId must be provided on Android"

**Bug 2 - Logout Navigation:**
- User creates reader account → logs in successfully → logs out
- Expected: Sign In screen is displayed
- Actual: Create Account screen is displayed (because `isSignUp.value` is still `true` from account creation)

**Bug 3 - Error State Persistence:**
- User enters wrong email/password → sees "Invalid email or password" error → clicks "Create account" text
- Expected: Create Account screen appears with no error message
- Actual: Create Account screen appears but still displays "Invalid email or password" error message

**Bug 4 - Session Persistence:**
- User creates account → logs in → reads novels → closes app completely → reopens app next day
- Expected: App navigates directly to home screen (shell) with authenticated session
- Actual: App displays sign-in screen, requiring user to log in again

## Expected Behavior

### Bug 1: Google Sign-In Configuration Fix

When a user clicks "Sign in with Google" button on Android, the system SHALL successfully initialize GoogleSignIn with the serverClientId parameter set to the Firebase Web Client ID from the google-services.json configuration, allowing the authentication flow to proceed normally.

### Bug 2: Logout Navigation Fix

When a user logs out from any authenticated state, the system SHALL reset the `isSignUp` observable to `false` in the `signOut()` method before navigating to the auth screen, ensuring the Sign In form is displayed.

### Bug 3: Error State Clearing on Navigation

When a user navigates from sign-in form to create account form (or vice versa) via `toggleSignUpMode()`, the system SHALL reset the AuthState from AuthFailureState to AuthInitial (or Unauthenticated), clearing any previously displayed error messages.

### Bug 4: Session Persistence Implementation

When a user has previously authenticated and reopens the app, the system SHALL check the authentication state in the InitialBinding or app initialization, and if a valid session exists (AuthController.currentUser is not null), navigate directly to the appropriate authenticated screen (shell or writer pending approval) instead of the auth screen.

### Preservation Requirements

**Unchanged Behaviors:**

**For Bug 1:**
- Google Sign-In on iOS and web platforms must continue to function correctly without serverClientId configuration changes
- Google Sign-In user cancellation flow must continue to return to unauthenticated state without error

**For Bug 2:**
- Form toggle functionality on the same AuthPage must continue to clear form fields and update UI
- Admin mode functionality must continue to work correctly on the sign-in screen
- Navigation after successful authentication must continue to route based on user role and approval status

**For Bug 3:**
- Error display for valid authentication errors must continue to show appropriate error messages on the same screen
- Form toggle must continue to clear form field values correctly

**For Bug 4:**
- Initial app launch with no previous session must continue to display the sign-in screen
- Successful authentication navigation must continue to route to appropriate screens based on user role
- Writer approval flow must continue to navigate to pending approval screen when applicable

**Scope:**

All authentication flows that do NOT involve the specific bug conditions should be completely unaffected by these fixes. This includes:
- Successful email/password authentication
- Form field validation and error handling (non-navigation errors)
- Role selection during account creation
- Admin portal authentication
- Writer pending approval flows
- Profile updates and role switching

## Hypothesized Root Cause

### Bug 1: Google Sign-In Configuration Error (Android)

Based on the bug description and code analysis, the root causes are:

1. **Missing serverClientId in GoogleSignIn initialization**: The `signInWithGoogle()` method in `auth_repository_impl.dart` initializes GoogleSignIn with `GoogleSignIn.instance` which uses default configuration. On Android, Google Sign-In requires the serverClientId parameter to be explicitly provided for Firebase Authentication integration.

2. **Platform-specific requirement not handled**: The code does not check the platform and conditionally provide serverClientId only for Android. The serverClientId should be the OAuth 2.0 Web Client ID from the Firebase project configuration (available in google-services.json).

### Bug 2: Logout Navigation Error

Based on the code analysis:

1. **Missing state reset in signOut()**: The `signOut()` method in `auth_controller.dart` (line 251) correctly sets `currentUser.value = null` and `state.value = const Unauthenticated()`, but does NOT reset the `isSignUp` observable to `false`.

2. **Form mode persists across navigation**: When navigating back to AuthPage via `Get.offAllNamed(AppRoutes.auth)`, the AuthController is permanent and retains its state. The `isSignUp` observable keeps its previous value (true if user created an account), causing the Create Account form to display instead of Sign In.

### Bug 3: Error State Persistence Across Navigation

Based on the code analysis:

1. **toggleSignUpMode() does not clear error state**: The `toggleSignUpMode()` method in `auth_controller.dart` (lines 53-60) correctly clears form field controllers and toggles the `isSignUp` flag, but does NOT reset the `state` observable from AuthFailureState to Unauthenticated or AuthInitial.

2. **Error state is checked in UI**: The AuthPage UI (lines 77-79 in `auth_page.dart`) directly checks if `state is AuthFailureState` and displays the error message. Since the state is not cleared during form mode toggle, the error persists visually.

### Bug 4: Session Persistence Failure

Based on the code analysis:

1. **Static initial route with no session check**: The `AppPages.initial` constant in `app_pages.dart` (line 24) is hardcoded to `AppRoutes.auth`, which always navigates to the authentication screen on app startup.

2. **AuthController initializes correctly but too late**: The `AuthController._initAuthListener()` method (lines 48-63 in `auth_controller.dart`) correctly checks for `_authUseCases.currentUser` and sets the authenticated state, but this happens AFTER the GetMaterialApp has already navigated to the initial route.

3. **No navigation logic based on auth state on startup**: There is no middleware, guard, or callback in the app initialization that checks the authentication state and conditionally navigates to the shell route if a user is already authenticated.

## Correctness Properties

Property 1: Bug Condition 1 - Google Sign-In on Android

_For any_ user action on Android platform where the user clicks "Sign in with Google" button, the fixed signInWithGoogle function SHALL successfully initialize GoogleSignIn with serverClientId parameter, proceed with the authentication flow, and navigate to the appropriate authenticated screen without throwing a clientConfigurationError.

**Validates: Requirements 2.1**

Property 2: Bug Condition 2 - Logout Navigation

_For any_ logout action from an authenticated state where the user was previously in create account mode, the fixed signOut function SHALL reset the isSignUp state to false before navigation, ensuring the Sign In screen (not Create Account screen) is displayed after logout.

**Validates: Requirements 2.2**

Property 3: Bug Condition 3 - Error State Clearing

_For any_ form mode toggle action (toggleSignUpMode) when the current state is AuthFailureState, the fixed toggleSignUpMode function SHALL reset the state to Unauthenticated, clearing any displayed error messages and showing a clean form on the new screen.

**Validates: Requirements 2.3**

Property 4: Bug Condition 4 - Session Persistence

_For any_ app cold start where a valid authenticated session exists (currentUser is not null), the fixed initialization logic SHALL check the authentication state and navigate directly to the appropriate authenticated screen (shell or writer pending approval) instead of the auth screen.

**Validates: Requirements 2.4**

Property 5: Preservation - Non-Android Google Sign-In

_For any_ user action on iOS or web platforms where the user clicks "Sign in with Google" button, the fixed signInWithGoogle function SHALL produce exactly the same behavior as the original function, successfully authenticating without requiring serverClientId configuration.

**Validates: Requirements 3.1**

Property 6: Preservation - Initial Launch Without Session

_For any_ app launch where no previous authenticated session exists (currentUser is null), the fixed initialization SHALL produce exactly the same behavior as the original code, displaying the Sign In screen as the initial route.

**Validates: Requirements 3.2**

Property 7: Preservation - Successful Authentication Navigation

_For any_ successful authentication (sign-in or sign-up), the fixed code SHALL produce exactly the same navigation behavior as the original code, routing to the appropriate screen based on user role and approval status.

**Validates: Requirements 3.3**

Property 8: Preservation - Error Display for Valid Errors

_For any_ authentication error that occurs during form submission (invalid credentials, network errors), the fixed code SHALL continue to display the appropriate error message on the same screen until the user takes action.

**Validates: Requirements 3.4**

Property 9: Preservation - Form Toggle Functionality

_For any_ form toggle action on the same AuthPage (when not navigating between separate screens), the fixed toggleSignUpMode SHALL continue to clear form fields and update the UI appropriately.

**Validates: Requirements 3.5**

Property 10: Preservation - Google Sign-In User Cancellation

_For any_ Google Sign-In flow where the user cancels the authentication, the fixed signInWithGoogle SHALL continue to return to the unauthenticated state without displaying an error message.

**Validates: Requirements 3.7**

## Fix Implementation

### Changes Required

Assuming our root cause analysis is correct:

#### Fix 1: Google Sign-In Configuration (Android)

**File**: `lib/data/repositories/auth_repository_impl.dart`

**Function**: `signInWithGoogle()`

**Specific Changes**:

1. **Add platform detection**: Import `dart:io` and check if the platform is Android using `Platform.isAndroid`

2. **Extract Web Client ID from Firebase configuration**: The serverClientId should be the OAuth 2.0 Web Client ID from the Firebase project. This can be obtained from the Firebase Console or extracted from `android/app/google-services.json` under `client[].oauth_client[where client_type == 3].client_id`

3. **Initialize GoogleSignIn with serverClientId on Android**:
   ```dart
   final GoogleSignIn googleSignIn = Platform.isAndroid
       ? GoogleSignIn(
           serverClientId: 'YOUR_WEB_CLIENT_ID_FROM_FIREBASE',
         )
       : GoogleSignIn.instance;
   ```

4. **Alternative approach - Use FirebaseAuth to get serverClientId**: Instead of hardcoding, retrieve it programmatically from Firebase configuration if possible, or store it in environment configuration

**Note**: The Web Client ID (OAuth 2.0 client with type 3) is different from the Android client ID in google-services.json. It should be found under the `oauth_client` array where `client_type` is 3.

#### Fix 2: Logout Navigation Error

**File**: `lib/features/auth/controllers/auth_controller.dart`

**Function**: `signOut()`

**Specific Changes**:

1. **Reset isSignUp observable to false**: Add `isSignUp.value = false;` before or after setting the authentication state to unauthenticated

2. **Reset isAdminMode observable to false**: Add `isAdminMode.value = false;` to ensure admin mode is also cleared

3. **Clear form field controllers**: Add code to clear `nameController`, `emailController`, and `passwordController` to ensure no residual data

4. **Updated signOut method**:
   ```dart
   Future<void> signOut() async {
     await _authUseCases.signOut();
     currentUser.value = null;
     state.value = const Unauthenticated();
     
     // Reset form state to ensure Sign In screen is shown
     isSignUp.value = false;
     isAdminMode.value = false;
     
     // Clear form fields
     nameController.clear();
     emailController.clear();
     passwordController.clear();
     
     Get.offAllNamed(AppRoutes.auth);
   }
   ```

#### Fix 3: Error State Clearing on Navigation

**File**: `lib/features/auth/controllers/auth_controller.dart`

**Function**: `toggleSignUpMode()`

**Specific Changes**:

1. **Check if current state is AuthFailureState**: Add a condition to check if `state.value is AuthFailureState`

2. **Reset state to Unauthenticated**: If error state exists, reset it to `const Unauthenticated()` to clear the error message

3. **Updated toggleSignUpMode method**:
   ```dart
   void toggleSignUpMode() {
     isSignUp.value = !isSignUp.value;
     if (isSignUp.value) {
       isAdminMode.value = false;
     }
     
     // Clear error state when switching between forms
     if (state.value is AuthFailureState) {
       state.value = const Unauthenticated();
     }
     
     nameController.clear();
     emailController.clear();
     passwordController.clear();
   }
   ```

#### Fix 4: Session Persistence Implementation

**File**: `lib/app/routes/app_pages.dart` and potentially `lib/app/bindings/initial_binding.dart`

**Approach**: Implement dynamic initial route selection based on authentication state

**Specific Changes**:

**Option A: Dynamic initial route in AppPages**

1. **Change AppPages.initial from const to getter**: Convert the static const to a static getter that checks authentication state

2. **Check AuthController currentUser**: Access the AuthController to check if a user is already authenticated

3. **Return appropriate route**:
   ```dart
   static String get initial {
     try {
       final authController = Get.find<AuthController>();
       final user = authController.currentUser.value;
       
       if (user != null) {
         // User is authenticated, check if writer pending approval
         if (user.role == UserRole.writer && 
             user.approvalStatus == ApprovalStatus.pending) {
           return AppRoutes.writerPendingApproval;
         }
         // Otherwise go to main shell
         return AppRoutes.shell;
       }
     } catch (e) {
       // AuthController not initialized yet, fall back to auth
     }
     
     // No authenticated session, show auth screen
     return AppRoutes.auth;
   }
   ```

**Option B: Add initialization callback in AuthController**

1. **Add a method to check and navigate on startup**: Create a new method `checkInitialRoute()` in AuthController

2. **Call it after initialization in InitialBinding**: Add a callback in `InitialBinding.dependencies()` after AuthController is registered

3. **Implementation**:
   ```dart
   // In AuthController
   void checkInitialRoute() {
     final user = currentUser.value;
     if (user != null) {
       // User is authenticated, navigate appropriately
       _routeUserAfterAuth(user);
     }
     // Otherwise, stay on auth screen (already at initial route)
   }
   
   // In InitialBinding.dependencies()
   Get.put<AuthController>(
     AuthController(Get.find(), Get.find()), 
     permanent: true
   );
   
   // Check and navigate after initialization
   WidgetsBinding.instance.addPostFrameCallback((_) {
     Get.find<AuthController>().checkInitialRoute();
   });
   ```

**Recommended Approach**: Option A (dynamic initial route) is cleaner and more idiomatic for GetX routing, but requires ensuring AuthController is initialized before GetMaterialApp accesses `AppPages.initial`. Option B is safer but adds a navigation jump. For this fix, we'll use **Option A with proper initialization order**.

## Testing Strategy

### Validation Approach

The testing strategy follows a two-phase approach: first, surface counterexamples that demonstrate each bug on unfixed code, then verify the fixes work correctly and preserve existing behavior. Since there are four distinct bugs, we'll test each bug condition and its corresponding fix separately, followed by comprehensive preservation testing.

### Exploratory Bug Condition Checking

**Goal**: Surface counterexamples that demonstrate all four bugs BEFORE implementing the fixes. Confirm or refute the root cause analysis. If we refute, we will need to re-hypothesize.

**Test Plan**: Write tests that simulate each bug condition and assert the expected incorrect behavior (demonstrating the bug). Run these tests on the UNFIXED code to observe failures and understand the root causes.

**Test Cases**:

**Bug 1 - Google Sign-In Configuration:**
1. **Android Platform Test**: Mock Platform.isAndroid to return true, call `signInWithGoogle()`, expect GoogleSignInException with "serverClientId must be provided" (will fail on unfixed code with this specific error)
2. **ServerClientId Missing Test**: Verify GoogleSignIn is initialized without serverClientId parameter on Android (will fail on unfixed code)

**Bug 2 - Logout Navigation:**
3. **Logout After Account Creation Test**: Create account (sets isSignUp to true), login, logout, check that Create Account form is displayed instead of Sign In (will fail on unfixed code - bug is present)
4. **isSignUp State After Logout Test**: Check `authController.isSignUp.value` immediately after logout, expect false but get true (will fail on unfixed code)

**Bug 3 - Error State Persistence:**
5. **Error Persists on Toggle Test**: Trigger authentication error, call `toggleSignUpMode()`, check that state is still AuthFailureState (will fail on unfixed code - bug is present)
6. **Error Message Display After Toggle Test**: Trigger error, toggle form, verify error message is still rendered in UI (will fail on unfixed code)

**Bug 4 - Session Persistence:**
7. **Cold Start With Session Test**: Mock authenticated user in AuthController, simulate app cold start, verify initial route is still `AppRoutes.auth` instead of `AppRoutes.shell` (will fail on unfixed code - bug is present)
8. **Navigation After Cold Start Test**: Authenticate user, restart app (cold start), verify user lands on auth screen requiring re-login (will fail on unfixed code)

**Expected Counterexamples**:
- Bug 1: GoogleSignInException on Android with clientConfigurationError
- Bug 2: Create Account form displayed after logout when Sign In form expected
- Bug 3: Error message persists after toggling between sign-in and create account forms
- Bug 4: Auth screen displayed on cold start despite valid session existing

### Fix Checking

**Goal**: Verify that for all inputs where the bug conditions hold, the fixed functions produce the expected correct behavior.

**Bug 1 - Google Sign-In Fix Checking:**

**Pseudocode:**
```
FOR ALL platform IN [Android, iOS, Web] DO
  IF platform == Android THEN
    input := { platform: platform, action: 'signInWithGoogle' }
    IF isBugCondition1(input) THEN
      result := signInWithGoogle_fixed()
      ASSERT result.success == true
      ASSERT result.serverClientIdConfigured == true
      ASSERT NO GoogleSignInException raised
    END IF
  END IF
END FOR
```

**Bug 2 - Logout Navigation Fix Checking:**

**Pseudocode:**
```
FOR ALL authState IN [Authenticated_AfterAccountCreation, Authenticated_AfterSignIn] DO
  FOR ALL formMode IN ['createAccount', 'signIn'] DO
    input := { currentState: authState, action: 'signOut', previousFormMode: formMode }
    IF isBugCondition2(input) THEN
      signOut_fixed()
      ASSERT authController.isSignUp.value == false
      ASSERT displayedForm == 'signIn'
    END IF
  END FOR
END FOR
```

**Bug 3 - Error State Clearing Fix Checking:**

**Pseudocode:**
```
FOR ALL errorMessage IN [ValidAuthErrors] DO
  authController.state.value := AuthFailureState(errorMessage)
  input := { currentState: authController.state.value, action: 'toggleSignUpMode' }
  IF isBugCondition3(input) THEN
    toggleSignUpMode_fixed()
    ASSERT authController.state.value IS Unauthenticated
    ASSERT errorMessageDisplayed == false
  END IF
END FOR
```

**Bug 4 - Session Persistence Fix Checking:**

**Pseudocode:**
```
FOR ALL userType IN [Reader, Writer_Pending, Writer_Approved, Admin] DO
  authController.currentUser.value := userType
  input := { appLaunchType: 'coldStart', sessionExists: true }
  IF isBugCondition4(input) THEN
    initialRoute := AppPages.initial_fixed
    ASSERT initialRoute IN [AppRoutes.shell, AppRoutes.writerPendingApproval]
    ASSERT initialRoute != AppRoutes.auth
  END IF
END FOR
```

### Preservation Checking

**Goal**: Verify that for all inputs where the bug conditions do NOT hold, the fixed functions produce the same results as the original functions.

**Pseudocode:**
```
FOR ALL authFlow IN [EmailPasswordSignIn, EmailPasswordSignUp, RoleSwitch, ProfileUpdate] DO
  FOR ALL input IN ValidInputs(authFlow) WHERE NOT anyBugCondition(input) DO
    ASSERT originalBehavior(input) == fixedBehavior(input)
  END FOR
END FOR
```

**Testing Approach**: Property-based testing is recommended for preservation checking because:
- It generates many test cases automatically across the input domain
- It catches edge cases that manual unit tests might miss
- It provides strong guarantees that behavior is unchanged for all non-buggy inputs

**Test Plan**: Observe behavior on UNFIXED code first for non-bug scenarios, then write property-based tests capturing that behavior.

**Test Cases**:

**Preservation Test 1 - iOS/Web Google Sign-In:**
1. **iOS Google Sign-In**: Mock Platform.isIOS, call `signInWithGoogle()`, verify it works without serverClientId configuration
2. **Web Google Sign-In**: Mock kIsWeb, call `signInWithGoogle()`, verify it works without serverClientId configuration

**Preservation Test 2 - Initial Launch Without Session:**
3. **First Time User**: Set currentUser to null, check that initial route is `AppRoutes.auth` (should be preserved)
4. **After Logout Cold Start**: Logout completely, simulate cold start, verify auth screen is displayed

**Preservation Test 3 - Successful Authentication Navigation:**
5. **Reader Sign In**: Sign in as reader, verify navigation to shell with reader tab
6. **Writer Pending**: Create writer account, verify navigation to writer pending approval screen
7. **Admin Sign In**: Sign in as admin, verify navigation to shell with admin tab

**Preservation Test 4 - Error Display for Valid Errors:**
8. **Invalid Credentials**: Submit wrong email/password, verify error message displays on same form (sign-in)
9. **Network Error**: Simulate network failure during sign-in, verify error message displays

**Preservation Test 5 - Form Toggle on Same Screen:**
10. **Toggle Without Error**: Toggle between sign-in and create account forms when no error exists, verify form fields clear correctly
11. **Admin Mode Toggle**: Toggle admin mode on sign-in screen, verify branding updates correctly

**Preservation Test 6 - Google Sign-In Cancellation:**
12. **User Cancels Google Flow**: Simulate user canceling Google Sign-In picker, verify app returns to unauthenticated state without error message

### Unit Tests

**Bug 1 - Google Sign-In Configuration:**
- Test GoogleSignIn initialization with serverClientId on Android platform
- Test GoogleSignIn initialization without serverClientId on iOS platform
- Test extraction of Web Client ID from Firebase configuration
- Test error handling when serverClientId is invalid

**Bug 2 - Logout Navigation:**
- Test that `signOut()` sets `isSignUp.value` to false
- Test that `signOut()` sets `isAdminMode.value` to false
- Test that `signOut()` clears all form field controllers
- Test navigation to `AppRoutes.auth` after logout

**Bug 3 - Error State Clearing:**
- Test that `toggleSignUpMode()` clears AuthFailureState to Unauthenticated
- Test that `toggleSignUpMode()` does not affect state when no error exists
- Test that error message is not rendered after toggle when error was present

**Bug 4 - Session Persistence:**
- Test that `AppPages.initial` returns `AppRoutes.shell` when user is authenticated as reader
- Test that `AppPages.initial` returns `AppRoutes.writerPendingApproval` when user is writer with pending approval
- Test that `AppPages.initial` returns `AppRoutes.auth` when no user is authenticated
- Test that `AppPages.initial` handles AuthController not initialized gracefully

### Property-Based Tests

**Bug 1 - Google Sign-In:**
- Generate random platform types and verify serverClientId is provided only on Android
- Generate random Firebase configurations and verify Web Client ID extraction is correct

**Bug 2 - Logout Navigation:**
- Generate random authentication states and form modes, verify logout always resets to sign-in form
- Generate random sequences of sign-in/sign-up/logout actions, verify form state is always correct after logout

**Bug 3 - Error State Clearing:**
- Generate random error messages and form toggle sequences, verify error never persists after toggle
- Generate random sequences of authentication attempts and form toggles, verify clean state

**Bug 4 - Session Persistence:**
- Generate random user states (authenticated/unauthenticated, different roles), verify correct initial route
- Generate random app restart scenarios with varying session states, verify correct navigation

### Integration Tests

**End-to-End Bug 1 Test:**
- Launch app on Android emulator
- Navigate to sign-in screen
- Click "Sign in with Google" button
- Verify Google account picker appears (no clientConfigurationError)
- Complete sign-in flow
- Verify navigation to home screen

**End-to-End Bug 2 Test:**
- Launch app
- Click "Create account" 
- Fill in reader account details and submit
- Login successfully
- Logout from profile menu
- Verify Sign In screen is displayed (not Create Account screen)

**End-to-End Bug 3 Test:**
- Launch app on sign-in screen
- Enter invalid credentials and submit
- Verify error message "Invalid email or password" appears
- Click "Create account" text to toggle forms
- Verify Create Account form is shown with NO error message

**End-to-End Bug 4 Test:**
- Launch app and create a new reader account
- Login and navigate to home screen
- Read a novel
- Close the app completely (kill process)
- Reopen the app
- Verify home screen is displayed immediately (not sign-in screen)
