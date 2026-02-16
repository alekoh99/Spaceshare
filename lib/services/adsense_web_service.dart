/// Platform-aware export:
/// - On web, use the real AdSense implementation that relies on `dart:html`
/// - On mobile/desktop, use a no-op stub that keeps the same public API
library;
export 'adsense_web_service_stub.dart'
    if (dart.library.html) 'adsense_web_service_web.dart';

