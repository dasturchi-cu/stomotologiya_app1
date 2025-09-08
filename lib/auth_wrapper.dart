import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:stomotologiya_app/screens/auth/login_screen_new.dart';
import 'package:stomotologiya_app/screens/home/home_screen.dart';

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  final _auth = Supabase.instance.client.auth;
  bool _isLoading = true;
  late Stream<AuthState> _authStateChanges;

  @override
  void initState() {
    super.initState();
    _authStateChanges = _auth.onAuthStateChange;
    _checkAuthState();
  }

  Future<void> _checkAuthState() async {
    try {
      // Check if there's a valid session
      final session = _auth.currentSession;
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error checking auth state: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: _authStateChanges,
      builder: (context, snapshot) {
        if (_isLoading) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        // Check if user is signed in
        final session = _auth.currentSession;
        
        if (session != null) {
          // User is signed in, show home screen
          return const HomeScreen();
        } else {
          // User is not signed in, show login screen
          return const LoginScreenNew();
        }
      },
    );
  }
}
