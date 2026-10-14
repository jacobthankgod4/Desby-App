import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;

class VimeoUploadResult {
  final String videoId;
  final String embedUrl;
  final String downloadUrl;
  VimeoUploadResult({
    required this.videoId,
    required this.embedUrl,
    required this.downloadUrl,
  });
}

class VimeoService {
  // TODO: Vimeo token must be proxied through a Supabase Edge Function in production.
  // The client should never hold a Vimeo access token directly.
  final String _accessToken = '';
  final String _baseUrl = 'https://api.vimeo.com';

  Map<String, String> get _headers => {
    'Authorization': 'Bearer $_accessToken',
    'Content-Type': 'application/json',
    'Accept': 'application/vnd.vimeo.*+json;version=3.4',
  };

  /// Step 1: Create a video entry and get upload ticket
  Future<Map<String, dynamic>> _createVideoTicket(
    String name,
    int fileSize,
  ) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/me/videos'),
      headers: _headers,
      body: jsonEncode({
        'name': name,
        'upload': {'approach': 'tus', 'size': fileSize},
        'privacy': {'view': 'unlisted'},
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to create video ticket: ${response.body}');
    }

    return jsonDecode(response.body);
  }

  /// Step 2: Upload video file via TUS protocol
  Future<void> _uploadViaTus(String uploadLink, Uint8List fileBytes) async {
    final uri = Uri.parse(uploadLink);

    // TUS resume init
    final initResponse = await http.patch(
      uri,
      headers: {
        'Tus-Resumable': '1.0.0',
        'Upload-Offset': '0',
        'Content-Length': '0',
      },
    );

    final offset = initResponse.headers['upload-offset'] ?? '0';

    // Upload the file
    final uploadResponse = await http.put(
      uri,
      headers: {
        'Tus-Resumable': '1.0.0',
        'Upload-Offset': offset,
        'Content-Type': 'application/offset+octet-stream',
      },
      body: fileBytes,
    );

    if (uploadResponse.statusCode != 200 && uploadResponse.statusCode != 204) {
      throw Exception(
        'Upload failed: ${uploadResponse.statusCode} ${uploadResponse.body}',
      );
    }
  }

  /// Upload a video file to Vimeo
  Future<VimeoUploadResult> uploadVideo({
    required String name,
    required Uint8List fileBytes,
    required String fileName,
  }) async {
    // Step 1: Create video entry
    final ticket = await _createVideoTicket(name, fileBytes.length);

    final videoUri = ticket['uri'] as String;
    final videoId = videoUri.split('/').last;
    final uploadLink = ticket['upload']['upload_link'] as String;

    // Step 2: Upload file via TUS
    await _uploadViaTus(uploadLink, fileBytes);

    return VimeoUploadResult(
      videoId: videoId,
      embedUrl: 'https://player.vimeo.com/video/$videoId',
      downloadUrl: 'https://vimeo.com/$videoId',
    );
  }

  /// Get video details
  Future<Map<String, dynamic>> getVideoDetails(String videoId) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/videos/$videoId'),
      headers: _headers,
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to get video details: ${response.body}');
    }

    return jsonDecode(response.body);
  }

  /// Delete a video
  Future<void> deleteVideo(String videoId) async {
    final response = await http.delete(
      Uri.parse('$_baseUrl/videos/$videoId'),
      headers: _headers,
    );

    if (response.statusCode != 204 && response.statusCode != 200) {
      throw Exception('Failed to delete video: ${response.body}');
    }
  }

  /// Check if Vimeo access token is configured
  bool get isConfigured => _accessToken.isNotEmpty;
}
