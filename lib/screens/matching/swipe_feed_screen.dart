import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:card_swiper/card_swiper.dart';
import '../../config/app_colors.dart';
import '../../providers/matching_controller.dart';
import '../../utils/debounce_throttle.dart';
import '../../widgets/app_svg_icon.dart';
import '../../widgets/bottom_navigation_bar_widget.dart';

class SwipeFeedScreen extends StatefulWidget {
  const SwipeFeedScreen({super.key});

  @override
  State<SwipeFeedScreen> createState() => _SwipeFeedScreenState();
}

class _SwipeFeedScreenState extends State<SwipeFeedScreen> {
  late SwiperController swiperController;
  final matchingController = Get.find<MatchingController>();
  int _currentNavIndex = 0; // Match is index 0
  late Debounce _swipeRightDebounce;
  late Debounce _swipeLeftDebounce;

  @override
  void initState() {
    super.initState();
    swiperController = SwiperController();
    _swipeRightDebounce = Debounce(duration: const Duration(milliseconds: 500));
    _swipeLeftDebounce = Debounce(duration: const Duration(milliseconds: 500));
    // Defer the async call to after the build phase to avoid setState during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      matchingController.loadSwipeFeed();
    });
  }

  @override
  void dispose() {
    swiperController.dispose();
    _swipeRightDebounce.dispose();
    _swipeLeftDebounce.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          color: AppColors.darkBg,
        ),
        child: Column(
          children: [
            // Header
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Discover',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    IconButton(
                      icon: AppSvgIcon.icon(Icons.tune, color: AppColors.cyan),
                      onPressed: _showFilterSheet,
                    ),
                  ],
                ),
              ),
            ),
            // Content
            Expanded(
              child: Obx(() {
                if (matchingController.isLoadingFeed.value) {
                  return const Center(
                    child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(AppColors.cyan)),
                  );
                }

                if (matchingController.swipeFeed.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        AppSvgIcon.icon(
                          Icons.person_search,
                          size: 64,
                          color: AppColors.textTertiary,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'No more profiles',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return Column(
                  children: [
                    Expanded(
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          return Obx(() {
                            // Rebuild when feed changes
                            final feedLength = matchingController.swipeFeed.length;
                            
                            if (feedLength == 0) {
                              return Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    AppSvgIcon.icon(
                                      Icons.person_search,
                                      size: 64,
                                      color: AppColors.textTertiary,
                                    ),
                                    const SizedBox(height: 16),
                                    const Text(
                                      'No more profiles',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }

                            return Swiper(
                              controller: swiperController,
                              itemCount: feedLength,
                              itemBuilder: (context, index) {
                                if (index >= feedLength) return const SizedBox();
                                
                                final profile = matchingController.swipeFeed[index];
                                
                                // Lazy load more when approaching end
                                if (index > feedLength - 3 && 
                                    matchingController.hasMoreFeed.value &&
                                    !matchingController.isLoadingMoreFeed.value) {
                                  Future.microtask(() => matchingController.loadMoreFeed());
                                }
                                
                                return _buildProfileCard(profile);
                              },
                              onIndexChanged: (index) {
                                matchingController.currentFeedIndex.value = index;
                              },
                              onTap: (index) {
                                // Optional: Navigate to detail view on tap
                              },
                              layout: SwiperLayout.STACK,
                              itemWidth: constraints.maxWidth * 0.85,
                              itemHeight: constraints.maxHeight * 0.8,
                              curve: Curves.easeInOut,
                              pagination: const SwiperPagination(
                                builder: DotSwiperPaginationBuilder(
                                  color: AppColors.borderLight,
                                  activeColor: AppColors.cyan,
                                  size: 8,
                                  activeSize: 10,
                                  space: 8,
                                ),
                              ),
                            );
                          });
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                      child: Column(
                        children: [
                          // Primary action buttons with labels
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _buildActionButtonWithLabel(
                                icon: Icons.close,
                                label: 'Skip',
                                color: AppColors.textSecondary,
                                isLoading: matchingController.isSwipingLeft.value,
                                onPressed: () {
                                  _handleSkip();
                                },
                              ),
                              _buildActionButtonWithLabel(
                                icon: Icons.favorite,
                                label: 'Like',
                                color: AppColors.cyan,
                                isPrimary: true,
                                isLoading: matchingController.isSwipingRight.value,
                                onPressed: () {
                                  _handleLike();
                                },
                              ),
                              _buildActionButtonWithLabel(
                                icon: Icons.favorite_border,
                                label: 'Dislike',
                                color: AppColors.error,
                                isLoading: matchingController.isSwipingLeft.value,
                                onPressed: () {
                                  _handleDislike();
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              }),
            ),
          ],
        ),
      ),
      bottomNavigationBar: AppBottomNavigationBar(
        currentIndex: _currentNavIndex,
        onIndexChanged: (index) {
          setState(() => _currentNavIndex = index);
        },
      ),
    );
  }

  void _handleSkip() {
    if (matchingController.swipeFeed.isEmpty) {
      Get.snackbar('No more profiles', 'Come back later for more matches');
      return;
    }
    
    final currentIndex = matchingController.currentFeedIndex.value;
    if (currentIndex < matchingController.swipeFeed.length) {
      final profile = matchingController.swipeFeed[currentIndex];
      // Advance swiper BEFORE removing from feed
      if (currentIndex + 1 < matchingController.swipeFeed.length) {
        swiperController.next();
      }
      // Now remove the profile
      matchingController.swipeLeft(profile.userId);
    }
  }

  void _handleLike() {
    if (matchingController.swipeFeed.isEmpty) {
      Get.snackbar('No more profiles', 'Come back later for more matches');
      return;
    }
    
    final currentIndex = matchingController.currentFeedIndex.value;
    if (currentIndex < matchingController.swipeFeed.length) {
      final profile = matchingController.swipeFeed[currentIndex];
      // Advance swiper BEFORE removing from feed
      if (currentIndex + 1 < matchingController.swipeFeed.length) {
        swiperController.next();
      }
      // Now remove the profile (this calls createMatch)
      matchingController.swipeRight(profile.userId);
    }
  }

  void _handleDislike() {
    if (matchingController.swipeFeed.isEmpty) {
      Get.snackbar('No more profiles', 'Come back later for more matches');
      return;
    }
    
    final currentIndex = matchingController.currentFeedIndex.value;
    if (currentIndex < matchingController.swipeFeed.length) {
      final profile = matchingController.swipeFeed[currentIndex];
      // Advance swiper BEFORE removing from feed
      if (currentIndex + 1 < matchingController.swipeFeed.length) {
        swiperController.next();
      }
      // Now remove the profile
      matchingController.swipeLeft(profile.userId);
    }
  }

  Widget _buildProfileCard(dynamic profile) {
    return Container(
      margin: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
          BoxShadow(
            color: AppColors.cyan.withValues(alpha: 0.1),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Background image
            Container(
              color: Colors.grey[300],
              child: (profile.avatar?.isNotEmpty ?? false)
                  ? Image.network(
                      profile.avatar!,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Container(
                          color: AppColors.darkBg2,
                          child: const Center(
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(AppColors.cyan),
                            ),
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: AppColors.darkBg2,
                          child: AppSvgIcon.icon(
                            Icons.person,
                            size: 80,
                            color: AppColors.textTertiary,
                          ),
                        );
                      },
                    )
                  : Container(
                      color: AppColors.darkBg2,
                      child: AppSvgIcon.icon(
                        Icons.person,
                        size: 80,
                        color: AppColors.textTertiary,
                      ),
                    ),
            ),
            
            // Top gradient overlay (subtle darker at top)
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.center,
                  colors: [
                    Colors.black.withValues(alpha: 0.3),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
            
            // Bottom gradient overlay (strong at bottom)
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.center,
                  colors: [
                    Colors.black.withValues(alpha: 0.85),
                    Colors.black.withValues(alpha: 0.4),
                  ],
                ),
              ),
            ),
            
            // Top-right verification badge
            Positioned(
              top: 16,
              right: 16,
              child: _buildVerificationBadge(profile),
            ),
            
            // Bottom content
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Name, Age, Location
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${profile.name}, ${profile.age}',
                                style: const TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  Icon(
                                    Icons.location_on_outlined,
                                    size: 16,
                                    color: AppColors.cyan,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    profile.city ?? 'Unknown Location',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.white.withValues(alpha: 0.85),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 14),
                    
                    // Bio/Headline
                    if (profile.bio.isNotEmpty)
                      Text(
                        profile.bio,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withValues(alpha: 0.8),
                          height: 1.4,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildVerificationBadge(dynamic profile) {
    // Check if profile has verification
    final isVerified = profile.verified ?? false;
    
    if (!isVerified) return const SizedBox.shrink();
    
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: AppColors.cyan,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: AppColors.cyan.withValues(alpha: 0.4),
            blurRadius: 8,
          ),
        ],
      ),
      child: const Icon(
        Icons.verified,
        color: Colors.white,
        size: 18,
      ),
    );
  }

  Widget _buildActionButtonWithLabel({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
    required bool isLoading,
    bool isPrimary = false,
  }) {
    return GestureDetector(
      onTap: isLoading ? null : onPressed,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: isPrimary ? 72 : 64,
            height: isPrimary ? 72 : 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isPrimary ? color : AppColors.darkBg2,
              border: isPrimary 
                ? null 
                : Border.all(color: color, width: 2),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: isPrimary ? 0.4 : 0.2),
                  blurRadius: isPrimary ? 16 : 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: isLoading
                ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.cyan),
                  ),
                )
                : Icon(
                  icon,
                  color: isPrimary ? Colors.white : color,
                  size: isPrimary ? 32 : 28,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
    required bool isLoading,
  }) {
    return GestureDetector(
      onTap: isLoading ? null : onPressed,
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.darkBg2,
          border: Border.all(color: color, width: 2),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.2),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: isLoading
            ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.cyan),
              ),
            )
            : AppSvgIcon.icon(icon, color: color, size: 28),
      ),
    );
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.darkBg2,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => _FilterSheetWidget(
        matchingController: matchingController,
        onApplyFilters: () => Navigator.pop(context),
      ),
    );
  }

  Widget _buildFilterOption(String label, String value, {VoidCallback? onTap}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.borderLight),
            borderRadius: BorderRadius.circular(12),
            color: AppColors.darkBg,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
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
              AppSvgIcon.icon(Icons.arrow_forward_ios, color: AppColors.textTertiary, size: 16),
            ],
          ),
        ),
      ),
    );
  }
}

/// Filter Sheet Widget - Stateful widget for managing filters
class _FilterSheetWidget extends StatefulWidget {
  final MatchingController matchingController;
  final VoidCallback onApplyFilters;

  const _FilterSheetWidget({
    required this.matchingController,
    required this.onApplyFilters,
  });

  @override
  State<_FilterSheetWidget> createState() => _FilterSheetWidgetState();
}

class _FilterSheetWidgetState extends State<_FilterSheetWidget> {
  late String _selectedCity;
  late double _minCompatibilityScore;
  late TextEditingController _cityController;
  bool _isApplying = false;

  @override
  void initState() {
    super.initState();
    _selectedCity = widget.matchingController.currentCity.value ?? 'All Cities';
    _minCompatibilityScore = widget.matchingController.minScore.value;
    _cityController = TextEditingController(text: _selectedCity);
  }

  @override
  void dispose() {
    _cityController.dispose();
    super.dispose();
  }

  Future<void> _applyFilters() async {
    setState(() => _isApplying = true);
    try {
      final city = _cityController.text.isEmpty ? null : _cityController.text;
      widget.matchingController.updateFilters(city, _minCompatibilityScore);
      Get.snackbar(
        'Success',
        'Filters applied',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
      );
      widget.onApplyFilters();
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to apply filters: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      setState(() => _isApplying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Filters',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Icon(Icons.close, color: AppColors.textSecondary),
                ),
              ],
            ),
            const SizedBox(height: 24),
            // City Filter
            const Text(
              'City',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _cityController,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: InputDecoration(
                hintText: 'Enter city name',
                hintStyle: const TextStyle(color: AppColors.textTertiary),
                filled: true,
                fillColor: AppColors.darkBg,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppColors.borderColor),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppColors.borderColor),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppColors.cyan, width: 2),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              ),
            ),
            const SizedBox(height: 24),
            // Compatibility Score Filter
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Minimum Compatibility Score',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.darkBg,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.borderColor),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Score:',
                            style: TextStyle(color: AppColors.textSecondary),
                          ),
                          Text(
                            '${_minCompatibilityScore.toStringAsFixed(0)}/100',
                            style: const TextStyle(
                              color: AppColors.cyan,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      Slider(
                        value: _minCompatibilityScore,
                        min: 0,
                        max: 100,
                        divisions: 10,
                        activeColor: AppColors.cyan,
                        inactiveColor: AppColors.borderColor,
                        onChanged: (value) {
                          setState(() => _minCompatibilityScore = value);
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            // Apply Filters Button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.gold,
                  disabledBackgroundColor: AppColors.darkSecondaryBg,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: _isApplying ? null : _applyFilters,
                child: _isApplying
                    ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(AppColors.darkBg),
                      ),
                    )
                    : const Text(
                      'Apply Filters',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.darkBg,
                      ),
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
