import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/app_user.dart';
import '../models/user_status.dart';

// Extension to handle timeout on Future
extension FutureTimeoutExtension<T> on Future<T> {
  Future<T> timeoutAfter(Duration duration, {FutureOr<T> Function()? onTimeout}) {
    return timeout(duration, onTimeout: onTimeout);
  }
}

// Remove generated part file import as it's not needed

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  late final SupabaseClient _supabase;
  late final GoTrueClient _auth;

  final StreamController<AppUser?> _userController =
      StreamController<AppUser?>.broadcast();
  final StreamController<UserStatus> _statusController =
      StreamController<UserStatus>.broadcast();

  bool _isInitialized = false;

  StreamSubscription<AuthState>? _authStateSubscription;

  Stream<AppUser?> get userStream => _userController.stream;
  Stream<UserStatus> get statusStream => _statusController.stream;

  AppUser? _currentUser;
  AppUser? get currentUser => _currentUser;

  get user => null;

  Future<void> _ensureInitialized() async {
    if (!_isInitialized) {
      await initialize();
    }
  }

  Future<void> initialize() async {
    if (_isInitialized) {
      return;
    }
    _supabase = Supabase.instance.client;
    _auth = _supabase.auth;

    try {
      _authStateSubscription = _auth.onAuthStateChange.listen((authState) {
        final session = authState.session;
        if (session != null) {
          _handleSupabaseUser(session.user);
        } else {
          _currentUser = null;
          _userController.add(null);
          _statusController.add(UserStatus.unregistered);
        }
      });

      // Check for existing session first
      final currentSession = _auth.currentSession;
      if (currentSession != null) {
        debugPrint(
            'Existing session found, auto-logging in user: ${currentSession.user.email}');
        await _handleSupabaseUser(currentSession.user);
      } else {
        debugPrint('No existing session found');
        _statusController.add(UserStatus.unregistered);
      }

      _isInitialized = true;
      debugPrint('Supabase Auth service ishga tushdi');
    } catch (e) {
      debugPrint('Supabase initialize xatoligi: $e');
      _statusController.add(UserStatus.unregistered);
    }
  }

  Future<void> _handleSupabaseUser(User? supabaseUser) async {
    try {
      if (supabaseUser == null) {
        _currentUser = null;
        _userController.add(null);
        _statusController.add(UserStatus.unregistered);
        return;
      }

      Map<String, dynamic>? profile;
      try {
        profile = await _supabase
            .from('profiles')
            .select('display_name, disabled')
            .eq('id', supabaseUser.id)
            .maybeSingle()
            .timeout(const Duration(seconds: 8));
      } catch (e) {
        debugPrint('profiles not available/blocked, skipping. Error: $e');
        profile = null;
      }

      final disabled = profile != null && profile['disabled'] == true;
      final displayName = (profile != null ? profile['display_name'] : null) ??
          (supabaseUser.userMetadata?['display_name']) ??
          (supabaseUser.email?.split('@').first ?? 'User');

      _currentUser = AppUser(
        uid: supabaseUser.id,
        email: supabaseUser.email ?? '',
        displayName: displayName?.toString(),
        status: disabled ? UserStatus.disabled : UserStatus.active,
        isEmailVerified: supabaseUser.emailConfirmedAt != null,
        createdAt: DateTime.now(),
        lastLoginAt: DateTime.now(),
      );

      _userController.add(_currentUser);
      if (_currentUser != null) {
        _statusController.add(_currentUser!.status);
        debugPrint('User session updated: ${_currentUser!.email}');
      }
    } catch (e, stackTrace) {
      debugPrint('Error handling user session: $e');
      debugPrint('Stack trace: $stackTrace');

      // Re-throw with a user-friendly message (don't force sign-out for DB/table issues)
      if (e is TimeoutException) {
        throw TimeoutException('Serverga ulanish vaqti tugadi. Iltimos, internet aloqasini tekshiring.');
      } else {
        throw Exception('Kirishda xatolik yuz berdi. Iltimos, qaytadan urinib ko\'ring.');
      }
    }
  }

  Future<AppUser> signInWithEmailAndPassword(String email, String password) async {
    await _ensureInitialized();
    try {
      // Input validation
      if (email.isEmpty || password.isEmpty) {
        throw Exception('Iltimos, email va parolni kiriting');
      }

      debugPrint('Attempting to sign in with email: $email');
      
      final response = await _auth.signInWithPassword(
        email: email.trim(),
        password: password,
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw TimeoutException('Serverga ulanish vaqti tugadi. Iltimos, internet aloqasini tekshiring.');
        },
      );

      final user = response.user;
      if (user == null) {
        throw Exception('Kirish muvaffaqiyatsiz. Iltimos, qaytadan urinib ko\'ring.');
      }

      debugPrint('Supabase login muvaffaqiyatli: ${user.email}');
      
      // Handle the user session
      await _handleSupabaseUser(user);
      
      if (_currentUser == null) {
        throw Exception('Foydalanuvchi ma\'lumotlarini yuklashda xatolik yuz berdi');
      }
      
      debugPrint('User email verified: ${user.emailConfirmedAt != null}');
      return _currentUser!;
      
    } on TimeoutException catch (e) {
      debugPrint('Login timeout: $e');
      _statusController.add(UserStatus.error);
      throw Exception('Serverga ulanish vaqti tugadi. Iltimos, internet aloqasini tekshiring.');
      
    } on AuthException catch (e) {
      debugPrint('Auth error: ${e.message} (${e.statusCode})');
      _statusController.add(UserStatus.error);
      
      // Handle specific auth errors
      if (e.statusCode == '400') {
        if (e.message.contains('Invalid login credentials')) {
          throw Exception('Email yoki parol noto\'g\'ri. Iltimos, qaytadan urinib ko\'ring.');
        } else if (e.message.contains('Email not confirmed')) {
          throw Exception('Email tasdiqlanmagan. Iltimos, emailingizni tekshiring.');
        }
      } else if (e.statusCode == '429') {
        throw Exception('Juda ko\'p urinishlar. Iltimos, bir necha daqiqadan keyin qayta urinib ko\'ring.');
      }
      
      throw Exception('Kirish xatoligi: ${e.message}');
      
    } catch (e, stackTrace) {
      debugPrint('Login error: $e');
      debugPrint('Stack trace: $stackTrace');
      _statusController.add(UserStatus.error);
      
      if (e.toString().contains('network') || e.toString().contains('SocketException')) {
        throw Exception('Internet ulanishi yo\'q. Iltimos, ulanishni tekshiring.');
      } else if (e.toString().contains('timeout') || e is TimeoutException) {
        throw Exception('Serverga ulanish vaqti tugadi. Iltimos, keyinroq urinib ko\'ring.');
      } else {
        throw Exception('Kirishda xatolik yuz berdi. Iltimos, qaytadan urinib ko\'ring.');
      }
    }
  }

  Future<AppUser?> registerWithEmailAndPassword(String email, String password,
      {String? displayName}) async {
    await _ensureInitialized();
    try {
      final response = await _auth.signUp(
        email: email.trim(),
        password: password,
        data: {
          'display_name': displayName,
        },
      );

      if (response.user != null) {
        // Do not insert into 'users' here; RLS blocks client inserts.
        await _handleSupabaseUser(response.user);
        debugPrint('Supabase register muvaffaqiyatli');
        return _currentUser;
      }

      return null;
    } on AuthException catch (e) {
      debugPrint('Supabase register xatoligi: ${e.message} (${e.statusCode})');
      _statusController.add(UserStatus.error);

      if (e.statusCode == '429' ||
          e.message.toLowerCase().contains('rate limit') ||
          e.message.toLowerCase().contains('over_email_send_rate_limit')) {
        throw Exception(
            'Ko\'p urinish bo\'ldi (email limit). 10-30 daqiqa kuting yoki Supabase Auth’da "Confirm email" ni vaqtincha o\'chirib turing.');
      }
      if (e.message.contains('User already registered')) {
        throw Exception('Bu email allaqachon ishlatilgan. Login qiling.');
      }
      if (e.message.toLowerCase().contains('invalid email') ||
          e.message.toLowerCase().contains('email address') ||
          e.message.toLowerCase().contains('email_address_invalid')) {
        throw Exception('Email formati noto\'g\'ri. To\'g\'ri email kiriting.');
      }
      if (e.message.toLowerCase().contains('password')) {
        throw Exception('Parol juda zaif. Kamida 6 ta belgi kiriting.');
      }
      throw Exception('Ro\'yxatdan o\'tish xatoligi: ${e.message}');
    } catch (e) {
      debugPrint('Supabase register xatoligi: $e');
      _statusController.add(UserStatus.error);

      if (e.toString().contains('User already registered')) {
        // Attempt to log the user in if already registered
        try {
          await signInWithEmailAndPassword(email, password);
          return _currentUser;
        } catch (_) {
          throw Exception(
              'Bu email allaqachon ishlatilgan. Boshqa email kiriting yoki login qiling.');
        }
      } else if (e.toString().contains('Password should be at least')) {
        throw Exception('Parol juda zaif. Kamida 6 ta belgi kiriting.');
      } else if (e.toString().contains('Invalid email')) {
        throw Exception('Email formati noto\'g\'ri. To\'g\'ri email kiriting.');
      } else if (e.toString().contains('over_email_send_rate_limit') ||
          e.toString().contains('rate limit')) {
        throw Exception(
            'Ko\'p urinish bo\'ldi (email limit). 10-30 daqiqa kuting yoki Supabase Auth’da "Confirm email" ni vaqtincha o\'chirib turing.');
      } else if (e.toString().contains('network')) {
        throw Exception(
            'Internet ulanishi yo\'q. Iltimos, ulanishni tekshiring.');
      } else {
        throw Exception(
            'Ro\'yxatdan o\'tish xatoligi: Iltimos, qaytadan urinib ko\'ring.');
      }
    }
  }

  Future<AppUser?> signInWithGoogle() async {
    await _ensureInitialized();
    try {
      _statusController.add(UserStatus.checking);

      await _auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: kIsWeb ? null : 'io.supabase.flutter://login-callback/',
      );

      // OAuth flow will open in browser, result comes through authStateChange
      debugPrint('Google sign-in started');
      return null;
    } catch (e) {
      _statusController.add(UserStatus.error);

      if (e.toString().contains('OAuth error')) {
        throw Exception('Google autentifikatsiya xatoligi.');
      } else if (e.toString().contains('network')) {
        throw Exception('Internet ulanishi yo\'q. Ulanishni tekshiring.');
      } else {
        throw Exception('Google bilan kirish xatoligi: $e');
      }
    }
  }

  Future<void> signOut() async {
    await _ensureInitialized();
    try {
      await _auth.signOut();
      _currentUser = null;
      _userController.add(null);
      _statusController.add(UserStatus.unregistered);
      debugPrint('User signed out successfully');
    } catch (e, stackTrace) {
      debugPrint('Error signing out: $e');
      debugPrint('Stack trace: $stackTrace');
      _statusController.add(UserStatus.error);
      rethrow;
    }
  }

  Future<void> resetPassword(String email) async {
    await _ensureInitialized();
    try {
      await _auth.resetPasswordForEmail(email);
      debugPrint('Parol tiklash emaili yuborildi');
    } catch (e) {
      debugPrint('Password reset xatoligi: $e');
      throw Exception('Parol tiklash xatoligi: $e');
    }
  }

  void dispose() {
    _authStateSubscription?.cancel();
    _userController.close();
    _statusController.close();
  }
}
