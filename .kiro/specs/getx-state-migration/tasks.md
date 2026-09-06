# Implementation Plan: GetX State Migration

## Overview

This implementation plan converts four Flutter components from StatefulWidget with setState to StatelessWidget with GetX reactive patterns. The migration establishes uniform state management by introducing GetxControllers and ValueBuilder for reactive state, while preserving all existing functionality and visual appearance.

## Tasks

- [x] 1. Migrate AppTextField to StatelessWidget with ValueBuilder
  - [x] 1.1 Convert AppTextField class from StatefulWidget to StatelessWidget
    - Remove _AppTextFieldState class entirely
    - Update AppTextField constructor to use const
    - Move all widget parameters to the StatelessWidget class
    - _Requirements: 1.1_
  
  - [x] 1.2 Implement password visibility with ValueBuilder and RxBool
    - Add conditional logic: if isPassword is false, return simple TextField
    - Wrap password TextField with ValueBuilder<bool?> initialized to true
    - Pass obscureText value from ValueBuilder to _buildTextField
    - Add onToggleVisibility callback that calls updateFn to toggle RxBool
    - _Requirements: 1.2, 1.3, 1.4, 1.5_
  
  - [x] 1.3 Write widget tests for AppTextField password visibility
    - Test password visibility toggle changes icon from visibility_off to visibility
    - Test non-password fields don't show visibility icon
    - Test obscureText parameter is respected for non-password fields
    - _Requirements: 6.1_

- [x] 2. Checkpoint - Verify AppTextField migration
  - Ensure all tests pass, ask the user if questions arise.

- [x] 3. Extend AuthController with form state management
  - [x] 3.1 Add reactive observables to AuthController
    - Add RxBool isSignUp initialized to false
    - Add RxBool isAdminMode initialized to false
    - Add Rx<UserRole> selectedRole initialized to UserRole.reader
    - _Requirements: 2.2, 2.3, 2.4_
  
  - [x] 3.2 Add TextEditingController instances to AuthController
    - Declare three late final TextEditingController fields (nameController, emailController, passwordController)
    - Initialize controllers in onInit() with default demo credentials
    - Add disposal logic in onClose() for all three controllers
    - _Requirements: 2.5, 2.6, 2.11_
  
  - [x] 3.3 Implement form state management methods in AuthController
    - Implement toggleSignUpMode() that toggles isSignUp and clears/resets credentials
    - Implement toggleAdminMode(bool enabled) that updates isAdminMode and sets appropriate credentials
    - Implement setSelectedRole(UserRole role) that updates selectedRole observable
    - _Requirements: 2.8, 2.9, 2.10_
  
  - [x] 3.4 Write unit tests for AuthController form state methods
    - Test toggleSignUpMode clears form for sign-up and resets for sign-in
    - Test toggleAdminMode updates credentials appropriately
    - Test setSelectedRole updates selectedRole observable
    - Test text controllers are disposed in onClose
    - _Requirements: 2.2, 2.3, 2.4, 2.5, 2.6, 7.1_

- [x] 4. Migrate AuthPage to StatelessWidget with GetX observables
  - [x] 4.1 Convert AuthPage to StatelessWidget
    - Remove _AuthPageState class entirely
    - Convert AuthPage class from StatefulWidget to StatelessWidget
    - Remove all local state variables (isSignUp, isAdminMode, selectedRole, text controllers)
    - _Requirements: 2.1_
  
  - [x] 4.2 Wrap form UI with Obx for reactive rebuilds
    - Inject AuthController using Get.find<AuthController>()
    - Wrap header section with Obx to react to isAdminMode changes
    - Wrap form card with Obx to react to isSignUp and isAdminMode changes
    - Use controller.nameController, emailController, passwordController for AppTextField instances
    - _Requirements: 2.7_
  
  - [x] 4.3 Update form interaction callbacks to use controller methods
    - Update sign-in/sign-up toggle to call controller.toggleSignUpMode()
    - Update admin mode switch to call controller.toggleAdminMode(value)
    - Update role chip taps to call controller.setSelectedRole(role)
    - Update submit button to read values from controller text controllers
    - _Requirements: 2.8, 2.9, 2.10_
  
  - [x] 4.4 Write integration tests for AuthPage form interactions
    - Test sign-in/sign-up toggle switches forms correctly
    - Test admin mode toggle updates UI and credentials
    - Test role selection updates selectedRole
    - Test form submission calls appropriate controller methods
    - _Requirements: 6.2, 6.3, 6.4_

- [x] 5. Checkpoint - Verify AuthPage migration
  - Ensure all tests pass, ask the user if questions arise.

- [x] 6. Create HomeCarouselController for carousel state
  - [x] 6.1 Create HomeCarouselController class extending GetxController
    - Create new file: lib/features/home/controllers/home_carousel_controller.dart
    - Add RxInt currentIndex initialized to 0
    - Add CarouselSliderController instance for programmatic navigation
    - Add documentation comments explaining controller responsibilities
    - _Requirements: 3.1, 3.2, 3.10, 8.3_
  
  - [x] 6.2 Implement carousel state management methods
    - Implement onPageChanged(int index, CarouselPageChangedReason reason) that updates currentIndex
    - Implement animateToSlide(int index) that calls carouselController.animateToPage
    - _Requirements: 3.3, 3.4_
  
  - [x] 6.3 Write unit tests for HomeCarouselController
    - Test onPageChanged updates currentIndex observable
    - Test animateToSlide calls carouselController.animateToPage with correct parameters
    - _Requirements: 3.3, 3.4_

- [x] 7. Migrate HomeCarouselSlider to StatelessWidget with controller
  - [x] 7.1 Convert HomeCarouselSlider to StatelessWidget
    - Remove _HomeCarouselSliderState class entirely
    - Convert HomeCarouselSlider from StatefulWidget to StatelessWidget
    - Remove local _currentIndex and _carouselController state variables
    - _Requirements: 3.5_
  
  - [x] 7.2 Integrate HomeCarouselController in widget build
    - Inject or create HomeCarouselController using Get.put(HomeCarouselController())
    - Pass controller.carouselController to CarouselSlider.builder
    - Pass controller.onPageChanged to CarouselOptions.onPageChanged callback
    - _Requirements: 3.6, 3.7, 3.8, 9.1_
  
  - [x] 7.3 Wrap carousel elements with Obx for reactive updates
    - Wrap slide card builder with Obx to react to currentIndex changes for isActive state
    - Wrap dot indicators with Obx to react to currentIndex changes
    - Update dot indicator tap callback to call controller.animateToSlide(index)
    - _Requirements: 3.7, 3.9_
  
  - [x] 7.4 Write integration tests for HomeCarouselSlider
    - Test carousel auto-play updates currentIndex
    - Test dot indicators reflect current slide
    - Test tapping dot animates to corresponding slide
    - _Requirements: 6.5, 6.6_

- [x] 8. Checkpoint - Verify HomeCarouselSlider migration
  - Ensure all tests pass, ask the user if questions arise.

- [x] 9. Extend EpisodeReaderController with ad state management
  - [x] 9.1 Add ad state observables to EpisodeReaderController
    - Add RxBool isAdLoaded initialized to false
    - Add Rx<BannerAd?> bannerAd initialized to null
    - Add documentation comments explaining ad state management
    - _Requirements: 4.2, 4.3, 8.4_
  
  - [x] 9.2 Implement loadReaderAd method in EpisodeReaderController
    - Create loadReaderAd() method that calls AdService().createBannerAd
    - Pass onAdLoaded callback that sets isAdLoaded to true
    - Pass onAdFailedToLoad callback that sets isAdLoaded to false and logs warning
    - Store ad instance in bannerAd observable and call load()
    - _Requirements: 4.4, 4.5, 4.6_
  
  - [x] 9.3 Add ad disposal logic to EpisodeReaderController.onClose
    - Call bannerAd.value?.dispose() in onClose method
    - Set bannerAd.value to null after disposal
    - _Requirements: 4.7, 7.2_
  
  - [x] 9.4 Write unit tests for EpisodeReaderController ad state
    - Test loadReaderAd creates and loads banner ad
    - Test onAdLoaded callback updates isAdLoaded to true
    - Test onAdFailedToLoad callback updates isAdLoaded to false
    - Test bannerAd is disposed in onClose
    - _Requirements: 4.4, 4.5, 4.6, 4.7_

- [x] 10. Migrate _ReaderAdWidget to StatelessWidget with controller state
  - [x] 10.1 Convert _ReaderAdWidget to StatelessWidget
    - Remove _ReaderAdWidgetState class entirely
    - Convert _ReaderAdWidget from StatefulWidget to StatelessWidget
    - Remove local _bannerAd and _isAdLoaded state variables
    - _Requirements: 4.1_
  
  - [x] 10.2 Inject EpisodeReaderController and trigger ad loading
    - Extract novelId and episodeId from Get.parameters
    - Inject EpisodeReaderController using Get.find with tag '$novelId-$episodeId'
    - Call controller.loadReaderAd() if controller.bannerAd.value is null
    - _Requirements: 4.8, 4.10, 9.2_
  
  - [x] 10.3 Wrap widget content with Obx for reactive ad display
    - Wrap entire build method body with Obx widget
    - Access isAdLoaded and bannerAd from controller observables
    - Show AdWidget when isAdLoaded is true and bannerAd is not null
    - Show placeholder when isAdLoaded is false or bannerAd is null
    - _Requirements: 4.9, 4.11, 4.12_
  
  - [x] 10.4 Write widget tests for _ReaderAdWidget
    - Test placeholder displays when ad is not loaded
    - Test AdWidget displays when ad is loaded
    - Test ad failure shows placeholder
    - _Requirements: 6.7, 6.8_

- [x] 11. Final verification and testing
  - [x] 11.1 Run dart analyze to verify zero errors and warnings
    - Execute dart analyze on the project
    - Verify zero errors related to the migration
    - Resolve any new linter violations in migrated files
    - _Requirements: 5.1, 5.2, 5.3, 5.4_
  
  - [x] 11.2 Verify controller lifecycle management and dependency injection
    - Verify AuthController text controllers are disposed
    - Verify EpisodeReaderController ad is disposed
    - Verify HomeCarouselController is registered before HomeCarouselSlider
    - Verify no duplicate controller instances are created
    - _Requirements: 7.1, 7.2, 7.3, 7.4, 7.5, 9.1, 9.2, 9.3, 9.4_
  
  - [x] 11.3 Run comprehensive manual testing checklist
    - Test AppTextField password visibility toggle
    - Test AuthPage form interactions (sign-in/sign-up toggle, admin mode, role selection)
    - Test HomeCarouselSlider auto-play and dot indicators
    - Test _ReaderAdWidget ad loading and placeholder display
    - _Requirements: 6.1, 6.2, 6.3, 6.4, 6.5, 6.6, 6.7, 6.8_

- [x] 12. Final checkpoint - Migration complete
  - Ensure all tests pass, ask the user if questions arise.

## Notes

- Tasks marked with `*` are optional and can be skipped for faster migration completion
- Each task references specific requirements from the requirements document for traceability
- Checkpoints ensure incremental validation and provide opportunities to address issues
- The migration preserves all existing functionality - no visual changes or behavior modifications
- All new observables and controllers follow GetX naming and lifecycle conventions
- Text controllers and ad instances are properly disposed to prevent memory leaks
- Controller registration follows GetX dependency injection patterns (Get.put, Get.find)

## Task Dependency Graph

```json
{
  "waves": [
    { "id": 0, "tasks": ["1.1"] },
    { "id": 1, "tasks": ["1.2", "3.1"] },
    { "id": 2, "tasks": ["1.3", "3.2"] },
    { "id": 3, "tasks": ["3.3", "4.1"] },
    { "id": 4, "tasks": ["3.4", "4.2", "6.1"] },
    { "id": 5, "tasks": ["4.3", "6.2"] },
    { "id": 6, "tasks": ["4.4", "6.3", "7.1"] },
    { "id": 7, "tasks": ["7.2"] },
    { "id": 8, "tasks": ["7.3", "9.1"] },
    { "id": 9, "tasks": ["7.4", "9.2"] },
    { "id": 10, "tasks": ["9.3", "10.1"] },
    { "id": 11, "tasks": ["9.4", "10.2"] },
    { "id": 12, "tasks": ["10.3"] },
    { "id": 13, "tasks": ["10.4", "11.1"] },
    { "id": 14, "tasks": ["11.2"] },
    { "id": 15, "tasks": ["11.3"] }
  ]
}
```
