import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:get/get.dart';
import '../config/app_config.dart';
import '../utils/logger.dart';

class AdMobService extends GetxService {
  static AdMobService get to => Get.find();

  late BannerAd _bannerAd;
  late InterstitialAd? _interstitialAd;
  late RewardedAd? _rewardedAd;

  final isAdLoaded = false.obs;
  final isInterstitialLoaded = false.obs;
  final isRewardedLoaded = false.obs;

  Future<AdMobService> init() async {
    try {
      if (!kIsWeb) {
        await MobileAds.instance.initialize();
        _loadBannerAd();
        _loadInterstitialAd();
        _loadRewardedAd();
      }
    } catch (e) {
      AppLogger.error('AdMobService', 'Initialization failed', e);
    }
    return this;
  }

  void _loadBannerAd() {
    _bannerAd = BannerAd(
      adUnitId: AppConfig.admobBannerAdUnitId,
      request: const AdRequest(),
      size: AdSize.banner,
      listener: BannerAdListener(
        onAdLoaded: (_) {
          isAdLoaded.value = true;
          AppLogger.info('AdMobService', 'Banner ad loaded');
        },
        onAdFailedToLoad: (ad, error) {
          AppLogger.error('AdMobService', 'Banner ad failed to load: ${error.message}');
          ad.dispose();
        },
      ),
    );
    _bannerAd.load();
  }

  void _loadInterstitialAd() {
    InterstitialAd.load(
      adUnitId: AppConfig.admobInterstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          isInterstitialLoaded.value = true;
          AppLogger.info('AdMobService', 'Interstitial ad loaded');
        },
        onAdFailedToLoad: (error) {
          AppLogger.error('AdMobService', 'Interstitial ad failed to load: ${error.message}');
        },
      ),
    );
  }

  void _loadRewardedAd() {
    RewardedAd.load(
      adUnitId: AppConfig.admobRewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedAd = ad;
          isRewardedLoaded.value = true;
          AppLogger.info('AdMobService', 'Rewarded ad loaded');
        },
        onAdFailedToLoad: (error) {
          AppLogger.error('AdMobService', 'Rewarded ad failed to load: ${error.message}');
        },
      ),
    );
  }

  BannerAd get bannerAd => _bannerAd;

  Future<void> showInterstitialAd() async {
    if (_interstitialAd != null) {
      _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (ad) {
          AppLogger.info('AdMobService', 'Interstitial ad dismissed');
          ad.dispose();
          _loadInterstitialAd();
        },
        onAdFailedToShowFullScreenContent: (ad, error) {
          AppLogger.error('AdMobService', 'Interstitial ad failed to show: ${error.message}');
          ad.dispose();
          _loadInterstitialAd();
        },
      );
      await _interstitialAd!.show();
    }
  }

  Future<void> showRewardedAd(Function(RewardItem) onRewardEarned) async {
    if (_rewardedAd != null) {
      _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (ad) {
          AppLogger.info('AdMobService', 'Rewarded ad dismissed');
          ad.dispose();
          _loadRewardedAd();
        },
        onAdFailedToShowFullScreenContent: (ad, error) {
          AppLogger.error('AdMobService', 'Rewarded ad failed to show: ${error.message}');
          ad.dispose();
          _loadRewardedAd();
        },
      );
      await _rewardedAd!.show(
        onUserEarnedReward: (ad, reward) {
          onRewardEarned(reward);
          AppLogger.info('AdMobService', 'User earned reward: ${reward.amount}');
        },
      );
    }
  }

  void dispose() {
    _bannerAd.dispose();
    _interstitialAd?.dispose();
    _rewardedAd?.dispose();
  }
}
