//flutter
import 'package:apapane/providers/auth_providers.dart';
import 'package:apapane/providers/make_story_providers.dart';
import 'package:apapane/views/profile_screen/components/favorite_story_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
//packages
import 'package:flutter_screenutil/flutter_screenutil.dart';
//constants
import 'package:apapane/constants/strings.dart';
//components
import 'package:apapane/views/common/icon_image.dart';
import 'package:apapane/views/common/rounded_button.dart';
//models
import 'package:apapane/view_models/profile_view_model.dart';
import 'package:apapane/view_models/edit_profile_view_model.dart';
import 'package:go_router/go_router.dart';

class ProfileDisplay extends ConsumerWidget {
  const ProfileDisplay(
      {super.key, required this.length, required this.profileViewModel});
  final double length;
  final ProfileViewModel profileViewModel;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final storyViewModel = ref.watch(storyViewModelProvider);

    final mainViewModel = ref.watch(mainViewModelProvider);
    final EditProfileModel editProfileViewModel =
        ref.watch(editProfileProvider);

    final firestoreUser = mainViewModel.firestoreUser;

    return ScreenUtilInit(
        designSize: const Size(360, 690),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              children: [
                SizedBox(width: 50.w),
                IconImage(
                    length: length, iconImageData: firestoreUser.userImageURL),
                SizedBox(width: 20.w),
                SizedBox(
                  width: 150.w,
                  child: Text(firestoreUser.userName,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 20.sp,
                          fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            SizedBox(height: 15.h),
            Row(
              children: [
                Text(' $followerText ${firestoreUser.followerCount}',
                    style: TextStyle(color: Colors.white, fontSize: 15.sp)),
                SizedBox(width: 20.w),
                Text(' $followingText ${firestoreUser.followingCount}',
                    style: TextStyle(color: Colors.white, fontSize: 15.sp)),
              ],
            ),
            SizedBox(height: 20.h),
            Padding(
              padding: EdgeInsets.only(left: 15.0.w),
              child: RoundedButton(
                  onPressed: () {
                    editProfileViewModel.init(mainViewModel);
                    context.push('/edit/profile');
                  },
                  widthRate: 0.65,
                  color:
                      const Color.fromARGB(255, 242, 0, 255).withOpacity(0.6),
                  text: editProfileText),
            ),
            SizedBox(height: 20.h),
            Text(favoriteStoryText,
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 15.sp,
                    fontWeight: FontWeight.bold)),
            SizedBox(
              height: 10.h,
            ),
            FavoriteStoryIcons(
                storyViewModel: storyViewModel, profileModel: profileViewModel)
          ],
        ));
  }
}
