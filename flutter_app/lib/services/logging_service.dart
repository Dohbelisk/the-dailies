import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'firebase_service.dart';

/// Log levels for filtering and categorization
enum LogLevel {
  debug,
  info,
  warning,
  error,
}

/// Comprehensive logging service with Crashlytics integration.
/// Provides structured logging for debugging and error tracking.
class LoggingService {
  static final LoggingService _instance = LoggingService._internal();
  factory LoggingService() => _instance;
  LoggingService._internal();

  final FirebaseService _firebase = FirebaseService();

  /// Minimum log level to output (debug mode shows all, release shows info+)
  LogLevel get minLevel => kDebugMode ? LogLevel.debug : LogLevel.info;

  /// Log a debug message (only shown in debug mode)
  void debug(String message, {String? tag, Map<String, dynamic>? data}) {
    _log(LogLevel.debug, message, tag: tag, data: data);
  }

  /// Log an info message
  void info(String message, {String? tag, Map<String, dynamic>? data}) {
    _log(LogLevel.info, message, tag: tag, data: data);
  }

  /// Log a warning message
  void warning(String message, {String? tag, Map<String, dynamic>? data}) {
    _log(LogLevel.warning, message, tag: tag, data: data);
  }

  /// Log an error with optional exception and stack trace
  void error(
    String message, {
    String? tag,
    dynamic exception,
    StackTrace? stackTrace,
    Map<String, dynamic>? data,
  }) {
    _log(LogLevel.error, message, tag: tag, data: data);

    // Report to Crashlytics if there's an exception
    if (exception != null) {
      _firebase.logError(
        exception,
        stackTrace ?? StackTrace.current,
        reason: '$tag: $message',
      );
    } else {
      // Log as a custom Crashlytics message for tracking
      _firebase.log('ERROR [$tag]: $message');
    }
  }

  /// Log an API request (debug level)
  void logApiRequest({
    required String method,
    required String url,
    Map<String, String>? headers,
    dynamic body,
  }) {
    final sanitizedHeaders = _sanitizeHeaders(headers);

    debug(
      'API Request: $method $url',
      tag: 'API',
      data: {
        'method': method,
        'url': url,
        if (sanitizedHeaders.isNotEmpty) 'headers': sanitizedHeaders,
        if (body != null) 'body': _truncateBody(body),
      },
    );
  }

  /// Log an API response
  void logApiResponse({
    required String method,
    required String url,
    required int statusCode,
    String? body,
    Duration? duration,
  }) {
    final isError = statusCode >= 400;
    final level = isError ? LogLevel.error : LogLevel.debug;

    final message = 'API Response: $method $url - $statusCode${duration != null ? ' (${duration.inMilliseconds}ms)' : ''}';

    _log(
      level,
      message,
      tag: 'API',
      data: {
        'method': method,
        'url': url,
        'statusCode': statusCode,
        if (duration != null) 'durationMs': duration.inMilliseconds,
        if (body != null && isError) 'responseBody': _truncateBody(body),
      },
    );

    // Report API errors to Crashlytics
    if (isError) {
      _firebase.log('API_ERROR: $method $url - $statusCode');
      _firebase.setCustomKey('last_api_error_url', url);
      _firebase.setCustomKey('last_api_error_status', statusCode);

      // Try to extract error message from response body
      final errorMessage = _extractErrorMessage(body);
      if (errorMessage != null) {
        _firebase.setCustomKey('last_api_error_message', errorMessage);
      }
    }
  }

  /// Log an API error (exception during request)
  void logApiError({
    required String method,
    required String url,
    required dynamic exception,
    StackTrace? stackTrace,
  }) {
    error(
      'API Error: $method $url - ${exception.toString()}',
      tag: 'API',
      exception: exception,
      stackTrace: stackTrace,
      data: {
        'method': method,
        'url': url,
        'error': exception.toString(),
      },
    );
  }

  /// Log a game action
  void logGameAction(String action, {String? gameType, Map<String, dynamic>? data}) {
    debug(
      'Game: $action',
      tag: 'Game${gameType != null ? ':$gameType' : ''}',
      data: data,
    );
  }

  /// Log a navigation event
  void logNavigation(String screen, {Map<String, dynamic>? params}) {
    debug(
      'Navigate: $screen',
      tag: 'Nav',
      data: params,
    );
  }

  /// Log a service initialization
  void logServiceInit(String serviceName, {bool success = true, String? error}) {
    if (success) {
      info('Service initialized: $serviceName', tag: 'Init');
    } else {
      this.error(
        'Service failed to initialize: $serviceName',
        tag: 'Init',
        data: error != null ? {'error': error} : null,
      );
    }
  }

  /// Log a user action
  void logUserAction(String action, {Map<String, dynamic>? data}) {
    info('User: $action', tag: 'User', data: data);
  }

  /// Set user context for all subsequent logs
  void setUserContext({String? userId, String? email, bool isAnonymous = false}) {
    if (userId != null) {
      _firebase.setUserId(userId);
      _firebase.setCustomKey('user_id', userId);
    }
    _firebase.setCustomKey('is_anonymous', isAnonymous);
  }

  /// Set custom context key-value pair
  void setContext(String key, dynamic value) {
    _firebase.setCustomKey(key, value);
  }

  // Private helper methods

  void _log(LogLevel level, String message, {String? tag, Map<String, dynamic>? data}) {
    if (level.index < minLevel.index) return;

    final prefix = _levelPrefix(level);
    final tagStr = tag != null ? '[$tag] ' : '';
    final fullMessage = '$prefix $tagStr$message';

    // Console output
    if (kDebugMode || level.index >= LogLevel.warning.index) {
      debugPrint(fullMessage);
      if (data != null && kDebugMode) {
        debugPrint('  Data: ${_formatData(data)}');
      }
    }

    // Send to Crashlytics for info level and above
    if (level.index >= LogLevel.info.index) {
      _firebase.log('$tagStr$message');
    }
  }

  String _levelPrefix(LogLevel level) {
    switch (level) {
      case LogLevel.debug:
        return '🔍';
      case LogLevel.info:
        return 'ℹ️';
      case LogLevel.warning:
        return '⚠️';
      case LogLevel.error:
        return '❌';
    }
  }

  String _formatData(Map<String, dynamic> data) {
    try {
      return const JsonEncoder.withIndent('  ').convert(data);
    } catch (e) {
      return data.toString();
    }
  }

  Map<String, String> _sanitizeHeaders(Map<String, String>? headers) {
    if (headers == null) return {};

    // Remove sensitive headers
    final sanitized = Map<String, String>.from(headers);
    if (sanitized.containsKey('Authorization')) {
      sanitized['Authorization'] = '[REDACTED]';
    }
    return sanitized;
  }

  String _truncateBody(dynamic body, {int maxLength = 500}) {
    final str = body is String ? body : body.toString();
    if (str.length <= maxLength) return str;
    return '${str.substring(0, maxLength)}... [truncated]';
  }

  String? _extractErrorMessage(String? body) {
    if (body == null) return null;
    try {
      final json = jsonDecode(body);
      if (json is Map) {
        return json['message'] ?? json['error'] ?? json['msg'];
      }
    } catch (_) {
      // Not JSON, return truncated body
      if (body.length > 100) {
        return body.substring(0, 100);
      }
      return body;
    }
    return null;
  }
}

/// Extension to add logging to http.Response
extension LoggedResponse on Future<http.Response> {
  Future<http.Response> logged({
    required String method,
    required String url,
    DateTime? startTime,
  }) async {
    final start = startTime ?? DateTime.now();
    try {
      final response = await this;
      final duration = DateTime.now().difference(start);

      LoggingService().logApiResponse(
        method: method,
        url: url,
        statusCode: response.statusCode,
        body: response.body,
        duration: duration,
      );

      return response;
    } catch (e, stack) {
      LoggingService().logApiError(
        method: method,
        url: url,
        exception: e,
        stackTrace: stack,
      );
      rethrow;
    }
  }
}
