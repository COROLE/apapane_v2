import 'package:flutter/material.dart';

class RoundedProfileIcon extends StatelessWidget {
  const RoundedProfileIcon({super.key, required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) {
    return ClipOval(
        child: Container(
            width: 140, // Increased width to allow yellow color to overflow
            height: 140, // Increased height to allow yellow color to overflow
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: Colors
                  .transparent, // Changed to transparent to allow overflow visibility
              shape: BoxShape.circle,
            ),
            child: Stack(alignment: Alignment.center, children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color.fromARGB(255, 251, 0, 192)
                          .withOpacity(0.6),
                      spreadRadius: 5,
                      blurRadius: 5,
                    ),
                  ],
                ),
              ),
              Container(
                  decoration: const BoxDecoration(
                    color: Color.fromARGB(
                        255, 255, 59, 128), // Background color added
                    shape: BoxShape.circle,
                  ),
                  child: child)
            ])));
  }
}
