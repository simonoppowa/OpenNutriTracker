import 'package:flutter/material.dart';
import 'package:opennutritracker/core/presentation/widgets/diary_page.dart';
import 'package:opennutritracker/core/presentation/widgets/home_appbar.dart';
import 'package:opennutritracker/core/presentation/widgets/home_page.dart';
import 'package:opennutritracker/core/presentation/widgets/profile_page.dart';
import 'package:opennutritracker/generated/l10n.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({Key? key}) : super(key: key);

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedPageIndex = 0;
  
  final List<Widget> _bodyPages = [
    const HomePage(),
    const DiaryPage(),
    const ProfilePage(),
  ];
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const HomeAppbar(),
      body: _bodyPages[_selectedPageIndex],
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        tooltip: S.of(context).addLabel,
        child: const Icon(Icons.add),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedPageIndex,
        onDestinationSelected: _setPage,
        destinations: [
          NavigationDestination(
              icon: const Icon(Icons.home_outlined),
              label: S.of(context).homeLabel),
          NavigationDestination(
              icon: const Icon(Icons.book_outlined),
              label: S.of(context).diaryLabel),
          NavigationDestination(
              icon: const Icon(Icons.account_circle_outlined),
              label: S.of(context).profileLabel)
        ],
      ),
    );
  }
  
  void _setPage(int selectedIndex) {
    setState(() {
      _selectedPageIndex = selectedIndex;
    });
  }

}
