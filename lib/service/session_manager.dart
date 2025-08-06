import 'dart:async';
import 'package:flutter/material.dart';
import '../models/user_status.dart';
import 'auth_service.dart';
import 'payment_enforcement_service.dart';

/// Foydalanuvchi sessiyasini boshqarish service
class SessionManager {
  static final SessionManager _instance = SessionManager._internal();
  factory SessionManager() => _instance;
  SessionManager._internal();

  final AuthService _authService = AuthService();
  final PaymentEnforcementService _paymentService = PaymentEnforcementService();

  // Session holati
  bool _isSessionActive = false;
  DateTime? _lastActivityTime;
  Timer? _sessionTimer;
  Timer? _inactivityTimer;

  // Session sozlamalari
  static const Duration _sessionTimeout = Duration(hours: 8); // 8 soat
  static const Duration _inactivityTimeout = Duration(minutes: 30); // 30 daqiqa
  static const Duration _checkInterval = Duration(minutes: 1); // Har daqiqada tekshirish

  // Stream controllerlar
  final StreamController<bool> _sessionController = StreamController<bool>.broadcast();
  final StreamController<String> _sessionMessageController = StreamController<String>.broadcast();

  // Streamlar
  Stream<bool> get sessionStream => _sessionController.stream;
  Stream<String> get sessionMessageStream => _sessionMessageController.stream;

  bool get isSessionActive => _isSessionActive;
  DateTime? get lastActivityTime => _lastActivityTime;

  /// Session manager ni ishga tushirish
  Future<void> initialize() async {
    // Auth service dan foydalanuvchi o'zgarishlarini kuzatish
    _authService.userStream.listen(_onUserChanged);
    _authService.statusStream.listen(_onStatusChanged);
  }

  /// Foydalanuvchi o'zgarganida
  void _onUserChanged(user) {
    if (user != null) {
      _startSession();
    } else {
      _endSession();
    }
  }

  /// Status o'zgarganida
  void _onStatusChanged(UserStatus status) {
    if (status == UserStatus.disabled || status == UserStatus.error) {
      _endSession(reason: 'Hisobingiz holati o\'zgargan.');
    }
  }

  /// Sessiyani boshlash
  void _startSession() {
    _isSessionActive = true;
    _lastActivityTime = DateTime.now();
    
    _sessionController.add(true);
    
    // Session timer ni boshlash
    _startSessionTimer();
    _startInactivityTimer();
    
    print('Session boshlandi: ${DateTime.now()}');
  }

  /// Sessiyani tugatish
  void _endSession({String? reason}) {
    _isSessionActive = false;
    _lastActivityTime = null;
    
    _sessionController.add(false);
    
    if (reason != null) {
      _sessionMessageController.add(reason);
    }
    
    // Timer larni to'xtatish
    _stopTimers();
    
    print('Session tugadi: ${DateTime.now()}, Sabab: ${reason ?? "Noma\'lum"}');
  }

  /// Session timer ni boshlash
  void _startSessionTimer() {
    _sessionTimer?.cancel();
    
    _sessionTimer = Timer.periodic(_checkInterval, (timer) {
      _checkSessionValidity();
    });
  }

  /// Inactivity timer ni boshlash
  void _startInactivityTimer() {
    _inactivityTimer?.cancel();
    
    _inactivityTimer = Timer(_inactivityTimeout, () {
      _handleInactivityTimeout();
    });
  }

  /// Session yaroqliligini tekshirish
  void _checkSessionValidity() {
    if (!_isSessionActive || _lastActivityTime == null) return;

    final now = DateTime.now();
    final sessionDuration = now.difference(_lastActivityTime!);

    // Session timeout tekshirish
    if (sessionDuration > _sessionTimeout) {
      _forceLogout('Sessiya vaqti tugadi. Qayta tizimga kiring.');
      return;
    }

    // Inactivity timeout tekshirish
    if (sessionDuration > _inactivityTimeout) {
      _handleInactivityTimeout();
    }
  }

  /// Inactivity timeout ni boshqarish
  void _handleInactivityTimeout() {
    _forceLogout('Faollik yo\'qligi sababli sessiya tugadi.');
  }

  /// Majburiy logout
  Future<void> _forceLogout(String reason) async {
    _endSession(reason: reason);
    await _paymentService.forceLogout(reason: reason);
  }

  /// Foydalanuvchi faolligini yangilash
  void updateActivity() {
    if (!_isSessionActive) return;

    _lastActivityTime = DateTime.now();
    
    // Inactivity timer ni qayta boshlash
    _startInactivityTimer();
  }

  /// Timer larni to'xtatish
  void _stopTimers() {
    _sessionTimer?.cancel();
    _sessionTimer = null;
    
    _inactivityTimer?.cancel();
    _inactivityTimer = null;
  }

  /// Qo'lda logout
  Future<void> logout() async {
    _endSession(reason: 'Foydalanuvchi tizimdan chiqdi.');
    await _authService.signOut();
  }

  /// Session ma'lumotlarini olish
  Map<String, dynamic> getSessionInfo() {
    return {
      'isActive': _isSessionActive,
      'lastActivity': _lastActivityTime?.toIso8601String(),
      'sessionDuration': _lastActivityTime != null 
          ? DateTime.now().difference(_lastActivityTime!).inMinutes
          : 0,
      'remainingTime': _lastActivityTime != null
          ? _sessionTimeout.inMinutes - DateTime.now().difference(_lastActivityTime!).inMinutes
          : 0,
    };
  }

  /// Session warning ko'rsatish
  bool shouldShowSessionWarning() {
    if (!_isSessionActive || _lastActivityTime == null) return false;

    final now = DateTime.now();
    final sessionDuration = now.difference(_lastActivityTime!);
    final remainingTime = _sessionTimeout - sessionDuration;

    // 5 daqiqa qolganda warning ko'rsatish
    return remainingTime.inMinutes <= 5 && remainingTime.inMinutes > 0;
  }

  /// Session ni uzaytirish
  void extendSession() {
    if (_isSessionActive) {
      updateActivity();
      _sessionMessageController.add('Session uzaytirildi.');
    }
  }

  /// Service ni tozalash
  void dispose() {
    _stopTimers();
    _sessionController.close();
    _sessionMessageController.close();
  }
}

/// Session activity tracker widget
class SessionActivityTracker extends StatefulWidget {
  final Widget child;
  
  const SessionActivityTracker({
    super.key,
    required this.child,
  });

  @override
  State<SessionActivityTracker> createState() => _SessionActivityTrackerState();
}

class _SessionActivityTrackerState extends State<SessionActivityTracker> {
  final SessionManager _sessionManager = SessionManager();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _sessionManager.updateActivity(),
      onPanUpdate: (_) => _sessionManager.updateActivity(),
      onScaleUpdate: (_) => _sessionManager.updateActivity(),
      child: widget.child,
    );
  }
}
