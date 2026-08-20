import 'package:flutter/material.dart';
import 'package:opennutritracker/core/domain/usecase/get_config_usecase.dart';
import 'package:opennutritracker/core/presentation/widgets/add_item_bottom_sheet.dart';
import 'package:opennutritracker/core/presentation/widgets/demo_mode_banner.dart';
import 'package:opennutritracker/core/styles/app_palette.dart';
import 'package:opennutritracker/core/utils/json_meal_importer.dart';
import 'package:opennutritracker/core/utils/locator.dart';
import 'package:opennutritracker/core/utils/share_intent_service.dart';
import 'package:opennutritracker/features/diary/diary_page.dart';
import 'package:opennutritracker/features/diary/presentation/bloc/calendar_day_bloc.dart';
import 'package:opennutritracker/features/diary/presentation/bloc/diary_bloc.dart';
import 'package:opennutritracker/core/presentation/widgets/home_appbar.dart';
import 'package:opennutritracker/features/home/home_page.dart';
import 'package:opennutritracker/features/home/presentation/bloc/home_bloc.dart';
import 'package:opennutritracker/core/presentation/widgets/main_appbar.dart';
import 'package:opennutritracker/features/profile/profile_page.dart';
import 'package:opennutritracker/features/settings/domain/usecase/import_meals_json_usecase.dart';
import 'package:opennutritracker/features/trends/presentation/trends_page.dart';
import 'package:opennutritracker/generated/l10n.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedPageIndex = 0;
  bool _isDemoData = false;

  late List<Widget> _bodyPages;
  late List<PreferredSizeWidget> _appbarPages;
  late final AppLifecycleListener _lifecycleListener;

  @override
  void initState() {
    super.initState();
    _loadDemoDataFlag();
    _lifecycleListener = AppLifecycleListener(onResume: _handleSharedMeal);
    // Check for a share intent that launched the app cold.
    WidgetsBinding.instance.addPostFrameCallback((_) => _handleSharedMeal());
  }

  @override
  void dispose() {
    _lifecycleListener.dispose();
    super.dispose();
  }

  // Checked once per screen instance rather than kept live — leaving demo
  // mode always replaces this whole screen with the onboarding route (see
  // DemoModeBanner), so there's no in-place transition to react to.
  Future<void> _loadDemoDataFlag() async {
    final config = await locator<GetConfigUsecase>().getConfig();
    if (!mounted) return;
    setState(() => _isDemoData = config.isDemoData);
  }

  /// Reads any pending share-intent text, validates it as meal JSON, shows a
  /// confirmation dialog, and imports on approval. Safe to call frequently —
  /// Kotlin clears the value after the first read so subsequent calls are
  /// no-ops when nothing was shared.
  Future<void> _handleSharedMeal() async {
    if (!mounted) return;
    final text = await ShareIntentService.consumeSharedText();
    if (text == null || !mounted) return;

    final parsed = JsonMealImporter.parse(text);

    if (parsed.intakes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(S.of(context).shareJsonImportErrorLabel)),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(S.of(ctx).importMealConfirmTitle(parsed.intakes.length)),
        content: Text(S.of(ctx).shareJsonImportContent),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(S.of(ctx).dialogCancelLabel),
          ),
          Semantics(
            identifier: 'share-json-import-confirm',
            child: TextButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: Text(S.of(ctx).dialogOKLabel),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final result = await locator<ImportMealsJsonUsecase>().importFromJsonString(text);
    if (!mounted) return;

    locator<HomeBloc>().add(const LoadItemsEvent());
    locator<DiaryBloc>().add(const LoadDiaryYearEvent());
    locator<CalendarDayBloc>().add(RefreshCalendarDayEvent());

    final message = result.imported > 0
        ? S.of(context).csvImportSuccessLabel(result.imported)
        : S.of(context).shareJsonImportErrorLabel;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

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
      body: Column(
        children: [
          if (_isDemoData) const DemoModeBanner(),
          Expanded(
            child: IndexedStack(
              index: _selectedPageIndex,
              children: _bodyPages,
            ),
          ),
        ],
      ),
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
