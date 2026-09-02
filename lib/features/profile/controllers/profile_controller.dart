import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../domain/entities/user_entity.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../../app/routes/app_routes.dart';

class ProfileController extends GetxController {
  final AuthController _authController;

  ProfileController(this._authController);

  final TextEditingController nameController = TextEditingController();
  final TextEditingController bioController = TextEditingController();

  final RxBool isEditing = false.obs;

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
    Get.snackbar('Profile Updated', 'Your profile details have been saved.');
  }

  Future<void> switchRole(UserRole newRole) async {
    await _authController.switchRole(newRole);
    Get.snackbar('Role Switched', 'Active workspace updated to ${newRole.displayName}.');
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
