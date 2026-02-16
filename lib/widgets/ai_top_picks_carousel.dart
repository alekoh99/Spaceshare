import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../config/theme.dart';
import '../utils/constants.dart';
import '../models/user_model.dart';

class AITopPicksCarousel extends StatefulWidget {
  final List<Map<String, dynamic>> topPicks;
  final bool isLoading;
  final VoidCallback? onRefresh;
  final Function(String userId)? onViewProfile;

  const AITopPicksCarousel({
    super.key,
    required this.topPicks,
    this.isLoading = false,
    this.onRefresh,
    this.onViewProfile,
  });

  @override
  State<AITopPicksCarousel> createState() => _AITopPicksCarouselState();
}

class _AITopPicksCarouselState extends State<AITopPicksCarousel>
    with SingleTickerProviderStateMixin {
  late PageController _pageController;
  int _currentPage = 0;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.85);
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _animationController.forward();
    _pageController.addListener(() {
      setState(() => _currentPage = _pageController.page?.toInt() ?? 0);
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  String _getCompatibilityReason(Map<String, dynamic> pick) {
    final reason = pick['reason'] as String?;
    return reason ?? 'Great match based on preferences';
  }

  @override
  Widget build(BuildContext context) {
    if (widget.topPicks.isEmpty && !widget.isLoading) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: AppPadding.large),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text(
                        '🎯 ',
                        style: TextStyle(fontSize: 20),
                      ),
                      Text(
                        'Top Picks For You',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: AppTheme.textPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: AppPadding.small / 2),
                  Text(
                    'AI-powered recommendations',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
              if (widget.onRefresh != null)
                GestureDetector(
                  onTap: widget.onRefresh,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.refresh,
                      size: 18,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ),
            ],
          ),
        ),
        SizedBox(height: AppPadding.medium),
        if (widget.isLoading)
          _buildLoadingState()
        else if (widget.topPicks.isNotEmpty)
          _buildCarousel()
        else
          const SizedBox.shrink(),
        if (widget.topPicks.length > 1) ...[
          SizedBox(height: AppPadding.medium),
          _buildPageIndicator(),
        ],
      ],
    );
  }

  Widget _buildLoadingState() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: AppPadding.large),
      child: SizedBox(
        height: 200,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: 3,
          itemBuilder: (context, index) => _buildSkeletonCard(),
        ),
      ),
    );
  }

  Widget _buildSkeletonCard() {
    return Container(
      width: 280,
      margin: EdgeInsets.only(right: AppPadding.medium),
      decoration: BoxDecoration(
        color: AppTheme.bgLighter,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Shimmer.fromColors(
        baseColor: Colors.grey[300]!,
        highlightColor: Colors.grey[100]!,
        child: Column(
          children: [
            Container(
              height: 100,
              color: Colors.grey[300],
            ),
            Expanded(
              child: Padding(
                padding: EdgeInsets.all(AppPadding.medium),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 12,
                      width: 80,
                      color: Colors.grey[300],
                    ),
                    SizedBox(height: AppPadding.small),
                    Container(
                      height: 10,
                      width: 120,
                      color: Colors.grey[300],
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

  Widget _buildCarousel() {
    return SizedBox(
      height: 240,
      child: PageView.builder(
        controller: _pageController,
        itemCount: widget.topPicks.length,
        itemBuilder: (context, index) {
          final pick = widget.topPicks[index];
          final isCurrent = index == _currentPage;
          
          return AnimatedBuilder(
            animation: _pageController,
            builder: (context, child) {
              double value = 1.0;
              if (_pageController.position.haveDimensions) {
                value = index - (_pageController.page ?? 0);
                value = (1 - (value.abs() * 0.3)).clamp(0.0, 1.0);
              }
              
              return Transform.scale(
                scale: value,
                child: child,
              );
            },
            child: _buildPickCard(pick, isCurrent),
          );
        },
      ),
    );
  }

  Widget _buildPickCard(Map<String, dynamic> pick, bool isCurrent) {
    final profile = pick['profile'] as UserProfile?;
    final compatibilityScore = (pick['compatibilityScore'] as num?)?.toInt() ?? 0;
    final reason = _getCompatibilityReason(pick);

    return GestureDetector(
      onTap: () {
        if (profile != null) {
          widget.onViewProfile?.call(profile.userId);
        }
      },
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: AppPadding.small),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppTheme.primaryColor.withValues(alpha: 0.2),
            width: isCurrent ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryColor.withValues(
                alpha: isCurrent ? 0.15 : 0.05,
              ),
              blurRadius: isCurrent ? 20 : 10,
              offset: Offset(0, isCurrent ? 12 : 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            children: [
              // Background image
              if (profile?.avatar != null)
                CachedNetworkImage(
                  imageUrl: profile!.avatar!,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    color: AppTheme.bgLighter,
                    child: const Center(child: CircularProgressIndicator()),
                  ),
                  errorWidget: (context, url, error) => _buildAvatarFallback(),
                )
              else
                _buildAvatarFallback(),
              
              // Overlay gradient
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.8),
                      Colors.black.withValues(alpha: 0.3),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
              
              // Top badges
              Positioned(
                top: AppPadding.medium,
                right: AppPadding.medium,
                child: Row(
                  children: [
                    if (pick['isTrending'] == true)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: 0.9),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '🔥 ',
                              style: TextStyle(fontSize: 12),
                            ),
                            Text(
                              'Trending',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              
              // Content at bottom
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Padding(
                  padding: EdgeInsets.all(AppPadding.medium),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Name and location
                      if (profile != null)
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${profile.name}, ${profile.age}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  SizedBox(height: AppPadding.small / 2),
                                  Text(
                                    profile.city,
                                    style: TextStyle(
                                      color: Colors.white.withValues(alpha: 0.7),
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Compatibility badge
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.green.shade400,
                                    Colors.green.shade700,
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Column(
                                children: [
                                  Text(
                                    '$compatibilityScore%',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    'Match',
                                    style: TextStyle(
                                      color: Colors.white.withValues(alpha: 0.8),
                                      fontSize: 10,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      
                      SizedBox(height: AppPadding.medium),
                      
                      // Reason
                      Text(
                        reason,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          height: 1.4,
                        ),
                      ),
                      
                      SizedBox(height: AppPadding.medium),
                      
                      // Action buttons
                      Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () => widget.onViewProfile?.call(profile?.userId ?? ''),
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                  vertical: AppPadding.small,
                                ),
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryColor,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Center(
                                  child: Text(
                                    'View Profile',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvatarFallback() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.primaryColor.withValues(alpha: 0.3),
            AppTheme.accentColor.withValues(alpha: 0.3),
          ],
        ),
      ),
      child: const Icon(
        Icons.person,
        color: AppTheme.primaryColor,
        size: 60,
      ),
    );
  }

  Widget _buildPageIndicator() {
    return Center(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(
          widget.topPicks.length,
          (index) => AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            margin: EdgeInsets.symmetric(horizontal: 4),
            height: 8,
            width: index == _currentPage ? 24 : 8,
            decoration: BoxDecoration(
              color: index == _currentPage
                  ? AppTheme.primaryColor
                  : AppTheme.primaryColor.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ),
      ),
    );
  }
}

// Shimmer widget for loading states
class Shimmer extends StatefulWidget {
  final Widget child;
  final Color baseColor;
  final Color highlightColor;

  const Shimmer.fromColors({
    super.key,
    required this.child,
    required this.baseColor,
    required this.highlightColor,
  });

  @override
  State<Shimmer> createState() => _ShimmerState();
}

class _ShimmerState extends State<Shimmer>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return ShaderMask(
          blendMode: BlendMode.lighten,
          shaderCallback: (bounds) {
            return LinearGradient(
              colors: [
                widget.baseColor,
                widget.highlightColor,
                widget.baseColor,
              ],
              stops: [
                0.0,
                _animationController.value,
                1.0,
              ],
              begin: const Alignment(-1.0, 0.0),
              end: const Alignment(1.0, 0.0),
              tileMode: TileMode.clamp,
            ).createShader(bounds);
          },
          child: widget.child,
        );
      },
    );
  }
}
