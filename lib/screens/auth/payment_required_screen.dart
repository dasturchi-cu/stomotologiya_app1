import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../service/auth_service.dart';
import '../../service/payment_enforcement_service.dart';

class PaymentRequiredScreen extends StatefulWidget {
  final String message;
  
  const PaymentRequiredScreen({
    super.key,
    required this.message,
  });

  @override
  State<PaymentRequiredScreen> createState() => _PaymentRequiredScreenState();
}

class _PaymentRequiredScreenState extends State<PaymentRequiredScreen>
    with TickerProviderStateMixin {
  final _authService = AuthService();
  final _paymentService = PaymentEnforcementService();
  
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _logout() async {
    await _authService.signOut();
  }

  void _contactSupport() {
    // Bu yerda support bilan bog'lanish funksiyasini qo'shishingiz mumkin
    // Masalan, telefon raqamini ko'rsatish yoki email yuborish
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Yordam'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('To\'lov bo\'yicha yordam olish uchun:'),
            SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.phone, color: Colors.blue),
                SizedBox(width: 8),
                Text('+998 90 123 45 67'),
              ],
            ),
            SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.email, color: Colors.blue),
                SizedBox(width: 8),
                Text('support@stomotracker.uz'),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Yopish'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Clipboard.setData(const ClipboardData(text: '+998901234567'));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Telefon raqami nusxalandi'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
            child: const Text('Raqamni nusxalash'),
          ),
        ],
      ),
    );
  }

  void _showPaymentInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('To\'lov ma\'lumotlari'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Oylik to\'lov: 50,000 so\'m'),
            SizedBox(height: 8),
            Text('Yillik to\'lov: 500,000 so\'m (2 oy bepul)'),
            SizedBox(height: 12),
            Text('To\'lov usullari:'),
            SizedBox(height: 8),
            Text('• Click'),
            Text('• Payme'),
            Text('• Uzcard'),
            Text('• Humo'),
            SizedBox(height: 12),
            Text(
              'To\'lovdan so\'ng hisobingiz avtomatik faollashadi.',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Yopish'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.red[50],
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              // AppBar
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'StomoTrack',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[800],
                    ),
                  ),
                  TextButton.icon(
                    onPressed: _logout,
                    icon: const Icon(Icons.logout, size: 18),
                    label: const Text('Chiqish'),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.grey[600],
                    ),
                  ),
                ],
              ),
              
              Expanded(
                child: Center(
                  child: AnimatedBuilder(
                    animation: _animationController,
                    builder: (context, child) {
                      return FadeTransition(
                        opacity: _fadeAnimation,
                        child: ScaleTransition(
                          scale: _scaleAnimation,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // Asosiy icon
                              Container(
                                width: 120,
                                height: 120,
                                decoration: BoxDecoration(
                                  color: Colors.red[100],
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.payment,
                                  size: 60,
                                  color: Colors.red[600],
                                ),
                              ),
                              const SizedBox(height: 32),

                              // Sarlavha
                              Text(
                                'To\'lov talab qilinadi',
                                style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.red[700],
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 16),

                              // Xabar
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.red[200]!),
                                ),
                                child: Text(
                                  widget.message,
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey[700],
                                    height: 1.5,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              const SizedBox(height: 32),

                              // To'lov ma'lumotlari tugmasi
                              ElevatedButton.icon(
                                onPressed: _showPaymentInfo,
                                icon: const Icon(Icons.info_outline),
                                label: const Text('To\'lov ma\'lumotlari'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue[600],
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 24,
                                    vertical: 12,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),

                              // Yordam tugmasi
                              OutlinedButton.icon(
                                onPressed: _contactSupport,
                                icon: const Icon(Icons.support_agent),
                                label: const Text('Yordam olish'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.blue[600],
                                  side: BorderSide(color: Colors.blue[600]!),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 24,
                                    vertical: 12,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),

              // Pastki ma'lumot
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info, color: Colors.blue[600], size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'To\'lovdan so\'ng hisobingiz avtomatik faollashadi va barcha funksiyalardan foydalanishingiz mumkin bo\'ladi.',
                        style: TextStyle(
                          color: Colors.blue[700],
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
