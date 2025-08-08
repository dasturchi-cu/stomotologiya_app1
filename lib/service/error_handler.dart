import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

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

  /// Firebase Auth xatoliklarini boshqarish
  String handleFirebaseAuthError(FirebaseAuthException e) {
    String message;

    switch (e.code) {
      case 'user-not-found':
        message = 'Bunday email bilan foydalanuvchi topilmadi.';
        break;
      case 'wrong-password':
        message = 'Noto\'g\'ri parol kiritildi.';
        break;
      case 'email-already-in-use':
        message = 'Bu email allaqachon ishlatilmoqda.';
        break;
      case 'weak-password':
        message = 'Parol juda zaif. Kamida 6 ta belgi kiriting.';
        break;
      case 'invalid-email':
        message = 'Noto\'g\'ri email formati.';
        break;
      case 'user-disabled':
        message = 'Sizning hisobingiz o\'chirilgan. To\'lov qiling.';
        break;
      case 'too-many-requests':
        message = 'Juda ko\'p urinish. Biroz kutib qayta urinib ko\'ring.';
        break;
      case 'operation-not-allowed':
        message = 'Bu operatsiya ruxsat etilmagan.';
        break;
      case 'invalid-credential':
        message = 'Noto\'g\'ri ma\'lumotlar kiritildi.';
        break;
      case 'account-exists-with-different-credential':
        message = 'Bu email boshqa usul bilan ro\'yxatdan o\'tgan.';
        break;
      case 'requires-recent-login':
        message = 'Bu operatsiya uchun qayta tizimga kirish talab qilinadi.';
        break;
      case 'network-request-failed':
        message = 'Internet aloqasi yo\'q. Ulanishni tekshiring.';
        break;
      default:
        message = 'Xatolik yuz berdi: ${e.message ?? "Noma\'lum xatolik"}';
    }

    _logError('FirebaseAuth', e.code, e.message ?? '');
    return message;
  }

  /// Firestore xatoliklarini boshqarish
  String handleFirestoreError(FirebaseException e) {
    String message;

    switch (e.code) {
      case 'permission-denied':
        message = 'Sizda bu operatsiya uchun ruxsat yo\'q.';
        break;
      case 'unavailable':
        message = 'Server vaqtincha ishlamayapti. Qayta urinib ko\'ring.';
        break;
      case 'deadline-exceeded':
        message = 'So\'rov vaqti tugadi. Qayta urinib ko\'ring.';
        break;
      case 'not-found':
        message = 'So\'ralgan ma\'lumot topilmadi.';
        break;
      case 'already-exists':
        message = 'Bu ma\'lumot allaqachon mavjud.';
        break;
      case 'resource-exhausted':
        message = 'Resurs cheklovi oshib ketdi. Keyinroq urinib ko\'ring.';
        break;
      case 'failed-precondition':
        message = 'Operatsiya uchun shart bajarilmagan.';
        break;
      case 'aborted':
        message = 'Operatsiya bekor qilindi. Qayta urinib ko\'ring.';
        break;
      case 'out-of-range':
        message = 'Noto\'g\'ri qiymat kiritildi.';
        break;
      case 'unimplemented':
        message = 'Bu funksiya hali ishlamaydi.';
        break;
      case 'internal':
        message = 'Ichki server xatoligi. Qayta urinib ko\'ring.';
        break;
      case 'data-loss':
        message = 'Ma\'lumotlar yo\'qoldi. Qayta urinib ko\'ring.';
        break;
      default:
        message =
            'Ma\'lumotlar bazasi xatoligi: ${e.message ?? "Noma\'lum xatolik"}';
    }

    _logError('Firestore', e.code, e.message ?? '');
    return message;
  }

  /// Umumiy xatoliklarni boshqarish
  String handleGeneralError(dynamic error) {
    String message;

    if (error is FirebaseAuthException) {
      return handleFirebaseAuthError(error);
    } else if (error is FirebaseException) {
      return handleFirestoreError(error);
    } else if (error is TimeoutException) {
      message = 'So\'rov vaqti tugadi. Internet aloqasini tekshiring.';
    } else if (error is FormatException) {
      message = 'Noto\'g\'ri ma\'lumot formati.';
    } else if (error.toString().contains('SocketException')) {
      message = 'Internet aloqasi yo\'q. Ulanishni tekshiring.';
    } else if (error.toString().contains('HandshakeException')) {
      message = 'Xavfsiz ulanish o\'rnatilmadi. Qayta urinib ko\'ring.';
    } else {
      message = 'Kutilmagan xatolik yuz berdi. Qayta urinib ko\'ring.';
    }

    _logError('General', 'unknown', error.toString());
    return message;
  }

  /// Foydalanuvchiga xabar ko'rsatish
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
    print('[$timestamp] ERROR [$source:$code]: $message');

    // Bu yerda xatoliklarni remote logging service ga yuborish mumkin
    // Masalan: Crashlytics, Sentry, yoki boshqa logging service
  }

  /// Service ni tozalash
  void dispose() {
    _messageController.close();
  }
}

/// Foydalanuvchi xabari modeli
class UserMessage {
  final String message;
  final MessageType type;
  final DateTime timestamp;

  const UserMessage({
    required this.message,
    required this.type,
    required this.timestamp,
  });
}

/// Xabar turlari
enum MessageType {
  success,
  error,
  warning,
  info,
}

/// MessageType uchun extension
extension MessageTypeExtension on MessageType {
  Color get color {
    switch (this) {
      case MessageType.success:
        return Colors.green;
      case MessageType.error:
        return Colors.red;
      case MessageType.warning:
        return Colors.orange;
      case MessageType.info:
        return Colors.blue;
    }
  }

  IconData get icon {
    switch (this) {
      case MessageType.success:
        return Icons.check_circle;
      case MessageType.error:
        return Icons.error;
      case MessageType.warning:
        return Icons.warning;
      case MessageType.info:
        return Icons.info;
    }
  }

  String get title {
    switch (this) {
      case MessageType.success:
        return 'Muvaffaqiyat';
      case MessageType.error:
        return 'Xatolik';
      case MessageType.warning:
        return 'Ogohlantirish';
      case MessageType.info:
        return 'Ma\'lumot';
    }
  }
}
