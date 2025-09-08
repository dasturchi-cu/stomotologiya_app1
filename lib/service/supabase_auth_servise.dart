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

      // Try to get user data from Supabase
      final response = await _supabase
          .from('users')
          .select()
          .eq('id', supabaseUser.id)
          .maybeSingle()
          .timeout(const Duration(seconds: 10));

      // If user doesn't exist in the database, try to create a new user (may fail due to RLS)
      if (response == null) {
        final newUser = {
          'id': supabaseUser.id,
          'email': supabaseUser.email,
          'display_name': supabaseUser.email?.split('@')[0] ?? 'User',
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
          'disabled': false,
        };

        try {
          await _supabase.from('users').insert(newUser);
        } catch (e) {
          // RLS may forbid client-side inserts; log and continue without failing
          debugPrint(
              'RLS prevented client insert into users table. Skipping. Error: $e');
        }

        _currentUser = AppUser(
          uid: supabaseUser.id,
          email: supabaseUser.email ?? '',
          displayName: supabaseUser.email?.split('@')[0] ?? 'User',
          status: UserStatus.active,
          isEmailVerified: supabaseUser.emailConfirmedAt != null,
          createdAt: DateTime.now(),
          lastLoginAt: DateTime.now(),
        );
      } else {
        // User exists, update last login time
        await _supabase.from('users').update({
          'last_login_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        }).eq('id', supabaseUser.id);

        _currentUser = AppUser(
          uid: supabaseUser.id,
          email: supabaseUser.email ?? '',
          displayName: response['display_name'] ??
              supabaseUser.email?.split('@')[0] ??
              'User',
          status: (response['disabled'] == true)
              ? UserStatus.disabled
              : UserStatus.active,
          isEmailVerified: supabaseUser.emailConfirmedAt != null,
          createdAt: response['created_at'] != null
              ? DateTime.tryParse(response['created_at']) ?? DateTime.now()
              : DateTime.now(),
          lastLoginAt: DateTime.now(),
        );
      }

      _userController.add(_currentUser);
      if (_currentUser != null) {
        _statusController.add(_currentUser!.status);
        debugPrint('User session updated: ${_currentUser!.email}');
      }
    } catch (e, stackTrace) {
      debugPrint('Error handling user session: $e');
      debugPrint('Stack trace: $stackTrace');

      // If there's an error, sign out to prevent invalid states
      try {
        await _auth.signOut();
      } catch (signOutError) {
        debugPrint('Error during sign out: $signOutError');
      }

      _currentUser = null;
      _userController.add(null);
      _statusController.add(UserStatus.unregistered);

      // Re-throw with a user-friendly message
      if (e is TimeoutException) {
        throw TimeoutException('Serverga ulanish vaqti tugadi. Iltimos, internet aloqasini tekshiring.');
      } else {
        throw Exception('Kirishda xatolik yuz berdi. Iltimos, qaytadan urinib ko\'ring.');
      }
    }
  }

  Future<AppUser> signInWithEmailAndPassword(String email, String password) async {
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
    try {
      final response = await _auth.signUp(
        email: email,
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
