import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

import '../services/image_upload_service.dart';
import 'app_file.dart';

abstract class MediaService {
  Future<AppFile?> pickImage({bool fromCamera = false});
  Future<List<AppFile>> pickMultiImage();
  Future<AppFile> uploadFile(AppFile file, String folder);
  Future<void> deleteFile(String fileId);
}

class MediaServiceImpl implements MediaService {
  final ImageUploadService _imageUploadService = ImageUploadService();

  @override
  Future<AppFile?> pickImage({bool fromCamera = false}) async {
    try {
      final XFile? xFile = fromCamera
          ? await _imageUploadService.pickImageFromCamera()
          : await _imageUploadService.pickImageFromGallery();
      if (xFile == null) return null;
      return AppFile(
        id: xFile.name.hashCode.toString(),
        name: xFile.name,
        url: xFile.path,
        type: FileType.image,
        size: await xFile.length(),
        uploadedAt: DateTime.now(),
      );
    } catch (e) {
      debugPrint('Error picking image: $e');
      return null;
    }
  }

  @override
  Future<List<AppFile>> pickMultiImage() async {
    try {
      final List<XFile> xFiles = await _imageUploadService.pickMultipleImages();
      final List<AppFile> files = [];
      for (final xFile in xFiles) {
        files.add(AppFile(
          id: xFile.name.hashCode.toString(),
          name: xFile.name,
          url: xFile.path,
          type: FileType.image,
          size: await xFile.length(),
          uploadedAt: DateTime.now(),
        ));
      }
      return files;
    } catch (e) {
      debugPrint('Error picking multiple images: $e');
      return [];
    }
  }

  @override
  Future<AppFile> uploadFile(AppFile file, String folder) async {
    try {
      final XFile xFile = XFile(file.url);
      final url = await _imageUploadService.uploadImage(xFile, 'user', folder);
      if (url != null) {
        return AppFile(
          id: file.id,
          name: file.name,
          url: url,
          type: file.type,
          size: file.size,
          uploadedAt: file.uploadedAt,
        );
      }
      return file;
    } catch (e) {
      debugPrint('Error uploading file: $e');
      return file;
    }
  }

  @override
  Future<void> deleteFile(String fileId) async {
    try {
      await _imageUploadService.deleteImage(fileId);
    } catch (e) {
      debugPrint('Error deleting file: $e');
    }
  }
}
