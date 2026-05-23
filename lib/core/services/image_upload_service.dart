import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

class ImageUploadService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final ImagePicker _picker = ImagePicker();

  /// Pick image from gallery - Returns XFile for cross-platform compatibility
  Future<XFile?> pickImageFromGallery() async {
    try {
      return await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
    } catch (e) {
      debugPrint('Error picking image from gallery: $e');
    }
    return null;
  }

  /// Pick image from camera
  Future<XFile?> pickImageFromCamera() async {
    try {
      return await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
    } catch (e) {
      debugPrint('Error picking image from camera: $e');
    }
    return null;
  }

  /// Pick multiple images from gallery
  Future<List<XFile>> pickMultipleImages() async {
    try {
      return await _picker.pickMultiImage(
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
    } catch (e) {
      debugPrint('Error picking multiple images: $e');
    }
    return [];
  }

  /// Upload image to Firebase Storage (Byte-based for Web/Mobile support)
  Future<String?> uploadImage(XFile xFile, String userId, String folder) async {
    try {
      final String fileName = '${userId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final Reference ref = _storage.ref().child(folder).child(userId).child(fileName);

      final Uint8List bytes = await xFile.readAsBytes();
      
      final UploadTask task = ref.putData(
        bytes,
        SettableMetadata(
          contentType: 'image/jpeg',
          customMetadata: {'userId': userId},
        ),
      );

      final TaskSnapshot snapshot = await task;
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      debugPrint('Error uploading image: $e');
      return null;
    }
  }

  /// Upload multiple images
  Future<List<String>> uploadImages(List<XFile> xFiles, String userId, String folder) async {
    final List<String> imageUrls = [];
    for (var xFile in xFiles) {
      final url = await uploadImage(xFile, userId, folder);
      if (url != null) imageUrls.add(url);
    }
    return imageUrls;
  }

  /// Delete image from Firebase Storage
  Future<bool> deleteImage(String imageUrl) async {
    try {
      final Reference ref = _storage.refFromURL(imageUrl);
      await ref.delete();
      return true;
    } catch (e) {
      debugPrint('Error deleting image: $e');
      return false;
    }
  }

  /// Delete multiple images
  Future<bool> deleteImages(List<String> imageUrls) async {
    try {
      for (final url in imageUrls) {
        await deleteImage(url);
      }
      return true;
    } catch (e) {
      debugPrint('Error deleting images: $e');
      return false;
    }
  }
}
