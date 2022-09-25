import 'package:flutter/material.dart';
import 'package:opennutritracker/core/presentation/widgets/home_appbar.dart';
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
    );
  }
}
