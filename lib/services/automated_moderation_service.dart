import 'package:get/get.dart';
import '../utils/result.dart';
import '../utils/exceptions.dart';
import 'unified_database_service.dart';

abstract class IAutomatedModerationService {
  Future<Result<Map<String, dynamic>>> analyzeContent(String content, String contentType);
  Future<Result<void>> flagContentIfNeeded(String contentId, String content, String contentType);
  Future<Result<List<String>>> getProhibitedKeywords();
}

class AutomatedModerationService implements IAutomatedModerationService {
  late final UnifiedDatabaseService _databaseService;
  
  final List<String> _prohibitedKeywords = [
    'spam', 'abuse', 'hate', 'violence', 'drugs',
  ];

  AutomatedModerationService() {
    try {
      _databaseService = Get.find<UnifiedDatabaseService>();
    } catch (e) {
      throw ServiceException('Failed to initialize AutomatedModerationService: $e');
    }
  }

  @override
  Future<Result<Map<String, dynamic>>> analyzeContent(String content, String contentType) async {
    try {
      final report = <String, dynamic>{
        'contentLength': content.length,
        'containsProhibited': _containsProhibitedContent(content),
        'isSuspicious': _isSuspiciousContent(content),
        'riskLevel': _calculateRiskLevel(content),
        'analyzedAt': DateTime.now().toIso8601String(),
      };

      return Result.success(report);
    } catch (e) {
      return Result.failure(Exception('Failed to analyze content: $e'));
    }
  }

  @override
  Future<Result<void>> flagContentIfNeeded(String contentId, String content, String contentType) async {
    try {
      final analysis = await analyzeContent(content, contentType);

      if (analysis.isSuccess()) {
        final report = analysis.data!;
        
        if (report['containsProhibited'] == true || report['riskLevel'] == 'high') {
          final flagId = 'auto_flag_${DateTime.now().millisecondsSinceEpoch}';
          
          final flagData = {
            'flagId': flagId,
            'contentId': contentId,
            'contentType': contentType,
            'reason': 'automated_moderation',
            'analysis': report,
            'status': 'pending_review',
            'createdAt': DateTime.now().toIso8601String(),
          };

          final result = await _databaseService.createPath(
            'moderationFlags/$flagId',
            flagData,
          );

          return result.isSuccess() 
              ? Result.success(null)
              : Result.failure(Exception('Failed to create moderation flag'));
        }
      }

      return Result.success(null);
    } catch (e) {
      return Result.failure(Exception('Failed to flag content: $e'));
    }
  }

  @override
  Future<Result<List<String>>> getProhibitedKeywords() async {
    try {
      return Result.success(_prohibitedKeywords);
    } catch (e) {
      return Result.failure(Exception('Failed to get prohibited keywords: $e'));
    }
  }

  bool _containsProhibitedContent(String content) {
    final lowerContent = content.toLowerCase();
    return _prohibitedKeywords.any((keyword) => lowerContent.contains(keyword));
  }

  bool _isSuspiciousContent(String content) {
    // Check for excessive caps, special characters, repetition
    int capsCount = 0;
    for (final c in content.split('')) {
      if (c == c.toUpperCase() && c != c.toLowerCase()) {
        capsCount++;
      }
    }
    final capsRatio = content.isNotEmpty ? capsCount / content.length : 0;

    if (capsRatio > 0.7) return true;

    // Check for repeated characters
    if (RegExp(r'([a-zA-Z])\1{4,}').hasMatch(content)) return true;

    return false;
  }

  String _calculateRiskLevel(String content) {
    if (content.length < 10) return 'low';
    
    if (_containsProhibitedContent(content)) return 'high';
    if (_isSuspiciousContent(content)) return 'medium';
    
    return 'low';
  }
}
