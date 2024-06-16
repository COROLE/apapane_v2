//flutter
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
//packages
import 'package:flutter_screenutil/flutter_screenutil.dart';
//constants
import 'package:apapane/constants/strings.dart';
import 'package:apapane/constants/routes.dart' as routes;
//components
import 'package:apapane/details/story_icon.dart';
import 'package:apapane/details/icon_image.dart';
import 'package:apapane/details/rounded_button.dart';
//models
import 'package:apapane/model/main/profile_model.dart';
import 'package:apapane/model/story_model.dart';
import 'package:apapane/model/main_model.dart';
import 'package:apapane/model/edit_profile_model.dart';

class ProfileDisplay extends ConsumerWidget {
  const ProfileDisplay(
      {super.key, required this.length, required this.profileModel});
  final double length;
  final ProfileModel profileModel;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final MainModel mainModel = ref.watch(mainProvider);
    final EditProfileModel editProfileModel = ref.watch(editProfileProvider);
    final StoryModel storyModel = ref.watch(storyProvider);

    final firestoreUser = mainModel.firestoreUser;

    return ScreenUtilInit(
        designSize: const Size(360, 690),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Row(
              children: [
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
                    editProfileModel.init(mainModel);
                    routes.toEditProfileScreen(context: context);
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
              height: 20.h,
            ),
            InkWell(
              onTap: () => profileModel.getMyStories(
                  context: context,
                  storyModel: storyModel,
                  storyDoc: profileModel.favoriteStoryDocs[0]),
              child: StoryIcon(
                  storyImageURL: profileModel.favoriteStoryDocs.isNotEmpty
                      ? profileModel.favoriteStoryDocs[0]
                          .data()!['titleImage']
                          .toString()
                      : ''),
            ),
          ],
        ));
  }
}
