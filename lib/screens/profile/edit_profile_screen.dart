import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:flutter/foundation.dart'; // Import for kIsWeb
import '../../providers/auth_controller.dart';
import '../../models/user_model.dart';
import '../../widgets/app_svg_icon.dart';
import '../../config/app_colors.dart';
import '../../utils/logger.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final authController = Get.find<AuthController>();
  final formKey = GlobalKey<FormState>();
  final ImagePicker _imagePicker = ImagePicker();
  
  late TextEditingController nameController;
  late TextEditingController bioController;
  late TextEditingController ageController;
  late TextEditingController cityController;
  late TextEditingController budgetController;
  
  XFile? _selectedImage;
  late double cleanlinessScore;
  late double sleepScheduleScore;
  late double socialFrequencyScore;
  late double noiseToleranceScore;
  late double financialReliabilityScore;

  @override
  void initState() {
    super.initState();
    final user = authController.currentUser.value;
    nameController = TextEditingController(text: user?.name ?? '');
    bioController = TextEditingController(text: user?.bio ?? '');
    ageController = TextEditingController(text: user?.age.toString() ?? '');
    cityController = TextEditingController(text: user?.city ?? '');
    budgetController = TextEditingController(text: user?.budgetMax.toString() ?? '');
    
    cleanlinessScore = (user?.cleanliness ?? 5).toDouble();
    sleepScheduleScore = user?.sleepSchedule == 'early' ? 2.0 : (user?.sleepSchedule == 'night' ? 8.0 : 5.0);
    socialFrequencyScore = (user?.socialFrequency ?? 5).toDouble();
    noiseToleranceScore = (user?.noiseTolerance ?? 5).toDouble();
    financialReliabilityScore = (user?.financialReliability ?? 5).toDouble();
  }

  @override
  void dispose() {
    nameController.dispose();
    bioController.dispose();
    ageController.dispose();
    cityController.dispose();
    budgetController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1024,
        maxHeight: 1024,
      );
      
      if (image != null) {
        setState(() {
          _selectedImage = image;
        });
        
        Get.snackbar(
          'Success',
          'Image selected. Save changes to upload.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white,
          duration: const Duration(seconds: 2),
        );
      }
    } catch (e) {
      AppLogger.error('EDIT_PROFILE', 'Failed to pick image: $e');
      Get.snackbar(
        'Error',
        'Failed to pick image',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  void _saveProfile() async {
    if (!formKey.currentState!.validate()) {
      AppLogger.warning('EDIT_PROFILE', 'Form validation failed');
      return;
    }
    
    // Validate city is not empty before proceeding
    final city = cityController.text.trim();
    if (city.isEmpty) {
      AppLogger.error('EDIT_PROFILE', 'City field is empty despite form validation');
      Get.snackbar(
        'Error',
        'City is required',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }
    
    try {
      final currentUser = authController.currentUser.value;
      
      // Determine sleep schedule from slider
      String sleepSchedule = 'normal';
      if (sleepScheduleScore < 4.0) {
        sleepSchedule = 'early';
      } else if (sleepScheduleScore > 6.0) {
        sleepSchedule = 'night';
      }
      
      // Upload image if selected
      String? avatarUrl;
      if (_selectedImage != null) {
        try {
          avatarUrl = await authController.userService.uploadAvatar(
            currentUser?.userId ?? '',
            _selectedImage!.path,
          );
        } catch (e) {
          AppLogger.error('EDIT_PROFILE', 'Avatar upload failed: $e');
          // Continue without avatar - it's optional
        }
      }
      
      AppLogger.info('EDIT_PROFILE', 'Saving profile with city: $city');
      
      final updatedUser = UserProfile(
        userId: currentUser?.userId ?? '',
        name: nameController.text.trim(),
        bio: bioController.text.trim(),
        age: int.tryParse(ageController.text) ?? 0,
        avatar: avatarUrl ?? currentUser?.avatar,
        city: cityController.text.trim(),
        state: currentUser?.state ?? '',
        budgetMin: currentUser?.budgetMin ?? 0,
        budgetMax: double.tryParse(budgetController.text) ?? 0,
        neighborhoods: currentUser?.neighborhoods ?? [],
        moveInDate: currentUser?.moveInDate ?? DateTime.now(),
        phone: currentUser?.phone ?? '',
        phoneVerified: currentUser?.phoneVerified ?? false,
        email: currentUser?.email,
        emailVerified: currentUser?.emailVerified ?? false,
        verified: currentUser?.verified ?? false,
        cleanliness: cleanlinessScore.toInt(),
        sleepSchedule: sleepSchedule,
        socialFrequency: socialFrequencyScore.toInt(),
        noiseTolerance: noiseToleranceScore.toInt(),
        financialReliability: financialReliabilityScore.toInt(),
        hasPets: currentUser?.hasPets,
        petTolerance: currentUser?.petTolerance,
        guestPolicy: currentUser?.guestPolicy,
        privacyNeed: currentUser?.privacyNeed,
        kitchenHabits: currentUser?.kitchenHabits,
        lastActiveAt: DateTime.now(),
        trustScore: currentUser?.trustScore ?? 0,
        createdAt: currentUser?.createdAt ?? DateTime.now(),
        isActive: true,
        isSuspended: false,
      );
      
      // Call updateProfile and wait for completion
      await authController.updateProfile(updatedUser);
      
      // Check if update was successful (no error)
      if (authController.error.value == null) {
        Get.snackbar(
          'Success',
          'Profile updated successfully',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white,
          duration: const Duration(seconds: 2),
        );
        // Delay slightly before going back to ensure UI updates
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) Get.back();
        });
      } else {
        Get.snackbar(
          'Error',
          authController.error.value ?? 'Failed to update profile',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      AppLogger.error('EDIT_PROFILE', 'Profile save error: $e');
      Get.snackbar(
        'Error',
        'Failed to update profile: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
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
          'Edit Profile',
          style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 20),
        ),
        leading: IconButton(
          icon: AppSvgIcon.icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Get.back(),
        ),
      ),
      body: Form(
        key: formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // Profile Photo
              Center(
                child: Stack(
                  children: [
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.darkBg2,
                      ),
                      child: _selectedImage != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(60),
                              child: kIsWeb
                                  ? Image.network(
                                      _selectedImage!.path, // assumes path is a URL on web
                                      fit: BoxFit.cover,
                                    )
                                  : Image.file(
                                      File(_selectedImage!.path),
                                      fit: BoxFit.cover,
                                    ),
                            )
                          : AppSvgIcon.icon(Icons.person, size: 60, color: AppColors.textSecondary),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: _pickImage,
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.cyan,
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.cyan.withValues(alpha: 0.3),
                                blurRadius: 8,
                              ),
                            ],
                          ),
                          padding: const EdgeInsets.all(8),
                          child: AppSvgIcon.icon(Icons.camera_alt, color: AppColors.textPrimary, size: 20),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              // Name Field
              _buildTextField(
                controller: nameController,
                label: 'Full Name',
                icon: Icons.person_outline,
                validator: (value) => value?.isEmpty ?? true ? 'Name required' : null,
              ),
              const SizedBox(height: 16),
              // Age Field
              _buildTextField(
                controller: ageController,
                label: 'Age',
                icon: Icons.cake_outlined,
                keyboardType: TextInputType.number,
                validator: (value) => value?.isEmpty ?? true ? 'Age required' : null,
              ),
              const SizedBox(height: 16),
              // City Field
              _buildTextField(
                controller: cityController,
                label: 'City',
                icon: Icons.location_on_outlined,
                validator: (value) => value?.isEmpty ?? true ? 'City required' : null,
              ),
              const SizedBox(height: 16),
              // Budget Field
              _buildTextField(
                controller: budgetController,
                label: 'Monthly Budget (\$)',
                icon: Icons.attach_money,
                keyboardType: TextInputType.number,
                validator: (value) => value?.isEmpty ?? true ? 'Budget required' : null,
              ),
              const SizedBox(height: 16),
              // Bio Field
              TextFormField(
                controller: bioController,
                maxLines: 4,
                decoration: InputDecoration(
                  labelText: 'About You',
                  hintText: 'Tell people about yourself...',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: AppSvgIcon.icon(Icons.info_outline),
                  contentPadding: const EdgeInsets.all(16),
                ),
                validator: (value) => value?.isEmpty ?? true ? 'Bio required' : null,
              ),
              const SizedBox(height: 24),
              // Compatibility Section
              const Text('Compatibility Preferences', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
              const SizedBox(height: 16),
              
              // Cleanliness Slider
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Cleanliness', style: TextStyle(fontSize: 14)),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.cyan.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text('${cleanlinessScore.toInt()}/10', style: const TextStyle(color: AppColors.cyan, fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SliderTheme(
                    data: SliderThemeData(
                      activeTrackColor: AppColors.cyan,
                      thumbColor: AppColors.cyan,
                    ),
                    child: Slider(
                      value: cleanlinessScore,
                      min: 1,
                      max: 10,
                      divisions: 9,
                      label: '${cleanlinessScore.toInt()}',
                      onChanged: (value) {
                        setState(() => cleanlinessScore = value);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              
              // Sleep Schedule Slider
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Sleep Schedule', style: TextStyle(fontSize: 14)),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.cyan.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          sleepScheduleScore < 4 ? 'Early' : (sleepScheduleScore > 6 ? 'Late' : 'Normal'),
                          style: const TextStyle(color: AppColors.cyan, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SliderTheme(
                    data: SliderThemeData(
                      activeTrackColor: AppColors.cyan,
                      thumbColor: AppColors.cyan,
                    ),
                    child: Slider(
                      value: sleepScheduleScore,
                      min: 1,
                      max: 10,
                      divisions: 9,
                      label: sleepScheduleScore < 4 ? 'Early' : (sleepScheduleScore > 6 ? 'Late' : 'Normal'),
                      onChanged: (value) {
                        setState(() => sleepScheduleScore = value);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              
              // Social Frequency Slider
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Social Frequency', style: TextStyle(fontSize: 14)),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.cyan.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text('${socialFrequencyScore.toInt()}/10', style: const TextStyle(color: AppColors.cyan, fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SliderTheme(
                    data: SliderThemeData(
                      activeTrackColor: AppColors.cyan,
                      thumbColor: AppColors.cyan,
                    ),
                    child: Slider(
                      value: socialFrequencyScore,
                      min: 1,
                      max: 10,
                      divisions: 9,
                      label: '${socialFrequencyScore.toInt()}',
                      onChanged: (value) {
                        setState(() => socialFrequencyScore = value);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              
              // Noise Tolerance Slider
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Noise Tolerance', style: TextStyle(fontSize: 14)),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.cyan.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text('${noiseToleranceScore.toInt()}/10', style: const TextStyle(color: AppColors.cyan, fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SliderTheme(
                    data: SliderThemeData(
                      activeTrackColor: AppColors.cyan,
                      thumbColor: AppColors.cyan,
                    ),
                    child: Slider(
                      value: noiseToleranceScore,
                      min: 1,
                      max: 10,
                      divisions: 9,
                      label: '${noiseToleranceScore.toInt()}',
                      onChanged: (value) {
                        setState(() => noiseToleranceScore = value);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              
              // Financial Reliability Slider
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Financial Reliability', style: TextStyle(fontSize: 14)),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.cyan.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text('${financialReliabilityScore.toInt()}/10', style: const TextStyle(color: AppColors.cyan, fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SliderTheme(
                    data: SliderThemeData(
                      activeTrackColor: AppColors.cyan,
                      thumbColor: AppColors.cyan,
                    ),
                    child: Slider(
                      value: financialReliabilityScore,
                      min: 1,
                      max: 10,
                      divisions: 9,
                      label: '${financialReliabilityScore.toInt()}',
                      onChanged: (value) {
                        setState(() => financialReliabilityScore = value);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              // Save Button
              Obx(() => SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: authController.isLoading.value ? null : _saveProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.cyan,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    disabledBackgroundColor: AppColors.darkSecondaryBg,
                  ),
                  child: authController.isLoading.value
                      ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(AppColors.textPrimary),
                        ),
                      )
                      : const Text(
                        'Save Changes',
                        style: TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                ),
              )),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    FormFieldValidator<String>? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        prefixIcon: AppSvgIcon.icon(icon),
        contentPadding: const EdgeInsets.all(16),
      ),
      validator: validator,
    );
  }
}
