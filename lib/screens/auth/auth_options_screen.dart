import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../providers/auth_controller.dart';
import '../../config/app_colors.dart';

class AuthOptionsScreen extends StatelessWidget {
  const AuthOptionsScreen({super.key});

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
              child: Column(
                children: [
                  // Logo section with cyan glow
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.cyan,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.cyan.withValues(alpha: 0.5),
                          blurRadius: 30,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: Center(
                      child: SvgPicture.asset(
                        'assets/fontawesome-free-7.1.0-web/svgs/solid/house.svg',
                        width: 50,
                        height: 50,
                        colorFilter: const ColorFilter.mode(
                          AppColors.darkBg,
                          BlendMode.srcIn,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  
                  // Welcome text
                  const Text(
                    'SpaceShare',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Find your perfect roommate',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 60),
                  
                  // Email Button
                  _buildAuthButton(
                    label: 'Continue with Email',
                    iconAsset: 'assets/fontawesome-free-7.1.0-web/svgs/solid/envelope.svg',
                    iconColor: AppColors.gold,
                    onPressed: () => Get.toNamed('/auth/email-signin'),
                  ),
                  const SizedBox(height: 16),
                  
                  // Google Button
                  Obx(() => _buildAuthButton(
                    label: authController.isLoading.value ? 'Signing in...' : 'Continue with Google',
                    iconAsset: 'assets/fontawesome-free-7.1.0-web/svgs/brands/google.svg',
                    isBrandIcon: true,
                    isLoading: authController.isLoading.value,
                    onPressed: authController.isLoading.value ? null : () => authController.signInWithGoogle(),
                  )),
                  const SizedBox(height: 16),
                  
                  // Phone Button
                  _buildAuthButton(
                    label: 'Continue with Phone',
                    iconAsset: 'assets/fontawesome-free-7.1.0-web/svgs/solid/mobile-phone.svg',
                    iconColor: AppColors.gold,
                    onPressed: () => Get.toNamed('/phone-entry'),
                  ),
                  
                  const SizedBox(height: 60),
                  
                  // Terms text
                  const Text(
                    'By continuing, you agree to our\nTerms of Service and Privacy Policy',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                      height: 1.6,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
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
                  // Brand icons keep original colors, custom icons can be colored
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
}
