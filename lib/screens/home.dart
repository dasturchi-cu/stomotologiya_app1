import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';
import 'package:stomotologiya_app/models/app_user.dart';
import 'package:stomotologiya_app/models/patient.dart';
import 'package:stomotologiya_app/routes.dart';
import '../service/patient_service.dart';
import '../service/supabase_auth_servise.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  final _patientService = PatientService();
  final _searchController = TextEditingController();
  final _authService = AuthService();
  AppUser? get user => _authService.currentUser;

  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // State variables
  List<Patient> _patients = [];
  String _searchQuery = '';
  Timer? _searchDebounceTimer;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _initializeAnimations();
    _loadPatients();
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(
        CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic));
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchDebounceTimer?.cancel();
    _fadeController.dispose();
    _slideController.dispose();
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

      // Load patients data
      final patients = await _patientService.getPatients();
      if (mounted) {
        setState(() {
          _patients = patients;
          _isLoading = false;
        });
        // Update local cache
        _updateLocalCache(patients);
        _fadeController.forward();
        _slideController.forward();
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Bemorni yuklashda xatolik: $error';
          _isLoading = false;
        });
      }
    }
  }

  // Update local cache (simplified without Hive for now)
  Future<void> _updateLocalCache(List<Patient> patients) async {
    // Cache is now handled in PatientService
    // This method kept for compatibility
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
          (patient.telefonRaqami?.contains(query) ?? false) ||
          patient.shikoyat.toLowerCase().contains(query) ||
          patient.manzil.toLowerCase().contains(query);
    }).toList();
  }

  Future<void> _refreshData() async {
    setState(() {
      _isLoading = true;
    });

    _fadeController.reset();
    _slideController.reset();

    // Simulate a small delay for refresh animation
    await Future.delayed(const Duration(milliseconds: 300));

    // Reload patients
    await _loadPatients();
  }

  Future<void> _clearCache() async {
    try {
      _patientService.clearCache();
      await _loadPatients();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Xotirani tozalashda xatolik: $e'),
            backgroundColor: Colors.red.shade400,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
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
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withOpacity(0.15),
            color.withOpacity(0.08),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 14, color: color),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: color.withOpacity(0.85),
                fontWeight: FontWeight.w600,
                letterSpacing: 0.4,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }


  // Build empty state widget
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(30),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.grey.shade50,
                  Colors.grey.shade100,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(120),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.15),
                  blurRadius: 25,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Lottie.asset(
              'assets/empty.json',
              width: 140,
              height: 140,
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(height: 40),
          Text(
            'Bemorlar topilmadi',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade700,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              'Yangi bemor qo\'shish uchun quyidagi tugmani bosing',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
                letterSpacing: 0.4,
                height: 1.4,
              ),
            ),
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

    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                spreadRadius: 0,
                blurRadius: 25,
                offset: const Offset(0, 12),
              ),
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                spreadRadius: 0,
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(28),
            child: InkWell(
              borderRadius: BorderRadius.circular(28),
              onTap: () {
                Navigator.pushNamed(
                  context,
                  AppRoutes.patientDetails,
                  arguments: patient,
                );
              },
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Row(
                  children: [
                    // Enhanced avatar with patient image or gradient
                    Hero(
                      tag: 'patient_${patient.id}',
                      child: Container(
                        width: 70,
                        height: 70,
                        decoration: BoxDecoration(
                          gradient: patient.rasmlarManzillari.isNotEmpty ? null : LinearGradient(
                            colors: hasRecentVisit
                                ? [
                                    Colors.green.shade400,
                                    Colors.green.shade600,
                                    Colors.green.shade700,
                                  ]
                                : [
                                    Colors.indigo.shade400,
                                    Colors.indigo.shade600,
                                    Colors.indigo.shade700,
                                  ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(22),
                          boxShadow: [
                            BoxShadow(
                              color: (hasRecentVisit
                                      ? Colors.green
                                      : Colors.indigo)
                                  .withOpacity(0.4),
                              spreadRadius: 0,
                              blurRadius: 15,
                              offset: const Offset(0, 6),
                            ),
                          ],
                          image: patient.rasmlarManzillari.isNotEmpty
                              ? DecorationImage(
                                  image: NetworkImage(patient.rasmlarManzillari.first),
                                  fit: BoxFit.cover,
                                  onError: (exception, stackTrace) {
                                    // Fallback to initials if image fails to load
                                  },
                                )
                              : null,
                        ),
                        child: patient.rasmlarManzillari.isEmpty
                            ? Center(
                                child: Text(
                                  initials,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 22,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                              )
                            : null,
                      ),
                    ),
                    const SizedBox(width: 24),
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
                                    fontSize: 20,
                                    color: Colors.black87,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                              if (hasRecentVisit)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 8),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        Colors.green.shade400,
                                        Colors.green.shade600,
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(30),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.green.withOpacity(0.3),
                                        blurRadius: 10,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: const Text(
                                    '● Yaqinda',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.6,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.blue.shade50,
                                      Colors.blue.shade100,
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  Icons.phone_rounded,
                                  size: 18,
                                  color: Colors.blue.shade600,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                patient.telefonRaqami ?? 'N/A',
                                style: TextStyle(
                                  color: Colors.grey.shade700,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  letterSpacing: 0.4,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Wrap(
                            spacing: 14,
                            runSpacing: 10,
                            children: [
                              _buildEnhancedInfoChip(
                                Icons.schedule_rounded,
                                'So\'nggi: $lastVisitFormatted',
                                Colors.orange.shade600,
                              ),
                              if (patient.shikoyat.isNotEmpty)
                                _buildEnhancedInfoChip(
                                  Icons.medical_services_rounded,
                                  patient.shikoyat,
                                  Colors.red.shade500,
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    // Action buttons
                    Column(
                      children: [
                        Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.blue.shade50,
                                Colors.blue.shade100,
                              ],
                            ),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.blue.withOpacity(0.1),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: IconButton(
                            icon: Icon(
                              Icons.edit_rounded,
                              color: Colors.blue.shade600,
                              size: 22,
                            ),
                            onPressed: () {
                              Navigator.pushNamed(
                                context,
                                AppRoutes.patientEdit,
                                arguments: patient,
                              ).then((_) => _loadPatients());
                            },
                          ),
                        ),
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.red.shade50,
                                Colors.red.shade100,
                              ],
                            ),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.red.withOpacity(0.1),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: IconButton(
                            icon: Icon(
                              Icons.delete_rounded,
                              color: Colors.red.shade500,
                              size: 22,
                            ),
                            onPressed: () => _showDeleteConfirmation(
                                context, patient, index),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
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
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          elevation: 20,
          shadowColor: Colors.black.withOpacity(0.3),
          backgroundColor: Colors.white,
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.orange.shade400, Colors.orange.shade600],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.warning_amber_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Text(
                  'Bemorni o\'chirish',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.4,
                  ),
                ),
              ),
            ],
          ),
          content: Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              '${patient.ismi} ismli bemorni ro\'yxatdan o\'chirishni istaysizmi?',
              style: const TextStyle(
                fontSize: 16,
                letterSpacing: 0.3,
                height: 1.4,
              ),
            ),
          ),
          actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              style: TextButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Text(
                'Bekor qilish',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: () async {
                final navigator = Navigator.of(context);
                final scaffoldMessenger = ScaffoldMessenger.of(context);
                navigator.pop();
                try {
                  await _patientService.deletePatient(patient.id!);
                  // Refresh the patient list after successful deletion
                  await _loadPatients();
                  if (mounted) {
                    scaffoldMessenger.showSnackBar(
                      SnackBar(
                        content:
                            Text('${patient.ismi} muvaffaqiyatli o\'chirildi'),
                        backgroundColor: Colors.green.shade500,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        margin: const EdgeInsets.all(16),
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    scaffoldMessenger.showSnackBar(
                      SnackBar(
                        content: Text('Xatolik yuz berdi: $e'),
                        backgroundColor: Colors.red.shade500,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        margin: const EdgeInsets.all(16),
                      ),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade500,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 4,
                shadowColor: Colors.red.withOpacity(0.3),
              ),
              child: const Text(
                'O\'chirish',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) async {
          if (didPop) return;

          // Show confirmation dialog before exiting app
          final shouldExit = await showDialog<bool>(
            context: context,
            barrierDismissible: false,
            builder: (context) => AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              elevation: 20,
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.red.shade400, Colors.red.shade600],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.exit_to_app_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Text('Ilovadan chiqish'),
                ],
              ),
              content: const Text(
                'Ilovadan chiqishni xohlaysizmi?',
                style: TextStyle(fontSize: 16),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: Text(
                    'Yo\'q',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade500,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'Ha',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          );

          if (shouldExit == true && context.mounted) {
            Navigator.of(context).pop();
          }
        },
        child: Scaffold(
          backgroundColor: Colors.grey.shade50,
          appBar: PreferredSize(
            preferredSize: const Size.fromHeight(85),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.indigo.shade500,
                    Colors.indigo.shade600,
                    Colors.indigo.shade700,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.indigo.withOpacity(0.4),
                    spreadRadius: 0,
                    blurRadius: 25,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: AppBar(
                elevation: 0,
                backgroundColor: Colors.transparent,
                foregroundColor: Colors.white,
                centerTitle: true,
                title: const Text(
                  'Bemorlar Ro\'yxati',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 24,
                    letterSpacing: 0.8,
                  ),
                ),
                actions: [
                  Container(
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.analytics_outlined, size: 22),
                      onPressed: () {
                        Navigator.pushNamed(context, AppRoutes.analytics);
                      },
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.refresh_rounded, size: 22),
                      onPressed: _refreshData,
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.only(right: 18),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                    child: PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert_rounded,
                          color: Colors.white),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                      elevation: 15,
                      shadowColor: Colors.black.withOpacity(0.3),
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
                              Icon(Icons.clear_all_rounded, size: 20),
                              SizedBox(width: 14),
                              Text(
                                'Keshni tozalash',
                                style: TextStyle(
                                  fontSize: 15,
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
          ),
          body: Column(
            children: [
              // Search bar
              Container(
                margin: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      spreadRadius: 0,
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      spreadRadius: 0,
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Bemor qidirish...',
                    hintStyle: TextStyle(
                      color: Colors.grey.shade500,
                      fontSize: 17,
                      letterSpacing: 0.4,
                    ),
                    prefixIcon: Container(
                      margin: const EdgeInsets.all(14),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.indigo.shade400,
                            Colors.indigo.shade600,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.indigo.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.search_rounded,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 18,
                    ),
                  ),
                  style: const TextStyle(
                    fontSize: 17,
                    letterSpacing: 0.4,
                  ),
                ),
              ),

              // Patient count info
              if (_patients.isNotEmpty)
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 24),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.blue.shade50,
                        Colors.blue.shade100,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.blue.shade200,
                      width: 1.2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blue.withOpacity(0.1),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade600,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.people_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Text(
                        'Jami bemorlar: ${_patients.length}',
                        style: TextStyle(
                          color: Colors.blue.shade700,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 20),
              // Main content
              Expanded(
                child: _isLoading
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.08),
                                    blurRadius: 20,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.indigo.shade600,
                                ),
                                strokeWidth: 4,
                              ),
                            ),
                            const SizedBox(height: 24),
                            Text(
                              'Ma\'lumotlar yuklanmoqda...',
                              style: TextStyle(
                                fontSize: 17,
                                color: Colors.grey.shade600,
                                letterSpacing: 0.4,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      )
                    : _errorMessage != null
                        ? Center(
                            child: Container(
                              margin: const EdgeInsets.all(24),
                              padding: const EdgeInsets.all(32),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(28),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.08),
                                    spreadRadius: 0,
                                    blurRadius: 25,
                                    offset: const Offset(0, 12),
                                  ),
                                ],
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          Colors.red.shade400,
                                          Colors.red.shade600,
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: const Icon(
                                      Icons.error_outline_rounded,
                                      size: 48,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                  Text(
                                    _errorMessage!,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      fontSize: 17,
                                      letterSpacing: 0.4,
                                      height: 1.4,
                                    ),
                                  ),
                                  const SizedBox(height: 32),
                                  ElevatedButton(
                                    onPressed: _refreshData,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.indigo.shade600,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 32,
                                        vertical: 16,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      elevation: 8,
                                      shadowColor:
                                          Colors.indigo.withOpacity(0.3),
                                    ),
                                    child: const Text(
                                      'Qayta urinish',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 16,
                                        letterSpacing: 0.4,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : _filteredPatients.isEmpty
                            ? _buildEmptyState()
                            : RefreshIndicator(
                                onRefresh: _refreshData,
                                color: Colors.indigo.shade600,
                                backgroundColor: Colors.white,
                                strokeWidth: 3,
                                child: ListView.builder(
                                  padding: const EdgeInsets.only(
                                    top: 8,
                                    bottom: 120,
                                  ),
                                  itemCount: _filteredPatients.length,
                                  itemBuilder: (context, index) {
                                    final patient = _filteredPatients[index];
                                    final hasVisitDates =
                                        patient.tashrifSanalari.isNotEmpty;
                                    final lastVisit = hasVisitDates
                                        ? DateTime.parse(
                                            patient.tashrifSanalari.last)
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
          floatingActionButton: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.indigo.shade500,
                  Colors.indigo.shade600,
                  Colors.indigo.shade700,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.indigo.withOpacity(0.4),
                  spreadRadius: 0,
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: FloatingActionButton.extended(
              onPressed: () {
                Navigator.pushNamed(context, AppRoutes.addPatient).then((_) {
                  _loadPatients();
                });
              },
              backgroundColor: Colors.transparent,
              foregroundColor: Colors.white,
              elevation: 0,
              icon: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.person_add_rounded, size: 22),
              ),
              label: const Text(
                'Yangi bemor',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 17,
                  letterSpacing: 0.6,
                ),
              ),
            ),
          ),
          floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
        ));
  }


}
