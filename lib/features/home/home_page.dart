import 'package:flutter/material.dart';
import 'package:opennutritracker/features/home/presentation/dashboard_widget.dart';

class HomePage extends StatelessWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16.0, 0.0, 16.0, 0.0),
      child: ListView(children: const [DashboardWidget()]),
    );
  }
}
