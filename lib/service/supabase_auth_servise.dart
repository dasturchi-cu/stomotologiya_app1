import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/app_user.dart';
import '../models/user_status.dart';

// Remove generated part file import as it's not needed

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  late final SupabaseClient _supabase;
  late final GoTrueClient _auth;
  
  Future<void> initializeService() async {
    try {
      // Initialize Supabase if not already initialized
      if (!Supabase.instance.isInitialized) {
        await Supabase.initialize(
          url: 'YOUR_SUPABASE_URL',
          anonKey: 'YOUR_SUPABASE_ANON_KEY',
        );
      }
      
      _supabase = Supabase.instance.client;
      _auth = _supabase.auth;
      
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

      final currentSession = _auth.currentSession;
      if (currentSession != null) {
        await _handleSupabaseUser(currentSession.user);
      } else {
        _statusController.add(UserStatus.unregistered);
      }

      debugPrint('Supabase Auth service ishga tushdi');
    } catch (e) {
      debugPrint('Supabase initialize xatoligi: $e');
      _statusController.add(UserStatus.unregistered);
      rethrow;
    }
  }

  final StreamController<AppUser?> _userController =
  StreamController<AppUser?>.broadcast();
  final StreamController<UserStatus> _statusController =
  StreamController<UserStatus>.broadcast();

  StreamSubscription<AuthState>? _authStateSubscription;

  Stream<AppUser?> get userStream => _userController.stream;
  Stream<UserStatus> get statusStream => _statusController.stream;

  AppUser? _currentUser;
  AppUser? get currentUser => _currentUser;

  Future<void> initialize() async {
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

      final currentSession = _auth.currentSession;
      if (currentSession != null) {
        await _handleSupabaseUser(currentSession.user);
      } else {
        _statusController.add(UserStatus.unregistered);
      }

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

      // If user doesn't exist in the database, create a new user
      if (response == null) {
        final newUser = {
          'id': supabaseUser.id,
          'email': supabaseUser.email,
          'display_name': supabaseUser.email?.split('@')[0] ?? 'User',
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
          'disabled': false,
        };

        await _supabase.from('users').insert(newUser);
        
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
        await _supabase
            .from('users')
            .update({
              'last_login_at': DateTime.now().toIso8601String(),
              'updated_at': DateTime.now().toIso8601String(),
            })
            .eq('id', supabaseUser.id);

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
      _statusController.add(_currentUser!.status);

      debugPrint('User session updated: ${_currentUser!.email}');
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
      
      // Re-throw the error if it's a critical error
      if (e is! TimeoutException) {
        rethrow;
      }
    }
  }

  Future<AppUser?> signInWithEmailAndPassword(
      String email, String password) async {
    try {
      final response = await _auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user != null) {
        await _handleSupabaseUser(response.user);
        debugPrint('Supabase login muvaffaqiyatli');
        return _currentUser;
      }

      return null;
    } catch (e) {
      debugPrint('Supabase login xatoligi: $e');
      _statusController.add(UserStatus.error);

      if (e.toString().contains('Invalid login credentials')) {
        throw Exception(
            'Email yoki parol noto\'g\'ri. Iltimos, qaytadan urinib ko\'ring.');
      } else if (e.toString().contains('Email not confirmed')) {
        throw Exception(
            'Email tasdiqlanmagan. Iltimos, emailingizni tekshiring.');
      } else if (e.toString().contains('too many requests')) {
        throw Exception(
            'Juda ko\'p urinish. Iltimos, keyinroq urinib ko\'ring.');
      } else if (e.toString().contains('network')) {
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
      final response = await _auth.signUp(
        email: email,
        password: password,
        data: {
          'display_name': displayName,
        },
      );

      if (response.user != null) {
        // Yangi user ma'lumotlarini users jadvaliga qo'shish
        await _supabase
          .from('users')
          .insert({
            'id': response.user!.id,
            'email': email,
            'display_name': displayName ?? '',
            'disabled': false,
            'created_at': DateTime.now().toIso8601String(),
          });

        await _handleSupabaseUser(response.user);
        debugPrint('Supabase register muvaffaqiyatli');
        return _currentUser;
      }

      return null;
    } catch (e) {
      debugPrint('Supabase register xatoligi: $e');
      _statusController.add(UserStatus.error);

      if (e.toString().contains('User already registered')) {
        throw Exception(
            'Bu email allaqachon ishlatilgan. Boshqa email kiriting yoki login qiling.');
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

      debugPrint('Tizimdan muvaffaqiyatli chiqildi');
    } catch (e) {
      debugPrint('SignOut xatoligi: $e');
      _statusController.add(UserStatus.error);
      throw Exception('SignOut xatoligi: $e');
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