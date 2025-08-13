import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/app_user.dart';
import '../models/user_status.dart';

/// Firebase Authentication service
class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  // Firebase instances
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final GoogleAuthProvider _googleProvider = GoogleAuthProvider();

  // Stream controllerlar
  final StreamController<AppUser?> _userController =
      StreamController<AppUser?>.broadcast();
  final StreamController<UserStatus> _statusController =
      StreamController<UserStatus>.broadcast();

  // Firebase auth state subscription
  StreamSubscription<User?>? _authStateSubscription;

  // Streamlar
  Stream<AppUser?> get userStream => _userController.stream;
  Stream<UserStatus> get statusStream => _statusController.stream;

  // Hozirgi foydalanuvchi
  AppUser? _currentUser;
  AppUser? get currentUser => _currentUser;

  /// Service ni ishga tushirish - Firebase only
  Future<void> initialize() async {
    try {
      // Firebase Auth state ni eshitish
      _authStateSubscription =
          _firebaseAuth.authStateChanges().listen(_onAuthStateChanged);

      // Hozirgi foydalanuvchini tekshirish (tez)
      final currentFirebaseUser = _firebaseAuth.currentUser;
      if (currentFirebaseUser != null) {
        // Background da handle qilish - UI ni bloklamaslik uchun
        _handleFirebaseUser(currentFirebaseUser);
      } else {
        _statusController.add(UserStatus.unregistered);
      }

      debugPrint('Firebase Auth service ishga tushdi');
    } catch (e) {
      debugPrint('Firebase initialize xatoligi: $e');
      // API key xatoligi bo'lsa ham login sahifasiga o'tish
      if (e.toString().contains('API key') ||
          e.toString().contains('firebase_auth')) {
        debugPrint(
            'Firebase API key muammosi - SHA-256 fingerprint qo\'shish kerak');
        debugPrint(
            'SHA-256: 4C:A3:8E:84:FA:6C:5A:E0:53:1B:61:1F:BD:77:57:CA:3A:8A:5F:2D:6A:E9:59:63:0A:FC:DF:1F:F3:71:E2:0A');
      }
      _statusController.add(UserStatus.unregistered);
    }
  }

  /// Firebase auth state o'zgarishini boshqarish
  Future<void> _onAuthStateChanged(User? firebaseUser) async {
    if (firebaseUser != null) {
      await _handleFirebaseUser(firebaseUser);
    } else {
      _currentUser = null;
      _userController.add(null);
      _statusController.add(UserStatus.unregistered);
    }
  }

  /// Firebase foydalanuvchisini AppUser ga aylantirish (Firestore siz)
  Future<void> _handleFirebaseUser(User? firebaseUser) async {
    if (firebaseUser == null) {
      _currentUser = null;
      _userController.add(null);
      _statusController.add(UserStatus.unregistered);
      return;
    }

    try {
      // Faqat Firebase Auth ma'lumotlaridan foydalanish
      _currentUser = AppUser(
        uid: firebaseUser.uid,
        email: firebaseUser.email ?? '',
        displayName: firebaseUser.displayName ??
            firebaseUser.email?.split('@')[0] ??
            'Foydalanuvchi',
        status: UserStatus.active, // Har doim active
        isEmailVerified: firebaseUser.emailVerified,
        createdAt: DateTime.now(),
        lastLoginAt: DateTime.now(),
      );

      _userController.add(_currentUser);
      _statusController.add(UserStatus.active);

      debugPrint('Firebase user handle muvaffaqiyatli: ${_currentUser!.email}');
    } catch (e) {
      debugPrint('Firebase user handle xatoligi: $e');
      _statusController.add(UserStatus.error);
      throw Exception('Firebase Auth xatoligi: $e');
    }
  }

  /// Email va parol bilan kirish - Firebase only
  Future<AppUser?> signInWithEmailAndPassword(
      String email, String password) async {
    try {
      final credential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Firebase user mavjud bo'lsa, _handleFirebaseUser avtomatik chaqiriladi
      if (credential.user != null) {
        debugPrint('Firebase login muvaffaqiyatli');
        return _currentUser;
      }

      return null;
    } catch (e) {
      debugPrint('Firebase login xatoligi: $e');

      _statusController.add(UserStatus.error);

      // Xatolik turini aniqlash
      if (e.toString().contains('invalid-credential')) {
        throw Exception(
            'Email yoki parol noto\'g\'ri. Iltimos, qaytadan urinib ko\'ring.');
      } else if (e.toString().contains('user-not-found')) {
        throw Exception(
            'Bu email bilan foydalanuvchi topilmadi. Avval ro\'yxatdan o\'ting.');
      } else if (e.toString().contains('wrong-password')) {
        throw Exception(
            'Parol noto\'g\'ri. Iltimos, to\'g\'ri parolni kiriting.');
      } else if (e.toString().contains('too-many-requests')) {
        throw Exception(
            'Juda ko\'p urinish. Iltimos, keyinroq urinib ko\'ring.');
      } else if (e.toString().contains('network-request-failed')) {
        throw Exception(
            'Internet ulanishi yo\'q. Iltimos, ulanishni tekshiring.');
      } else if (e.toString().contains('API key')) {
        throw Exception(
            'Firebase konfiguratsiya xatoligi. SHA-256 fingerprint qo\'shilmagan.');
      } else {
        throw Exception('Login xatoligi: Iltimos, qaytadan urinib ko\'ring.');
      }
    }
  }

  /// Email va parol bilan ro'yxatdan o'tish - Firebase only
  Future<AppUser?> registerWithEmailAndPassword(String email, String password,
      {String? displayName}) async {
    try {
      final credential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Display name ni o'rnatish
      if (displayName != null && credential.user != null) {
        await credential.user!.updateDisplayName(displayName);
      }

      // Firebase user mavjud bo'lsa, _handleFirebaseUser avtomatik chaqiriladi
      if (credential.user != null) {
        debugPrint('Firebase register muvaffaqiyatli');
        return _currentUser;
      }

      return null;
    } catch (e) {
      debugPrint('Firebase register xatoligi: $e');

      _statusController.add(UserStatus.error);

      // Xatolik turini aniqlash
      if (e.toString().contains('email-already-in-use')) {
        throw Exception(
            'Bu email allaqachon ishlatilgan. Boshqa email kiriting yoki login qiling.');
      } else if (e.toString().contains('weak-password')) {
        throw Exception('Parol juda zaif. Kamida 6 ta belgi kiriting.');
      } else if (e.toString().contains('invalid-email')) {
        throw Exception('Email formati noto\'g\'ri. To\'g\'ri email kiriting.');
      } else if (e.toString().contains('network-request-failed')) {
        throw Exception(
            'Internet ulanishi yo\'q. Iltimos, ulanishni tekshiring.');
      } else if (e.toString().contains('API key')) {
        throw Exception(
            'Firebase konfiguratsiya xatoligi. SHA-256 fingerprint qo\'shilmagan.');
      } else {
        throw Exception(
            'Ro\'yxatdan o\'tish xatoligi: Iltimos, qaytadan urinib ko\'ring.');
      }
    }
  }

  /// Google bilan kirish - Firebase Auth (provider-based)
  Future<AppUser?> signInWithGoogle() async {
    try {
      _statusController.add(UserStatus.checking);

      // Web: popup, Mobile/Desktop: provider
      if (kIsWeb) {
        final credential = await _firebaseAuth.signInWithPopup(_googleProvider);
        if (credential.user != null) {
          return _currentUser;
        }
      } else {
        final credential =
            await _firebaseAuth.signInWithProvider(_googleProvider);
        if (credential.user != null) {
          return _currentUser;
        }
      }

      throw Exception(
          'Google bilan kirish amalga oshmadi. Iltimos, qayta urinib ko\'ring.');
    } on FirebaseAuthException catch (e) {
      _statusController.add(UserStatus.error);

      // Mashhur xatoliklarni tarjima qilish
      switch (e.code) {
        case 'account-exists-with-different-credential':
          throw Exception(
              'Ushbu email boshqa provider bilan bog\'langan. Avval o\'sha usulda kiring.');
        case 'invalid-credential':
          throw Exception(
              'Google hisob ma\'lumotlari noto\'g\'ri yoki muddati o\'tgan.');
        case 'operation-not-allowed':
          throw Exception(
              'Google bilan kirish o\'chirilgan. Admin bilan bog\'laning.');
        case 'user-disabled':
          throw Exception('Hisobingiz o\'chirilgan.');
        case 'network-request-failed':
          throw Exception('Internet ulanishi yo\'q. Ulanishni tekshiring.');
        default:
          final message = e.message ?? '';
          if (message.contains('DEVELOPER_ERROR') || message.contains('10:')) {
            throw Exception(
                'Google OAuth konfiguratsiyasi kerak. Firebase konsolida Android ilovasi uchun SHA-1 va SHA-256 fingerprintlarni qo\'shing va Google Sign-In ni yoqing.');
          }
          throw Exception('Google bilan kirish xatoligi: ${e.code}');
      }
    } catch (e) {
      _statusController.add(UserStatus.error);
      throw Exception(e.toString());
    }
  }

  /// Tizimdan chiqish - Firebase only
  Future<void> signOut() async {
    try {
      await Future.wait([
        _firebaseAuth.signOut(),
      ]);

      _currentUser = null;
      _userController.add(null);
      _statusController.add(UserStatus.unregistered);

      debugPrint('Tizimdan muvaffaqiyatli chiqildi');
    } catch (e) {
      debugPrint('SignOut xatoligi: $e');
      _statusController.add(UserStatus.error);
      throw Exception('SignOut xatoligi: $e');
    }
  }

  /// Service ni tozalash
  void dispose() {
    _authStateSubscription?.cancel();
    _userController.close();
    _statusController.close();
  }
}
