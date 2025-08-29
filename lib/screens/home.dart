import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';
import 'package:stomotologiya_app/models/app_user.dart';
import 'package:stomotologiya_app/routes.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/patient.dart';
import '../service/patient_service.dart';
import '../service/supabase_auth_servise.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _patientService = PatientService();
  final _searchController = TextEditingController();
  final _authService = AuthService();
  AppUser? get user => _authService.currentUser;
  
  // State variables
  late final Box<Patient> box;
  List<Patient> _patients = [];
  String _searchQuery = '';
  Timer? _searchDebounceTimer;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _initializeHive();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchDebounceTimer?.cancel();
    super.dispose();
  }

  // Load patients from Supabase
  Future<void> _loadPatients() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      // Initialize PatientService
      await _patientService.initialize();
      
      // Listen to patients stream from Supabase
      _patientService.getPatients().listen((patients) {
        if (mounted) {
          setState(() {
            _patients = patients;
            _isLoading = false;
          });
          // Update local cache
          _updateLocalCache(patients);
        }
      }, onError: (error) {
        if (mounted) {
          setState(() {
            _errorMessage = 'Bemorni yuklashda xatolik: $error';
            _isLoading = false;
          });
        }
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Xatolik yuz berdi: $e';
          _isLoading = false;
        });
      }
      debugPrint('Bemorni yuklashda xatolik: $e');
    }
  }

  // Update local Hive database with fresh data from Supabase
  Future<void> _updateLocalCache(List<Patient> patients) async {
    try {
      await box.clear();
      for (var patient in patients) {
        await box.put(patient.key, patient);
      }
    } catch (e) {
      debugPrint('Error updating local cache: $e');
    }
  }

  void _onSearchChanged() {
    // Cancel previous timer
    _searchDebounceTimer?.cancel();

    // Start new timer with 300ms delay for better performance
    _searchDebounceTimer = Timer(const Duration(milliseconds: 300), () {
      if (mounted) {
        setState(() {
          _searchQuery = _searchController.text.trim();
        });
      }
    });
  }

  // Filter patients based on search query
  List<Patient> get _filteredPatients {
    if (_searchQuery.isEmpty) return _patients;

    final query = _searchQuery.toLowerCase();
    return _patients.where((patient) {
      return patient.ismi.toLowerCase().contains(query) ||
          patient.telefonRaqami.contains(query) ||
          (patient.shikoyat != null && patient.shikoyat!.toLowerCase().contains(query)) ||
          (patient.manzil != null && patient.manzil!.toLowerCase().contains(query));
    }).toList();
  }

  Future<void> _refreshData() async {
    setState(() {
      _isLoading = true;
    });

    // Simulate a small delay for refresh animation
    await Future.delayed(const Duration(milliseconds: 300));
    
    // Reload patients
    await _loadPatients();
  }

  Future<void> _clearCache() async {
    try {
      await box.clear();
      await _loadPatients();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Xotirani tozalashda xatolik: $e')),
        );
      }
    }
  }

  // Get initials from name
  String _getInitials(String fullName) {
    if (fullName.isEmpty) return '';
    return fullName
        .split(' ')
        .where((s) => s.isNotEmpty)
        .map((s) => s[0].toUpperCase())
        .take(2)
        .join('');
  }

  // Format date to display
  String _formatDate(DateTime date) {
    return DateFormat('dd.MM.yyyy').format(date);
  }

  // Build enhanced info chip widget
  Widget _buildEnhancedInfoChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: color.withOpacity(0.8),
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  // Build info chip widget (kept for compatibility)
  Widget _buildInfoChip(IconData icon, String label) {
    return _buildEnhancedInfoChip(icon, label, Colors.grey);
  }

  // Build empty state widget
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Lottie.asset(
            'assets/empty.json',
            width: 200,
            height: 200,
            fit: BoxFit.contain,
          ),
          const SizedBox(height: 16),
          const Text(
            'Bemorlar topilmadi',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Yangi bemor qo\'shish uchun quyidagi tugmani bosing',
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // Build enhanced patient card widget
  Widget _buildEnhancedPatientCard(
      BuildContext context, Patient patient, int index,
      {required bool hasRecentVisit, required DateTime lastVisit}) {
    final lastVisitFormatted = _formatDate(lastVisit);
    final initials = _getInitials(patient.ismi);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white,
            Colors.blue[50]!,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            Navigator.pushNamed(
              context,
              AppRoutes.patientDetails,
              arguments: patient,
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Enhanced avatar with gradient
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.blue[400]!,
                        Colors.blue[600]!,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blue.withOpacity(0.3),
                        spreadRadius: 1,
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      initials,
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
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              patient.ismi,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 17,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                          if (hasRecentVisit)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.green[400]!,
                                    Colors.green[600]!,
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Text(
                                'Yaqinda',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(Icons.phone_rounded, 
                               size: 16, 
                               color: Colors.blue[600]),
                          const SizedBox(width: 6),
                          Text(
                            patient.telefonRaqami,
                            style: TextStyle(
                              color: Colors.grey[700],
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          _buildEnhancedInfoChip(
                            Icons.calendar_today_rounded,
                            'So\'nggi: $lastVisitFormatted',
                            Colors.orange,
                          ),
                          const SizedBox(width: 8),
                          if (patient.shikoyat?.isNotEmpty ?? false)
                            Expanded(
                              child: _buildEnhancedInfoChip(
                                Icons.medical_services_rounded,
                                patient.shikoyat!,
                                Colors.red,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                Column(
                  children: [
                    IconButton(
                      icon: Icon(Icons.edit_rounded, 
                                color: Colors.blue[600],
                                size: 22),
                      onPressed: () {
                        Navigator.pushNamed(
                          context,
                          AppRoutes.patientEdit,
                          arguments: patient,
                        ).then((_) => _loadPatients());
                      },
                    ),
                    IconButton(
                      icon: Icon(Icons.delete_rounded, 
                                color: Colors.red[400],
                                size: 22),
                      onPressed: () => _showDeleteConfirmation(context, patient, index),
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

  // Show delete confirmation dialog
  void _showDeleteConfirmation(
      BuildContext context, Patient patient, int index) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Bemorni o\'chirish'),
          content: Text(
              '${patient.ismi} ismli bemorni ro\'yxatdan o\'chirishni istaysizmi?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Bekor qilish'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                try {
                  await _patientService.deletePatient(patient.id!);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                            '${patient.ismi} muvaffaqiyatli o\'chirildi'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Xatolik yuz berdi: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              child: const Text('O\'chirish', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
        title: const Text(
          'Bemorlar Ro\'yxati',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.analytics_outlined),
            onPressed: () {
              Navigator.pushNamed(context, AppRoutes.analytics);
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshData,
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'clear_cache') {
                _clearCache();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'clear_cache',
                child: Row(
                  children: [
                    Icon(Icons.clear_all),
                    SizedBox(width: 8),
                    Text('Keshni tozalash'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue[600],
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
            ),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Bemor qidirish...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
              ),
            ),
          ),
          // Patient count info
          if (_patients.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                'Jami bemorlar: ${_patients.length}',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          // Main content
          Expanded(
            child: _isLoading
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('Ma\'lumotlar yuklanmoqda...'),
                      ],
                    ),
                  )
                : _errorMessage != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.error_outline,
                              size: 64,
                              color: Colors.red[300],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _errorMessage!,
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: 16),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _refreshData,
                              child: const Text('Qayta urinish'),
                            ),
                          ],
                        ),
                      )
                    : _filteredPatients.isEmpty
                        ? _buildEmptyState()
                        : RefreshIndicator(
                            onRefresh: _refreshData,
                            child: ListView.builder(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              itemCount: _filteredPatients.length,
                              itemBuilder: (context, index) {
                                final patient = _filteredPatients[index];
                                final hasVisitDates = patient.tashrifSanalari.isNotEmpty;
                                final lastVisit = hasVisitDates
                                    ? DateTime.parse(patient.tashrifSanalari.last)
                                    : patient.birinchiKelganSana;
                                final hasRecentVisit = hasVisitDates &&
                                    lastVisit.isAfter(DateTime.now()
                                        .subtract(const Duration(days: 7)));

                                return _buildEnhancedPatientCard(
                                  context,
                                  patient,
                                  index,
                                  hasRecentVisit: hasRecentVisit,
                                  lastVisit: lastVisit,
                                );
                              },
                            ),
                          ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.pushNamed(context, AppRoutes.addPatient).then((_) {
            _loadPatients();
          });
        },
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
        icon: const Icon(Icons.person_add),
        label: const Text(
          'Yangi bemor',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Future<void> _initializeHive() async {
    try {
      if (!Hive.isBoxOpen('patients')) {
        box = await Hive.openBox<Patient>('patients');
      } else {
        box = Hive.box<Patient>('patients');
      }
      _loadPatients();
    } catch (e) {
      if (kDebugMode) {
        print('Error initializing Hive box: $e');
      }
      setState(() {
        _errorMessage = 'Ma\'lumotlar bazasida xatolik yuz berdi';
        _isLoading = false;
      });
    }
  }

  // Build patient card content
  Widget _buildPatientCardContent(
      Patient patient, bool hasRecentVisit, DateTime lastVisit, int index) {
    final initials = _getInitials(patient.ismi);
    final lastVisitFormatted = _formatDate(lastVisit);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // Patient avatar with initials
          CircleAvatar(
            radius: 24,
            backgroundColor: Colors.blue[100],
            child: Text(
              initials,
              style: TextStyle(
                color: Colors.blue[800],
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Patient details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        patient.ismi,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    if (hasRecentVisit)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.green[100],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'Yaqinda',
                          style: TextStyle(
                            color: Colors.green[800],
                            fontSize: 12,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.phone, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      patient.telefonRaqami,
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _buildInfoChip(
                      Icons.calendar_today,
                      'So\'nggi: $lastVisitFormatted',
                    ),
                    const SizedBox(width: 8),
                    if (patient.shikoyat.isNotEmpty)
                      _buildInfoChip(
                        Icons.medical_services,
                        patient.shikoyat,
                      ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.delete_outline, color: Colors.red[400]),
            onPressed: () => _showDeleteConfirmation(context, patient, index),
          ),
        ],
      ),
    );
  }

}
