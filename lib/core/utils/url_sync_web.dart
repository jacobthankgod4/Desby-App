import 'dart:js_interop';

import 'package:web/web.dart' as web;

/// Real browser implementation.
String readUrlHash() => web.window.location.hash;

String getUrlPath() => web.window.location.pathname;

void replaceUrlHash(String hash) =>
    web.window.history.replaceState(null, '', hash);

void pushUrlHash(String hash) => web.window.history.pushState(null, '', hash);

void listenToPopState(void Function(String hash) onPop) {
  web.window.addEventListener(
    'popstate',
    ((web.Event event) {
      onPop(web.window.location.hash);
    }).toJS,
  );
}
