import 'package:apapane/model/main/profile_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
//packages
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
//components
import 'package:apapane/view/main_screen/profile_screen/components/profile_display.dart';
import 'package:apapane/view/main_screen/profile_screen/components/profile_image_switcher.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ProfileModel profileModel = ref.watch(profileProvider);

    double screenHeight = MediaQuery.of(context).size.height;
    double screenWidth = MediaQuery.of(context).size.width;
    return Scaffold(
      body: Stack(
        children: [
          ProfileImageSwitcher(profileModel: profileModel),
          Container(
            color: const Color.fromARGB(255, 34, 34, 34).withOpacity(0.5),
          ),
          Positioned(
            top: screenHeight * 0.1.w,
            left: screenWidth * 0.05.w,
            child: Container(
              width: screenWidth * 0.82.w,
              height: screenHeight * 0.74,
              decoration: BoxDecoration(
                color: const Color.fromARGB(255, 0, 0, 0).withOpacity(0.3),
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
          Positioned(
              top: screenHeight * 0.16.w,
              child: ProfileDisplay(
                length: screenWidth * 0.25,
                profileModel: profileModel,
              )),
        ],
      ),
    );
  }
}
