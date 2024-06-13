// ignore_for_file: file_names
import 'package:apapane/view/main_screen/home_screen.dart';
import 'package:apapane/view/main_screen/archive_screen.dart';
import 'package:flutter/material.dart';
import 'package:persistent_bottom_nav_bar/persistent_tab_view.dart';

final pages = <Widget>[
  const HomeScreen(),
  ArchiveScreen(),
];

class BottomNavBar extends StatelessWidget {
  const BottomNavBar({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: PersistentTabView(
        context,
        screens: pages,
        items: [
          PersistentBottomNavBarItem(
              icon: const Icon(Icons.edit),
              title: ('つくる'),
              activeColorPrimary: Colors.red,
              inactiveColorPrimary: Colors.grey),
          PersistentBottomNavBarItem(
              icon: const Icon(Icons.archive),
              title: ('きみのぼうけん'),
              activeColorPrimary: Colors.red,
              inactiveColorPrimary: Colors.grey),
          PersistentBottomNavBarItem(
              icon: const Icon(Icons.person),
              title: ('アカウント'),
              activeColorPrimary: Colors.red,
              inactiveColorPrimary: Colors.grey)
        ],
      ),
    );
  }
}
