import 'package:flutter/material.dart';

class MainAppbar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final IconData iconData;

  const MainAppbar({super.key, required this.title, required this.iconData});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      leading: Icon(iconData),
      title: Text(title),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
