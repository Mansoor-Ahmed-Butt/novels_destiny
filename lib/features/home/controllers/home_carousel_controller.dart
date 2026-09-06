import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:carousel_slider/carousel_slider.dart';

/// Controller managing carousel state and programmatic navigation
///
/// Responsibilities:
/// - Track current slide index via reactive [currentIndex] observable
/// - Manage [CarouselSliderController] instance for programmatic slide transitions
/// - Handle page change events triggered by auto-play or manual user gestures
class HomeCarouselController extends GetxController {
  /// Reactive observable tracking the active carousel slide index
  final RxInt currentIndex = 0.obs;

  /// Carousel controller used for programmatic slide navigation and animations
  final CarouselSliderController carouselController = CarouselSliderController();

  /// Called when carousel page changes (auto-play or swipe gesture).
  /// Updates the reactive [currentIndex] observable.
  void onPageChanged(int index, CarouselPageChangedReason reason) {
    currentIndex.value = index;
  }

  /// Navigates to a specific slide with smooth cubic easing animation.
  void animateToSlide(int index) {
    carouselController.animateToPage(
      index,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOutCubic,
    );
  }
}
