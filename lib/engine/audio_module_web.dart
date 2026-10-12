import 'dart:js_interop';

@JS('guitarBridgeEnsureAudioReady')
external JSPromise<JSAny?> _ensureAudioReady();

Future<void> ensureAudioModuleReady() async {
  await _ensureAudioReady().toDart;
}
