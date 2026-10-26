import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../core/constants/colors.dart';
import '../../core/widgets/sheep_hoof_icon.dart';

class MainNavigationShell extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const MainNavigationShell({super.key, required this.navigationShell});

  void _onItemTapped(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: AppColors.divider)),
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 64,
            child: Row(
              children: [
                _buildNavItem(
                  index: 0,
                  icon: LucideIcons.layoutGrid,
                  label: 'Aperçu',
                ),
                _buildNavItem(
                  index: 1,
                  customIconBuilder: (color) =>
                      SheepHoofIcon(size: 21, color: color),
                  label: 'Cheptel',
                ),
                _buildNavItem(
                  index: 2,
                  icon: LucideIcons.heart,
                  label: 'Repro',
                ),
                _buildNavItem(
                  index: 3,
                  icon: LucideIcons.user,
                  label: 'Profil',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    IconData? icon,
    Widget Function(Color color)? customIconBuilder,
    required String label,
  }) {
    final isSelected = navigationShell.currentIndex == index;
    final itemColor = isSelected ? AppColors.goldDark : AppColors.textSecondary;

    return Expanded(
      child: Semantics(
        button: true,
        selected: isSelected,
        label: label,
        child: InkWell(
          onTap: () => _onItemTapped(index),
          child: SizedBox.expand(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                customIconBuilder != null
                    ? customIconBuilder(itemColor)
                    : Icon(
                        icon,
                        size: 21,
                        color: itemColor,
                      ),
                AnimatedSize(
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeOutCubic,
                  child: isSelected
                      ? Padding(
                          padding: const EdgeInsets.only(top: 3),
                          child: Text(
                            label,
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        )
                      : const SizedBox.shrink(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
