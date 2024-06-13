import 'package:apapane/details/rounded_button.dart';
import 'package:apapane/model/main_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:apapane/details/icon_image.dart';
import 'package:apapane/details/original_flash_bar.dart';

class EditProfileScreen extends ConsumerWidget {
  EditProfileScreen({Key? key}) : super(key: key);

  final TextEditingController _nameController = TextEditingController();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final MainModel mainModel = ref.watch(mainProvider);
    double screenWidth = MediaQuery.of(context).size.width;
    return Scaffold(
      appBar: AppBar(
        title: const Text('へんしゅう'),
        backgroundColor: const Color.fromARGB(255, 255, 255, 255),
      ),
      body: SingleChildScrollView(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(height: screenWidth * 0.02),
              IconImage(
                length: 100,
                iconImageURL: mainModel.firestoreUser.userImageURL,
              ),
              ClipOval(
                child: Material(
                  color: const Color.fromARGB(0, 252, 80, 246), // Button color
                  child: InkWell(
                    splashColor:
                        const Color.fromARGB(255, 239, 42, 137), // Splash color
                    onTap: () {
                      // Logic to handle album icon button press
                      print('Album icon button pressed');
                    },
                    child: Container(
                      color: const Color.fromARGB(0, 252, 80, 246),
                      width: 48, // Button size
                      height: 48, // Button size
                      child: const Icon(
                        Icons.photo_camera_back,
                        size: 30,
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(height: screenWidth * 0.01),
              SizedBox(
                width: screenWidth * 0.7,
                child: OriginalFlashBar(
                  controller: _nameController,
                  hintText: mainModel.firestoreUser.userName,
                  height: 60,
                  onPressed: () {
                    // Save name logic or API call
                    print('Name saved: ${_nameController.text}');
                  },
                  isSend: false,
                ),
              ),
              SizedBox(height: 20.h),
              RoundedButton(
                  onPressed: () {},
                  widthRate: 0.8,
                  color: Colors.red,
                  text: 'ほぞんする')
            ],
          ),
        ),
      ),
    );
  }
}
