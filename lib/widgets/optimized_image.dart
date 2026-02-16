import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../utils/logger.dart';
import 'app_svg_icon.dart';

class OptimizedImage extends StatelessWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Duration cacheDuration;
  final Color? errorColor;

  const OptimizedImage({super.key, 
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.cacheDuration = const Duration(days: 7),
    this.errorColor,
  });

  @override
  Widget build(BuildContext context) {
    if (imageUrl.isEmpty) {
      return _buildPlaceholder();
    }

    try {
      return CachedNetworkImage(
        imageUrl: imageUrl,
        width: width,
        height: height,
        fit: fit,
        maxHeightDiskCache: 1024,
        maxWidthDiskCache: 1024,
        cacheKey: imageUrl,
        placeholder: (context, url) => _buildPlaceholder(),
        errorWidget: (context, url, error) => _buildError(),
      );
    } catch (e) {
      AppLogger.debug('OptimizedImage', 'Error loading image: $e');
      return _buildError();
    }
  }

  Widget _buildPlaceholder() {
    return Container(
      width: width,
      height: height,
      color: Colors.grey[300],
      child: const Center(
        child: SizedBox(
          width: 40,
          height: 40,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
    );
  }

  Widget _buildError() {
    return Container(
      width: width,
      height: height,
      color: errorColor ?? Colors.grey[300],
      child: AppSvgIcon.icon(Icons.image_not_supported, color: Colors.grey),
    );
  }
}

class ImageCacheManager {
  static final ImageCacheManager _instance = ImageCacheManager._internal();

  factory ImageCacheManager() {
    return _instance;
  }

  ImageCacheManager._internal();

  void clearCache() {
    imageCache.clear();
    imageCache.clearLiveImages();
  }

  void clearSpecificImage(String imageUrl) {
    imageCache.evict(NetworkImage(imageUrl));
  }

  int getCacheSize() {
    return imageCache.currentSize;
  }

  int getMaxCacheSize() {
    return imageCache.maximumSize;
  }
}
