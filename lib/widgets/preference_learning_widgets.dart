import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../services/ai_preference_learning.dart';
import '../utils/constants.dart';

class PreferenceLearningController extends GetxController {
  final preferenceInsight = Rx<AIPreferenceInsight?>(null);
  final isLoading = false.obs;
  final error = Rx<String?>(null);

  Future<void> loadUserPreferences(String userId) async {
    isLoading.value = true;
    error.value = null;
    
    try {
      final service = Get.find<AIPreferenceLearningService>();
      final preferences = await service.analyzeUserPreferences(userId);
      preferenceInsight.value = preferences;
    } catch (e) {
      error.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }

  void updatePreferenceWeight(String dimension, int newWeight) {
    if (preferenceInsight.value == null) return;
    
    // Update locally first (optimistic update)
    final updated = Map<String, int>.from(preferenceInsight.value!.dimensionPreferences);
    updated[dimension] = newWeight;
    
    // In production, persist to service
  }
}

class PreferenceLearningWidget extends StatelessWidget {
  final AIPreferenceInsight preferenceInsight;

  const PreferenceLearningWidget({
    required this.preferenceInsight,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(AppPadding.large),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'AI Learning Profile',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Chip(
                  label: Text(
                    '${((preferenceInsight.dimensionPreferences.length / 10) * 100).toStringAsFixed(0)}% Profile Complete',
                    style: const TextStyle(
                      color: Colors.blue,
                    ),
                  ),
                  backgroundColor: Colors.blue.withValues(alpha: 0.1),
                ),
              ],
            ),
            SizedBox(height: AppPadding.large),
            Text(
              'Learned Preferences',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            SizedBox(height: AppPadding.medium),
            ..._buildDimensionSliders(context),
            SizedBox(height: AppPadding.large),
            _buildLearningStats(context),
            SizedBox(height: AppPadding.medium),
            _buildLearningInsights(context),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildDimensionSliders(BuildContext context) {
    final dimensions = preferenceInsight.dimensionPreferences.entries.toList();
    
    return [
      for (int i = 0; i < dimensions.length; i++) ...[
        _buildDimensionSlider(
          context,
          dimensions[i].key,
          dimensions[i].value.toDouble(),
        ),
        if (i < dimensions.length - 1) SizedBox(height: AppPadding.medium),
      ]
    ];
  }

  Widget _buildDimensionSlider(
    BuildContext context,
    String dimension,
    double weight,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _formatDimensionName(dimension),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: AppPadding.small,
                vertical: 4,
              ),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                '${(weight * 100).toStringAsFixed(0)}%',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: weight,
            minHeight: 6,
            backgroundColor: Colors.grey[200],
            valueColor: AlwaysStoppedAnimation(
              _getDimensionColor(dimension),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLearningStats(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(AppPadding.medium),
      decoration: BoxDecoration(
        color: Colors.blue.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Learning Stats',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: AppPadding.medium),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStatItem(
                context,
                'Interactions',
                preferenceInsight.successFactors.length.toString(),
              ),
              _buildStatItem(
                context,
                'Accepted',
                preferenceInsight.successFactors.length.toString(),
              ),
              _buildStatItem(
                context,
                'Rejected',
                preferenceInsight.riskFactors.length.toString(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(BuildContext context, String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: Colors.blue,
          ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall,
        ),
      ],
    );
  }

  Widget _buildLearningInsights(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(AppPadding.medium),
      decoration: BoxDecoration(
        color: Colors.amber.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.amber.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lightbulb, color: Colors.amber, size: 20),
              SizedBox(width: AppPadding.small),
              Text(
                'AI Insights',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: AppPadding.small),
          Text(
            _generateInsight(),
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  Color _getConfidenceColor(double confidence) {
    if (confidence > 0.8) return Colors.green;
    if (confidence > 0.6) return Colors.orange;
    return Colors.red;
  }

  Color _getDimensionColor(String dimension) {
    final colors = {
      'cleanliness': Colors.blue,
      'noise_tolerance': Colors.purple,
      'social_frequency': Colors.green,
      'budget': Colors.orange,
      'schedule': Colors.red,
      'lifestyle': Colors.pink,
      'privacy': Colors.teal,
    };
    return colors[dimension] ?? Colors.grey;
  }

  String _formatDimensionName(String dimension) {
    return dimension
        .split('_')
        .map((word) => word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }

  String _generateInsight() {
    if (preferenceInsight.dimensionPreferences.isEmpty) {
      return 'AI is learning your preferences. Interact with more matches to get better recommendations.';
    }
    
    final topDimension = preferenceInsight.dimensionPreferences.entries
        .reduce((a, b) => a.value > b.value ? a : b);
    
    final dimensionName = _formatDimensionName(topDimension.key);
    final weight = (topDimension.value / 10 * 100).toStringAsFixed(0);
    
    return 'The AI has learned that $dimensionName ($weight%) is your most important compatibility factor. '
        'This is based on ${preferenceInsight.matchingPatterns.length} interaction patterns analyzed so far.';
  }
}

class PreferenceLearningSheet extends StatelessWidget {
  final AIPreferenceInsight preferenceInsight;
  final VoidCallback onApplyInsights;

  const PreferenceLearningSheet({
    required this.preferenceInsight,
    required this.onApplyInsights,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Container(
        padding: EdgeInsets.all(AppPadding.large),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Preference Learning',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Icon(Icons.close),
                ),
              ],
            ),
            SizedBox(height: AppPadding.large),
            PreferenceLearningWidget(preferenceInsight: preferenceInsight),
            SizedBox(height: AppPadding.extraLarge),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onApplyInsights,
                child: Text('Apply These Insights'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
