//flutter
import 'package:flutter/material.dart';
//constants
import 'package:apapane/constants/bottom_nav_bar_element.dart';
//model
import 'package:apapane/model/bottom_nav_bar_model.dart';

class BottomNavigationBars extends StatelessWidget {
  const BottomNavigationBars({Key? key, required this.bottomNavigationBarModel})
      : super(key: key);

  final BottomNavigationBarModel bottomNavigationBarModel;

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      type: BottomNavigationBarType.shifting,
      items: bottomNavigationBarElements,
      currentIndex: bottomNavigationBarModel.currentIndex,
      onTap: (index) => bottomNavigationBarModel.onTabTapped(index: index),
      selectedItemColor: Colors.pink,
      unselectedItemColor: Colors.grey,
    );
  }
}
