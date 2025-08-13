import 'dart:async';
import 'package:flutter/material.dart';
import '../service/auth_service.dart';
import '../models/app_user.dart';
import '../models/user_status.dart';
import 'auth/login_screen.dart';
import 'home.dart';

/// Soddalashtirilgan ilova wrapper - smooth transition bilan
class AppWrapper extends StatefulWidget {
  const AppWrapper({super.key});

  @override
  State<AppWrapper> createState() => _AppWrapperState();
}

class _AppWrapperState extends State<AppWrapper> {
  final AuthService _authService = AuthService();

  UserStatus _currentStatus = UserStatus.checking;
  bool _isInitialized = false;

  // Stream subscriptions
  StreamSubscription<AppUser?>? _userSubscription;
  StreamSubscription<UserStatus>?
      _statusSubscription; // Minimal loading time ko'rsatish uchun

  @override
  void initState() {
    super.initState();
    _initializeServices();
  }

  Future<void> _initializeServices() async {
    try {
      // Optimized: Tez splash screen - 500ms
      Future.delayed(const Duration(milliseconds: 500), () {
        if (!mounted) return;
        // Faqat checking holatida bo'lsa login sahifasiga tushiramiz
        if (_currentStatus == UserStatus.checking) {
          setState(() {
            _currentStatus = UserStatus.unregistered;
            _isInitialized = true;
          });
          debugPrint('500ms splash tugadi - login sahifasiga o\'tish');
        } else if (!_isInitialized) {
          // Agar status allaqachon o'zgargan bo'lsa, faqat initialized ni yoqamiz
          setState(() {
            _isInitialized = true;
          });
        }
      });

      // Avval streamlarga yozilamiz
      _userSubscription = _authService.userStream.listen(_onUserChanged);
      _statusSubscription = _authService.statusStream.listen(_onStatusChanged);

      // Keyin AuthService ni ishga tushiramiz
      await _authService.initialize();

      // Agar foydalanuvchi allaqachon mavjud bo'lsa, darhol Home ga o'tkazamiz
      final existingUser = _authService.currentUser;
      if (mounted && existingUser != null) {
        debugPrint(
            'Mavjud user topildi: ${existingUser.email}, Home ga o\'tish...');
        setState(() {
          _currentStatus = UserStatus.active;
          _isInitialized = true;
        });
      } else {
        debugPrint('Mavjud user yo\'q, login sahifasiga o\'tish...');
      }

      debugPrint('AuthService background da tayyor');
    } catch (e) {
      debugPrint('Service initialization error: $e');
      // Xatolik bo'lsa ham login sahifasiga o'tish
      if (mounted) {
        setState(() {
          _currentStatus = UserStatus.unregistered;
          _isInitialized = true;
        });
      }
    }
  }

  // ChatGPT tavsiyasi: Asinxron ishlarni alohida metodda qilish
  void _loadDataInBackground() async {
    // Endi initializeServices ichida bajariladi
  }

  void _onUserChanged(AppUser? user) {
    if (!mounted) return;
    debugPrint('User o\'zgarishi: ${user?.email ?? 'null'}');
    // Fallback: agar status eventni o'tkazib yuborsak ham, user mavjud bo'lsa Home ga o'tamiz
    if (user != null) {
      debugPrint('User mavjud, Home ga o\'tish...');
      setState(() {
        _currentStatus = UserStatus.active;
        _isInitialized = true;
      });
    } else {
      debugPrint('User yo\'q, login sahifasiga o\'tish...');
      setState(() {
        _currentStatus = UserStatus.unregistered;
        _isInitialized = true;
      });
    }
  }

  void _onStatusChanged(UserStatus status) {
    if (mounted) {
      debugPrint('Status o\'zgarishi: $status');
      setState(() {
        _currentStatus = status;
        _isInitialized = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Service lar hali ishga tushmagan bo'lsa loading ko'rsatish
    if (!_isInitialized) {
      return _buildLoadingScreen('Ilova ishga tushirilmoqda...');
    }

    // Status ga qarab ekranni aniqlash - smooth transition bilan
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      transitionBuilder: (Widget child, Animation<double> animation) {
        return FadeTransition(
          opacity: animation,
          child: child,
        );
      },
      child: _buildScreenBasedOnStatus(),
    );
  }

  Widget _buildScreenBasedOnStatus() {
    switch (_currentStatus) {
      case UserStatus.unregistered:
      case UserStatus.disabled:
      case UserStatus.error:
        // Barcha xatolik va disabled holatlarda login sahifasiga yo'naltirish
        return const LoginScreen(key: ValueKey('login'));

      case UserStatus.active:
        return const HomeScreen();

      case UserStatus.checking:
        return _buildLoadingScreen('Hisobingiz holati tekshirilmoqda...',
            key: const ValueKey('checking'));
    }
  }

  Widget _buildLoadingScreen(String message, {Key? key}) {
    return Scaffold(
      key: key,
      backgroundColor: Colors.grey[50],
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo with animation - optimized
            TweenAnimationBuilder(
              duration: const Duration(milliseconds: 400),
              tween: Tween<double>(begin: 0.0, end: 1.0),
              builder: (context, double value, child) {
                return Transform.scale(
                  scale: value,
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.blue[800],
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.blue.withValues(alpha: 0.3),
                          blurRadius: 20,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.medical_services,
                      size: 60,
                      color: Colors.white,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 32),

            // App title with fade-in - optimized
            TweenAnimationBuilder(
              duration: const Duration(milliseconds: 500),
              tween: Tween<double>(begin: 0.0, end: 1.0),
              builder: (context, double value, child) {
                return Opacity(
                  opacity: value,
                  child: Text(
                    'StomoTrack',
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[800],
                      letterSpacing: 1.2,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 48),

            // Loading indicator
            SizedBox(
              width: 40,
              height: 40,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.blue[600]!),
              ),
            ),
            const SizedBox(height: 24),

            // Message with fade-in
            TweenAnimationBuilder(
              duration: const Duration(milliseconds: 1200),
              tween: Tween<double>(begin: 0.0, end: 1.0),
              builder: (context, double value, child) {
                return Opacity(
                  opacity: value,
                  child: Text(
                    message,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                );
              },
            ),

            // Progress dots animation
            const SizedBox(height: 32),
            _buildProgressDots(),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressDots() {
    return TweenAnimationBuilder(
      duration: const Duration(milliseconds: 1500),
      tween: Tween<double>(begin: 0.0, end: 1.0),
      builder: (context, double value, child) {
        return Opacity(
          opacity: value,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(3, (index) {
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: Colors.blue[300],
                  borderRadius: BorderRadius.circular(4),
                ),
              );
            }),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    // Stream subscriptions ni tozalash
    _userSubscription?.cancel();
    _statusSubscription?.cancel();
    super.dispose();
  }
}
