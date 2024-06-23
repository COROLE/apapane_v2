//flutter
import 'package:flutter/material.dart';
//packages
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
//constants
import 'package:apapane/constants/enums.dart';
import 'package:apapane/constants/others.dart';
import 'package:apapane/constants/routes.dart' as routes;
//models
import 'package:apapane/model/story_model.dart';
//components
import 'package:apapane/view/main_screen/profile_screen/components/profile_component.dart';

final profileProvider = ChangeNotifierProvider((ref) => ProfileModel());

class ProfileModel extends ChangeNotifier {
  List<DocumentSnapshot<Map<String, dynamic>>> favoriteStoryDocs = [];

  List<String> imagesPictureList = [
    'assets/images/volt_boy.png',
    'assets/images/pirates.png',
    'assets/images/dragon_boy.png',
    'assets/images/fairy.png',
    'assets/images/girl_rabbit.png',
    'assets/images/venture.png',
  ]..shuffle();

  Query<Map<String, dynamic>> returnQuery() {
    final User? currentUser = returnAuthUser();
    return FirebaseFirestore.instance
        .collection('users')
        .doc(currentUser!.uid)
        .collection('favoriteStories');
  }

  late List<Widget> imagesList;

  ProfileModel() {
    init();
  }

  void init() {
    imagesList =
        imagesPictureList.map((e) => ProfileComponent(image: e)).toList();
    onReload();
  }

  void addFavoriteStoryDocs(
      {required DocumentSnapshot<Map<String, dynamic>> storyDoc}) {
    favoriteStoryDocs.add(storyDoc);
    notifyListeners();
  }

  void removeFavoriteStoryDocs(
      {required DocumentSnapshot<Map<String, dynamic>> storyDoc}) {
    favoriteStoryDocs
        .removeWhere((doc) => doc['titleText'] == storyDoc['titleText']);
    notifyListeners();
  }

  Future<void> onReload() async {
    final query = returnQuery();
    final qshot = await query.limit(5).get();
    qshot.docs.map((e) => favoriteStoryDocs.add(e)).toList();
    notifyListeners();
  }

  Future<void> getMyStories(
      {required BuildContext context,
      required StoryModel storyModel,
      required DocumentSnapshot<Map<String, dynamic>> storyDoc}) async {
    final List<dynamic> myStoryMaps = storyDoc['stories'] as List<dynamic>;
    storyModel.getTitleTextAndImage(
        title: storyDoc['titleText'], image: storyDoc['titleImage']);
    storyModel.updateStoryMaps(
        newStoryMaps: myStoryMaps.cast<Map<String, dynamic>>());
    storyModel.toStoryPageType = ToStoryPageType.memoryStory;
    routes.toStoryScreen(context: context, isNew: false);
  }
}
