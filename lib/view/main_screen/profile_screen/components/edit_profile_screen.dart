import 'package:apapane/constants/strings.dart';
import 'package:apapane/details/circle_progress_indicator.dart';
import 'package:apapane/details/rounded_button.dart';
import 'package:apapane/details/rounded_profile_icon.dart';
import 'package:apapane/model/edit_profile_model.dart';
import 'package:apapane/model/main_model.dart';
import 'package:apapane/model/bottom_nav_bar_model.dart';
import 'package:apapane/ui_core/dialog_core.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:apapane/details/icon_image.dart';
import 'package:apapane/details/original_flash_bar.dart';

class EditProfileScreen extends ConsumerWidget {
  const EditProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final MainModel mainModel = ref.watch(mainProvider);
    final EditProfileModel editProfileModel = ref.watch(editProfileProvider);
    final BottomNavigationBarModel bottomNavBarModel =
        ref.watch(bottomNavigationBarProvider);
    final double screenHeight = MediaQuery.of(context).size.height;
    double screenWidth = MediaQuery.of(context).size.width;
    return editProfileModel.isLoading
        ? const CircleProgressIndicator(
            message: 'へんこうちゅう', circleIndicatorImage: updateProfileImage)
        : Scaffold(
            appBar: AppBar(
              backgroundColor: Colors.white,
              title: const Text('へんしゅう'),
              actions: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 13.0),
                  child: InkWell(
                      onTap: () {
                        DialogCore.cupertinoAlertDialog(
                            context,
                            'ログアウトしますか',
                            'ログアウト',
                            () async => await mainModel.logout(
                                  context: context,
                                  bottomNavBarModel: bottomNavBarModel,
                                ));
                      },
                      child: const Text(
                        'ログアウト',
                        style: TextStyle(color: Color.fromARGB(255, 45, 83, 1)),
                      )),
                ),
              ],
            ),
            body: Stack(
              children: [
                Image.asset(
                  judgeBackground,
                  fit: BoxFit.cover,
                  height: screenHeight,
                ),
                SingleChildScrollView(
                  child: Center(
                    child: Column(
                      children: [
                        SizedBox(height: screenWidth * 0.35),
                        RoundedProfileIcon(
                          child: IconImage(
                            length: 120,
                            iconImageData: editProfileModel.croppedImage,
                          ),
                        ),
                        SizedBox(height: screenWidth * 0.02),
                        InkWell(
                          splashColor: const Color.fromARGB(
                              255, 239, 42, 137), // Splash color
                          onTap: editProfileModel.selectImage,
                          child: Container(
                            decoration: BoxDecoration(
                              color: const Color.fromARGB(133, 230, 255, 7)
                                  .withOpacity(0.9),
                              shape: BoxShape.circle,
                            ),
                            width: 48, // Button size
                            height: 48, // Button size
                            child: const Icon(
                              Icons.photo_camera_back,
                              color: Color.fromARGB(255, 45, 45, 45),
                              size: 30,
                            ),
                          ),
                        ),
                        SizedBox(height: screenWidth * 0.03),
                        SizedBox(
                          width: screenWidth * 0.7,
                          child: OriginalFlashBar(
                            controller: editProfileModel.nameController,
                            hintText: mainModel.firestoreUser.userName,
                            height: 60,
                            onPressed: () {},
                            isSend: false,
                          ),
                        ),
                        SizedBox(height: screenWidth * 0.1),
                        RoundedButton(
                            onPressed: () => editProfileModel.saveButtonPressed(
                                context, mainModel, bottomNavBarModel),
                            widthRate: 0.5,
                            color: (editProfileModel
                                        .nameController.text.isNotEmpty ||
                                    editProfileModel.isChanged)
                                ? Colors.red
                                : Colors.green,
                            text: (editProfileModel
                                        .nameController.text.isNotEmpty ||
                                    editProfileModel.isChanged)
                                ? 'ほぞんする'
                                : 'ホームへもどる'),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
  }
}
