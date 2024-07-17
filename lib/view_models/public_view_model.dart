//flutter
import 'package:apapane/core/firestore/query_core.dart';
import 'package:apapane/enums/to_story_page_type.dart';
import 'package:apapane/view_models/abstract/base_log_view_model.dart';
import 'package:apapane/view_models/story_view_model.dart';
import 'package:flutter/material.dart';
//packages
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';

//constants
//models

class PublicViewModel extends BaseLogViewModel {
  PublicViewModel(super.firestoreRepository);

  @override
  Future<void> onRefresh() async {
    refreshController.refreshCompleted();
    await addStoryDoc(
        QueryCore.newStoriesCollectionQuery(null, storyDocs, false));
    notifyListeners();
  }

  @override
  Future<void> onReload() async {
    startLoading();
    await addStoryDoc(QueryCore.publicStoriesCollectionQuery());
    notifyListeners();
    endLoading();
  }

  @override
  Future<void> onLoading() async {
    refreshController.loadComplete();
    await addStoryDoc(
        QueryCore.oldStoriesCollectionQuery(null, storyDocs, false));
    notifyListeners();
  }

  @override
  Future<void> getMyStories({
    required BuildContext context,
    required StoryViewModel storyViewModel,
    required DocumentSnapshot<Map<String, dynamic>> storyDoc,
  }) async {
    final List<dynamic> myStoryMaps = storyDoc['stories'] as List<dynamic>;
    storyViewModel.getTitleTextAndImage(
        title: storyDoc['titleText'], image: storyDoc['titleImage']);
    storyViewModel.updateStoryMaps(
        newStoryMaps: myStoryMaps.cast<Map<String, dynamic>>());
    storyViewModel.toStoryPageType = ToStoryPageType.memoryStory;
    context.push('/story?isNew=false');
  }
}
