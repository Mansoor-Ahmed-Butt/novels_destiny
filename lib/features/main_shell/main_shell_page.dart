import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/widgets/responsive_navigation_shell.dart';
import '../../core/constants/app_icons.dart';
import '../../domain/entities/user_entity.dart';
import '../auth/controllers/auth_controller.dart';
import '../home/pages/home_page.dart';
import '../library/pages/library_page.dart';
import '../writer_dashboard/pages/writer_dashboard_page.dart';
import '../admin_dashboard/pages/admin_dashboard_page.dart';
import '../profile/pages/profile_page.dart';

class MainShellController extends GetxController {
  final RxInt selectedIndex = 0.obs;

  void changeIndex(int index) {
    selectedIndex.value = index;
  }
}

class MainShellPage extends StatelessWidget {
  const MainShellPage({super.key});

  @override
  Widget build(BuildContext context) {
    final shellController = Get.put(MainShellController());
    final authController = Get.find<AuthController>();

    return Obx(() {
      final user = authController.currentUser.value;
      final role = user?.role ?? UserRole.reader;

      // Build navigation items based on current active user role
      final List<NavItem> navItems = [
        const NavItem(
          label: 'Discover',
          icon: AppIcons.home,
          selectedIcon: AppIcons.homeFilled,
          route: '/home',
        ),
        const NavItem(
          label: 'Library',
          icon: AppIcons.library,
          selectedIcon: AppIcons.libraryFilled,
          route: '/library',
        ),
        if (role == UserRole.writer || role == UserRole.admin)
          const NavItem(
            label: 'Studio',
            icon: AppIcons.studio,
            selectedIcon: AppIcons.studioFilled,
            route: '/writer',
          ),
        if (role == UserRole.admin)
          const NavItem(
            label: 'Admin',
            icon: AppIcons.admin,
            selectedIcon: AppIcons.adminFilled,
            route: '/admin',
          ),
        const NavItem(
          label: 'Profile',
          icon: AppIcons.profile,
          selectedIcon: AppIcons.profileFilled,
          route: '/profile',
        ),
      ];

      final List<Widget> pages = [
        const HomePage(),
        const LibraryPage(),
        if (role == UserRole.writer || role == UserRole.admin) const WriterDashboardPage(),
        if (role == UserRole.admin) const AdminDashboardPage(),
        const ProfilePage(),
      ];

      // Ensure index is within bounds
      if (shellController.selectedIndex.value >= pages.length) {
        shellController.selectedIndex.value = 0;
      }

      final currentIndex = shellController.selectedIndex.value;

      return ResponsiveNavigationShell(
        currentIndex: currentIndex,
        onNavigationChanged: shellController.changeIndex,
        navItems: navItems,
        child: IndexedStack(
          index: currentIndex,
          children: pages,
        ),
      );
    });
  }
}
