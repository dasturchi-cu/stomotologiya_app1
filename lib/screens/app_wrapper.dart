import 'package:flutter/material.dart';
import '../service/auth_service.dart';
import '../models/app_user.dart';
import '../models/user_status.dart';
import 'auth/login_screen.dart';
import 'home.dart';

/// Asosiy ilova wrapper - authentication va payment enforcement ni boshqaradi
class AppWrapper extends StatefulWidget {
  const AppWrapper({super.key});

  @override
  State<AppWrapper> createState() => _AppWrapperState();
}

class _AppWrapperState extends State<AppWrapper> {
  final AuthService _authService = AuthService();

  AppUser? _currentUser;
  UserStatus _currentStatus = UserStatus.checking;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeServices();
  }

  Future<void> _initializeServices() async {
    try {
      // Auth service ni ishga tushirish
      await _authService.initialize();

      // Streamlarni kuzatish
      _authService.userStream.listen(_onUserChanged);
      _authService.statusStream.listen(_onStatusChanged);

      setState(() {
        _isInitialized = true;
      });
    } catch (e) {
      print('Service larni ishga tushirishda xatolik: $e');
      setState(() {
        _currentStatus = UserStatus.error;
        _isInitialized = true;
      });
    }
  }

  void _onUserChanged(AppUser? user) {
    if (mounted) {
      setState(() {
        _currentUser = user;
      });
    }
  }

  void _onStatusChanged(UserStatus status) {
    if (mounted) {
      setState(() {
        _currentStatus = status;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Service lar hali ishga tushmagan bo'lsa loading ko'rsatish
    if (!_isInitialized) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Ilova ishga tushirilmoqda...'),
            ],
          ),
        ),
      );
    }

    // Status ga qarab ekranni aniqlash
    return _buildScreenBasedOnStatus();
  }

  Widget _buildScreenBasedOnStatus() {
    switch (_currentStatus) {
      case UserStatus.unregistered:
        return const LoginScreen();

      case UserStatus.disabled:
        // Disabled bo'lsa login ekraniga qaytarish
        return const LoginScreen();

      case UserStatus.active:
        return HomeScreen();

      case UserStatus.checking:
        return _buildLoadingScreen('Hisobingiz holati tekshirilmoqda...');

      case UserStatus.error:
        return _buildErrorScreen();
    }
  }

  Widget _buildLoadingScreen(String message) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo
            Icon(
              Icons.medical_services,
              size: 80,
              color: Colors.blue[800],
            ),
            const SizedBox(height: 24),

            Text(
              'StomoTrack',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.blue[800],
              ),
            ),
            const SizedBox(height: 48),

            const CircularProgressIndicator(),
            const SizedBox(height: 16),

            Text(
              message,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorScreen() {
    return Scaffold(
      backgroundColor: Colors.red[50],
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 80,
                color: Colors.red[600],
              ),
              const SizedBox(height: 24),
              Text(
                'Xatolik yuz berdi',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.red[700],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Hisobingiz holatini tekshirishda xatolik yuz berdi.',
                style: TextStyle(
                  color: Colors.grey[700],
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    _isInitialized = false;
                  });
                  _initializeServices();
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Qayta urinish'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[600],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () async {
                  await _authService.signOut();
                },
                child: const Text('Tizimdan chiqish'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    // Service larni tozalash shart emas, chunki ular singleton
    super.dispose();
  }
}
