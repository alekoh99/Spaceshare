import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:get/get.dart';
import '../utils/logger.dart';

class MonetizationController extends GetxController {
  final adImpressions = 0.obs;
  final adClicks = 0.obs;
  final estimatedEarnings = 0.0.obs;

  final _adMetrics = <String, dynamic>{}.obs;

  @override
  void onInit() {
    super.onInit();
    _initializeMetrics();
  }

  void _initializeMetrics() {
    _adMetrics['banner_impressions'] = 0;
    _adMetrics['interstitial_impressions'] = 0;
    _adMetrics['rewarded_impressions'] = 0;
  }

  void recordAdImpression(String adType) {
    adImpressions.value++;
    _adMetrics['${adType}_impressions'] = (_adMetrics['${adType}_impressions'] ?? 0) + 1;
    AppLogger.info('MonetizationController', 'Ad impression recorded: $adType');
  }

  void recordAdClick(String adType) {
    adClicks.value++;
    AppLogger.info('MonetizationController', 'Ad click recorded: $adType');
  }

  void recordRewardEarned(RewardItem reward) {
    final amount = double.tryParse(reward.amount.toString()) ?? 0.0;
    estimatedEarnings.value += amount;
    AppLogger.info('MonetizationController', 'Reward earned: ${reward.type} = $amount');
  }

  Map<String, dynamic> getMetrics() => _adMetrics;

  void resetMetrics() {
    adImpressions.value = 0;
    adClicks.value = 0;
    estimatedEarnings.value = 0.0;
    _initializeMetrics();
  }

  @override
  void onClose() {
    AppLogger.info('MonetizationController', 'Disposing controller resources');
    _adMetrics.clear();
    super.onClose();
  }
}
