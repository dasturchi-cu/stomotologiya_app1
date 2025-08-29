import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/patient.dart';
import '../service/patient_service.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen>
    with TickerProviderStateMixin {
  final PatientService _patientService = PatientService();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  bool _isLoading = true;
  List<Patient> _patients = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    _animationController.forward();
    _loadPatients();
  }

  Future<void> _loadPatients() async {
    try {
      setState(() => _isLoading = true);
      await _patientService.initialize();
      
      _patientService.getPatients().listen((patients) {
        if (mounted) {
          setState(() {
            _patients = patients;
            _isLoading = false;
            _error = null;
          });
        }
      }).onError((error) {
        if (mounted) {
          setState(() {
            _error = 'Xatolik yuz berdi: ${error.toString()}';
            _isLoading = false;
          });
        }
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Xatolik yuz berdi: ${e.toString()}';
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF1E88E5),
              Color(0xFF1976D2),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : _error != null
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.error_outline,
                                size: 64,
                                color: Colors.white70,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                _error!,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: _loadPatients,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: Colors.blue,
                                ),
                                child: const Text('Qayta urinish'),
                              ),
                            ],
                          ),
                        )
                      : _patients.isEmpty
                          ? _buildEmptyState()
                          : FadeTransition(
                              opacity: _fadeAnimation,
                              child: SingleChildScrollView(
                                padding: const EdgeInsets.all(20),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildOverviewCards(_patients),
                                    const SizedBox(height: 32),
                                    _buildRecentActivity(_patients),
                                    const SizedBox(height: 20),
                                  ],
                                ),
                              ),
                            ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1976D2), Color(0xFF1565C0)],
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.analytics_rounded,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Statistika',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Bemorlar ma\'lumotlari tahlili',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.analytics_outlined,
                size: 80,
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Statistika uchun bemorlar kerak',
              style: TextStyle(
                fontSize: 20,
                color: Colors.white70,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Birinchi bemorni qo\'shing',
              style: TextStyle(
                fontSize: 16,
                color: Colors.white54,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewCards(List<Patient> patients) {
    final totalPatients = patients.length;
    final thisMonth = DateTime.now();
    final thisMonthPatients = patients
        .where((p) =>
            p.birinchiKelganSana.year == thisMonth.year &&
            p.birinchiKelganSana.month == thisMonth.month)
        .length;

    final totalVisits =
        patients.fold<int>(0, (sum, p) => sum + p.tashrifSanalari.length);
    final avgVisitsPerPatient = totalPatients > 0
        ? (totalVisits / totalPatients).toStringAsFixed(1)
        : '0';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Umumiy ko\'rsatkichlar',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Jami bemorlar',
                totalPatients.toString(),
                Icons.people_rounded,
                const Color(0xFF4FC3F7),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildStatCard(
                'Ushbu oy',
                thisMonthPatients.toString(),
                Icons.calendar_today_rounded,
                const Color(0xFF66BB6A),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Jami tashriflar',
                totalVisits.toString(),
                Icons.medical_services_rounded,
                const Color(0xFFFF7043),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildStatCard(
                'O\'rtacha tashrif',
                avgVisitsPerPatient,
                Icons.trending_up_rounded,
                const Color(0xFFAB47BC),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 24,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.grey,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentActivity(List<Patient> patients) {
    final recentPatients = [...patients]
      ..sort((a, b) => b.birinchiKelganSana.compareTo(a.birinchiKelganSana));

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF66BB6A), Color(0xFF4CAF50)],
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.history_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Text(
                    'So\'nggi bemorlar',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2C3E50),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            ...recentPatients.take(5).map((patient) {
              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8F9FA),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFFE9ECEF),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              Color(0xFF1E88E5),
                              Color(0xFF1976D2),
                            ],
                          ),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF1E88E5).withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            patient.ismi.isNotEmpty
                                ? patient.ismi[0].toUpperCase()
                                : '?',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              patient.ismi,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF2C3E50),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "Birinchi kelgan: ${DateFormat('dd.MM.yyyy').format(patient.birinchiKelganSana)}",
                              style: const TextStyle(
                                fontSize: 13,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
