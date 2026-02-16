import 'dart:html' as html;
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import '../utils/logger.dart';

class AdSenseWebService extends GetxService {
  static AdSenseWebService get to => Get.find();

  final String publisherId = 'ca-pub-xxxxxxxxxxxxxxxx';
  final isInitialized = false.obs;

  Future<AdSenseWebService> init() async {
    try {
      if (kIsWeb) {
        _injectAdSenseScript();
        isInitialized.value = true;
        AppLogger.info('AdSenseWebService', 'AdSense initialized');
      }
    } catch (e) {
      AppLogger.error('AdSenseWebService', 'Initialization failed', e);
    }
    return this;
  }

  void _injectAdSenseScript() {
    final scriptElement = html.ScriptElement()
      ..async = true
      ..src = 'https://pagead2.googlesyndication.com/pagead/js/adsbygoogle.js'
      ..setAttribute('data-ad-client', publisherId);

    html.document.head?.append(scriptElement);
  }

  void displayAd(String adSlotId) {
    if (kIsWeb) {
      try {
        html.window.adsbygoogle?.add({
          'google_ad_client': publisherId,
          'google_ad_slot': adSlotId,
          'google_ad_format': 'auto',
          'google_ad_full_width': true,
        } as Object);

        AppLogger.info('AdSenseWebService', 'Ad displayed: $adSlotId');
      } catch (e) {
        AppLogger.error('AdSenseWebService', 'Failed to display ad', e);
      }
    }
  }
}

extension on html.Window {
  external List<dynamic>? get adsbygoogle;
}


