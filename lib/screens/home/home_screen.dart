import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../config/app_colors.dart';
import '../../providers/auth_controller.dart';
import '../../providers/matching_controller.dart';
import '../../services/unified_database_service.dart';
import '../../models/user_model.dart';
import '../../models/match_model.dart';
import '../../widgets/bottom_navigation_bar_widget.dart';
import '../../utils/result.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final authController = Get.find<AuthController>();
  final matchingController = Get.find<MatchingController>();
  final dbService = Get.find<UnifiedDatabaseService>();
  int _currentNavIndex = 2; // Home is index 2

  @override
  void initState() {
    super.initState();
    // Defer the call to loadSwipeFeed until after the build phase completes
    // to avoid "setState() called during build" error
    WidgetsBinding.instance.addPostFrameCallback((_) {
      matchingController.loadSwipeFeed();
    });
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
                      'RoomieLink',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(FontAwesomeIcons.bell, color: AppColors.cyan),
                      onPressed: () => Get.toNamed('/notifications'),
                    ),
                  ],
                ),
              ),
            ),
            // Content
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Featured Section
                    _buildFeaturedSection(),
                    const SizedBox(height: 24),
                    // Popular Roommates Section
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Popular Roommates',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildPopularGrid(),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Recent Matches Section
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Your Matches',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildMatchesList(),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
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

  Widget _buildFeaturedSection() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.cyan.withValues(alpha: 0.9),
            AppColors.cyan.withValues(alpha: 0.7),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.cyan.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                color: AppColors.darkBg.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(
                child: Icon(
                  FontAwesomeIcons.users,
                  size: 35,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Find a Compatible\nRoommate',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.darkBg,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Discover potential roommates who match your lifestyle and preferences.',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.darkBg,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => Get.toNamed('/matching'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.gold,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Start Swiping',
                style: TextStyle(
                  color: AppColors.darkBg,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPopularGrid() {
    return FutureBuilder<Result<List<UserProfile>>>(
      future: dbService.getPopularUsers(
        limit: 6,
        excludeUserId: authController.currentUserId.value,
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            alignment: Alignment.center,
            padding: const EdgeInsets.all(16),
            height: 80,
            child: const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.cyan),
            ),
          );
        }

        if (snapshot.hasError) {
          return Container(
            alignment: Alignment.center,
            padding: const EdgeInsets.all(24),
            child: Text(
              'Error: ${snapshot.error}',
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          );
        }

        if (!snapshot.hasData) {
          return Container(
            alignment: Alignment.center,
            padding: const EdgeInsets.all(24),
            child: const Text(
              'Unable to load popular users',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          );
        }

        final result = snapshot.data;
        final users = result?.isSuccess() == true
            ? (result?.getOrNull() as List<UserProfile>?) ?? []
            : <UserProfile>[];

        if (users.isEmpty) {
          return Container(
            alignment: Alignment.center,
            padding: const EdgeInsets.all(24),
            child: const Text(
              'No popular users available',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          );
        }

        return Column(
          children: users.map((user) {
            return _buildPopularUserCard(
              user.name,
              user.age,
              user.city,
              user.avatar,
              user.trustScore,
              user.userId,
              user.verified,
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildPopularUserCard(
    String name,
    int age,
    String location,
    String? avatarUrl,
    int trustScore,
    String userId,
    bool isVerified,
  ) {
    return GestureDetector(
      onTap: () => Get.toNamed('/profile', arguments: {'userId': userId}),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Colors.white,
          border: Border.all(color: Colors.grey[200]!, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.max,
          children: [
            // Avatar
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: avatarUrl == null ? AppColors.cyan : null,
                image: avatarUrl != null
                    ? DecorationImage(
                        image: NetworkImage(avatarUrl),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: avatarUrl == null
                  ? Center(
                      child: Icon(
                        FontAwesomeIcons.user,
                        size: 22,
                        color: Colors.white,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            // Info Section
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name and verified badge
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          name,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            color: Colors.black87,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isVerified)
                        Padding(
                          padding: const EdgeInsets.only(left: 6),
                          child: Icon(
                            Icons.verified,
                            size: 16,
                            color: AppColors.cyan,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  // Age and location
                  Text(
                    '$age • $location',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[700],
                      fontWeight: FontWeight.w400,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 5),
                  // Trust score
                  SizedBox(
                    height: 14,
                    child: Row(
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(2),
                            child: LinearProgressIndicator(
                              value: (trustScore / 100).clamp(0.0, 1.0),
                              minHeight: 3,
                              backgroundColor: Colors.grey[300],
                              valueColor: AlwaysStoppedAnimation<Color>(
                                trustScore >= 80
                                    ? AppColors.cyan
                                    : trustScore >= 60
                                        ? Colors.orange
                                        : Colors.red,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '$trustScore%',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Arrow icon
            Icon(
              FontAwesomeIcons.chevronRight,
              size: 14,
              color: Colors.grey[400],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileCard(
    String name,
    String age,
    String location,
    String? avatarUrl,
    int trustScore,
    String userId,
  ) {
    return GestureDetector(
      onTap: () => Get.toNamed('/profile', arguments: {'userId': userId}),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Colors.white,
        ),
        child: Stack(
          children: [
            // Background image or gradient
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                image: avatarUrl != null
                    ? DecorationImage(
                        image: NetworkImage(avatarUrl),
                        fit: BoxFit.cover,
                      )
                    : null,
                gradient: avatarUrl == null
                    ? LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          const Color(0xFFFF6B6B),
                          const Color(0xFFEF4444),
                        ],
                      )
                    : null,
              ),
            ),
            // Dark overlay for text
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(16),
                    bottomRight: Radius.circular(16),
                  ),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Colors.black.withValues(alpha: 0.6)],
                  ),
                ),
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      '$age • $location',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Trust score badge
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '⭐ ${(trustScore / 10).toStringAsFixed(1)}',
                  style: const TextStyle(
                    color: Color(0xFFEF4444),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMatchesList() {
    return FutureBuilder<dynamic>(
      future: dbService.getActiveMatches(
        authController.currentUserId.value ?? '',
        limit: 3,
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: SizedBox(
              width: 40,
              height: 40,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.grey[400]!),
              ),
            ),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              children: [
                Icon(FontAwesomeIcons.heart, size: 48, color: Colors.grey[300]),
                const SizedBox(height: 12),
                Text(
                  'Error loading matches: ${snapshot.error}',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
          );
        }

        final result = snapshot.data;
        final matches = result != null && result.isSuccess()
            ? (result.getOrNull() as List<Match>?) ?? []
            : <Match>[];

        if (matches.isEmpty) {
          return Center(
            child: Column(
              children: [
                Icon(FontAwesomeIcons.heart, size: 48, color: Colors.grey[300]),
                const SizedBox(height: 12),
                Text(
                  'No matches yet',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
          );
        }

        return Column(
          children: matches.map((match) {
            return FutureBuilder<dynamic>(
              future: dbService.getProfile(match.user2Id),
              builder: (context, userSnapshot) {
                if (userSnapshot.connectionState == ConnectionState.waiting) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(12),
                    height: 60,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: Colors.grey[100],
                    ),
                    child: const Center(
                      child: SizedBox(
                        width: 30,
                        height: 30,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  );
                }

                if (!userSnapshot.hasData || userSnapshot.hasError) {
                  return const SizedBox.shrink();
                }

                final userResult = userSnapshot.data;
                final user = userResult != null && userResult.isSuccess()
                    ? (userResult.getOrNull() as UserProfile?)
                    : null;

                if (user == null) {
                  return const SizedBox.shrink();
                }

                return GestureDetector(
                  onTap: () => Get.toNamed('/match-detail', arguments: match),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: Colors.white,
                      border: Border.all(color: Colors.grey[200]!),
                    ),
                    child: Row(
                      children: [
                        // User avatar
                        Container(
                          width: 54,
                          height: 54,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: user.avatar == null ? AppColors.cyan : null,
                            image: user.avatar != null
                                ? DecorationImage(
                                    image: NetworkImage(user.avatar!),
                                    fit: BoxFit.cover,
                                  )
                                : null,
                          ),
                          child: user.avatar == null
                              ? Center(
                                  child: Text(
                                    user.name.isNotEmpty
                                        ? user.name[0].toUpperCase()
                                        : 'U',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 20,
                                    ),
                                  ),
                                )
                              : null,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                user.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                  color: Colors.black87,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 3),
                              Text(
                                '${user.age} • ${user.city} • ${match.compatibilityScore.toStringAsFixed(0)}% match',
                                style: TextStyle(
                                  color: Colors.grey[700],
                                  fontSize: 12,
                                  fontWeight: FontWeight.w400,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          FontAwesomeIcons.chevronRight,
                          size: 14,
                          color: Colors.grey[400],
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          }).toList(),
        );
      },
    );
  }
}
