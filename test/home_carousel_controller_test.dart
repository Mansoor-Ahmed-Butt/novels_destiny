import 'package:flutter_test/flutter_test.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:novels_destiny/features/home/controllers/home_carousel_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('HomeCarouselController Tests', () {
    late HomeCarouselController controller;

    setUp(() {
      controller = HomeCarouselController();
    });

    test('Initializes with currentIndex 0', () {
      expect(controller.currentIndex.value, 0);
      expect(controller.carouselController, isNotNull);
    });

    test('onPageChanged updates currentIndex observable', () {
      expect(controller.currentIndex.value, 0);

      controller.onPageChanged(2, CarouselPageChangedReason.manual);
      expect(controller.currentIndex.value, 2);

      controller.onPageChanged(4, CarouselPageChangedReason.timed);
      expect(controller.currentIndex.value, 4);

      controller.onPageChanged(0, CarouselPageChangedReason.controller);
      expect(controller.currentIndex.value, 0);
    });
  });
}
