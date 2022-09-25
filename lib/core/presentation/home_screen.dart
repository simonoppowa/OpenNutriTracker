import 'package:flutter/material.dart';
import 'package:opennutritracker/core/presentation/widgets/home_appbar.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    return const Scaffold(
        appBar: HomeAppbar(), body: Center(child: Text('Home Screen')));
  }
}
