import 'package:apapane/constants/strings.dart';
import 'package:flutter/material.dart';

const List<BottomNavigationBarItem> bottomNavigationBarElements = [
  BottomNavigationBarItem(icon: Icon(Icons.edit), label: createText),
  BottomNavigationBarItem(icon: Icon(Icons.language), label: publicText),
  BottomNavigationBarItem(icon: Icon(Icons.book), label: storyText),
  BottomNavigationBarItem(icon: Icon(Icons.person), label: profileText),
];
