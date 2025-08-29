import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Xatolik xabari turlari
enum MessageType {
  success,
  error,
  warning,
  info,
}

/// Xabar modeli
class UserMessage {
  final String message;
  final MessageType type;
  final DateTime timestamp;

  UserMessage({
    required this.message,
    required this.type,
    required this.timestamp,
  });
}

/// Xatoliklarni boshqarish va foydalanuvchiga xabar berish service
class ErrorHandler {
  static final ErrorHandler _instance = ErrorHandler._internal();
  factory ErrorHandler() => _instance;
  ErrorHandler._internal();

  // Stream controller
  final StreamController<UserMessage> _messageController =
      StreamController<UserMessage>.broadcast();

  // Stream
  Stream<UserMessage> get messageStream => _messageController.stream;

  /// Handle Supabase Auth errors
  static String handleAuthError(dynamic error) {
    if (error is AuthException) {
      return _handleSupabaseAuthError(error);
    } else if (error is PostgrestException) {
      return _handlePostgrestError(error);
    } else if (error is String) {
      return error;
    } else if (error is Error) {
      return error.toString();
    } else {
      return 'Noma\'lum xatolik yuz berdi: ${error.toString()}';
    }
  }

  /// Handle Supabase Auth specific errors
  static String _handleSupabaseAuthError(AuthException e) {
    String message;

    switch (e.statusCode) {
      case '400':
        message = 'Noto\'g\'ri so\'rov formati';
        break;
      case '401':
        message = 'Kirish rad etildi. Iltimos, qaytadan kiring';
        break;
      case '403':
        message = 'Ruxsat rad etildi';
        break;
      case '404':
        message = 'Manzil topilmadi';
        break;
      case '422':
        message = 'Tekshirish xatoligi';
        break;
      case '500':
        message = 'Server xatosi';
        break;
      default:
        message = e.message;
    }

    return message;
  }

  /// Handle PostgREST errors
  static String _handlePostgrestError(PostgrestException e) {
    String message;

    switch (e.code) {
      case '23505':
        message = 'Bu ma\'lumot allaqachon mavjud';
        break;
      case '23503':
        message = 'Bog\'liq ma\'lumot topilmadi';
        break;
      case '23514':
        message = 'Ma\'lumotlar bazasi cheklovlari buzilgan';
        break;
      case '42P01':
        message = 'Jadval topilmadi';
        break;
      case '42501':
        message = 'Ruxsat yo\'q';
        break;
      default:
        message = e.message;
    }

    return message;
  }

  /// General error handler
  static void handleError(dynamic error, {StackTrace? stackTrace}) {
    debugPrint('Error: $error');
    if (stackTrace != null) {
      debugPrint('Stack trace: $stackTrace');
    }
    
    String errorMessage = 'Xatolik yuz berdi';
    
    if (error is AuthException || error is PostgrestException) {
      errorMessage = handleAuthError(error);
    } else if (error is TimeoutException) {
      errorMessage = 'So\'rov vaqti tugadi. Internet aloqasini tekshiring.';
    } else if (error is FormatException) {
      errorMessage = 'Noto\'g\'ri ma\'lumot formati.';
    } else if (error is String) {
      errorMessage = error;
    } else if (error is Error) {
      errorMessage = error.toString();
    }
    
    _instance._logError('App', error.runtimeType.toString(), error.toString());
    _instance._showError(errorMessage);
  }

  /// Xatolik xabarini ko'rsatish
  void _showError(String message) {
    final userMessage = UserMessage(
      message: message,
      type: MessageType.error,
      timestamp: DateTime.now(),
    );
    _messageController.add(userMessage);
  }

  /// Xabarlarni ko'rsatish uchun
  void showMessage(String message, {MessageType type = MessageType.info}) {
    final userMessage = UserMessage(
      message: message,
      type: type,
      timestamp: DateTime.now(),
    );
    _messageController.add(userMessage);
  }

  /// Muvaffaqiyat xabarini ko'rsatish
  void showSuccess(String message) {
    showMessage(message, type: MessageType.success);
  }

  /// Xatolik xabarini ko'rsatish
  void showError(String message) {
    showMessage(message, type: MessageType.error);
  }

  /// Ogohlantirish xabarini ko'rsatish
  void showWarning(String message) {
    showMessage(message, type: MessageType.warning);
  }

  /// Ma'lumot xabarini ko'rsatish
  void showInfo(String message) {
    showMessage(message, type: MessageType.info);
  }

  /// Xatolikni log qilish
  void _logError(String source, String code, String message) {
    final timestamp = DateTime.now().toIso8601String();
    debugPrint('[$timestamp] ERROR [$source:$code]: $message');
    
    // TODO: Add remote logging service integration (e.g., Sentry, Crashlytics)
  }

  /// Service ni tozalash
  void dispose() {
    _messageController.close();
  }
}
