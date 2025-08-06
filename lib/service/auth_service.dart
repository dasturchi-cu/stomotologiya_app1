import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/app_user.dart';
import '../models/user_status.dart';
import 'error_handler.dart';

/// Firebase Authentication bilan ishlash uchun service
class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final ErrorHandler _errorHandler = ErrorHandler();

  // Stream controllerlar
  final StreamController<AppUser?> _userController =
      StreamController<AppUser?>.broadcast();
  final StreamController<UserStatus> _statusController =
      StreamController<UserStatus>.broadcast();

  // Streamlar
  Stream<AppUser?> get userStream => _userController.stream;
  Stream<UserStatus> get statusStream => _statusController.stream;

  // Hozirgi foydalanuvchi
  AppUser? _currentUser;
  AppUser? get currentUser => _currentUser;

  /// Service ni ishga tushirish
  Future<void> initialize() async {
    try {
      // Firebase Auth state o'zgarishlarini kuzatish
      _auth.authStateChanges().listen(_onAuthStateChanged);

      // Agar foydalanuvchi allaqachon tizimga kirgan bo'lsa
      if (_auth.currentUser != null) {
        await _onAuthStateChanged(_auth.currentUser);
      } else {
        // Foydalanuvchi yo'q bo'lsa darhol unregistered status berish
        _currentUser = null;
        _userController.add(null);
        _statusController.add(UserStatus.unregistered);
      }
    } catch (e) {
      // Firebase bilan ulanish muammosi bo'lsa
      print('Firebase Auth initialize xatoligi: $e');
      _currentUser = null;
      _userController.add(null);
      _statusController.add(UserStatus.unregistered);
    }
  }

  /// Auth state o'zgarishini boshqarish
  Future<void> _onAuthStateChanged(User? firebaseUser) async {
    if (firebaseUser == null) {
      _currentUser = null;
      _userController.add(null);
      _statusController.add(UserStatus.unregistered);
      return;
    }

    try {
      // Foydalanuvchi statusini tekshirish
      _statusController.add(UserStatus.checking);

      final userStatus = await _checkUserStatus(firebaseUser);
      _currentUser = AppUser.fromFirebaseUser(firebaseUser, status: userStatus);

      _userController.add(_currentUser);
      _statusController.add(userStatus);

      // Foydalanuvchi ma'lumotlari tayyor
    } catch (e) {
      print('Auth state o\'zgarishida xatolik: $e');
      _statusController.add(UserStatus.error);
    }
  }

  /// Foydalanuvchi statusini tekshirish
  Future<UserStatus> _checkUserStatus(User firebaseUser) async {
    try {
      // 5 soniya timeout bilan Firebase Auth statusini tekshirish
      final result = await _checkAuthWithTimeout(firebaseUser);
      return result;
    } catch (e) {
      print('Foydalanuvchi statusini tekshirishda xatolik: $e');
      // Firebase Auth xatoligi bo'lsa, disabled bo'lishi mumkin
      if (e.toString().contains('user-disabled') ||
          e.toString().contains('account-disabled')) {
        return UserStatus.disabled;
      }
      // Boshqa xatoliklarda active deb hisoblaymiz
      return UserStatus.active;
    }
  }

  /// Timeout bilan auth tekshirish
  Future<UserStatus> _checkAuthWithTimeout(User firebaseUser) async {
    try {
      return await Future.any([
        _performAuthCheck(firebaseUser),
        Future.delayed(Duration(seconds: 5)).then((_) {
          print('Firebase ulanish timeout - offline rejimda active');
          return UserStatus.active;
        }),
      ]);
    } catch (e) {
      return UserStatus.active;
    }
  }

  /// Auth tekshirish
  Future<UserStatus> _performAuthCheck(User firebaseUser) async {
    // Firebase Auth da foydalanuvchi disabled emasligini tekshirish
    await firebaseUser.reload();
    final refreshedUser = _auth.currentUser;

    if (refreshedUser == null) {
      // Foydalanuvchi disabled yoki o'chirilgan
      return UserStatus.disabled;
    }

    // Agar Firebase Auth da faol bo'lsa, active deb hisoblaymiz
    return UserStatus.active;
  }

  /// Email va parol bilan kirish
  Future<AppUser?> signInWithEmailAndPassword(
      String email, String password) async {
    try {
      _statusController.add(UserStatus.checking);

      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user != null) {
        // Auth state listener avtomatik ravishda ishga tushadi
        return _currentUser;
      }

      return null;
    } on FirebaseAuthException catch (e) {
      _statusController.add(UserStatus.error);
      throw _errorHandler.handleFirebaseAuthError(e);
    }
  }

  /// Email va parol bilan ro'yxatdan o'tish
  Future<AppUser?> registerWithEmailAndPassword(String email, String password,
      {String? displayName}) async {
    try {
      _statusController.add(UserStatus.checking);

      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user != null && displayName != null) {
        await credential.user!.updateDisplayName(displayName);
      }

      // Auth state listener avtomatik ravishda ishga tushadi
      return _currentUser;
    } on FirebaseAuthException catch (e) {
      _statusController.add(UserStatus.error);
      throw _errorHandler.handleFirebaseAuthError(e);
    }
  }

  /// Tizimdan chiqish
  Future<void> signOut() async {
    await _auth.signOut();
    _currentUser = null;
    _userController.add(null);
    _statusController.add(UserStatus.unregistered);
  }

  /// Service ni tozalash
  void dispose() {
    _userController.close();
    _statusController.close();
  }
}
