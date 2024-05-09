//flutter
import 'package:flutter/material.dart';
//packages
import 'package:flutter_screenutil/flutter_screenutil.dart';
//constants
import 'package:apapane/constants/strings.dart';
//components
import 'package:apapane/details/story_icon.dart';
import 'package:apapane/details/icon_image.dart';
import 'package:apapane/details/rounded_button.dart';
//models
import 'package:apapane/model/main/profile_model.dart';
import 'package:apapane/model/story_model.dart';
import 'package:apapane/model/main_model.dart';

class ProfileDisplay extends StatelessWidget {
  const ProfileDisplay(
      {Key? key,
      required this.length,
      required this.mainModel,
      required this.profileModel,
      required this.storyModel})
      : super(key: key);
  final double length;
  final MainModel mainModel;
  final ProfileModel profileModel;
  final StoryModel storyModel;
  @override
  Widget build(BuildContext context) {
    final firestoreUser = mainModel.firestoreUser;
    return ScreenUtilInit(
        designSize: const Size(360, 690),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Row(
              children: [
                IconImage(length: length, iconImageURL: ''),
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
                  onPressed: () {},
                  widthRate: 0.65,
                  color: Colors.grey,
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
