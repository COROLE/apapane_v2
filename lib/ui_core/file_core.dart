import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';

class FileCore {
  static Future<Uint8List?> getImage() async {
    final xFile = await _pickImage();
    final croppedImage = await _cropImage(xFile);
    return croppedImage == null ? null : File(croppedImage.path).readAsBytes();
  }

  static Future<XFile?> _pickImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);
    return image;
  }

  static Future<CroppedFile?> _cropImage(XFile? xFile) async {
    if (xFile == null) {
      return null;
    } else {
      final instance = ImageCropper();
      final result =
          await instance.cropImage(sourcePath: xFile.path, uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'Cropper',
          toolbarColor: Colors.deepOrange,
          toolbarWidgetColor: Colors.white,
          initAspectRatio: CropAspectRatioPreset.square,
          lockAspectRatio: true, // Lock aspect ratio for circle
          aspectRatioPresets: [
            CropAspectRatioPreset.square, // Maintain square aspect ratio
          ],
        ),
        IOSUiSettings(
          title: 'Cropper',
          aspectRatioPresets: [
            CropAspectRatioPreset.square, // Maintain square aspect ratio
          ],
        )
      ]);
      return result;
    }
  }
}
