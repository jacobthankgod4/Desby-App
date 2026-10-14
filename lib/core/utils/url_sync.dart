/// Browser URL synchronisation, split by platform.
///
/// `dart:html` does not exist on the VM, iOS or macOS, so importing it
/// unconditionally made every test and every desktop/mobile build fail to
/// compile — not just the web target. The stub keeps the signature identical so
/// callers need no `kIsWeb` guards of their own.
export 'url_sync_stub.dart'
    if (dart.library.js_interop) 'url_sync_web.dart';
