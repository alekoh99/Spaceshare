import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../config/app_colors.dart';

class CompatibilityQuestionnaireScreen extends StatefulWidget {
  const CompatibilityQuestionnaireScreen({super.key});

  @override
  State<CompatibilityQuestionnaireScreen> createState() =>
      _CompatibilityQuestionnaireScreenState();
}

class _CompatibilityQuestionnaireScreenState
    extends State<CompatibilityQuestionnaireScreen> {
  final PageController _pageController = PageController();
  int currentPage = 0;
  final answers = <int, String>{};

  final questions = [
    {'q': 'How clean do you like your space?', 'options': ['Very Clean', 'Moderately', 'Relaxed']},
    {'q': 'What\'s your typical bedtime?', 'options': ['Early (10pm)', 'Medium (11-12pm)', 'Late (1am+)']},
    {'q': 'How often do you have guests?', 'options': ['Frequently', 'Sometimes', 'Rarely']},
    {'q': 'Preferred roommate age range?', 'options': ['20-25', '25-30', '30+']},
    {'q': 'Smoking preference?', 'options': ['Non-smoker', 'Smoker OK', 'Outdoor only']},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBg,
      appBar: AppBar(
        backgroundColor: AppColors.darkBg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.cyan),
          onPressed: () => Get.back(),
        ),
        title: const Text(
          'Compatibility Quiz',
          style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
        ),
      ),
      body: Column(
        children: [
          LinearProgressIndicator(
            value: (currentPage + 1) / questions.length,
            backgroundColor: AppColors.darkBg2,
            valueColor: const AlwaysStoppedAnimation(AppColors.cyan),
          ),
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: (index) => setState(() => currentPage = index),
              itemCount: questions.length,
              itemBuilder: (context, index) {
                final q = questions[index];
                return _buildQuestionPage(q, index);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionPage(Map q, int index) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            children: [
              Text(
                'Question ${index + 1}/${questions.length}',
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
              ),
              const SizedBox(height: 24),
              Text(
                q['q'] as String,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          Column(
            children: (q['options'] as List<String>)
                .asMap()
                .entries
                .map((entry) {
                  final idx = entry.key;
                  final option = entry.value;
                  final isSelected = answers[index] == option;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: GestureDetector(
                      onTap: () {
                        setState(() => answers[index] = option);
                        if (index < questions.length - 1) {
                          Future.delayed(const Duration(milliseconds: 300), () {
                            _pageController.nextPage(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            );
                          });
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: isSelected ? AppColors.cyan : AppColors.borderColor,
                            width: isSelected ? 2 : 1,
                          ),
                          borderRadius: BorderRadius.circular(12),
                          color: isSelected ? AppColors.darkBg2 : AppColors.darkBg,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              option,
                              style: TextStyle(
                                fontSize: 16,
                                color: isSelected ? AppColors.cyan : AppColors.textPrimary,
                                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                              ),
                            ),
                            if (isSelected)
                              const Icon(Icons.check_circle, color: AppColors.cyan),
                          ],
                        ),
                      ),
                    ),
                  );
                })
                .toList(),
          ),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: currentPage == questions.length - 1 && answers.length == questions.length
                  ? () {
                      Get.snackbar('Success', 'Quiz completed!');
                      Get.back();
                    }
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.cyan,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: Text(
                currentPage == questions.length - 1 ? 'Complete' : 'Next',
                style: const TextStyle(color: AppColors.darkBg),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
}
