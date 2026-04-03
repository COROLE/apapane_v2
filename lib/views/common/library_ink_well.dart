import 'package:apapane/ui_core/ui_helper.dart';
import 'package:apapane/views/common/story_icon.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class LibraryInkWell extends StatelessWidget {
  const LibraryInkWell({
    super.key,
    required this.height,
    required this.width,
    required this.onTap,
    required this.storyImageURL,
    required this.titleText,
    this.isArchive = false,
    this.isFavorite = false,
    this.isPublic = false,
    this.isFavoriteLoading = false,
    this.onChanged,
    this.favoriteButtonPressed,
  });

  final double height;
  final double width;
  final void Function()? onTap;
  final void Function()? favoriteButtonPressed;
  final String storyImageURL;
  final String titleText;
  final bool isArchive;
  final bool isFavorite;
  final bool isPublic;
  final bool isFavoriteLoading;
  final void Function(bool)? onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(height: height * 0.02),
        InkWell(
          onTap: onTap,
          child: StoryIcon(
            storyImageURL: storyImageURL,
          ),
        ),
        SizedBox(height: height * 0.01),
        Container(
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.6),
                spreadRadius: 1,
                blurRadius: 4,
              ),
            ],
          ),
          child: Text(
            titleText,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 17,
              color: Colors.white,
            ),
          ),
        ),
        isArchive
            ? Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Column(
                    children: [
                      IconButton(
                        onPressed: () async => !isFavoriteLoading
                            ? favoriteButtonPressed?.call()
                            : await UIHelper.showFlutterToast('少し待ってください。'),
                        icon: Icon(
                          isFavoriteLoading ? Icons.circle : Icons.favorite,
                          color: isFavorite ? Colors.red : Colors.white,
                          size: isFavoriteLoading ? 20 : 30,
                        ),
                      ),
                      const Text(
                        'お気に入り',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  if (onChanged != null)
                    Column(
                      children: [
                        CupertinoSwitch(
                          focusColor: Colors.green,
                          value: isPublic,
                          onChanged: onChanged,
                        ),
                        const Text(
                          '公開',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                ],
              )
            : const SizedBox.shrink(),
        const Divider(
          color: Color.fromARGB(255, 166, 166, 166),
          thickness: 1,
        ),
      ],
    );
  }
}
