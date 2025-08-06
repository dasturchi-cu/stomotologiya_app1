import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/app_user.dart';
import '../models/user_status.dart';
import 'error_handler.dart';

/// Firebase Authentication bilan ishlash uchun service
class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
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
    // Firebase Auth state o'zgarishlarini kuzatish
    _auth.authStateChanges().listen(_onAuthStateChanged);

    // Agar foydalanuvchi allaqachon tizimga kirgan bo'lsa
    if (_auth.currentUser != null) {
      await _onAuthStateChanged(_auth.currentUser);
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

      // Foydalanuvchi ma'lumotlarini Firestore da yangilash
      await _updateUserInFirestore(_currentUser!);
    } catch (e) {
      print('Auth state o\'zgarishida xatolik: $e');
      _statusController.add(UserStatus.error);
    }
  }

  /// Foydalanuvchi statusini tekshirish
  Future<UserStatus> _checkUserStatus(User firebaseUser) async {
    try {
      // Firebase Auth da foydalanuvchi disabled emasligini tekshirish
      await firebaseUser.reload();
      final refreshedUser = _auth.currentUser;

      if (refreshedUser == null) {
        return UserStatus.disabled;
      }

      // Firestore dan foydalanuvchi ma'lumotlarini olish
      final userDoc =
          await _firestore.collection('users').doc(firebaseUser.uid).get();

      if (!userDoc.exists) {
        // Yangi foydalanuvchi - faol deb belgilaymiz
        return UserStatus.active;
      }

      final userData = userDoc.data()!;
      final statusString = userData['status'] as String?;

      switch (statusString) {
        case 'active':
          return UserStatus.active;
        case 'disabled':
          return UserStatus.disabled;
        default:
          return UserStatus.active;
      }
    } catch (e) {
      print('Foydalanuvchi statusini tekshirishda xatolik: $e');
      return UserStatus.error;
    }
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

  /// Foydalanuvchi ma'lumotlarini Firestore da yangilash
  Future<void> _updateUserInFirestore(AppUser user) async {
    try {
      await _firestore
          .collection('users')
          .doc(user.uid)
          .set(user.toMap(), SetOptions(merge: true));
    } catch (e) {
      print(
          'Firestore da foydalanuvchi ma\'lumotlarini yangilashda xatolik: $e');
    }
  }

  /// Service ni tozalash
  void dispose() {
    _userController.close();
    _statusController.close();
  }
}
