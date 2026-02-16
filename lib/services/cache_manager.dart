import 'package:hive_flutter/hive_flutter.dart';
import '../utils/logger.dart';
import '../utils/result.dart';
import 'dart:async';

/// Production-grade offline caching layer using Hive
/// Provides local persistence for all app data
class CacheManager {
  static const String usersBox = 'users_cache';
  static const String matchesBox = 'matches_cache';
  static const String messagesBox = 'messages_cache';
  static const String preferencesBox = 'preferences_cache';
  static const String metadataBox = 'metadata_cache';

  late Box<dynamic> _usersBox;
  late Box<dynamic> _matchesBox;
  late Box<dynamic> _messagesBox;
  late Box<dynamic> _preferencesBox;
  late Box<dynamic> _metadataBox;

  static final CacheManager _instance = CacheManager._internal();

  factory CacheManager() {
    return _instance;
  }

  CacheManager._internal();

  /// Initialize cache manager
  Future<void> initialize() async {
    try {
      await Hive.initFlutter();
      _usersBox = await Hive.openBox<dynamic>(usersBox);
      _matchesBox = await Hive.openBox<dynamic>(matchesBox);
      _messagesBox = await Hive.openBox<dynamic>(messagesBox);
      _preferencesBox = await Hive.openBox<dynamic>(preferencesBox);
      _metadataBox = await Hive.openBox<dynamic>(metadataBox);

      AppLogger.info('CacheManager', 'Cache initialized successfully');
    } catch (e) {
      AppLogger.error('CacheManager', 'Failed to initialize cache', e);
      rethrow;
    }
  }

  /// Save data with optional expiration
  Future<Result<void>> save<T>({
    required String key,
    required T value,
    required CacheType type,
    Duration? ttl,
  }) async {
    try {
      final metadata = _CacheMetadata(
        key: key,
        createdAt: DateTime.now(),
        expiresAt: ttl != null ? DateTime.now().add(ttl) : null,
      );

      final box = _getBox(type);
      await box.put(key, value);
      await _metadataBox.put('$key:metadata', metadata);

      AppLogger.debug('Cache', 'Saved $key to ${type.name}');
      return Result.success(null);
    } catch (e) {
      AppLogger.error('Cache', 'Failed to save $key', e);
      return Result.failure(CacheException(
        message: 'Failed to save cache data',
        originalException: e as Exception?,
      ));
    }
  }

  /// Get data if not expired
  Future<Result<T?>> get<T>({
    required String key,
    required CacheType type,
  }) async {
    try {
      final box = _getBox(type);
      final value = box.get(key) as T?;

      if (value == null) {
        return Result.success(null);
      }

      // Check expiration
      final metadata = _metadataBox.get('$key:metadata') as _CacheMetadata?;
      if (metadata?.isExpired ?? false) {
        await delete(key: key, type: type);
        return Result.success(null);
      }

      AppLogger.debug('Cache', 'Retrieved $key from ${type.name}');
      return Result.success(value);
    } catch (e) {
      AppLogger.error('Cache', 'Failed to get $key', e);
      return Result.failure(CacheException(
        message: 'Failed to retrieve cache data',
        originalException: e as Exception?,
      ));
    }
  }

  /// Delete specific key
  Future<Result<void>> delete({
    required String key,
    required CacheType type,
  }) async {
    try {
      final box = _getBox(type);
      await box.delete(key);
      await _metadataBox.delete('$key:metadata');

      AppLogger.debug('Cache', 'Deleted $key from ${type.name}');
      return Result.success(null);
    } catch (e) {
      AppLogger.error('Cache', 'Failed to delete $key', e);
      return Result.failure(CacheException(
        message: 'Failed to delete cache data',
        originalException: e as Exception?,
      ));
    }
  }

  /// Clear all data of specific type
  Future<Result<void>> clearType(CacheType type) async {
    try {
      final box = _getBox(type);
      await box.clear();

      AppLogger.info('Cache', 'Cleared ${type.name}');
      return Result.success(null);
    } catch (e) {
      AppLogger.error('Cache', 'Failed to clear ${type.name}', e);
      return Result.failure(CacheException(
        message: 'Failed to clear cache type',
        originalException: e as Exception?,
      ));
    }
  }

  /// Clear all cache
  Future<Result<void>> clearAll() async {
    try {
      await _usersBox.clear();
      await _matchesBox.clear();
      await _messagesBox.clear();
      await _preferencesBox.clear();
      await _metadataBox.clear();

      AppLogger.info('Cache', 'Cleared all cache');
      return Result.success(null);
    } catch (e) {
      AppLogger.error('Cache', 'Failed to clear all cache', e);
      return Result.failure(CacheException(
        message: 'Failed to clear cache',
        originalException: e as Exception?,
      ));
    }
  }

  /// Get cache size
  Future<int> getCacheSize() async {
    int total = 0;
    total += _usersBox.length;
    total += _matchesBox.length;
    total += _messagesBox.length;
    total += _preferencesBox.length;
    return total;
  }

  /// Clean expired entries
  Future<Result<int>> cleanExpired() async {
    try {
      int deleted = 0;

      final keys = _metadataBox.keys.toList();
      for (final key in keys) {
        if (key is String && key.endsWith(':metadata')) {
          final metadata = _metadataBox.get(key) as _CacheMetadata?;
          if (metadata?.isExpired ?? false) {
            final dataKey = key.replaceAll(':metadata', '');
            await _metadataBox.delete(key);
            // Delete from all boxes
            await _usersBox.delete(dataKey);
            await _matchesBox.delete(dataKey);
            await _messagesBox.delete(dataKey);
            await _preferencesBox.delete(dataKey);
            deleted++;
          }
        }
      }

      AppLogger.info('Cache', 'Cleaned $deleted expired entries');
      return Result.success(deleted);
    } catch (e) {
      AppLogger.error('Cache', 'Failed to clean expired entries', e);
      return Result.failure(CacheException(
        message: 'Failed to clean cache',
        originalException: e as Exception?,
      ));
    }
  }

  /// Close cache
  Future<void> close() async {
    try {
      await Hive.close();
      AppLogger.info('CacheManager', 'Cache closed');
    } catch (e) {
      AppLogger.error('CacheManager', 'Failed to close cache', e);
    }
  }

  Box<dynamic> _getBox(CacheType type) {
    return switch (type) {
      CacheType.users => _usersBox,
      CacheType.matches => _matchesBox,
      CacheType.messages => _messagesBox,
      CacheType.preferences => _preferencesBox,
    };
  }
}

enum CacheType {
  users,
  matches,
  messages,
  preferences,
}

/// Cache metadata with TTL support
class _CacheMetadata {
  final String key;
  final DateTime createdAt;
  final DateTime? expiresAt;

  _CacheMetadata({
    required this.key,
    required this.createdAt,
    this.expiresAt,
  });

  bool get isExpired {
    if (expiresAt == null) return false;
    return DateTime.now().isAfter(expiresAt!);
  }

  Duration get age => DateTime.now().difference(createdAt);
}

/// Composite caching strategy
class CacheStrategy<T> {
  final Duration ttl;
  final bool networkFirst;
  final CacheType cacheType;

  CacheStrategy({
    this.ttl = const Duration(hours: 24),
    this.networkFirst = false,
    required this.cacheType,
  });

  /// Execute with caching
  Future<Result<T>> execute({
    required String key,
    required Future<Result<T>> Function() networkCall,
  }) async {
    final cacheManager = CacheManager();

    if (networkFirst) {
      // Try network first
      final networkResult = await networkCall();
      if (networkResult.isSuccess()) {
        final value = networkResult.getOrNull();
        if (value != null) {
          await cacheManager.save(
            key: key,
            value: value,
            type: cacheType,
            ttl: ttl,
          );
        }
        return networkResult;
      }
    }

    // Try cache
    final cachedResult = await cacheManager.get<T>(
      key: key,
      type: cacheType,
    );

    if (cachedResult.isSuccess()) {
      final cachedValue = cachedResult.getOrNull();
      if (cachedValue != null) {
        AppLogger.debug('Cache', 'Using cached value for $key');
        return Result.success(cachedValue);
      }
    }

    // No cache, try network
    final networkResult = await networkCall();
    if (networkResult.isSuccess()) {
      final value = networkResult.getOrNull();
      if (value != null) {
        await cacheManager.save(
          key: key,
          value: value,
          type: cacheType,
          ttl: ttl,
        );
      }
    }

    return networkResult;
  }
}
