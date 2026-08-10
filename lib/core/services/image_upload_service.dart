import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';

class ImageUploadService {
  final SupabaseClient _supabase = Supabase.instance.client;
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

  /// Upload image to Supabase Storage
  Future<String?> uploadImage(XFile xFile, String userId, String folder) async {
    try {
      final String fileName = '$folder/$userId/${userId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final Uint8List bytes = await xFile.readAsBytes();
      
      await _supabase.storage.from('images').uploadBinary(
        fileName,
        bytes,
        fileOptions: const FileOptions(
          contentType: 'image/jpeg',
          upsert: true,
        ),
      );

      return _supabase.storage.from('images').getPublicUrl(fileName);
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

  /// Delete image from Supabase Storage
  Future<bool> deleteImage(String imageUrl) async {
    try {
      // Extract path from URL - this is simplified
      final uri = Uri.parse(imageUrl);
      final pathSegments = uri.pathSegments;
      final path = pathSegments.sublist(pathSegments.indexOf('images') + 1).join('/');
      
      await _supabase.storage.from('images').remove([path]);
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
