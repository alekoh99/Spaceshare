import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Widget for displaying SVG icons with color customization
class SvgIcon extends StatelessWidget {
  final String assetPath;
  final double? size;
  final Color? color;
  final BoxFit fit;

  const SvgIcon({
    super.key,
    required this.assetPath,
    this.size,
    this.color,
    this.fit = BoxFit.contain,
  });

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      assetPath,
      width: size,
      height: size,
      fit: fit,
      colorFilter: color != null
          ? ColorFilter.mode(color!, BlendMode.srcIn)
          : null,
    );
  }
}

/// Helper class with Font Awesome SVG asset paths
class FontAwesomeSvgIcons {
  // Solid icons
  static const String userShield = 'assets/fontawesome-free-7.1.0-web/svgs/solid/user-shield.svg';
  static const String creditCard = 'assets/fontawesome-free-7.1.0-web/svgs/solid/credit-card.svg';
  static const String comments = 'assets/fontawesome-free-7.1.0-web/svgs/solid/comments.svg';
  static const String shield = 'assets/fontawesome-free-7.1.0-web/svgs/solid/shield.svg';
  static const String shieldHalved = 'assets/fontawesome-free-7.1.0-web/svgs/solid/shield-halved.svg';
  static const String star = 'assets/fontawesome-free-7.1.0-web/svgs/solid/star.svg';
  static const String check = 'assets/fontawesome-free-7.1.0-web/svgs/solid/check.svg';
  static const String circleCheck = 'assets/fontawesome-free-7.1.0-web/svgs/solid/circle-check.svg';
  static const String bell = 'assets/fontawesome-free-7.1.0-web/svgs/solid/bell.svg';
  static const String users = 'assets/fontawesome-free-7.1.0-web/svgs/solid/users.svg';
  static const String heart = 'assets/fontawesome-free-7.1.0-web/svgs/solid/heart.svg';
  static const String comment = 'assets/fontawesome-free-7.1.0-web/svgs/solid/comment.svg';
  static const String user = 'assets/fontawesome-free-7.1.0-web/svgs/solid/user.svg';
  static const String arrowTrendUp = 'assets/fontawesome-free-7.1.0-web/svgs/solid/arrow-trend-up.svg';
  static const String chevronRight = 'assets/fontawesome-free-7.1.0-web/svgs/solid/chevron-right.svg';
}

