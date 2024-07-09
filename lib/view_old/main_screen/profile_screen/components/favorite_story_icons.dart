import 'package:apapane/details/story_icon.dart';
import 'package:apapane/model_riverpod_old/main/profile_model.dart';
import 'package:apapane/model_riverpod_old/story_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class FavoriteStoryIcons extends StatefulWidget {
  final StoryModel storyModel;
  final ProfileModel profileModel;

  const FavoriteStoryIcons(
      {super.key, required this.storyModel, required this.profileModel});

  @override
  // ignore: library_private_types_in_public_api
  _FavoriteStoryIconsState createState() => _FavoriteStoryIconsState();
}

class _FavoriteStoryIconsState extends State<FavoriteStoryIcons> {
  final PageController _pageController = PageController(viewportFraction: 0.8);
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController.addListener(() {
      int next = _pageController.page!.round();
      if (_currentPage != next) {
        setState(() {
          _currentPage = next;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<DocumentSnapshot> favoriteStoryDocs =
        widget.profileModel.favoriteStoryDocs;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: 230,
          width: MediaQuery.of(context).size.width,
          child: PageView.builder(
            itemCount: favoriteStoryDocs.length,
            controller: _pageController,
            itemBuilder: (context, index) {
              final storyDoc =
                  favoriteStoryDocs[index].data() as Map<String, dynamic>;
              final storyImageURL = storyDoc['titleImage']?.toString() ?? '';
              final storyTitle = (storyDoc['titleText']?.toString() ?? '');
              final displayTitle = storyTitle.length > 12
                  ? storyTitle.substring(0, 12)
                  : storyTitle;
              return InkWell(
                onTap: () => widget.profileModel.getMyStories(
                    context: context,
                    storyModel: widget.storyModel,
                    storyDoc: favoriteStoryDocs[index]
                        as DocumentSnapshot<Map<String, dynamic>>),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Column(
                    children: [
                      Expanded(
                        child: StoryIcon(storyImageURL: storyImageURL),
                      ),
                      const SizedBox(height: 5),
                      Text(displayTitle,
                          style: const TextStyle(
                              fontSize: 15,
                              color: Color.fromARGB(255, 229, 229, 229),
                              fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List<Widget>.generate(
            favoriteStoryDocs.length,
            (index) => DotIndicator(isActive: _currentPage == index),
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
}

class DotIndicator extends StatelessWidget {
  final bool isActive;

  const DotIndicator({super.key, required this.isActive});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 10,
      height: 10,
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isActive ? Colors.white : Colors.grey,
      ),
      child: Center(
        child: Text(
          isActive ? '●' : '○',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: isActive ? Colors.white : Colors.grey,
          ),
        ),
      ),
    );
  }
}
