import 'dart:js_interop';
import 'dart:js_interop_unsafe';

@JS('__ensureFlutterwave')
external JSPromise _ensureFlutterwaveSDK();

@JS('__openFwCheckout')
external void _openFwCheckoutJS(String jsonConfig);

@JS('globalThis')
external JSObject get _globalThis;

class FlutterwaveWebBridge {
  static Future<bool> openCheckout(String jsonConfig) async {
    try {
      await _ensureFlutterwaveSDK().toDart;
      for (var i = 0; i < 40; i++) {
        if (_globalThis.getProperty('FlutterwaveCheckout'.toJS) != null) break;
        await Future<void>.delayed(const Duration(milliseconds: 100));
      }

      if (_globalThis.getProperty('FlutterwaveCheckout'.toJS) == null) {
        return false;
      }

      _globalThis.setProperty('__fwDone'.toJS, false.toJS);
      _globalThis.setProperty('__fwClosed'.toJS, false.toJS);
      _globalThis.setProperty('__fwResult'.toJS, ''.toJS);
      _openFwCheckoutJS(jsonConfig);
      return true;
    } catch (_) {
      return false;
    }
  }

  static bool get isDone =>
      _globalThis.getProperty('__fwDone'.toJS).dartify() == true;

  static bool get isClosed =>
      _globalThis.getProperty('__fwClosed'.toJS).dartify() == true;

  static String get result =>
      _globalThis.getProperty('__fwResult'.toJS).dartify()?.toString() ?? '';
}
