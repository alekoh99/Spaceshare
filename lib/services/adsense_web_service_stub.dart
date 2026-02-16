import 'package:get/get.dart';
import '../utils/logger.dart';

/// No-op implementation used on non-web platforms where `dart:html`
/// is not available. This keeps the API surface identical so other
/// code can depend on `AdSenseWebService` without platform checks.
class AdSenseWebService extends GetxService {
  static AdSenseWebService get to => Get.find();

  final String publisherId = 'ca-pub-xxxxxxxxxxxxxxxx';
  final isInitialized = false.obs;

  Future<AdSenseWebService> init() async {
    AppLogger.info(
      'AdSenseWebService',
      'AdSense is not supported on this platform. Skipping initialization.',
    );
    return this;
  }

  void displayAd(String adSlotId) {
    AppLogger.debug(
      'AdSenseWebService',
      'displayAd called for slot $adSlotId on unsupported platform. No-op.',
    );
  }
}


