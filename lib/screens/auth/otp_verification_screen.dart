import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../providers/auth_controller.dart';
import '../../config/app_colors.dart';

class OTPVerificationScreen extends StatefulWidget {
  final String phone;

  const OTPVerificationScreen({super.key, required this.phone});

  @override
  State<OTPVerificationScreen> createState() => _OTPVerificationScreenState();
}

class _OTPVerificationScreenState extends State<OTPVerificationScreen> {
  final otpController = TextEditingController();
  final formKey = GlobalKey<FormState>();
  final remainingSeconds = 60.obs;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void dispose() {
    otpController.dispose();
    super.dispose();
  }

  void _startTimer() {
    Future.delayed(const Duration(seconds: 1), () {
      if (remainingSeconds.value > 0) {
        remainingSeconds.value--;
        _startTimer();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final authController = Get.find<AuthController>();

    return Scaffold(
      body: Container(
        color: AppColors.darkBg,
        child: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
              child: Form(
                key: formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Back button
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
                      onPressed: () => Get.back(),
                      padding: EdgeInsets.zero,
                      alignment: Alignment.centerLeft,
                    ),
                    const SizedBox(height: 20),
                    
                    const Text(
                      'Confirm Phone Number',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Enter the code we\'ve sent via SMS to ${widget.phone}',
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 40),
                    
                    // OTP Input Field
                    TextFormField(
                      controller: otpController,
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      maxLength: 6,
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 8,
                        color: AppColors.cyan,
                      ),
                      decoration: InputDecoration(
                        hintText: '------',
                        hintStyle: const TextStyle(color: AppColors.textTertiary),
                        counterText: '',
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
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      ),
                      validator: (value) {
                        if (value?.isEmpty ?? true) return 'OTP is required';
                        if (value!.length != 6) return 'OTP must be 6 digits';
                        return null;
                      },
                    ),
                    
                    const SizedBox(height: 40),
                    
                    // Verify Button
                    Obx(() => SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.gold,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          disabledBackgroundColor: AppColors.darkSecondaryBg,
                        ),
                        onPressed: authController.isLoading.value
                            ? null
                            : () => _handleVerifyOTP(authController),
                        child: authController.isLoading.value
                            ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(AppColors.darkBg),
                              ),
                            )
                            : const Text(
                              'Continue',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: AppColors.darkBg,
                              ),
                            ),
                      ),
                    )),
                    
                    const SizedBox(height: 20),
                    
                    // Resend Button with Timer
                    Center(
                      child: Obx(() => GestureDetector(
                        onTap: remainingSeconds.value > 0
                            ? null
                            : () => _handleResendOTP(authController),
                        child: Text(
                          remainingSeconds.value > 0
                              ? 'Resend code in ${remainingSeconds.value}s'
                              : 'Resend code',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: remainingSeconds.value > 0
                                ? AppColors.textTertiary
                                : AppColors.cyan,
                          ),
                        ),
                      )),
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Error State
                    Obx(() {
                      if (authController.error.value != null) {
                        return Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.errorBg,
                            border: Border.all(color: AppColors.error),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            authController.error.value!,
                            style: const TextStyle(color: AppColors.error, fontSize: 13),
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    }),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _handleVerifyOTP(AuthController authController) {
    if (!formKey.currentState!.validate()) return;

    final otp = otpController.text.trim();
    authController.verifyOTP(widget.phone, otp);

    Future.delayed(const Duration(milliseconds: 500), () {
      if (authController.error.value == null &&
          authController.isAuthenticated.value) {
        Get.toNamed('/profile-setup');
      }
    });
  }

  void _handleResendOTP(AuthController authController) {
    if (remainingSeconds.value > 0) return;
    
    authController.sendOTP(widget.phone);
    remainingSeconds.value = 60;
    _startTimer();
  }
}
