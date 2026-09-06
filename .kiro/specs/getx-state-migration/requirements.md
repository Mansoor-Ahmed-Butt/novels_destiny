# Requirements Document

## Introduction

This document defines requirements for migrating the Novels Destiny Flutter application from setState-based state management to a pure GetX reactive architecture. The migration enforces professional, consistent state management patterns across the application by removing all StatefulWidget usage and replacing it with GetX reactive patterns (Obx, GetxController, RxBool, ValueBuilder).

The migration affects four primary components:
1. **AppTextField** - Password visibility toggle state
2. **AuthPage** - Form state (isSignUp, isAdminMode, selectedRole, text controllers)
3. **HomeCarouselSlider** - Carousel current index state
4. **EpisodeReaderPage (_ReaderAdWidget)** - Ad loading state

## Glossary

- **GetX**: A lightweight and powerful Flutter state management library
- **StatefulWidget**: Flutter widget that maintains mutable state using setState
- **StatelessWidget**: Flutter widget with immutable properties that rebuilds reactively
- **Obx**: GetX reactive widget that rebuilds when observable values change
- **RxBool**: GetX reactive boolean observable
- **RxInt**: GetX reactive integer observable
- **Rx**: GetX reactive wrapper for complex types
- **GetxController**: GetX controller class managing reactive state with lifecycle methods
- **ValueBuilder**: GetX widget for localized reactive state without full controller
- **TextEditingController**: Flutter controller for text input fields
- **AppTextField**: Custom reusable text input widget
- **AuthPage**: Authentication page with sign-in and sign-up forms
- **AuthController**: GetX controller managing authentication state and logic
- **HomeCarouselSlider**: Featured novels carousel widget on home page
- **EpisodeReaderPage**: Chapter reading page with content blocks
- **_ReaderAdWidget**: Private stateful widget displaying banner ads in reader
- **EpisodeReaderController**: GetX controller managing episode reading state
- **BannerAd**: Google Mobile Ads banner advertisement instance
- **AdService**: Service class managing ad initialization and creation

## Requirements

### Requirement 1: Remove setState from AppTextField

**User Story:** As a developer, I want AppTextField to be a StatelessWidget with reactive password visibility, so that all widgets follow consistent GetX patterns.

#### Acceptance Criteria

1. THE AppTextField SHALL be converted from StatefulWidget to StatelessWidget
2. WHERE the isPassword parameter is true, THE AppTextField SHALL use ValueBuilder with RxBool for password visibility toggle state
3. WHEN the visibility icon is pressed, THE AppTextField SHALL toggle the RxBool and trigger Obx rebuild
4. THE AppTextField SHALL initialize the RxBool to true (obscured) when isPassword is true
5. THE AppTextField SHALL dispose the RxBool when the ValueBuilder is disposed
6. WHEN obscureText parameter changes from parent, THE AppTextField SHALL respect the new value
7. THE AppTextField SHALL maintain all existing functionality (validation, controllers, callbacks, styling)

### Requirement 2: Move AuthPage Form State to AuthController

**User Story:** As a developer, I want all AuthPage local state managed by AuthController, so that form state is centralized and testable.

#### Acceptance Criteria

1. THE AuthPage SHALL be converted from StatefulWidget to StatelessWidget
2. THE AuthController SHALL expose an RxBool named isSignUp for sign-in/sign-up toggle state
3. THE AuthController SHALL expose an RxBool named isAdminMode for admin portal toggle state
4. THE AuthController SHALL expose an Rx<UserRole> named selectedRole for role selection state
5. THE AuthController SHALL own three TextEditingController instances (nameController, emailController, passwordController)
6. WHEN AuthController is disposed, THE AuthController SHALL dispose all three TextEditingController instances
7. THE AuthPage SHALL access form state through AuthController observables wrapped in Obx
8. WHEN the sign-in/sign-up toggle is pressed, THE AuthController SHALL toggle isSignUp observable
9. WHEN the admin mode switch is changed, THE AuthController SHALL update isAdminMode and set appropriate default credentials
10. WHEN a role chip is tapped, THE AuthController SHALL update selectedRole observable
11. THE AuthController SHALL initialize email and password controllers with default demo credentials

### Requirement 3: Extract HomeCarouselSlider State to HomeCarouselController

**User Story:** As a developer, I want carousel state managed by a dedicated GetX controller, so that carousel state is reactive and follows architectural patterns.

#### Acceptance Criteria

1. THE System SHALL create a new HomeCarouselController extending GetxController
2. THE HomeCarouselController SHALL expose an RxInt named currentIndex initialized to 0
3. THE HomeCarouselController SHALL expose a method named onPageChanged accepting index and reason parameters
4. WHEN onPageChanged is called, THE HomeCarouselController SHALL update currentIndex observable
5. THE HomeCarouselSlider SHALL be converted from StatefulWidget to StatelessWidget
6. THE HomeCarouselSlider SHALL inject HomeCarouselController using Get.put or Get.find
7. THE HomeCarouselSlider SHALL wrap carousel and dot indicator sections with Obx widgets
8. THE HomeCarouselSlider SHALL pass controller.onPageChanged to CarouselOptions.onPageChanged callback
9. THE HomeCarouselSlider SHALL access currentIndex through controller.currentIndex.value
10. THE HomeCarouselController SHALL maintain CarouselSliderController instance for programmatic navigation

### Requirement 4: Move Reader Ad State to Controller

**User Story:** As a developer, I want reader ad state managed reactively, so that ad widgets follow GetX patterns and can be tested.

#### Acceptance Criteria

1. THE _ReaderAdWidget SHALL be converted from StatefulWidget to StatelessWidget
2. THE EpisodeReaderController SHALL expose an RxBool named isAdLoaded initialized to false
3. THE EpisodeReaderController SHALL expose a nullable Rx<BannerAd?> named bannerAd initialized to null
4. THE EpisodeReaderController SHALL expose a method named loadReaderAd that creates and loads a BannerAd
5. WHEN loadReaderAd creates an ad, THE loadReaderAd SHALL pass onAdLoaded callback that sets isAdLoaded to true
6. WHEN loadReaderAd creates an ad, THE loadReaderAd SHALL pass onAdFailedToLoad callback that sets isAdLoaded to false
7. WHEN EpisodeReaderController is disposed, THE EpisodeReaderController SHALL dispose bannerAd if not null
8. THE _ReaderAdWidget SHALL inject EpisodeReaderController using Get.find
9. THE _ReaderAdWidget SHALL wrap its build method content with Obx widget
10. THE _ReaderAdWidget SHALL call controller.loadReaderAd() in initState or constructor
11. THE _ReaderAdWidget SHALL display AdWidget when controller.isAdLoaded is true and controller.bannerAd is not null
12. THE _ReaderAdWidget SHALL display placeholder when controller.isAdLoaded is false or controller.bannerAd is null

### Requirement 5: Verify Dart Analysis Compliance

**User Story:** As a developer, I want the migrated code to pass static analysis, so that code quality standards are maintained.

#### Acceptance Criteria

1. WHEN dart analyze is run on the project, THE System SHALL return zero errors
2. WHEN dart analyze is run on the project, THE System SHALL return zero warnings related to the migration
3. THE System SHALL not introduce new linter violations in migrated files
4. THE System SHALL resolve any existing linter violations in migrated files where possible

### Requirement 6: Verify Functional Correctness

**User Story:** As a user, I want all UI behaviors to work exactly as before migration, so that the refactoring is transparent.

#### Acceptance Criteria

1. WHEN the password visibility icon is tapped in AppTextField, THE AppTextField SHALL toggle between showing and hiding password
2. WHEN the sign-in/sign-up toggle is pressed on AuthPage, THE AuthPage SHALL switch between sign-in and sign-up forms
3. WHEN the admin mode switch is toggled on AuthPage, THE AuthPage SHALL update UI styling and set admin credentials
4. WHEN a role chip is tapped on sign-up form, THE AuthPage SHALL highlight the selected role
5. WHEN the home carousel auto-plays, THE HomeCarouselSlider SHALL update dot indicators to reflect current slide
6. WHEN a carousel dot indicator is tapped, THE HomeCarouselSlider SHALL animate to the corresponding slide
7. WHEN the reader page displays a content block with type ad, THE _ReaderAdWidget SHALL load and display a banner ad
8. WHEN an ad fails to load, THE _ReaderAdWidget SHALL display the placeholder advertisement container

### Requirement 7: Maintain Controller Lifecycle Management

**User Story:** As a developer, I want proper disposal of resources, so that memory leaks are prevented.

#### Acceptance Criteria

1. WHEN AuthController is disposed, THE AuthController SHALL call dispose on all TextEditingController instances
2. WHEN EpisodeReaderController is disposed, THE EpisodeReaderController SHALL call dispose on bannerAd if not null
3. WHERE ValueBuilder is used with RxBool, THE ValueBuilder SHALL automatically dispose the RxBool when disposed
4. THE System SHALL not create duplicate GetxController instances for the same logical component
5. THE System SHALL use appropriate GetX dependency injection patterns (Get.put, Get.lazyPut, Get.find)

### Requirement 8: Document Migration Patterns

**User Story:** As a developer, I want clear code comments documenting GetX patterns, so that future developers understand the architectural decisions.

#### Acceptance Criteria

1. THE AppTextField SHALL include a comment explaining why ValueBuilder is used instead of GetxController
2. THE AuthController SHALL include a comment explaining the ownership of TextEditingControllers
3. THE HomeCarouselController SHALL include a comment explaining the purpose of onPageChanged method
4. THE EpisodeReaderController SHALL include a comment explaining ad state management in the controller
5. WHERE RxBool or RxInt is used, THE System SHALL include inline comments explaining the observable pattern

### Requirement 9: Ensure GetX Dependency Availability

**User Story:** As a developer, I want GetX dependencies properly registered, so that controllers are accessible where needed.

#### Acceptance Criteria

1. THE HomeCarouselController SHALL be registered using Get.put or Get.lazyPut before HomeCarouselSlider is built
2. THE AuthController SHALL already be registered before AuthPage is built (existing requirement)
3. THE EpisodeReaderController SHALL already be registered with tag before EpisodeReaderPage is built (existing requirement)
4. WHERE Get.find is used, THE System SHALL ensure the controller is already registered in the dependency tree
5. WHEN a controller is not found, THE System SHALL throw a clear error message indicating missing registration

### Requirement 10: Preserve Existing Behavior and Props

**User Story:** As a developer, I want all widget properties and behaviors preserved, so that no regressions are introduced.

#### Acceptance Criteria

1. THE AppTextField SHALL maintain all existing parameters (label, hint, controller, onChanged, onSubmitted, obscureText, isPassword, keyboardType, maxLines, minLines, prefixIcon, suffixIcon, errorText, enabled)
2. THE AuthPage SHALL maintain all existing user interactions (quick login badges, Google sign-in, form submission)
3. THE HomeCarouselSlider SHALL maintain all existing parameters (novels, onNovelTap)
4. THE HomeCarouselSlider SHALL maintain carousel options (autoPlay, autoPlayInterval, viewportFraction, enlargeCenterPage)
5. THE _ReaderAdWidget SHALL maintain the theme parameter and placeholder styling
6. THE System SHALL not modify any styling, layout, or visual appearance during migration
