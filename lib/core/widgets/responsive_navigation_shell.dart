import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../app/theme/app_theme.dart';
import '../../domain/entities/user_entity.dart';
import '../responsive/responsive_layout.dart';
import '../../features/auth/controllers/auth_controller.dart';

class NavItem {
  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final String route;
  final List<UserRole> allowedRoles;

  const NavItem({
    required this.label,
    required this.icon,
    required this.selectedIcon,
    required this.route,
    this.allowedRoles = const [UserRole.reader, UserRole.writer, UserRole.admin],
  });
}

class ResponsiveNavigationShell extends StatelessWidget {
  final Widget child;
  final int currentIndex;
  final ValueChanged<int> onNavigationChanged;
  final List<NavItem> navItems;
  final Widget? floatingActionButton;

  const ResponsiveNavigationShell({
    super.key,
    required this.child,
    required this.currentIndex,
    required this.onNavigationChanged,
    required this.navItems,
    this.floatingActionButton,
  });

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(
      compact: _buildCompact(context),
      medium: _buildMedium(context),
      expanded: _buildExpanded(context),
    );
  }

  Widget _buildCompact(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(child: child),
      floatingActionButton: floatingActionButton,
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.m, vertical: AppSpacing.s),
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: const Border(top: BorderSide(color: AppColors.cardBorder, width: 1)),
        ),
        child: SafeArea(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(navItems.length, (index) {
              final item = navItems[index];
              final isSelected = index == currentIndex;
              return InkWell(
                onTap: () => onNavigationChanged(index),
                borderRadius: BorderRadius.circular(AppRadii.pill),
                child: AnimatedContainer(
                  duration: AppDurations.fast,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.surfaceMuted : Colors.transparent,
                    borderRadius: BorderRadius.circular(AppRadii.pill),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isSelected ? item.selectedIcon : item.icon,
                        size: 22,
                        color: isSelected ? AppColors.primary : AppColors.textSecondary,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        item.label,
                        style: AppTextStyles.labelSmall.copyWith(
                          color: isSelected ? AppColors.primary : AppColors.textSecondary,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }

  Widget _buildMedium(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Row(
        children: [
          Container(
            width: 88,
            decoration: const BoxDecoration(
              color: AppColors.surface,
              border: Border(right: BorderSide(color: AppColors.cardBorder)),
            ),
            child: SafeArea(
              child: Column(
                children: [
                  const SizedBox(height: AppSpacing.l),
                  _buildBrandLogo(isCompact: true),
                  const SizedBox(height: AppSpacing.xl),
                  Expanded(
                    child: ListView.separated(
                      itemCount: navItems.length,
                      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.s),
                      itemBuilder: (context, index) {
                        final item = navItems[index];
                        final isSelected = index == currentIndex;
                        return InkWell(
                          onTap: () => onNavigationChanged(index),
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: AppSpacing.s),
                            padding: const EdgeInsets.symmetric(vertical: AppSpacing.m),
                            decoration: BoxDecoration(
                              color: isSelected ? AppColors.surfaceMuted : Colors.transparent,
                              borderRadius: BorderRadius.circular(AppRadii.m),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  isSelected ? item.selectedIcon : item.icon,
                                  color: isSelected ? AppColors.primary : AppColors.textSecondary,
                                  size: 24,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  item.label,
                                  style: AppTextStyles.labelSmall.copyWith(
                                    color: isSelected ? AppColors.primary : AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  _buildUserBadge(isCompact: true),
                  const SizedBox(height: AppSpacing.m),
                ],
              ),
            ),
          ),
          Expanded(child: SafeArea(child: child)),
        ],
      ),
      floatingActionButton: floatingActionButton,
    );
  }

  Widget _buildExpanded(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Row(
        children: [
          Container(
            width: 260,
            decoration: const BoxDecoration(
              color: AppColors.surface,
              border: Border(right: BorderSide(color: AppColors.cardBorder)),
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.l),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildBrandLogo(isCompact: false),
                    const SizedBox(height: AppSpacing.xxl),
                    Expanded(
                      child: ListView.separated(
                        itemCount: navItems.length,
                        separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.xs),
                        itemBuilder: (context, index) {
                          final item = navItems[index];
                          final isSelected = index == currentIndex;
                          return InkWell(
                            onTap: () => onNavigationChanged(index),
                            borderRadius: BorderRadius.circular(AppRadii.pill),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.m,
                                vertical: AppSpacing.m,
                              ),
                              decoration: BoxDecoration(
                                color: isSelected ? AppColors.surfaceMuted : Colors.transparent,
                                borderRadius: BorderRadius.circular(AppRadii.pill),
                                border: isSelected
                                    ? Border.all(color: AppColors.cardBorder.withOpacity(0.8))
                                    : null,
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    isSelected ? item.selectedIcon : item.icon,
                                    color: isSelected ? AppColors.primary : AppColors.textSecondary,
                                    size: 20,
                                  ),
                                  const SizedBox(width: AppSpacing.m),
                                  Text(
                                    item.label,
                                    style: AppTextStyles.titleSmall.copyWith(
                                      color: isSelected ? AppColors.primary : AppColors.textSecondary,
                                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    _buildUserBadge(isCompact: false),
                  ],
                ),
              ),
            ),
          ),
          Expanded(child: SafeArea(child: child)),
        ],
      ),
      floatingActionButton: floatingActionButton,
    );
  }

  Widget _buildBrandLogo({required bool isCompact}) {
    if (isCompact) {
      return Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(AppRadii.m),
        ),
        child: const Center(
          child: Icon(Icons.auto_stories, color: AppColors.textInverse, size: 22),
        ),
      );
    }

    return Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(AppRadii.m),
          ),
          child: const Center(
            child: Icon(Icons.auto_stories, color: AppColors.textInverse, size: 20),
          ),
        ),
        const SizedBox(width: AppSpacing.m),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Novels Destiny',
              style: AppTextStyles.titleMedium.copyWith(
                fontWeight: FontWeight.w800,
                color: AppColors.primary,
                letterSpacing: -0.2,
              ),
            ),
            Text(
              'Editorial Studio',
              style: AppTextStyles.labelSmall.copyWith(color: AppColors.textTertiary),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildUserBadge({required bool isCompact}) {
    final authController = Get.find<AuthController>();
    return Obx(() {
      final user = authController.currentUser.value;
      if (user == null) return const SizedBox.shrink();

      if (isCompact) {
        return Tooltip(
          message: '${user.displayName} (${user.role.displayName})',
          child: CircleAvatar(
            radius: 18,
            backgroundColor: AppColors.primary,
            child: Text(
              user.displayName.isNotEmpty ? user.displayName[0] : 'U',
              style: const TextStyle(color: AppColors.textInverse, fontWeight: FontWeight.bold),
            ),
          ),
        );
      }

      return Container(
        padding: const EdgeInsets.all(AppSpacing.s),
        decoration: BoxDecoration(
          color: AppColors.surfaceMuted,
          borderRadius: BorderRadius.circular(AppRadii.card),
          border: Border.all(color: AppColors.cardBorder.withOpacity(0.8)),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: AppColors.primary,
              child: Text(
                user.displayName.isNotEmpty ? user.displayName[0] : 'U',
                style: const TextStyle(color: AppColors.textInverse, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: AppSpacing.s),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.displayName,
                    style: AppTextStyles.labelLarge,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    user.role.displayName,
                    style: AppTextStyles.labelSmall.copyWith(
                      color: AppColors.accent,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    });
  }
}
