import 'dart:io';
import 'package:image_picker/image_picker.dart';

class ImageService {
  final ImagePicker _picker = ImagePicker();
  static final ImageService _instance = ImageService._internal();

  factory ImageService() {
    return _instance;
  }

  ImageService._internal();

  // Grab image from Camera
  Future<File?> captureFromCamera() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
        maxWidth: 1080,
      );
      if (image != null) {
        return File(image.path);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Grab image from Gallery
  Future<File?> selectFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1080,
      );
      if (image != null) {
        return File(image.path);
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}
