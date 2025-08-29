import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../service/supabase_storage_service.dart';
import '../../routes.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _storageService = SupabaseStorageService();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _isLogin = true;
  String? _errorMessage;

  void _toggleAuthMode() {
    setState(() {
      _isLogin = !_isLogin;
      _errorMessage = null;
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text;

      if (_isLogin) {
        // Sign in
        await _storageService.signInWithEmail(email, password);
      } else {
        // Sign up
        await _storageService.signUpWithEmail(email, password);
      }

      if (mounted) {
Navigator.of(context).pushReplacementNamed(AppRoutes.home);
      }
    } on AuthException catch (e) {
      setState(() {
        _errorMessage = e.message;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Xatolik yuz berdi: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Future<void> _signInWithGoogle() async {
  //   setState(() {
  //     _isLoading = true;
  //     _errorMessage = null;
  //   });

  //   try {
  //     // TODO: Implement Google Sign In with Supabase
  //     // await _supabase.auth.signInWithOAuth(Provider.google);
  //   } catch (e) {
  //     if (mounted) {
  //       setState(() {
  //         _errorMessage = e.toString();
  //       });
  //     }
  //   } finally {
  //     if (mounted) {
  //       setState(() {
  //         _isLoading = false;
  //       });
  //     }
  //   }
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 60),
                const Icon(
                  Icons.medical_services,
                  size: 80,
                  color: Colors.blue,
                ),
                const SizedBox(height: 16),
                Text(
                  'Stomatologiya Dasturi',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[700],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                if (_errorMessage != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.red[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red[200]!),
                    ),
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
                  ),
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'Elektron pochta',
                    prefixIcon: Icon(Icons.email),
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Iltimos, elektron pochtangizni kiriting';
                    }
                    if (!value.contains('@')) {
                      return 'Iltimos, to\'g\'ri elektron pochta kiriting';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  decoration: InputDecoration(
                    labelText: 'Parol',
                    prefixIcon: const Icon(Icons.lock),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                    border: const OutlineInputBorder(),
                  ),
                  obscureText: _obscurePassword,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Iltimos, parolni kiriting';
                    }
                    if (value.length < 6) {
                      return 'Parol kamida 6 ta belgidan iborat bo\'lishi kerak';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(_isLogin ? 'KIRISH' : 'RO\'YXATDAN O\'TISH'),
                ),
                const SizedBox(height: 16),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _isLogin 
                          ? 'Hisobingiz yo\'qmi? ' 
                          : 'Allaqachon hisobingiz bormi? ',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                    TextButton(
                      onPressed: _isLoading ? null : _toggleAuthMode,
                      child: Text(
                        _isLogin 
                            ? 'Ro\'yxatdan o\'tish'
                            : 'Tizimga kirish',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
