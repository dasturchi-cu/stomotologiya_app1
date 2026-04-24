import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../routes.dart';

class LoginScreenNew extends StatefulWidget {
  const LoginScreenNew({super.key});

  @override
  State<LoginScreenNew> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreenNew>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late AnimationController _logoAnimationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _logoScaleAnimation;
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  // Theme colors
  final Color _primaryColor = Colors.blue.shade700;
  final Color _errorColor = Colors.red.shade400;
  final Color _backgroundColor = Colors.grey.shade50;

  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _logoAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutQuart,
      ),
    );

    _logoScaleAnimation = Tween<double>(
      begin: 0.5,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _logoAnimationController,
        curve: Curves.elasticOut,
      ),
    );

    _logoAnimationController.forward();
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _logoAnimationController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await Supabase.instance.client.auth.signInWithPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      if (response.user == null) {
        throw Exception('Kirish muvaffaqiyatsiz. Iltimos, qayta urinib ko\'ring.');
      }

      // Navigation is handled by AuthWrapper
      if (mounted) {
        Navigator.of(context).pushReplacementNamed(AppRoutes.wrapper);
      }
    } on AuthException catch (e) {
      setState(() {
        _errorMessage = _translateAuthError(e.message);
        debugPrint('Auth error: ${e.message}');
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Xatolik yuz berdi. Iltimos, qayta urinib ko\'ring.';
        debugPrint('Login error: $e');
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _translateAuthError(String message) {
    if (message.contains('Invalid login credentials')) {
      return 'Noto\'g\'ri elektron pochta yoki parol';
    } else if (message.contains('Email not confirmed')) {
      return 'Iltimos, elektron pochtangizni tasdiqlang';
    } else if (message.contains('Invalid email')) {
      return 'Noto\'g\'ri elektron pochta formati';
    } else if (message.contains('Network error')) {
      return 'Internet aloqasini tekshiring';
    }
    return message;
  }

  void _navigateToRegister() {
    Navigator.pushReplacementNamed(context, AppRoutes.register);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 40),
                // Logo
                ScaleTransition(
                  child: Icon(
                    Icons.medical_services,
                    size: 100,
                    color: _primaryColor,
                  ),
                  scale: _logoScaleAnimation,
                ),
                const SizedBox(height: 16),
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: Text(
                    'Tizimga kirish',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          color: _primaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 40),

                // Email Field
                SlideTransition(
                  position: _slideAnimation,
                  child: TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      labelText: 'Elektron pochta',
                      prefixIcon: const Icon(Icons.email_outlined),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
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
                ),
                const SizedBox(height: 16),

                // Password Field
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: 'Parol',
                    prefixIcon: const Icon(Icons.lock_outline),
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
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Iltimos, parolingizni kiriting';
                    }
                    if (value.length < 6) {
                      return 'Parol kamida 6 ta belgidan iborat bo\'lishi kerak';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 8),

                // Error Message
                if (_errorMessage != null)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    decoration: BoxDecoration(
                      color: _errorColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: _errorColor.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.error_outline, color: _errorColor, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: TextStyle(
                              color: _errorColor,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 24),

                // Login Button
                SlideTransition(
                  position: _slideAnimation,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _login,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _primaryColor,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            'Kirish',
                            style: TextStyle(fontSize: 16, color: Colors.white),
                          ),
                  ),
                ),
                const SizedBox(height: 16),

                // Register Link
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: TextButton(
                    onPressed: _isLoading ? null : _navigateToRegister,
                    child: RichText(
                      text: TextSpan(
                        text: 'Hisobingiz yo\'qmi? ',
                        style: const TextStyle(color: Colors.black87),
                        children: [
                          TextSpan(
                            text: 'Ro\'yxatdan o\'tish',
                            style: TextStyle(
                              color: _primaryColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
