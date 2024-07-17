import 'package:apapane/constants/strings.dart';
import 'package:apapane/providers/auth_providers.dart';
import 'package:apapane/providers/normal_providers.dart';
import 'package:apapane/views/common/circle_progress_indicator.dart';
import 'package:apapane/views/common/rounded_button.dart';
import 'package:apapane/views/common/rounded_profile_icon.dart';
import 'package:apapane/view_models/edit_profile_view_model.dart';
import 'package:apapane/view_models/main_view_model.dart';
import 'package:apapane/ui_core/dialog_core.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:apapane/views/common/icon_image.dart';
import 'package:apapane/views/common/original_flash_bar.dart';
import 'package:go_router/go_router.dart';

class EditProfileScreen extends ConsumerWidget {
  const EditProfileScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final MainViewModel mainViewModel = ref.watch(mainViewModelProvider);
    final EditProfileModel editProfileModel = ref.watch(editProfileProvider);
    final bottomNavBarViewModel =
        ref.watch(bottomNavigationBarViewModelProvider);
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
                            () async => await mainViewModel.logout(
                                  context: context,
                                  bottomNavBarViewModel: bottomNavBarViewModel,
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
                    child: Column(children: [
                      SizedBox(height: screenWidth * 0.35),
                      RoundedProfileIcon(
                        child: IconImage(
                          length: 120,
                          iconImageData: editProfileModel.croppedImage,
                        ),
                      ),
                      SizedBox(height: screenWidth * 0.02),
                      InkWell(
                        splashColor: Colors.transparent, // Splash color
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
                          hintText: mainViewModel.firestoreUser.userName,
                          height: 60,
                          onPressed: () {},
                          isSend: false,
                        ),
                      ),
                      SizedBox(height: screenWidth * 0.1),
                      RoundedButton(
                          onPressed: () => editProfileModel.saveButtonPressed(
                              context, mainViewModel),
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
                      mainViewModel.firestoreUser.isAdmin
                          ? Column(
                              children: [
                                SizedBox(height: screenWidth * 0.05),
                                RoundedButton(
                                    onPressed: () => context.push(
                                          '/admin',
                                          extra: {
                                            'currentUserDoc':
                                                mainViewModel.currentUserDoc,
                                            'firestoreUser':
                                                mainViewModel.firestoreUser,
                                          },
                                        ),
                                    widthRate: 0.5,
                                    color: Colors.black,
                                    text: 'アドミン画面へ'),
                              ],
                            )
                          : const SizedBox.shrink()
                    ]),
                  ),
                ),
              ],
            ),
          );
  }
}
