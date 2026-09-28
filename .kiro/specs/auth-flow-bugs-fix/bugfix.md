# Bugfix Requirements Document

## Introduction

This document addresses multiple authentication flow bugs in the Novels Destiny Flutter application that impact user experience and authentication reliability. These bugs include Google Sign-In configuration errors on Android, incorrect navigation after logout, error state persistence across screen transitions, and lack of session persistence across app restarts. Fixing these issues will ensure smooth authentication flows, proper error handling, and consistent user sessions.

## Bug Analysis

### Current Behavior (Defect)

#### 1. Google Sign-In Configuration Error (Android)

1.1 WHEN a user clicks the "Sign in with Google" button on Android THEN the system throws a GoogleSignInException with error code `clientConfigurationError` and message "serverClientId must be provided on Android"

#### 2. Logout Navigation Error

1.2 WHEN a new user creates an account as reader, logs in successfully, and then logs out THEN the system displays the Create Account screen instead of the Sign In screen

#### 3. Error State Persistence Across Navigation

1.3 WHEN a user enters wrong credentials on the sign-in form and sees an error message, then clicks the "Create account" text to navigate to account creation THEN the error message remains displayed on the Create Account screen

#### 4. Session Persistence Failure

1.4 WHEN a user creates an account, logs in to the app, reads a novel, closes the app completely, and reopens the app later THEN the system displays the sign-in screen instead of navigating directly to the home screen

### Expected Behavior (Correct)

#### 1. Google Sign-In Configuration Fix

2.1 WHEN a user clicks the "Sign in with Google" button on Android THEN the system SHALL successfully initialize Google Sign-In with proper serverClientId configuration and allow the user to select a Google account

#### 2. Logout Navigation Fix

2.2 WHEN a user logs out from any authenticated state THEN the system SHALL navigate to and display the Sign In screen (not the Create Account screen)

#### 3. Error State Clearing on Navigation

2.3 WHEN a user navigates from the sign-in form to the create account form (or vice versa) THEN the system SHALL clear any previously displayed error messages and show a clean form state

#### 4. Session Persistence Implementation

2.4 WHEN a user has previously logged in and reopens the app THEN the system SHALL automatically restore the authenticated session and navigate directly to the home screen without requiring login again

### Unchanged Behavior (Regression Prevention)

#### 1. Google Sign-In - Non-Android Platforms

3.1 WHEN a user clicks "Sign in with Google" on iOS or web platforms THEN the system SHALL CONTINUE TO function correctly without requiring serverClientId configuration changes

#### 2. Initial App Launch (No Previous Session)

3.2 WHEN a user launches the app for the first time (no previous authentication session exists) THEN the system SHALL CONTINUE TO display the Sign In screen as the initial route

#### 3. Successful Authentication Navigation

3.3 WHEN a user successfully signs in or creates an account THEN the system SHALL CONTINUE TO navigate to the appropriate screen based on user role and approval status (home screen, writer pending approval, etc.)

#### 4. Error Display for Valid Errors

3.4 WHEN a user enters invalid credentials and submits the form THEN the system SHALL CONTINUE TO display the appropriate error message on the same screen until the user takes action

#### 5. Form Toggle Functionality

3.5 WHEN a user clicks the toggle button to switch between sign-in and create account modes on the same screen THEN the system SHALL CONTINUE TO clear form fields and update the UI appropriately

#### 6. Admin Mode Functionality

3.6 WHEN a user enables admin mode on the sign-in screen THEN the system SHALL CONTINUE TO display the admin portal branding and authentication flow

#### 7. Google Sign-In User Cancellation

3.7 WHEN a user initiates Google Sign-In but cancels the flow THEN the system SHALL CONTINUE TO return to the unauthenticated state without displaying an error message

#### 8. Writer Approval Flow

3.8 WHEN a user creates a writer account THEN the system SHALL CONTINUE TO set approval status to pending and navigate to the writer pending approval screen
