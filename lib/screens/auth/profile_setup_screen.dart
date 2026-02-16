import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:async';
import '../../providers/auth_controller.dart';
import '../../models/user_model.dart';
import '../../config/app_colors.dart';

class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  late final AuthController authController;
  late final TextEditingController nameController;
  late final TextEditingController bioController;
  late final TextEditingController locationController;
  late final TextEditingController budgetController;
  final formKey = GlobalKey<FormState>();
  DateTime? selectedBirthDate;
  int _currentStep = 0;

  @override
  void initState() {
    super.initState();
    authController = Get.find<AuthController>();
    nameController = TextEditingController();
    bioController = TextEditingController();
    locationController = TextEditingController();
    budgetController = TextEditingController();
  }

  @override
  void dispose() {
    nameController.dispose();
    bioController.dispose();
    locationController.dispose();
    budgetController.dispose();
    super.dispose();
  }

  void _selectBirthDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2000),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => selectedBirthDate = picked);
    }
  }

  bool _validateCurrentStep() {
    if (_currentStep == 0) {
      // Validate basic info
      if (nameController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter your name')),
        );
        return false;
      }
      if (selectedBirthDate == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select your birth date')),
        );
        return false;
      }
      return true;
    } else if (_currentStep == 1) {
      // Validate location and budget
      if (locationController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter your city')),
        );
        return false;
      }
      if (budgetController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter your budget')),
        );
        return false;
      }
      return true;
    }
    return true;
  }

  void _handleCreateProfile() async {
    if (!formKey.currentState!.validate()) {
      debugPrint('Form validation failed');
      return;
    }

    final userId = authController.currentUserId.value;
    if (userId == null || userId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error: User not authenticated')),
      );
      return;
    }

    // Validate required fields before creating profile
    final name = nameController.text.trim();
    final city = locationController.text.trim();
    final budget = budgetController.text.trim();
    
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your name')),
      );
      return;
    }
    
    if (city.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your city')),
      );
      return;
    }
    
    if (budget.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your budget')),
      );
      return;
    }
    
    if (selectedBirthDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select your birth date')),
      );
      return;
    }

    final profile = UserProfile(
      userId: userId,
      name: name,
      age: DateTime.now().year - selectedBirthDate!.year,
      avatar: null,
      bio: bioController.text.trim(),
      phone: '',
      phoneVerified: false,
      email: null,
      emailVerified: false,
      city: city,
      state: '',
      neighborhoods: [],
      moveInDate: DateTime.now(),
      budgetMin: double.tryParse(budget) ?? 0,
      budgetMax: double.tryParse(budget) ?? 0,
      roommatePrefGender: null,
      verified: false,
      stripeConnectId: null,
      backgroundCheckStatus: null,
      backgroundCheckDate: null,
      trustScore: 50,
      trustBadgeIds: [],
      identityVerifiedAt: null,
      identityDocumentSelfieVerified: false,
      cleanliness: 5,
      sleepSchedule: 'normal',
      socialFrequency: 5,
      noiseTolerance: 5,
      financialReliability: 5,
      hasPets: false,
      petTolerance: 5,
      guestPolicy: 5,
      privacyNeed: 5,
      kitchenHabits: 5,
      createdAt: DateTime.now(),
      lastActiveAt: DateTime.now(),
      isActive: true,
      isSuspended: false,
    );
    debugPrint('Creating profile for user: $userId with city: $city');

    try {
      // Actually save the profile to Firestore
      debugPrint('Calling authController.createProfile()');
      
      // Add timeout to prevent infinite hanging
      await authController.createProfile(profile)
          .timeout(
            const Duration(seconds: 40), // Increased to allow for retries
            onTimeout: () {
              throw TimeoutException('Profile creation timed out after 40 seconds - check internet connection');
            },
          );
      
      debugPrint('Profile saved to Firestore for user: $userId');
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile created successfully!'),
          backgroundColor: Colors.green,
        ),
      );
      
      // Wait a moment to ensure Firestore sync, then navigate to home
      await Future.delayed(const Duration(milliseconds: 1000));
      debugPrint('Navigating to home screen');
      Get.offAllNamed('/');
    } catch (e) {
      debugPrint('Error creating profile: $e');
      
      String errorMessage = e.toString();
      if (e is TimeoutException) {
        errorMessage = 'Network timeout - Please check your internet connection and try again';
      } else if (errorMessage.contains('Firestore write timeout')) {
        errorMessage = 'Could not connect to Firestore - Please check your internet connection';
      } else if (errorMessage.contains('All databases unavailable')) {
        errorMessage = 'Database unavailable - Please check your internet connection';
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error creating profile: $errorMessage'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: AppColors.darkBg,
        child: SafeArea(
          child: Column(
            children: [
              // Header with back button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
                      onPressed: () => Get.back(),
                      padding: EdgeInsets.zero,
                    ),
                    const Expanded(
                      child: Text(
                        'Profile Setup',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              // Progress bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: (_currentStep + 1) / 3,
                    minHeight: 6,
                    backgroundColor: AppColors.borderColor,
                    valueColor: const AlwaysStoppedAnimation<Color>(AppColors.cyan),
                  ),
                ),
              ),
              
              const SizedBox(height: 4),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'Step ${_currentStep + 1} of 3',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              
              // Form content
              Expanded(
                child: Form(
                  key: formKey,
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Step 1: Basic Information
                          if (_currentStep == 0) ...[
                            const Text(
                              'Tell us about yourself',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Help others get to know you',
                              style: TextStyle(
                                fontSize: 14,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 32),
                            
                            // Name field
                            _buildTextField(
                              controller: nameController,
                              label: 'Full Name',
                              hint: 'John Doe',
                            ),
                            const SizedBox(height: 20),
                            
                            // Birth date selector
                            GestureDetector(
                              onTap: _selectBirthDate,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                decoration: BoxDecoration(
                                  color: AppColors.darkSecondaryBg,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: AppColors.borderColor),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Birth Date',
                                          style: TextStyle(
                                            color: AppColors.textSecondary,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          selectedBirthDate != null
                                              ? '${selectedBirthDate!.month}/${selectedBirthDate!.day}/${selectedBirthDate!.year}'
                                              : 'Select your date of birth',
                                          style: TextStyle(
                                            color: selectedBirthDate != null ? AppColors.textPrimary : AppColors.textTertiary,
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const Icon(Icons.calendar_today, color: AppColors.textSecondary, size: 20),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                            
                            // Bio field
                            _buildTextField(
                              controller: bioController,
                              label: 'Bio',
                              hint: 'Tell us about yourself...',
                              maxLines: 3,
                            ),
                          ],
                          
                          // Step 2: Location & Budget
                          if (_currentStep == 1) ...[
                            const Text(
                              'Where and how much?',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Help us find matches near you',
                              style: TextStyle(
                                fontSize: 14,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 32),
                            
                            // Location field
                            _buildTextField(
                              controller: locationController,
                              label: 'City',
                              hint: 'San Francisco, CA',
                            ),
                            const SizedBox(height: 20),
                            
                            // Budget field
                            _buildTextField(
                              controller: budgetController,
                              label: 'Monthly Budget',
                              hint: '\$1,500',
                              prefixText: '\$',
                              keyboardType: TextInputType.number,
                            ),
                          ],
                          
                          // Step 3: Preferences
                          if (_currentStep == 2) ...[
                            const Text(
                              'Your preferences',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Tell us what matters to you',
                              style: TextStyle(
                                fontSize: 14,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 32),
                            
                            const Text(
                              'Profile setup complete! Review your information and continue.',
                              style: TextStyle(
                                fontSize: 14,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              
              // Action Buttons
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    if (_currentStep > 0)
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => setState(() => _currentStep -= 1),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: AppColors.cyan),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Back',
                            style: TextStyle(color: AppColors.cyan, fontSize: 16, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                    if (_currentStep > 0) const SizedBox(width: 12),
                    Expanded(
                      child: Obx(() => ElevatedButton(
                        onPressed: authController.isLoading.value ? null : () {
                          if (_currentStep < 2) {
                            if (_validateCurrentStep()) {
                              setState(() => _currentStep += 1);
                            }
                          } else {
                            _handleCreateProfile();
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: authController.isLoading.value ? AppColors.textTertiary : AppColors.gold,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: authController.isLoading.value
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.darkBg),
                                ),
                              )
                            : Text(
                                _currentStep < 2 ? 'Continue' : 'Create Profile',
                                style: const TextStyle(
                                  color: AppColors.darkBg,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      )),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReviewItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    int maxLines = 1,
    String? prefixText,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          style: const TextStyle(color: AppColors.textPrimary),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: AppColors.textTertiary),
            prefixText: prefixText,
            prefixStyle: const TextStyle(color: AppColors.textPrimary),
            filled: true,
            fillColor: AppColors.darkSecondaryBg,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.borderColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.borderColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.cyan, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
          validator: (value) {
            if (value?.isEmpty ?? true) return '$label is required';
            return null;
          },
        ),
      ],
    );
  }
}
