import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdWidget extends StatelessWidget {
  final BannerAd bannerAd;
  final EdgeInsets padding;

  const AdWidget({
    super.key,
    required this.bannerAd,
    this.padding = const EdgeInsets.all(8.0),
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Container(
        alignment: Alignment.center,
        width: bannerAd.size.width.toDouble(),
        height: bannerAd.size.height.toDouble(),
        color: Colors.grey[200],
        child: Center(
          child: Text('Banner Ad'),
        ),
      ),
    );
  }
}

class NativeAdWidget extends StatelessWidget {
  final NativeAd nativeAd;

  const NativeAdWidget({
    super.key,
    required this.nativeAd,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.center,
      color: Colors.grey[200],
      child: Center(
        child: Text('Native Ad'),
      ),
    );
  }
}
