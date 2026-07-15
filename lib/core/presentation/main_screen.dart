import 'package:flutter/material.dart';
import 'package:opennutritracker/core/domain/usecase/get_config_usecase.dart';
import 'package:opennutritracker/core/presentation/widgets/add_item_bottom_sheet.dart';
import 'package:opennutritracker/core/styles/app_palette.dart';
import 'package:opennutritracker/core/utils/locator.dart';
import 'package:opennutritracker/features/diary/diary_page.dart';
import 'package:opennutritracker/core/presentation/widgets/home_appbar.dart';
import 'package:opennutritracker/features/home/home_page.dart';
import 'package:opennutritracker/core/presentation/widgets/main_appbar.dart';
import 'package:opennutritracker/features/profile/profile_page.dart';
import 'package:opennutritracker/features/trends/presentation/trends_page.dart';
import 'package:opennutritracker/generated/l10n.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedPageIndex = 0;

  late List<Widget> _bodyPages;
  late List<PreferredSizeWidget> _appbarPages;

  @override
  void didChangeDependencies() {
    _bodyPages = [
      const HomePage(),
      const DiaryPage(),
      const TrendsPage(),
      const ProfilePage(),
    ];
    _appbarPages = [
      const HomeAppbar(),
      MainAppbar(title: S.of(context).diaryLabel, iconData: Icons.book),
      MainAppbar(title: S.of(context).trendsLabel, iconData: Icons.insights),
      MainAppbar(title: S.of(context).youLabel, iconData: Icons.account_circle),
    ];
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final palette = isDark ? AppPalette.dark : AppPalette.light;
    return Scaffold(
      appBar: _appbarPages[_selectedPageIndex],
      body: IndexedStack(index: _selectedPageIndex, children: _bodyPages),
      floatingActionButton: Semantics(
        identifier: 'fab-add-item',
        child: FloatingActionButton(
          onPressed: () => _onFabPressed(context),
          tooltip: S.of(context).addLabel,
          child: const Icon(Icons.add, size: 30),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        color: palette.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        height: 78,
        padding: EdgeInsets.zero,
        shape: const CircularNotchedRectangle(),
        notchMargin: 8,
        child: Row(
          children: [
            _NavItem(
              id: 'nav-home',
              icon: Icons.home_outlined,
              selectedIcon: Icons.home_rounded,
              label: S.of(context).homeLabel,
              index: 0,
              selectedIndex: _selectedPageIndex,
              palette: palette,
              onTap: _setPage,
            ),
            _NavItem(
              id: 'nav-diary',
              icon: Icons.book_outlined,
              selectedIcon: Icons.book_rounded,
              label: S.of(context).diaryLabel,
              index: 1,
              selectedIndex: _selectedPageIndex,
              palette: palette,
              onTap: _setPage,
            ),
            const SizedBox(width: 64), // notch gap for the centre Add FAB
            _NavItem(
              id: 'nav-trends',
              icon: Icons.insights_outlined,
              selectedIcon: Icons.insights_rounded,
              label: S.of(context).trendsLabel,
              index: 2,
              selectedIndex: _selectedPageIndex,
              palette: palette,
              onTap: _setPage,
            ),
            _NavItem(
              id: 'nav-you',
              icon: Icons.account_circle_outlined,
              selectedIcon: Icons.account_circle_rounded,
              label: S.of(context).youLabel,
              index: 3,
              selectedIndex: _selectedPageIndex,
              palette: palette,
              onTap: _setPage,
            ),
          ],
        ),
      ),
    );
  }

  void _setPage(int selectedIndex) {
    setState(() {
      _selectedPageIndex = selectedIndex;
    });
  }

  Future<void> _onFabPressed(BuildContext context) async {
    final config = await locator<GetConfigUsecase>().getConfig();
    if (!context.mounted) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return AddItemBottomSheet(
          day: DateTime.now(),
          showActivityTracking: config.showActivityTracking,
          usesImperialUnits: config.usesImperialFoodUnits,
        );
      },
    );
  }
}

class _NavItem extends StatelessWidget {
  final String id;
  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final int index;
  final int selectedIndex;
  final AppPalette palette;
  final void Function(int) onTap;

  const _NavItem({
    required this.id,
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.index,
    required this.selectedIndex,
    required this.palette,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final selected = index == selectedIndex;
    final color = selected ? Theme.of(context).colorScheme.primary : palette.textMuted;
    return Expanded(
      child: Semantics(
        identifier: id,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => onTap(index),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(selected ? selectedIcon : icon, color: color, size: 26),
                const SizedBox(height: 3),
                Text(
                  label,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(color: color),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
