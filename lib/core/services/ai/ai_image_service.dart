import 'dart:async';
import 'package:flutter/foundation.dart';
import 'puter_interop.dart';
import 'dart:js_interop';
import 'package:web/web.dart' as web;

/// AiImageService - Domain-level service for Neural Pre-Production
class AiImageService {
  /// Generates a neural concept image based on a fashion prompt.
  /// Automatically enriches prompts with African Luxury metadata.
  Future<String?> generateNeuralConcept(String userPrompt, {String model = 'black-forest-labs/flux-schnell'}) async {
    if (!kIsWeb) {
      debugPrint('AI Generation currently optimized for Web Environment.');
      return null;
    }

    try {
      final enrichedPrompt = _enrichPrompt(userPrompt);
      debugPrint('--- NEURAL ENGINE: Processing Design Architecture ---');
      debugPrint('PROMPT: $enrichedPrompt');

      // 1. Configure Puter Options
      final options = PuterImageOptions(
        model: model,
        quality: 'high',
      );

      // 2. Execute JS Interop Call
      // puter.ai.txt2img returns a Promise<HTMLImageElement>
      final Puter puter = web.window.getProperty('puter'.toJS) as Puter;
      final jsPromise = puter.ai.txt2img(enrichedPrompt, options);
      
      // 3. Resolve Promise to Dart Future
      final jsImage = await jsPromise.toDart;
      
      // 4. Extract Source from HTMLImageElement
      final imgElement = jsImage as web.HTMLImageElement;
      final src = imgElement.src;
      
      debugPrint('--- NEURAL ENGINE: Architecture Rendered Successfully ---');
      return src;
    } catch (e) {
      debugPrint('Neural Engine Fault: $e');
      return null;
    }
  }

  /// Context Enrichment Engine
  /// Appends professional photography and cultural metadata to user input.
  String _enrichPrompt(String input) {
    const String suffix = ", high-definition professional fashion photography, African luxury tailoring, intricate fabric textures, premium studio lighting, 8k resolution, photorealistic.";
    if (input.toLowerCase().contains('agbada') || input.toLowerCase().contains('kaftan')) {
      return "$input, premium silk embroidery $suffix";
    }
    return "$input $suffix";
  }
}
