import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Image generation service using Cloudflare Workers AI (FLUX.2 klein-9b).
/// Sends POST with multipart form data. No API keys exposed to client.
class CloudflareImageService {
  static const String _workerUrl = 'https://desby.app/api/image-gen/generate';

  /// Fashion-specific negative prompt to avoid common AI artifacts.
  static const String _negativePrompt =
      'blurry, low quality, deformed, disfigured, mutated, extra limbs, '
      'extra fingers, bad anatomy, bad proportions, watermark, text, logo, '
      'signature, cropped, out of frame, worst quality, jpeg artifacts, '
      'ugly, duplicate, multiple people, multiple figures, collage, '
      'split image, composite image, phone screen, mirror reflection';

  bool get isReady => true;

  /// Generate an image from a text prompt via POST.
  Future<Uint8List?> generateImage({
    required String prompt,
    int width = 1024,
    int height = 1536,
    double guidance = 8.0,
  }) async {
    try {
      final uri = Uri.parse(_workerUrl);

      // Build multipart form data
      final request = http.MultipartRequest('POST', uri);
      request.fields['prompt'] = prompt;
      request.fields['width'] = width.toString();
      request.fields['height'] = height.toString();
      request.fields['guidance'] = guidance.toString();

      final streamedResponse = await request.send().timeout(
        const Duration(seconds: 120),
      );

      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200 && response.bodyBytes.isNotEmpty) {
        debugPrint(
          '[CloudflareImage] Success: ${response.bodyBytes.length} bytes',
        );
        return response.bodyBytes;
      }
      debugPrint(
        '[CloudflareImage] HTTP ${response.statusCode}: ${response.body}',
      );
      return null;
    } catch (e) {
      debugPrint('[CloudflareImage] Error: $e');
      return null;
    }
  }

  /// Generate a fashion concept image with enriched prompts.
  Future<String?> generateFashionConcept(String userPrompt) async {
    final enriched = _buildFashionPrompt(userPrompt);
    final bytes = await generateImage(
      prompt: enriched,
      width: 1024,
      height: 1536,
      guidance: 8.0,
    );
    if (bytes == null) return null;
    return 'data:image/jpeg;base64,${base64Encode(bytes)}';
  }

  /// Generate a sewing/pattern illustration.
  Future<String?> generateSewingGuide(String garment, String step) async {
    final prompt = _buildSewingPrompt(garment, step);
    final bytes = await generateImage(
      prompt: prompt,
      width: 1024,
      height: 1024,
      guidance: 7.5,
    );
    if (bytes == null) return null;
    return 'data:image/jpeg;base64,${base64Encode(bytes)}';
  }

  // ---------------------------------------------------------------------------
  // FASHION PROMPT BUILDER — Nigerian/African fashion-specific
  // ---------------------------------------------------------------------------

  String _buildFashionPrompt(String input) {
    final lower = input.toLowerCase();

    // Detect garment type
    String garment;
    String fabricDetail;
    String styleDetail;

    if (lower.contains('agbada')) {
      garment = 'flowing Agbada robe with wide kimono-style sleeves';
      fabricDetail =
          'premium damask or aso-oke fabric with rich geometric embroidery on the neckline, cuffs, and chest panel';
      styleDetail =
          'regal, commanding presence; the robe drapes elegantly with structured shoulders and fluid movement';
    } else if (lower.contains('senator')) {
      garment =
          'tailored Senator suit — a fitted mandarin collar tunic with matching trousers';
      fabricDetail =
          'premium cotton or polished lace fabric with subtle embroidery or piping detail along the collar and front placket';
      styleDetail = 'clean modern lines, sharp tailoring, fitted silhouette';
    } else if (lower.contains('kaftan')) {
      garment =
          'luxurious African Kaftan — a relaxed long tunic with side slits';
      fabricDetail =
          'silk or premium cotton with intricate hand-embroidered neckline and hem detailing';
      styleDetail = 'effortlessly elegant, relaxed fit with refined finishing';
    } else if (lower.contains('babariga') || lower.contains('babadiga')) {
      garment = 'traditional Babariga — a majestic layered Hausa royal robe';
      fabricDetail =
          'heavy aso-oke or handwoven fabric with concentric embroidery patterns on the chest';
      styleDetail =
          'voluminous, layered, commanding traditional Yoruba/Hausa royalty aesthetic';
    } else if (lower.contains('boubou')) {
      garment =
          'flowing West African Boubou — wide flowing gown with embroidered neckline';
      fabricDetail =
          'luxurious bazin or damask fabric with intricate hand-embroidery';
      styleDetail = 'regal, flowing silhouette with wide sleeves';
    } else if (lower.contains('iro') || lower.contains('buba')) {
      garment =
          'traditional Yoruba Iro and Buba — wrapped wrapper with loose blouse';
      fabricDetail =
          'premium aso-oke or lace fabric with matching headwrap (gele)';
      styleDetail = 'elegant traditional Yoruba feminine silhouette';
    } else if (lower.contains('wrapper') || lower.contains('gele')) {
      garment = 'elegant African wrapper ensemble with matching headwrap';
      fabricDetail = 'premium George, lace, or Ankara fabric';
      styleDetail = 'graceful draping with traditional African elegance';
    } else if (lower.contains('bridal') || lower.contains('wedding')) {
      garment =
          'luxurious African bridal gown — fusion of traditional and modern';
      fabricDetail =
          'premium lace, chiffon, or silk with crystal and bead embellishments';
      styleDetail =
          'show-stopping bridal elegance, floor-length, cathedral train';
    } else if (lower.contains('ankara')) {
      garment = 'vibrant Ankara wax print fashion ensemble';
      fabricDetail =
          'bold African wax print fabric with intricate geometric or floral patterns';
      styleDetail =
          'modern African fashion with traditional fabric, contemporary cut';
    } else if (lower.contains('gown') || lower.contains('dress')) {
      garment = 'elegant African fashion gown';
      fabricDetail =
          'luxurious fabric — chiffon, lace, or silk with delicate embellishments';
      styleDetail =
          'floor-length flowing silhouette, flattering cut, red-carpet worthy';
    } else if (lower.contains('suit')) {
      garment = 'bespoke tailored suit';
      fabricDetail = 'premium Italian wool with fine pinstripe or solid finish';
      styleDetail = 'sharp modern fit, peak lapels, structured shoulders';
    } else {
      garment = 'premium Nigerian fashion design';
      fabricDetail = 'luxurious fabric with handcrafted embroidery details';
      styleDetail = 'contemporary African fashion with traditional influence';
    }

    // Extract user-specified color — respect what they asked for
    final color = _extractColor(lower);

    return '$garment in $color, $fabricDetail. $styleDetail. '
        'Single confident Nigerian model standing in a professional fashion photography studio. '
        'Clean seamless background. '
        'Editorial fashion photography, soft studio lighting with dramatic key light, '
        'high resolution, sharp focus on garment details and fabric texture, '
        'Vogue Africa editorial quality, full-body shot, '
        'photorealistic, 8K detail. '
        'Negative: $_negativePrompt';
  }

  /// Extract color from user message. Uses word boundary matching to avoid
  /// false positives (e.g. "dress" matching "red").
  String _extractColor(String lower) {
    final words = lower.split(RegExp(r'\s+'));

    bool hasWord(String target) =>
        words.any((w) => w == target || w.startsWith(target));
    bool hasAny(List<String> targets) => targets.any(hasWord);

    if (hasWord('black'))
      return 'elegant black fabric with matching black embroidery';
    if (hasWord('white'))
      return 'pristine white fabric with tonal white embroidery';
    if (hasWord('cream')) return 'rich cream fabric with gold embroidery';
    if (hasWord('gold'))
      return 'luxurious gold fabric with metallic embroidery';
    if (hasWord('navy')) return 'navy blue fabric with tonal embroidery';
    if (hasWord('blue')) return 'deep royal blue fabric with gold embroidery';
    if (hasAny(['green', 'emerald']))
      return 'emerald green fabric with gold thread embroidery';
    if (hasAny(['red', 'ruby']))
      return 'deep ruby red fabric with gold embroidery';
    if (hasAny(['burgundy', 'wine']))
      return 'burgundy wine fabric with tonal embroidery';
    if (hasAny(['purple', 'violet']))
      return 'rich purple fabric with gold embroidery';
    if (hasWord('brown')) return 'chocolate brown fabric with tan embroidery';
    if (hasWord('pink')) return 'blush pink fabric with rose gold embroidery';
    if (hasAny(['yellow', 'mustard']))
      return 'mustard yellow fabric with brown embroidery';
    if (hasWord('orange')) return 'burnt orange fabric with gold embroidery';
    if (hasAny(['grey', 'gray']))
      return 'charcoal grey fabric with silver embroidery';
    if (hasWord('silver')) return 'metallic silver fabric with grey embroidery';
    if (hasAny(['beige', 'tan']))
      return 'warm beige fabric with brown embroidery';
    if (hasWord('maroon')) return 'deep maroon fabric with gold embroidery';
    if (hasAny(['teal', 'turquoise']))
      return 'rich teal fabric with gold embroidery';
    if (hasWord('coral')) return 'coral fabric with gold embroidery';
    if (hasWord('lavender')) return 'lavender fabric with silver embroidery';
    if (hasAny(['olive', 'khaki']))
      return 'olive green fabric with brown embroidery';

    // No color specified — garment-appropriate default
    return 'royal blue fabric with gold embroidery';
  }

  // ---------------------------------------------------------------------------
  // SEWING/PATTERN PROMPT BUILDER
  // ---------------------------------------------------------------------------

  String _buildSewingPrompt(String garment, String step) {
    return 'Technical fashion illustration: $step for constructing a $garment. '
        'Clean flat pattern layout on white background, '
        'precise measurement lines and annotations, '
        'dotted fold lines, solid seam allowance lines, '
        'grain line arrows, notch markers, '
        'professional technical drawing style, '
        'fashion construction diagram, '
        'single image (not multiple views), '
        'clean crisp lines, high contrast, '
        'technical illustration, blueprint style. '
        'Negative: $_negativePrompt';
  }
}
