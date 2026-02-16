import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:get/get.dart';
import '../services/admob_service.dart';

class AdBannerWidget extends StatelessWidget {
  const AdBannerWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final adMobService = AdMobService.to;

    return Obx(() {
      if (!adMobService.isAdLoaded.value) {
        return const SizedBox.shrink();
      }

      return Container(
        alignment: Alignment.center,
        width: adMobService.bannerAd.size.width.toDouble(),
        height: adMobService.bannerAd.size.height.toDouble(),
        child: AdWidget(ad: adMobService.bannerAd),
      );
    });
  }
}
