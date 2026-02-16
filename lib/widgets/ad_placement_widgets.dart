import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../services/admob_service.dart';
import '../utils/constants.dart';

class BannerAdWidget extends StatelessWidget {
  final bool showBorder;

  const BannerAdWidget({
    this.showBorder = false,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    try {
      final adMobService = Get.find<AdMobService>();
      final bannerAd = adMobService.bannerAd;

      return Container(
        decoration: showBorder
            ? BoxDecoration(
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(8),
              )
            : null,
        child: SizedBox(
          width: bannerAd.size.width.toDouble(),
          height: bannerAd.size.height.toDouble(),
          child: Container(
            color: Colors.grey[200],
            child: Center(
              child: Text('Banner Ad'),
            ),
          ),
        ),
      );
    } catch (e) {
      // AdMob service not available or not initialized
      return SizedBox.shrink();
    }
  }
}

class InterstitialAdWrapper extends StatelessWidget {
  final Widget child;
  final int showAfterInteractions;

  const InterstitialAdWrapper({
    required this.child,
    this.showAfterInteractions = 5,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return child;
  }
}

class AdPlacementContainer extends StatelessWidget {
  final Widget child;
  final bool showTopBanner;
  final bool showBottomBanner;
  final double? bannerHeight;

  const AdPlacementContainer({
    required this.child,
    this.showTopBanner = false,
    this.showBottomBanner = true,
    this.bannerHeight,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (showTopBanner)
          Padding(
            padding: EdgeInsets.only(bottom: AppPadding.medium),
            child: BannerAdWidget(showBorder: true),
          ),
        Expanded(child: child),
        if (showBottomBanner)
          Padding(
            padding: EdgeInsets.only(top: AppPadding.medium),
            child: BannerAdWidget(showBorder: true),
          ),
      ],
    );
  }
}

class NativeAdPlaceholder extends StatelessWidget {
  final String title;
  final String subtitle;
  final Color? backgroundColor;

  const NativeAdPlaceholder({
    required this.title,
    required this.subtitle,
    this.backgroundColor,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(AppPadding.medium),
      decoration: BoxDecoration(
        color: backgroundColor ?? Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.campaign, color: Colors.grey[600]),
              SizedBox(width: AppPadding.small),
              Text(
                'Advertisement',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Colors.grey[600],
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: AppPadding.medium),
          Text(
            title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: AppPadding.small),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class AdManager {
  static int _interactionCount = 0;
  static const int _interactionThreshold = 5;

  static void recordInteraction() {
    _interactionCount++;
    if (_interactionCount >= _interactionThreshold) {
      showInterstitialIfReady();
      _interactionCount = 0;
    }
  }

  static void showInterstitialIfReady() {
    try {
      final adMobService = Get.find<AdMobService>();
      if (adMobService.isInterstitialLoaded.value) {
        adMobService.showInterstitialAd();
      }
    } catch (e) {
      // Ad service not available
    }
  }

  static void resetInteractionCounter() {
    _interactionCount = 0;
  }
}

/// Ad placement utilities for different screen contexts
class AdPlacementUtils {
  /// Get recommended ad placement for swipe feed screen
  static Widget buildSwipeFeedAdPlacement(Widget child) {
    return AdPlacementContainer(
      showBottomBanner: true,
      showTopBanner: false,
      child: child,
    );
  }

  /// Get recommended ad placement for list screens
  static Widget buildListAdPlacement(Widget child) {
    return AdPlacementContainer(
      showBottomBanner: true,
      showTopBanner: false,
      child: child,
    );
  }

  /// Get recommended ad placement for detail screens
  static Widget buildDetailAdPlacement(Widget child) {
    return AdPlacementContainer(
      showBottomBanner: true,
      showTopBanner: false,
      child: child,
    );
  }

  /// Add banner between list items
  static Widget buildListItemWithAd(
    BuildContext context,
    int index,
    Widget listItem, {
    int adFrequency = 5,
  }) {
    if (index > 0 && index % adFrequency == 0 && index > 0) {
      return Column(
        children: [
          listItem,
          SizedBox(height: 12),
          NativeAdPlaceholder(
            title: 'Sponsored Content',
            subtitle: 'Discover more opportunities',
            backgroundColor: Colors.amber.withValues(alpha: 0.05),
          ),
          SizedBox(height: 12),
        ],
      );
    }
    return listItem;
  }
}
