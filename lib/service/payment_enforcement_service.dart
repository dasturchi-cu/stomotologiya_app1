import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/app_user.dart';
import '../models/user_status.dart';
import 'auth_service.dart';

/// Soddalashtirilgan to'lov majburlash service - faqat Firebase Auth bilan ishlaydi
class PaymentEnforcementService {
  static final PaymentEnforcementService _instance = PaymentEnforcementService._internal();
  factory PaymentEnforcementService() => _instance;
  PaymentEnforcementService._internal();

  final AuthService _authService = AuthService();

  // Stream controllerlar
  final StreamController<bool> _accessController = StreamController<bool>.broadcast();
  final StreamController<String?> _messageController = StreamController<String?>.broadcast();

  // Streamlar
  Stream<bool> get accessStream => _accessController.stream;
  Stream<String?> get messageStream => _messageController.stream;

  // Status monitoring
  Timer? _statusCheckTimer;

  bool _hasAccess = false;
  String? _blockMessage;

  bool get hasAccess => _hasAccess;
  String? get blockMessage => _blockMessage;

  /// Service ni ishga tushirish
  Future<void> initialize() async {
    // Auth service dan foydalanuvchi o'zgarishlarini kuzatish
    _authService.userStream.listen(_onUserChanged);
    _authService.statusStream.listen(_onStatusChanged);
  }

  /// Foydalanuvchi o'zgarganida
  void _onUserChanged(AppUser? user) {
    if (user == null) {
      _stopStatusMonitoring();
      _updateAccess(false, 'Tizimga kirish talab qilinadi.');
      return;
    }

    _startStatusMonitoring();
  }

  /// Status o'zgarganida
  void _onStatusChanged(UserStatus status) {
    switch (status) {
      case UserStatus.active:
        _updateAccess(true, null);
        break;
      case UserStatus.disabled:
        _updateAccess(false, 'Sizning hisobingiz o\'chirilgan. Davom etish uchun to\'lov qiling.');
        break;
      case UserStatus.unregistered:
        _updateAccess(false, 'Ilovadan foydalanish uchun ro\'yxatdan o\'ting.');
        break;
      case UserStatus.checking:
        _updateAccess(false, 'Hisobingiz holati tekshirilmoqda...');
        break;
      case UserStatus.error:
        _updateAccess(false, 'Hisobingiz holatini tekshirishda xatolik yuz berdi.');
        break;
    }
  }

  /// Status monitoring ni boshlash
  void _startStatusMonitoring() {
    _stopStatusMonitoring();

    // Har 30 soniyada Firebase Auth statusini tekshirish
    _statusCheckTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _checkFirebaseAuthStatus();
    });
  }

  /// Firebase Auth statusini tekshirish
  Future<void> _checkFirebaseAuthStatus() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        _updateAccess(false, 'Tizimga kirish talab qilinadi.');
        return;
      }

      // Foydalanuvchi ma'lumotlarini yangilash
      await currentUser.reload();
      final refreshedUser = FirebaseAuth.instance.currentUser;

      if (refreshedUser == null) {
        // Foydalanuvchi o'chirilgan
        _updateAccess(false, 'Sizning hisobingiz o\'chirilgan. Davom etish uchun to\'lov qiling.');
        await _authService.signOut();
      }
    } catch (e) {
      print('Firebase Auth statusini tekshirishda xatolik: $e');
      if (e.toString().contains('user-disabled')) {
        _updateAccess(false, 'Sizning hisobingiz o\'chirilgan. Davom etish uchun to\'lov qiling.');
        await _authService.signOut();
      }
    }
  }

  /// Status monitoring ni to'xtatish
  void _stopStatusMonitoring() {
    _statusCheckTimer?.cancel();
    _statusCheckTimer = null;
  }

  /// Access holatini yangilash
  void _updateAccess(bool hasAccess, String? message) {
    _hasAccess = hasAccess;
    _blockMessage = message;
    
    _accessController.add(hasAccess);
    _messageController.add(message);
  }

  /// Foydalanuvchini majburiy chiqarish
  Future<void> forceLogout({String? reason}) async {
    _updateAccess(false, reason ?? 'Sizning sessiyangiz tugadi.');
    await _authService.signOut();
  }

  /// Service ni tozalash
  void dispose() {
    _stopStatusMonitoring();
    _accessController.close();
    _messageController.close();
  }
}
