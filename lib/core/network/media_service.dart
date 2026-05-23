import 'package:flutter/foundation.dart';
import 'app_file.dart';

abstract class MediaService {
  Future<AppFile?> pickImage({bool fromCamera = false});
  Future<List<AppFile>> pickMultiImage();
  Future<AppFile> uploadFile(AppFile file, String folder);
  Future<void> deleteFile(String fileId);
}

class MediaServiceImpl implements MediaService {
  @override
  Future<AppFile?> pickImage({bool fromCamera = false}) async {
    // Firebase pick
    return AppFile(
      id: 'firebase_img_1',
      name: 'sample_design.jpg',
      url: 'assets/images/logo.png', // Using existing asset for firebase
      type: FileType.image,
      size: 1024 * 1024 * 2, // 2MB
      uploadedAt: DateTime.now(),
    );
  }

  @override
  Future<List<AppFile>> pickMultiImage() async {
    return [
      AppFile(
        id: 'firebase_img_1',
        name: 'front_view.jpg',
        url: 'assets/images/logo.png',
        type: FileType.image,
        size: 1024 * 500,
        uploadedAt: DateTime.now(),
      ),
      AppFile(
        id: 'firebase_img_2',
        name: 'back_view.jpg',
        url: 'assets/images/logo.png',
        type: FileType.image,
        size: 1024 * 600,
        uploadedAt: DateTime.now(),
      ),
    ];
  }

  @override
  Future<AppFile> uploadFile(AppFile file, String folder) async {
    // Simulate upload delay
    await Future.delayed(const Duration(seconds: 2));
    return file;
  }

  @override
  Future<void> deleteFile(String fileId) async {
    debugPrint('Deleting file: $fileId');
  }
}
