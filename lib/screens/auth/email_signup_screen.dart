import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../providers/auth_controller.dart';
import '../../config/app_colors.dart';
import '../../routes.dart';

class EmailSignUpScreen extends StatefulWidget {
  const EmailSignUpScreen({super.key});

  @override
  State<EmailSignUpScreen> createState() => _EmailSignUpScreenState();
}

class _EmailSignUpScreenState extends State<EmailSignUpScreen> {
  late final AuthController authController;
  late final TextEditingController emailController;
  late final TextEditingController passwordController;
  late final TextEditingController confirmPasswordController;
  final formKey = GlobalKey<FormState>();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _showEmailForm = true;

  @override
  void initState() {
    super.initState();
    authController = Get.find<AuthController>();
    emailController = TextEditingController();
    passwordController = TextEditingController();
    confirmPasswordController = TextEditingController();
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  void _handleEmailSignUp() {
    if (!formKey.currentState!.validate()) return;

    if (passwordController.text != confirmPasswordController.text) {
      authController.error.value = 'Passwords do not match';
      return;
    }

    final email = emailController.text.trim();
    final password = passwordController.text;

    authController.error.value = null;
    authController.signUpWithEmail(email, password);
  }

  Widget _buildAuthButton({
    required String label,
    String? iconAsset,
    Color? iconColor,
    bool isBrandIcon = false,
    required VoidCallback? onPressed,
    bool isLoading = false,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        decoration: BoxDecoration(
          color: AppColors.gold,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: AppColors.gold.withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isLoading)
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: const AlwaysStoppedAnimation<Color>(AppColors.darkBg),
                ),
              )
            else if (iconAsset != null)
              SizedBox(
                width: 20,
                height: 20,
                child: SvgPicture.asset(
                  iconAsset,
                  width: 20,
                  height: 20,
                  colorFilter: (isBrandIcon || iconColor == null)
                      ? null
                      : ColorFilter.mode(AppColors.darkBg, BlendMode.srcIn),
                ),
              )
            else
              const SizedBox(width: 20),
            const SizedBox(width: 12),
            Text(
              label,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.darkBg,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBg,
      appBar: AppBar(
        backgroundColor: AppColors.darkBg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Get.back(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                const Text(
                  'Create Account',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Join SpaceShare to find your perfect roommate',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 32),

                // Toggle between form and auth options
                if (_showEmailForm)
                  Form(
                    key: formKey,
                    child: Column(
                      children: [
                        // Email Field
                        TextFormField(
                          controller: emailController,
                          keyboardType: TextInputType.emailAddress,
                          style: const TextStyle(color: AppColors.textPrimary),
                          decoration: InputDecoration(
                            hintText: 'Email address',
                            hintStyle: const TextStyle(color: AppColors.textTertiary),
                            prefixIcon: const Icon(Icons.email, color: AppColors.cyan, size: 20),
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
                            if (value?.isEmpty ?? true) return 'Email is required';
                            if (!value!.contains('@')) return 'Enter a valid email';
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),

                        // Password Field
                        TextFormField(
                          controller: passwordController,
                          obscureText: _obscurePassword,
                          style: const TextStyle(color: AppColors.textPrimary),
                          decoration: InputDecoration(
                            hintText: 'Password',
                            hintStyle: const TextStyle(color: AppColors.textTertiary),
                            prefixIcon: const Icon(Icons.lock, color: AppColors.cyan, size: 20),
                            suffixIcon: GestureDetector(
                              onTap: () => setState(() => _obscurePassword = !_obscurePassword),
                              child: Icon(
                                _obscurePassword ? Icons.visibility_off : Icons.visibility,
                                color: AppColors.cyan,
                                size: 20,
                              ),
                            ),
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
                            if (value?.isEmpty ?? true) return 'Password is required';
                            if (value!.length < 8) return 'Password must be at least 8 characters';
                            if (!RegExp(r'[A-Z]').hasMatch(value)) return 'Include an uppercase letter';
                            if (!RegExp(r'[a-z]').hasMatch(value)) return 'Include a lowercase letter';
                            if (!RegExp(r'[0-9]').hasMatch(value)) return 'Include a number';
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),

                        // Confirm Password Field
                        TextFormField(
                          controller: confirmPasswordController,
                          obscureText: _obscureConfirmPassword,
                          style: const TextStyle(color: AppColors.textPrimary),
                          decoration: InputDecoration(
                            hintText: 'Confirm Password',
                            hintStyle: const TextStyle(color: AppColors.textTertiary),
                            prefixIcon: const Icon(Icons.lock, color: AppColors.cyan, size: 20),
                            suffixIcon: GestureDetector(
                              onTap: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                              child: Icon(
                                _obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
                                color: AppColors.cyan,
                                size: 20,
                              ),
                            ),
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
                            if (value?.isEmpty ?? true) return 'Please confirm your password';
                            return null;
                          },
                        ),
                        const SizedBox(height: 32),

                        // Sign Up Button
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
                            onPressed: authController.isLoading.value ? null : _handleEmailSignUp,
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
                                  'Create Account',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.darkBg,
                                  ),
                                ),
                          ),
                        )),

                        // Error State
                        Obx(() {
                          if (authController.error.value != null) {
                            return Column(
                              children: [
                                const SizedBox(height: 16),
                                Container(
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
                                ),
                              ],
                            );
                          }
                          return const SizedBox.shrink();
                        }),

                        const SizedBox(height: 24),

                        // Divider
                        Row(
                          children: [
                            Expanded(child: Container(height: 1, color: AppColors.borderColor)),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              child: Text('Or sign up with', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                            ),
                            Expanded(child: Container(height: 1, color: AppColors.borderColor)),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Google Sign Up Button
                        Obx(() => _buildAuthButton(
                          label: authController.isLoading.value ? 'Signing up...' : 'Google',
                          iconAsset: 'assets/fontawesome-free-7.1.0-web/svgs/brands/google.svg',
                          isBrandIcon: true,
                          isLoading: authController.isLoading.value,
                          onPressed: authController.isLoading.value ? null : () => authController.signInWithGoogle(),
                        )),
                        const SizedBox(height: 16),

                        // Phone Sign Up Button
                        _buildAuthButton(
                          label: 'Phone',
                          iconAsset: 'assets/fontawesome-free-7.1.0-web/svgs/solid/mobile-phone.svg',
                          iconColor: AppColors.gold,
                          onPressed: () => Get.toNamed(AppRoutes.phoneEntry),
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 24),

                // Sign In Link
                Center(
                  child: RichText(
                    text: TextSpan(
                      text: 'Already have an account? ',
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                      children: [
                        TextSpan(
                          text: 'Sign in here',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.cyan,
                          ),
                          recognizer: TapGestureRecognizer()
                            ..onTap = () => Get.back(),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
