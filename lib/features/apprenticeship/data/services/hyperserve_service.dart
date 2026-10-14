import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import '../../../../config/environment.dart';

class HyperserveUploadResult {
  final String videoId;
  final String uploadUrl;
  final String contentType;
  HyperserveUploadResult({
    required this.videoId,
    required this.uploadUrl,
    required this.contentType,
  });
}

class HyperserveService {
  final String _apiKey = Environment.current.hyperserveApiKey;
  final String _baseUrl = 'https://api.hyperserve.io/api';

  Map<String, String> get _headers => {
    'X-API-KEY': _apiKey,
    'Content-Type': 'application/json',
  };

  bool get isConfigured => _apiKey.isNotEmpty;

  /// Step 1: Create video record and get presigned upload URL
  Future<HyperserveUploadResult> createVideo({
    required String filename,
    required int fileSizeBytes,
    List<String> resolutions = const ['1080p'],
    bool isPublic = true,
  }) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/video'),
      headers: _headers,
      body: jsonEncode({
        'filename': filename,
        'fileSizeBytes': fileSizeBytes,
        'resolutions': resolutions,
        'isPublic': isPublic,
      }),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Failed to create video: ${response.body}');
    }

    final data = jsonDecode(response.body);
    return HyperserveUploadResult(
      videoId: data['id'],
      uploadUrl: data['uploadUrl'],
      contentType: data['contentType'] ?? 'video/mp4',
    );
  }

  /// Step 2: Upload file directly to storage (browser-side, no API key needed)
  /// This is done in the browser using dart:html, but we provide the HTTP version too
  Future<void> uploadFile(
    String uploadUrl,
    Uint8List fileBytes,
    String contentType,
  ) async {
    final response = await http.put(
      Uri.parse(uploadUrl),
      headers: {'Content-Type': contentType},
      body: fileBytes,
    );

    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Upload failed: ${response.statusCode} ${response.body}');
    }
  }

  /// Step 3: Confirm upload is complete (triggers transcoding)
  Future<void> completeUpload(String videoId) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/video/$videoId/complete-upload'),
      headers: _headers,
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Failed to complete upload: ${response.body}');
    }
  }

  /// Get public video details (with playback URLs)
  Future<Map<String, dynamic>> getPublicVideo(String videoId) async {
    final url = '$_baseUrl/video/$videoId/public';

    final response = await http.get(Uri.parse(url), headers: _headers);

    if (response.statusCode != 200) {
      throw Exception('Failed to get video: ${response.body}');
    }

    return jsonDecode(response.body);
  }

  /// Get the best playback URL for a video
  Future<String?> getPlaybackUrl(String videoId) async {
    final video = await getPublicVideo(videoId);

    final resolutions = video['resolutions'] as Map<String, dynamic>?;

    if (resolutions == null || resolutions.isEmpty) {
      return null;
    }

    // Prefer 1080p, fallback to best available
    if (resolutions.containsKey('1080p')) {
      return resolutions['1080p']['videoUrl'];
    }
    if (resolutions.containsKey('720p')) {
      return resolutions['720p']['videoUrl'];
    }
    // Return first available
    final firstKey = resolutions.keys.first;
    return resolutions[firstKey]['videoUrl'];
  }

  /// Delete a video
  Future<void> deleteVideo(String videoId) async {
    final response = await http.delete(
      Uri.parse('$_baseUrl/video/$videoId'),
      headers: _headers,
    );

    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Failed to delete video: ${response.body}');
    }
  }
}
