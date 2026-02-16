import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../config/app_colors.dart';
import '../../config/feature_gating.dart';

/// Paywall screen shown when user attempts to access premium features
class PaywallScreen extends StatefulWidget {
  const PaywallScreen({super.key});

  @override
  State<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends State<PaywallScreen> {
  late String _requestedFeature;
  late SubscriptionTier? _currentTier;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _requestedFeature = Get.arguments?['feature'] ?? 'premium_feature';
    _loadCurrentSubscription();
  }

  Future<void> _loadCurrentSubscription() async {
    try {
      _currentTier = await FeatureGatingMiddleware.getUserSubscriptionTier();
      setState(() {});
    } catch (e) {
      debugPrint('Error loading subscription: $e');
    }
  }

  Future<void> _upgradeSubscription(SubscriptionTier tier) async {
    setState(() => _isLoading = true);
    try {
      // Navigate to payment processing
      Get.toNamed('/payment', arguments: {
        'type': 'subscription_upgrade',
        'tier': tier,
        'feature': _requestedFeature,
      });
    } catch (e) {
      Get.snackbar('Error', 'Failed to process upgrade: $e',
          snackPosition: SnackPosition.BOTTOM);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBg,
      appBar: AppBar(
        backgroundColor: AppColors.darkBg,
        elevation: 0,
        title: const Text(
          'Upgrade Your Plan',
          style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.cyan),
          onPressed: () => Get.back(),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Feature request header
              _buildHeader(),
              const SizedBox(height: 32),

              // Current tier indicator
              if (_currentTier != null) ...[
                _buildCurrentTierBadge(),
                const SizedBox(height: 32),
              ],

              // Tier comparison
              _buildTierComparison(),
              const SizedBox(height: 32),

              // Feature details
              _buildFeatureDetails(),
              const SizedBox(height: 40),

              // Action buttons
              _buildActionButtons(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.lock_outline, size: 48, color: Colors.orange),
        const SizedBox(height: 16),
        const Text(
          'Unlock Premium Features',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Upgrade your subscription to access $_requestedFeature',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildCurrentTierBadge() {
    final tierName = _currentTier?.toString().split('.').last ?? 'Unknown';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue[300]!),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: Colors.blue, size: 20),
          const SizedBox(width: 8),
          Text(
            'Current Plan: ${tierName.toUpperCase()}',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.blue,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTierComparison() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Choose Your Plan',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        // Premium tier card
        _buildTierCard(
          tier: SubscriptionTier.premium,
          title: 'Premium',
          price: '\$9.99',
          period: '/month',
          description: 'Perfect for active users',
          features: [
            '50 matches per day',
            '200 messages per day',
            'Advanced filters',
            'Match history',
            'Email support',
          ],
          isCurrentTier: _currentTier == SubscriptionTier.premium,
          onUpgrade: () => _upgradeSubscription(SubscriptionTier.premium),
        ),
        const SizedBox(height: 16),
        // Platinum tier card
        _buildTierCard(
          tier: SubscriptionTier.platinum,
          title: 'Platinum',
          price: '\$19.99',
          period: '/month',
          description: 'Maximum features & priority support',
          features: [
            'Unlimited matches',
            'Unlimited messages',
            'All advanced filters',
            'Full match history',
            'Video chat',
            'Priority support',
            'Premium badges',
          ],
          isCurrentTier: _currentTier == SubscriptionTier.platinum,
          onUpgrade: () => _upgradeSubscription(SubscriptionTier.platinum),
          isPopular: true,
        ),
      ],
    );
  }

  Widget _buildTierCard({
    required SubscriptionTier tier,
    required String title,
    required String price,
    required String period,
    required String description,
    required List<String> features,
    required bool isCurrentTier,
    required VoidCallback onUpgrade,
    bool isPopular = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: isPopular ? Colors.orange : Colors.grey[300]!,
          width: isPopular ? 2 : 1,
        ),
        borderRadius: BorderRadius.circular(12),
        color: isPopular ? Colors.orange[50] : Colors.white,
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (isPopular)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.orange,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Text(
                    'Most Popular',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            textBaseline: TextBaseline.alphabetic,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            children: [
              Text(
                price,
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                period,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            description,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 16),
          // Features list
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: features
                .map(
                  (feature) => Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.check_circle_outline,
                          size: 18,
                          color: Colors.green,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            feature,
                            style: const TextStyle(fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 20),
          // Action button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: isCurrentTier ? null : _isLoading ? null : onUpgrade,
              style: ElevatedButton.styleFrom(
                backgroundColor: isPopular ? Colors.orange : Colors.blue,
                padding: const EdgeInsets.symmetric(vertical: 12),
                disabledBackgroundColor: Colors.grey[300],
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation(Colors.white),
                      ),
                    )
                  : Text(
                      isCurrentTier ? 'Current Plan' : 'Upgrade Now',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureDetails() {
    final featureMap = {
      'unlimited_matches': 'Access unlimited potential matches daily',
      'unlimited_messages': 'Send unlimited messages to matches',
      'advanced_filters': 'Use advanced filtering options for better matches',
      'priority_support': 'Get priority customer support',
      'video_chat': 'Video call your matches',
    };

    final featureDescription = featureMap[_requestedFeature] ?? 'This premium feature';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'What You\'ll Get',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            featureDescription,
            style: const TextStyle(
              fontSize: 14,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '✓ Cancel anytime',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _isLoading
                ? null
                : () => _upgradeSubscription(SubscriptionTier.premium),
            icon: const Icon(Icons.trending_up),
            label: const Text('Upgrade to Premium'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              backgroundColor: Colors.orange,
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: TextButton(
            onPressed: () => Get.back(),
            child: const Text('Maybe Later'),
          ),
        ),
      ],
    );
  }
}
