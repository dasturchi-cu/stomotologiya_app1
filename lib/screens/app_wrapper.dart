import 'dart:async';
import 'package:flutter/material.dart';
import 'package:stomotologiya_app/payment/payment.dart';
import '../service/supabase_auth_servise.dart';
import '../models/app_user.dart';
import '../models/user_status.dart';
import 'auth/login_screen.dart';
import 'home.dart';

class AppWrapper extends StatefulWidget {
  const AppWrapper({super.key});

  @override
  State<AppWrapper> createState() => _AppWrapperState();
}

class _AppWrapperState extends State<AppWrapper> {
  final AuthService _authService = AuthService();

  UserStatus _currentStatus = UserStatus.checking;
  bool _isInitialized = false;

  StreamSubscription<AppUser?>? _userSubscription;
  StreamSubscription<UserStatus>? _statusSubscription;

  @override
  void initState() {
    super.initState();
    _initializeServices();
  }

  Future<void> _initializeServices() async {
    try {
      Future.delayed(const Duration(milliseconds: 500), () {
        if (!mounted) return;
        if (_currentStatus == UserStatus.checking) {
          setState(() {
            _currentStatus = UserStatus.unregistered;
            _isInitialized = true;
          });
        } else if (!_isInitialized) {
          setState(() {
            _isInitialized = true;
          });
        }
      });

      _userSubscription = _authService.userStream.listen(_onUserChanged);
      _statusSubscription = _authService.statusStream.listen(_onStatusChanged);

      await _authService.initialize();

      final existingUser = _authService.currentUser;
      if (mounted && existingUser != null) {
        setState(() {
          _currentStatus = UserStatus.active;
          _isInitialized = true;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _currentStatus = UserStatus.unregistered;
          _isInitialized = true;
        });
      }
    }
  }

  void _onUserChanged(AppUser? user) {
    if (!mounted) return;
    if (user != null) {
      setState(() {
        _currentStatus = UserStatus.active;
        _isInitialized = true;
      });
    } else {
      setState(() {
        _currentStatus = UserStatus.unregistered;
        _isInitialized = true;
      });
    }
  }

  void _onStatusChanged(UserStatus status) {
    if (mounted) {
      setState(() {
        _currentStatus = status;
        _isInitialized = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return _buildLoadingScreen('Ilova ishga tushirilmoqda...');
    }

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
      case UserStatus.error:
        return const LoginScreen(key: ValueKey('login'));
      case UserStatus.disabled:
        return const PaymentScreen(key: ValueKey('payment'));
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
                          color: Colors.blue.withOpacity(0.3),
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
            SizedBox(
              width: 40,
              height: 40,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.blue[600]!),
              ),
            ),
            const SizedBox(height: 24),
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
    _userSubscription?.cancel();
    _statusSubscription?.cancel();
    super.dispose();
  }
}
