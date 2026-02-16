import 'package:flutter/foundation.dart' show kIsWeb;
import '../utils/logger.dart';

class AuthDebugger {
  static void logAuthFlow(String stage, {Map<String, dynamic>? details}) {
    final buffer = StringBuffer();
    buffer.write('AUTH FLOW [$stage]');
    
    if (details != null && details.isNotEmpty) {
      details.forEach((key, value) {
        buffer.write(' | $key: $value');
      });
    }
    
    AppLogger.info('AUTH', buffer.toString());
  }

  static void logOAuthState(String provider, String state, {Map<String, dynamic>? details}) {
    final buffer = StringBuffer();
    buffer.write('OAuth [$provider] $state');
    
    if (details != null && details.isNotEmpty) {
      details.forEach((key, value) {
        buffer.write(' | $key: $value');
      });
    }
    
    AppLogger.debug('OAUTH', buffer.toString());
  }

  static void logPopupState(String state, {String? reason, String? errorCode}) {
    if (errorCode != null) {
      AppLogger.warning('POPUP', '$state - Error: $errorCode${reason != null ? ' ($reason)' : ''}');
    } else {
      AppLogger.debug('POPUP', state + (reason != null ? ' - $reason' : ''));
    }
  }

  static String generateDiagnostics({
    required bool isAuthenticated,
    required String? currentUserId,
    required String? currentEmail,
    String? lastAuthError,
  }) {
    final buffer = StringBuffer();
    buffer.writeln('=== AUTH DIAGNOSTICS ===');
    buffer.writeln('Platform: ${kIsWeb ? "Web" : "Mobile"}');
    buffer.writeln('Authenticated: $isAuthenticated');
    buffer.writeln('User ID: ${currentUserId ?? "Not authenticated"}');
    buffer.writeln('Email: ${currentEmail ?? "Not available"}');
    
    if (lastAuthError != null) {
      buffer.writeln('Last Error: $lastAuthError');
    }
    
    return buffer.toString();
  }

  static AuthFlowTracer createFlowTracer(String flowName) {
    return AuthFlowTracer(flowName);
  }
}

class AuthFlowTracer {
  final String flowName;
  final DateTime startTime = DateTime.now();
  final List<({String name, Duration elapsed, Map<String, dynamic>? data})> points = [];

  AuthFlowTracer(this.flowName) {
    AppLogger.debug('TRACE', 'Starting: $flowName');
  }

  void mark(String pointName, {Map<String, dynamic>? data}) {
    final elapsed = DateTime.now().difference(startTime);
    points.add((name: pointName, elapsed: elapsed, data: data));
    
    final dataStr = data?.entries.map((e) => '${e.key}=${e.value}').join(', ') ?? '';
    AppLogger.debug('TRACE', '$pointName (+${elapsed.inMilliseconds}ms) ${dataStr.isNotEmpty ? '[$dataStr]' : ''}');
  }

  void complete({String? result}) {
    final totalDuration = DateTime.now().difference(startTime);
    AppLogger.info('TRACE', 'Complete: $flowName (${totalDuration.inMilliseconds}ms)${result != null ? ' - $result' : ''}');
  }

  void error(String errorMessage, [Object? error, StackTrace? stackTrace]) {
    final totalDuration = DateTime.now().difference(startTime);
    AppLogger.error('TRACE', 'Failed: $flowName (${totalDuration.inMilliseconds}ms) - $errorMessage', error, stackTrace);
  }
}
