import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../domain/entities/user_entity.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../../app/routes/app_routes.dart';
import '../../../core/localization/localization_service.dart';

class ProfileController extends GetxController {
  final AuthController _authController;

  ProfileController(this._authController);

  LocalizationService get _localizationService => LocalizationService.to;

  final TextEditingController nameController = TextEditingController();
  final TextEditingController bioController = TextEditingController();

  final RxBool isEditing = false.obs;

  Rx<Locale> get currentLocale => _localizationService.rxLocale;
  bool get isUrdu => _localizationService.isUrdu;

  @override
  void onInit() {
    super.onInit();
    final user = _authController.currentUser.value;
    if (user != null) {
      nameController.text = user.displayName;
      bioController.text = user.bio ?? '';
    }
  }

  void toggleEdit() {
    isEditing.value = !isEditing.value;
    if (!isEditing.value) {
      final user = _authController.currentUser.value;
      if (user != null) {
        nameController.text = user.displayName;
        bioController.text = user.bio ?? '';
      }
    }
  }

  Future<void> saveProfile() async {
    await _authController.updateProfile(
      displayName: nameController.text.trim(),
      bio: bioController.text.trim(),
    );
    isEditing.value = false;
    Get.snackbar(
      'profile_updated'.tr,
      'profile_updated_message'.tr,
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  Future<void> switchRole(UserRole newRole) async {
    await _authController.switchRole(newRole);
    Get.snackbar(
      'role_switched'.tr,
      'active_workspace_updated'.trParams({'role': newRole.displayName}),
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  Future<void> changeLanguage(Locale locale) async {
    await _localizationService.changeLocale(locale);
    final isUrduNow = locale.languageCode == 'ur';
    Get.snackbar(
      isUrduNow ? 'زبان تبدیل ہو گئی' : 'Language Changed',
      isUrduNow
          ? 'ایپ کی زبان کامیابی سے اردو میں تبدیل کر دی گئی ہے۔'
          : 'App interface language successfully switched to English.',
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 3),
    );
  }

  Future<void> toggleLanguage() async {
    if (isUrdu) {
      await changeLanguage(LocalizationService.englishLocale);
    } else {
      await changeLanguage(LocalizationService.urduLocale);
    }
  }

  Future<void> signOut() async {
    await _authController.signOut();
    Get.offAllNamed(AppRoutes.auth);
  }

  @override
  void onClose() {
    nameController.dispose();
    bioController.dispose();
    super.onClose();
  }
}
