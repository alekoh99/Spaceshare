import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Professional SVG icon widget that replaces Material Icons
/// Usage: AppSvgIcon.icon(Icons.home) or AppSvgIcon.path('path/to/icon.svg')
class AppSvgIcon extends StatelessWidget {
  final String assetPath;
  final double? size;
  final Color? color;

  const AppSvgIcon._({
    required this.assetPath,
    this.size,
    this.color,
    super.key,
  });

  /// Create icon from Material icon - automatically maps to SVG
  factory AppSvgIcon.icon(IconData materialIcon, {double? size, Color? color, Key? key}) {
    final path = _getSvgPath(materialIcon);
    return AppSvgIcon._(assetPath: path, size: size, color: color, key: key);
  }

  /// Create icon directly from SVG path
  factory AppSvgIcon.path(String path, {double? size, Color? color, Key? key}) {
    return AppSvgIcon._(assetPath: path, size: size, color: color, key: key);
  }

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      assetPath,
      width: size ?? 24,
      height: size ?? 24,
      colorFilter: color != null
          ? ColorFilter.mode(color!, BlendMode.srcIn)
          : null,
    );
  }

  static String _getSvgPath(IconData icon) {
    // Safely extract the icon name from IconData.toString().
    // On some platforms (e.g. web), the string may not contain a '.' and
    // previously caused a RangeError. In that case, fall back to a default.
    final parts = icon.toString().split('.');
    if (parts.length < 2) {
      return 'assets/fontawesome-free-7.1.0-web/svgs/solid/circle-info.svg';
    }
    final iconName = parts[1];
    
    // Map Material Icons to Font Awesome SVG paths
    final iconMap = {
      // Navigation
      'arrow_back': 'assets/fontawesome-free-7.1.0-web/svgs/solid/arrow-left.svg',
      'arrow_forward': 'assets/fontawesome-free-7.1.0-web/svgs/solid/arrow-right.svg',
      'arrow_forward_ios': 'assets/fontawesome-free-7.1.0-web/svgs/solid/chevron-right.svg',
      'chevron_right': 'assets/fontawesome-free-7.1.0-web/svgs/solid/chevron-right.svg',
      'chevron_left': 'assets/fontawesome-free-7.1.0-web/svgs/solid/chevron-left.svg',
      
      // User & Profile
      'person': 'assets/fontawesome-free-7.1.0-web/svgs/solid/user.svg',
      'person_outline': 'assets/fontawesome-free-7.1.0-web/svgs/solid/user.svg',
      'account_circle': 'assets/fontawesome-free-7.1.0-web/svgs/solid/circle-user.svg',
      
      // Communication
      'mail_outline': 'assets/fontawesome-free-7.1.0-web/svgs/solid/envelope.svg',
      'email': 'assets/fontawesome-free-7.1.0-web/svgs/solid/envelope.svg',
      'message': 'assets/fontawesome-free-7.1.0-web/svgs/solid/message.svg',
      'send': 'assets/fontawesome-free-7.1.0-web/svgs/solid/envelope.svg',
      'comment': 'assets/fontawesome-free-7.1.0-web/svgs/solid/comment.svg',
      
      // Actions
      'edit': 'assets/fontawesome-free-7.1.0-web/svgs/solid/pen.svg',
      'edit_outlined': 'assets/fontawesome-free-7.1.0-web/svgs/solid/pen.svg',
      'delete': 'assets/fontawesome-free-7.1.0-web/svgs/solid/trash-can.svg',
      'delete_outline': 'assets/fontawesome-free-7.1.0-web/svgs/solid/trash-can.svg',
      'close': 'assets/fontawesome-free-7.1.0-web/svgs/solid/xmark.svg',
      'cancel': 'assets/fontawesome-free-7.1.0-web/svgs/solid/xmark.svg',
      'add': 'assets/fontawesome-free-7.1.0-web/svgs/solid/plus.svg',
      'add_circle': 'assets/fontawesome-free-7.1.0-web/svgs/solid/plus.svg',
      'remove': 'assets/fontawesome-free-7.1.0-web/svgs/solid/minus.svg',
      
      // Status
      'check': 'assets/fontawesome-free-7.1.0-web/svgs/solid/check.svg',
      'check_circle': 'assets/fontawesome-free-7.1.0-web/svgs/solid/circle-check.svg',
      'favorite': 'assets/fontawesome-free-7.1.0-web/svgs/solid/heart.svg',
      'favorite_outline': 'assets/fontawesome-free-7.1.0-web/svgs/solid/heart.svg',
      'star': 'assets/fontawesome-free-7.1.0-web/svgs/solid/star.svg',
      'notifications': 'assets/fontawesome-free-7.1.0-web/svgs/solid/bell.svg',
      'notifications_outlined': 'assets/fontawesome-free-7.1.0-web/svgs/solid/bell.svg',
      
      // Security
      'lock': 'assets/fontawesome-free-7.1.0-web/svgs/solid/lock.svg',
      'lock_outlined': 'assets/fontawesome-free-7.1.0-web/svgs/solid/lock.svg',
      'lock_open': 'assets/fontawesome-free-7.1.0-web/svgs/solid/lock-open.svg',
      
      // Location & Calendar
      'location_on': 'assets/fontawesome-free-7.1.0-web/svgs/solid/location-dot.svg',
      'location_on_outlined': 'assets/fontawesome-free-7.1.0-web/svgs/solid/location-dot.svg',
      'calendar_today': 'assets/fontawesome-free-7.1.0-web/svgs/solid/calendar.svg',
      'calendar': 'assets/fontawesome-free-7.1.0-web/svgs/solid/calendar.svg',
      
      // Media
      'camera_alt': 'assets/fontawesome-free-7.1.0-web/svgs/solid/camera.svg',
      'camera': 'assets/fontawesome-free-7.1.0-web/svgs/solid/camera.svg',
      'image': 'assets/fontawesome-free-7.1.0-web/svgs/solid/image.svg',
      'image_not_supported': 'assets/fontawesome-free-7.1.0-web/svgs/solid/image.svg',
      'attach_file': 'assets/fontawesome-free-7.1.0-web/svgs/solid/paperclip.svg',
      'attachment': 'assets/fontawesome-free-7.1.0-web/svgs/solid/paperclip.svg',
      
      // UI Elements
      'menu': 'assets/fontawesome-free-7.1.0-web/svgs/solid/bars.svg',
      'more_vert': 'assets/fontawesome-free-7.1.0-web/svgs/solid/ellipsis-vertical.svg',
      'search': 'assets/fontawesome-free-7.1.0-web/svgs/solid/magnifying-glass.svg',
      'filter_list': 'assets/fontawesome-free-7.1.0-web/svgs/solid/filter.svg',
      'tune': 'assets/fontawesome-free-7.1.0-web/svgs/solid/filter.svg',
      'settings': 'assets/fontawesome-free-7.1.0-web/svgs/solid/gear.svg',
      
      // Home & Building
      'home': 'assets/fontawesome-free-7.1.0-web/svgs/solid/house.svg',
      'home_work': 'assets/fontawesome-free-7.1.0-web/svgs/solid/house.svg',
      
      // Financial
      'attach_money': 'assets/fontawesome-free-7.1.0-web/svgs/solid/dollar-sign.svg',
      'payments': 'assets/fontawesome-free-7.1.0-web/svgs/solid/dollar-sign.svg',
      'receipt_long': 'assets/fontawesome-free-7.1.0-web/svgs/solid/receipt.svg',
      'receipt': 'assets/fontawesome-free-7.1.0-web/svgs/solid/receipt.svg',
      
      // Other
      'info': 'assets/fontawesome-free-7.1.0-web/svgs/solid/circle-info.svg',
      'info_outline': 'assets/fontawesome-free-7.1.0-web/svgs/solid/circle-info.svg',
      'lightbulb': 'assets/fontawesome-free-7.1.0-web/svgs/solid/lightbulb.svg',
      'campaign': 'assets/fontawesome-free-7.1.0-web/svgs/solid/bullhorn.svg',
      'cake': 'assets/fontawesome-free-7.1.0-web/svgs/solid/cake-candles.svg',
      'cake_outlined': 'assets/fontawesome-free-7.1.0-web/svgs/solid/cake-candles.svg',
      'thumb_down': 'assets/fontawesome-free-7.1.0-web/svgs/solid/thumbs-down.svg',
      'share': 'assets/fontawesome-free-7.1.0-web/svgs/solid/share.svg',
      'person_search': 'assets/fontawesome-free-7.1.0-web/svgs/solid/user-magnifying-glass.svg',
    };
    
    return iconMap[iconName] ?? 'assets/fontawesome-free-7.1.0-web/svgs/solid/circle-info.svg';
  }
}

