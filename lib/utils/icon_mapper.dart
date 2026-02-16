import 'package:flutter/material.dart';
import '../widgets/svg_icon_widget.dart';

/// Utility class to map Material Icons to Font Awesome SVG icons
class IconMapper {
  /// Gets SVG icon widget for a Material icon name
  static Widget getSvgIcon(
    IconData materialIcon, {
    double? size,
    Color? color,
  }) {
    final iconPath = _getIconPath(materialIcon);
    if (iconPath == null) {
      // Fallback to Material icon if SVG not found
      return Icon(materialIcon, size: size, color: color);
    }
    return SvgIcon(
      assetPath: iconPath,
      size: size,
      color: color,
    );
  }

  /// Gets SVG asset path for a Material icon
  static String? _getIconPath(IconData icon) {
    // Map common Material Icons to Font Awesome SVG paths.
    // Be defensive: on some platforms IconData.toString() doesn't contain a '.'
    // and splitting would otherwise throw a RangeError.
    final parts = icon.toString().split('.');
    if (parts.length < 2) {
      return null;
    }
    final iconName = parts[1];
    
    switch (iconName) {
      // Navigation
      case 'arrow_back':
        return 'assets/fontawesome-free-7.1.0-web/svgs/solid/arrow-left.svg';
      case 'arrow_forward':
      case 'arrow_forward_ios':
        return 'assets/fontawesome-free-7.1.0-web/svgs/solid/arrow-right.svg';
      case 'chevron_right':
        return 'assets/fontawesome-free-7.1.0-web/svgs/solid/chevron-right.svg';
      case 'chevron_left':
        return 'assets/fontawesome-free-7.1.0-web/svgs/solid/chevron-left.svg';
      
      // User & Profile
      case 'person':
      case 'person_outline':
        return 'assets/fontawesome-free-7.1.0-web/svgs/solid/user.svg';
      case 'account_circle':
        return 'assets/fontawesome-free-7.1.0-web/svgs/solid/circle-user.svg';
      
      // Communication
      case 'mail_outline':
      case 'email':
        return 'assets/fontawesome-free-7.1.0-web/svgs/solid/envelope.svg';
      case 'message':
        return 'assets/fontawesome-free-7.1.0-web/svgs/solid/message.svg';
      case 'send':
        return 'assets/fontawesome-free-7.1.0-web/svgs/solid/envelope.svg';
      case 'comment':
        return 'assets/fontawesome-free-7.1.0-web/svgs/solid/comment.svg';
      
      // Actions
      case 'edit':
      case 'edit_outlined':
        return 'assets/fontawesome-free-7.1.0-web/svgs/solid/pen.svg';
      case 'delete':
      case 'delete_outline':
        return 'assets/fontawesome-free-7.1.0-web/svgs/solid/trash-can.svg';
      case 'close':
      case 'cancel':
        return 'assets/fontawesome-free-7.1.0-web/svgs/solid/xmark.svg';
      case 'add':
      case 'add_circle':
        return 'assets/fontawesome-free-7.1.0-web/svgs/solid/plus.svg';
      case 'remove':
        return 'assets/fontawesome-free-7.1.0-web/svgs/solid/minus.svg';
      
      // Status
      case 'check':
      case 'check_circle':
        return 'assets/fontawesome-free-7.1.0-web/svgs/solid/circle-check.svg';
      case 'favorite':
      case 'favorite_outline':
        return 'assets/fontawesome-free-7.1.0-web/svgs/solid/heart.svg';
      case 'star':
        return 'assets/fontawesome-free-7.1.0-web/svgs/solid/star.svg';
      case 'notifications':
      case 'notifications_outlined':
        return 'assets/fontawesome-free-7.1.0-web/svgs/solid/bell.svg';
      
      // Security
      case 'lock':
      case 'lock_outlined':
        return 'assets/fontawesome-free-7.1.0-web/svgs/solid/lock.svg';
      case 'lock_open':
        return 'assets/fontawesome-free-7.1.0-web/svgs/solid/lock-open.svg';
      
      // Location & Calendar
      case 'location_on':
      case 'location_on_outlined':
        return 'assets/fontawesome-free-7.1.0-web/svgs/solid/location-dot.svg';
      case 'calendar_today':
      case 'calendar':
        return 'assets/fontawesome-free-7.1.0-web/svgs/solid/calendar.svg';
      
      // Media
      case 'camera_alt':
      case 'camera':
        return 'assets/fontawesome-free-7.1.0-web/svgs/solid/camera.svg';
      case 'image':
      case 'image_not_supported':
        return 'assets/fontawesome-free-7.1.0-web/svgs/solid/image.svg';
      case 'attach_file':
      case 'attachment':
        return 'assets/fontawesome-free-7.1.0-web/svgs/solid/paperclip.svg';
      
      // UI Elements
      case 'menu':
        return 'assets/fontawesome-free-7.1.0-web/svgs/solid/bars.svg';
      case 'more_vert':
        return 'assets/fontawesome-free-7.1.0-web/svgs/solid/ellipsis-vertical.svg';
      case 'search':
        return 'assets/fontawesome-free-7.1.0-web/svgs/solid/magnifying-glass.svg';
      case 'filter_list':
      case 'tune':
        return 'assets/fontawesome-free-7.1.0-web/svgs/solid/filter.svg';
      case 'settings':
        return 'assets/fontawesome-free-7.1.0-web/svgs/solid/gear.svg';
      
      // Home & Building
      case 'home':
      case 'home_work':
        return 'assets/fontawesome-free-7.1.0-web/svgs/solid/house.svg';
      
      // Financial
      case 'attach_money':
      case 'payments':
        return 'assets/fontawesome-free-7.1.0-web/svgs/solid/dollar-sign.svg';
      case 'receipt_long':
      case 'receipt':
        return 'assets/fontawesome-free-7.1.0-web/svgs/solid/receipt.svg';
      
      // Other
      case 'info':
      case 'info_outline':
        return 'assets/fontawesome-free-7.1.0-web/svgs/solid/circle-info.svg';
      case 'lightbulb':
        return 'assets/fontawesome-free-7.1.0-web/svgs/solid/lightbulb.svg';
      case 'campaign':
        return 'assets/fontawesome-free-7.1.0-web/svgs/solid/bullhorn.svg';
      case 'cake':
      case 'cake_outlined':
        return 'assets/fontawesome-free-7.1.0-web/svgs/solid/cake-candles.svg';
      case 'thumb_down':
        return 'assets/fontawesome-free-7.1.0-web/svgs/solid/thumbs-down.svg';
      case 'share':
        return 'assets/fontawesome-free-7.1.0-web/svgs/solid/share.svg';
      case 'person_search':
        return 'assets/fontawesome-free-7.1.0-web/svgs/solid/user-magnifying-glass.svg';
      
      default:
        return null;
    }
  }
}

/// Extended Icon widget that automatically uses SVG icons when available
class AppIcon extends StatelessWidget {
  final IconData icon;
  final double? size;
  final Color? color;

  const AppIcon({
    super.key,
    required this.icon,
    this.size,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return IconMapper.getSvgIcon(icon, size: size, color: color);
  }
}

