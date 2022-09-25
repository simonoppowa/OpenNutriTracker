import 'package:flutter/material.dart';
import 'package:opennutritracker/generated/l10n.dart';

class HomeAppbar extends StatelessWidget implements PreferredSizeWidget {
  const HomeAppbar({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Row(
        children: [
          SizedBox(
            width: 40,
            child: Image.asset('assets/icon/ont_logo_square.png'),
          ),
          Text(S.of(context).appTitle)
        ],
      ),
      actions: [
        IconButton(onPressed: () {}, icon: const Icon(Icons.settings_outlined))
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
