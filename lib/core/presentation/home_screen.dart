import 'package:flutter/material.dart';
import 'package:opennutritracker/core/presentation/widgets/diary_page.dart';
import 'package:opennutritracker/core/presentation/widgets/home_appbar.dart';
import 'package:opennutritracker/core/presentation/widgets/home_page.dart';
import 'package:opennutritracker/core/presentation/widgets/profile_page.dart';
import 'package:opennutritracker/generated/l10n.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const HomeAppbar(),
      body: const Center(child: Text('Home Screen')),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        tooltip: S.of(context).addLabel,
        child: const Icon(Icons.add),
      ),
      bottomNavigationBar: NavigationBar(
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
}
