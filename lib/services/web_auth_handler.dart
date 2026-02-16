/// Platform-aware export:
/// - On web, use the real implementation that relies on `dart:js`
/// - On mobile/desktop, use a stub that avoids importing `dart:js`
library;
export 'web_auth_handler_stub.dart'
    if (dart.library.js) 'web_auth_handler_web.dart';

