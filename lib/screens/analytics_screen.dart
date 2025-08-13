import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import '../models/patient.dart';
import 'patients/patient_info.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  final box = Hive.box<Patient>('patients');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Statistika',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.blue[800],
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: ValueListenableBuilder(
        valueListenable: box.listenable(),
        builder: (context, box, widget) {
          final patients = box.values.toList();

          if (patients.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.analytics_outlined,
                    size: 80,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Statistika uchun bemorlar kerak',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildOverviewCards(patients),
                const SizedBox(height: 24),
                _buildVisitStatistics(patients),
                const SizedBox(height: 24),
                _buildComplaintAnalysis(patients),
                const SizedBox(height: 24),
                _buildRecentActivity(patients),
              ],
            ),
          );
        },
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
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Jami bemorlar',
                totalPatients.toString(),
                Icons.people,
                Colors.blue,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'Ushbu oy',
                thisMonthPatients.toString(),
                Icons.calendar_today,
                Colors.green,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Jami tashriflar',
                totalVisits.toString(),
                Icons.medical_services,
                Colors.orange,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'O\'rtacha tashrif',
                avgVisitsPerPatient,
                Icons.trending_up,
                Colors.purple,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(
      String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 24),
                const Spacer(),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVisitStatistics(List<Patient> patients) {
    final now = DateTime.now();
    final last30Days = now.subtract(const Duration(days: 30));

    final recentVisits = patients
        .where((p) => p.visitDates.any((date) => date.isAfter(last30Days)))
        .length;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Tashrif statistikasi',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(Icons.access_time, color: Colors.blue[600]),
                const SizedBox(width: 8),
                Text('So\'nggi 30 kun ichida: $recentVisits ta bemor'),
              ],
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

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Eng ko\'p uchraydigan shikoyatlar',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...sortedComplaints.take(5).map((entry) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          entry.key,
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.blue[100],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          entry.value.toString(),
                          style: TextStyle(
                            color: Colors.blue[800],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentActivity(List<Patient> patients) {
    final recentPatients = patients
      ..sort((a, b) => b.lastVisitDate.compareTo(a.lastVisitDate));

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'So\'nggi faoliyat',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...recentPatients.take(5).map((patient) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            PatientDetailsScreen(patient: patient),
                      ),
                    );
                  },
                  leading: CircleAvatar(
                    backgroundColor: Colors.blue[100],
                    child: Text(
                      patient.fullName.isNotEmpty
                          ? patient.fullName[0].toUpperCase()
                          : '?',
                      style: TextStyle(
                        color: Colors.blue[800],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  title: Text(patient.fullName),
                  subtitle: Text(
                      'So\'nggi tashrif: ${DateFormat('dd.MM.yyyy').format(patient.lastVisitDate)}'),
                  trailing: Icon(Icons.chevron_right, color: Colors.grey[400]),
                )),
          ],
        ),
      ),
    );
  }
}
