import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/app_user.dart';
import '../models/user_status.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final GoogleAuthProvider _googleProvider = GoogleAuthProvider();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final StreamController<AppUser?> _userController =
      StreamController<AppUser?>.broadcast();
  final StreamController<UserStatus> _statusController =
      StreamController<UserStatus>.broadcast();

  StreamSubscription<User?>? _authStateSubscription;

  Stream<AppUser?> get userStream => _userController.stream;
  Stream<UserStatus> get statusStream => _statusController.stream;

  AppUser? _currentUser;
  AppUser? get currentUser => _currentUser;

  Future<void> initialize() async {
    try {
      _authStateSubscription =
          _firebaseAuth.authStateChanges().listen(_onAuthStateChanged);

      final currentFirebaseUser = _firebaseAuth.currentUser;
      if (currentFirebaseUser != null) {
        _handleFirebaseUser(currentFirebaseUser);
      } else {
        _statusController.add(UserStatus.unregistered);
      }

      debugPrint('Firebase Auth service ishga tushdi');
    } catch (e) {
      debugPrint('Firebase initialize xatoligi: $e');
      _statusController.add(UserStatus.unregistered);
    }
  }

  Future<void> _onAuthStateChanged(User? firebaseUser) async {
    if (firebaseUser != null) {
      await _handleFirebaseUser(firebaseUser);
    } else {
      _currentUser = null;
      _userController.add(null);
      _statusController.add(UserStatus.unregistered);
    }
  }

  Future<void> _handleFirebaseUser(User? firebaseUser) async {
    if (firebaseUser == null) {
      _currentUser = null;
      _userController.add(null);
      _statusController.add(UserStatus.unregistered);
      return;
    }

    try {
      // Firestore-dan user document o‘qiladi
      final doc =
          await _firestore.collection('users').doc(firebaseUser.uid).get();
      bool isDisabled = false;
      if (doc.exists && doc.data() != null) {
        isDisabled = doc.data()!['disabled'] == true;
      }

      UserStatus status = isDisabled ? UserStatus.disabled : UserStatus.active;

      _currentUser = AppUser(
        uid: firebaseUser.uid,
        email: firebaseUser.email ?? '',
        displayName: firebaseUser.displayName ??
            firebaseUser.email?.split('@')[0] ??
            'Foydalanuvchi',
        status: status,
        isEmailVerified: firebaseUser.emailVerified,
        createdAt: DateTime.now(),
        lastLoginAt: DateTime.now(),
      );

      _userController.add(_currentUser);
      _statusController.add(status);

      debugPrint('Firebase user handle muvaffaqiyatli: ${_currentUser!.email}');
    } catch (e) {
      debugPrint('Firebase user handle xatoligi: $e');
      _statusController.add(UserStatus.error);
      throw Exception('Firebase Auth xatoligi: $e');
    }
  }

  Future<AppUser?> signInWithEmailAndPassword(
      String email, String password) async {
    try {
      final credential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user != null) {
        await _handleFirebaseUser(credential.user);
        debugPrint('Firebase login muvaffaqiyatli');
        return _currentUser;
      }

      return null;
    } catch (e) {
      debugPrint('Firebase login xatoligi: $e');
      _statusController.add(UserStatus.error);

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
      } else {
        throw Exception('Login xatoligi: Iltimos, qaytadan urinib ko\'ring.');
      }
    }
  }

  Future<AppUser?> registerWithEmailAndPassword(String email, String password,
      {String? displayName}) async {
    try {
      final credential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (displayName != null && credential.user != null) {
        await credential.user!.updateDisplayName(displayName);
      }

      // Firestore-ga yangi user document qo‘shish
      await _firestore.collection('users').doc(credential.user!.uid).set({
        'email': email,
        'displayName': displayName ?? '',
        'disabled': false,
        'createdAt': DateTime.now(),
      });

      if (credential.user != null) {
        await _handleFirebaseUser(credential.user);
        debugPrint('Firebase register muvaffaqiyatli');
        return _currentUser;
      }

      return null;
    } catch (e) {
      debugPrint('Firebase register xatoligi: $e');
      _statusController.add(UserStatus.error);

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
      } else {
        throw Exception(
            'Ro\'yxatdan o\'tish xatoligi: Iltimos, qaytadan urinib ko\'ring.');
      }
    }
  }

  Future<AppUser?> signInWithGoogle() async {
    try {
      _statusController.add(UserStatus.checking);

      if (kIsWeb) {
        final credential = await _firebaseAuth.signInWithPopup(_googleProvider);
        if (credential.user != null) {
          await _handleFirebaseUser(credential.user);
          return _currentUser;
        }
      } else {
        final credential =
            await _firebaseAuth.signInWithProvider(_googleProvider);
        if (credential.user != null) {
          await _handleFirebaseUser(credential.user);
          return _currentUser;
        }
      }

      throw Exception(
          'Google bilan kirish amalga oshmadi. Iltimos, qayta urinib ko\'ring.');
    } on FirebaseAuthException catch (e) {
      _statusController.add(UserStatus.error);

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
          throw Exception('Google bilan kirish xatoligi: ${e.code}');
      }
    } catch (e) {
      _statusController.add(UserStatus.error);
      throw Exception(e.toString());
    }
  }

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

  void dispose() {
    _authStateSubscription?.cancel();
    _userController.close();
    _statusController.close();
  }
}
