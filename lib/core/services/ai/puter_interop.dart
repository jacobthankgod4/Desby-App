import 'dart:js_interop';

/// PuterInterop - Dart bridge for Puter.js AI capabilities
/// Leverages Puter's "User-Pays" serverless AI model.
@JS('puter')
external Puter get puter;

@JS('puter')
extension type Puter(JSObject _) implements JSObject {
  external PuterAI get ai;
}

@JS()
extension type PuterAI(JSObject _) implements JSObject {
  /// Generates an image using the specified model and options.
  /// Returns a Promise that resolves to an HTMLImageElement.
  @JS('txt2img')
  external JSPromise<JSObject> txt2img(String prompt, [JSObject? options]);
}

/// Options for Puter AI Image Generation
@JS()
@anonymous
extension type PuterImageOptions._(JSObject _) implements JSObject {
  external factory PuterImageOptions({
    String? model,
    String? quality,
    // ignore: non_constant_identifier_names
    bool? use_predefined_prompt,
  });
}
