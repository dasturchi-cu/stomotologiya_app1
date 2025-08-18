import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import '../models/patient.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen>
    with TickerProviderStateMixin {
  final box = Hive.box<Patient>('patients');
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

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
              Color(0xFF667eea),
              Color(0xFF764ba2),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: ValueListenableBuilder(
                  valueListenable: box.listenable(),
                  builder: (context, box, widget) {
                    final patients = box.values.toList();

                    if (patients.isEmpty) {
                      return _buildEmptyState();
                    }

                    return FadeTransition(
                      opacity: _fadeAnimation,
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildOverviewCards(patients),
                            const SizedBox(height: 32),
                            _buildVisitStatistics(patients),
                            const SizedBox(height: 32),
                            _buildComplaintAnalysis(patients),
                            const SizedBox(height: 32),
                            _buildRecentActivity(patients),
                            const SizedBox(height: 20),
                          ],
                        ),
                      ),
                    );
                  },
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
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'Bemorlar ma\'lumotlari tahlili',
                  style: TextStyle(
                    fontSize: 16,
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
            p.firstVisitDate.year == thisMonth.year &&
            p.firstVisitDate.month == thisMonth.month)
        .length;

    final totalVisits =
        patients.fold<int>(0, (sum, p) => sum + p.visitDates.length);
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
                const Color(0xFF29B6F6),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildStatCard(
                'Ushbu oy',
                thisMonthPatients.toString(),
                Icons.calendar_today_rounded,
                const Color(0xFF66BB6A),
                const Color(0xFF4CAF50),
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
                const Color(0xFFFF5722),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildStatCard(
                'O\'rtacha tashrif',
                avgVisitsPerPatient,
                Icons.trending_up_rounded,
                const Color(0xFFAB47BC),
                const Color(0xFF9C27B0),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon,
      Color lightColor, Color darkColor) {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 600),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, animationValue, child) {
        return Transform.scale(
          scale: 0.8 + (0.2 * animationValue),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [lightColor, darkColor],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: darkColor.withOpacity(0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () {},
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              icon,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            value,
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.9),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildVisitStatistics(List<Patient> patients) {
    final now = DateTime.now();
    final last30Days = now.subtract(const Duration(days: 30));

    final recentVisits = patients
        .where((p) => p.visitDates.any((date) => date.isAfter(last30Days)))
        .length;

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
                      colors: [Color(0xFF4FC3F7), Color(0xFF29B6F6)],
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.timeline_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Text(
                    'Tashrif statistikasi',
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
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF4FC3F7).withOpacity(0.1),
                    const Color(0xFF29B6F6).withOpacity(0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(0xFF4FC3F7).withOpacity(0.2),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF4FC3F7).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.access_time_rounded,
                      color: Color(0xFF29B6F6),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          recentVisits.toString(),
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF29B6F6),
                          ),
                        ),
                        const Text(
                          'So\'nggi 30 kun ichida tashrif',
                          style: TextStyle(
                            fontSize: 14,
                            color: Color(0xFF546E7A),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildComplaintAnalysis(List<Patient> patients) {
    final complaints = <String, int>{};

    for (final patient in patients) {
      final complaint = patient.complaint.toLowerCase().trim();
      if (complaint.isNotEmpty) {
        complaints[complaint] = (complaints[complaint] ?? 0) + 1;
      }
    }

    final sortedComplaints = complaints.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final colors = [
      const Color(0xFFE91E63),
      const Color(0xFF9C27B0),
      const Color(0xFF673AB7),
      const Color(0xFF3F51B5),
      const Color(0xFF2196F3),
    ];

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
                      colors: [Color(0xFFE91E63), Color(0xFFAD1457)],
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.pie_chart_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Text(
                    'Eng ko\'p uchraydigan shikoyatlar',
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
            ...sortedComplaints.take(5).map((entry) {
              final index = sortedComplaints.indexOf(entry);
              final color = colors[index % colors.length];
              final maxCount = sortedComplaints.isNotEmpty
                  ? sortedComplaints.first.value
                  : 1;
              final percentage = (entry.value / maxCount);

              return TweenAnimationBuilder<double>(
                duration: Duration(milliseconds: 800 + (index * 100)),
                tween: Tween(begin: 0.0, end: percentage),
                builder: (context, animationValue, child) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                entry.key,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF2C3E50),
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: color.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: color.withOpacity(0.3),
                                ),
                              ),
                              child: Text(
                                entry.value.toString(),
                                style: TextStyle(
                                  color: color,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Container(
                          height: 6,
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(3),
                          ),
                          child: FractionallySizedBox(
                            alignment: Alignment.centerLeft,
                            widthFactor: animationValue,
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [color, color.withOpacity(0.7)],
                                ),
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentActivity(List<Patient> patients) {
    final recentPatients = [...patients]
      ..sort((a, b) => b.lastVisitDate.compareTo(a.lastVisitDate));

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
                    'So\'nggi faoliyat',
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
              final index = recentPatients.indexOf(patient);
              return TweenAnimationBuilder<double>(
                duration: Duration(milliseconds: 600 + (index * 100)),
                tween: Tween(begin: 0.0, end: 1.0),
                builder: (context, animationValue, child) {
                  return Transform.translate(
                    offset: Offset(50 * (1 - animationValue), 0),
                    child: Opacity(
                      opacity: animationValue,
                      child: Container(
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
                                      Color(0xFF667eea),
                                      Color(0xFF764ba2),
                                    ],
                                  ),
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF667eea)
                                          .withOpacity(0.3),
                                      blurRadius: 8,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Center(
                                  child: Text(
                                    patient.fullName.isNotEmpty
                                        ? patient.fullName[0].toUpperCase()
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
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      patient.fullName,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF2C3E50),
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      "So'nggi tashrif: ${DateFormat('dd.MM.yyyy').format(patient.lastVisitDate)}",
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
                      ),
                    ),
                  );
                },
              );
            }),
          ],
        ),
      ),
    );
  }
}
