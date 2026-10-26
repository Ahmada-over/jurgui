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
            height: 68,
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
    final itemColor = isSelected ? AppColors.primary : AppColors.textSecondary;

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
                const SizedBox(height: 4),
                Text(
                  label,
                  style: TextStyle(
                    color: itemColor,
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
