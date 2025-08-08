import 'dart:async';
import 'package:flutter/material.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';
import 'package:stomotologiya_app/screens/analytics_screen.dart';
import 'package:stomotologiya_app/screens/appointments_screen.dart';
import 'package:stomotologiya_app/screens/export.dart';
import 'package:stomotologiya_app/screens/patients/add_patient_screen.dart';
import 'package:stomotologiya_app/screens/patients/patient_info.dart';
import 'package:stomotologiya_app/screens/patients/patient_screen.dart';
import 'package:stomotologiya_app/screens/settings_screen.dart';
import '../models/patient.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  var box = Hive.box<Patient>('patients');
  bool _isLoading = false;

  // Performance optimization: Cache filtered patients
  List<Patient>? _cachedFilteredPatients;
  String _lastSearchQuery = '';

  // Debounce timer for search
  Timer? _searchDebounceTimer;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _searchDebounceTimer?.cancel();
    super.dispose();
  }

  void _onSearchChanged() {
    // Cancel previous timer
    _searchDebounceTimer?.cancel();

    // Start new timer with 300ms delay for better performance
    _searchDebounceTimer = Timer(const Duration(milliseconds: 300), () {
      if (mounted) {
        setState(() {
          _searchQuery = _searchController.text;
          _cachedFilteredPatients = null; // Clear cache when search changes
        });
      }
    });
  }

  Future<void> _refreshData() async {
    setState(() {
      _isLoading = true;
    });

    // Clear cache to force refresh
    _clearCache();

    // Simulate a small delay for refresh animation
    await Future.delayed(const Duration(milliseconds: 300));

    setState(() {
      _isLoading = false;
    });
  }

  void _clearCache() {
    _cachedFilteredPatients = null;
    _lastSearchQuery = '';
  }

  List<Patient> _getFilteredPatients() {
    // Use cached results if search query hasn't changed
    if (_cachedFilteredPatients != null && _lastSearchQuery == _searchQuery) {
      return _cachedFilteredPatients!;
    }

    List<Patient> result;

    if (_searchQuery.isEmpty) {
      result = box.values.toList();
    } else {
      final query = _searchQuery.toLowerCase();
      result = box.values.where((patient) {
        final fullNameLower = patient.fullName.toLowerCase();
        final phoneNumber = patient.phoneNumber;
        final complaintLower = patient.complaint.toLowerCase();

        return fullNameLower.contains(query) ||
            phoneNumber.contains(_searchQuery) ||
            complaintLower.contains(query);
      }).toList();
    }

    // Cache the results for better performance
    _cachedFilteredPatients = result;
    _lastSearchQuery = _searchQuery;

    return result;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      drawer: _buildDrawer(),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        centerTitle: false,
        title: Text(
          'Bemorlar Ro\'yxati',
          style: TextStyle(
            color: Colors.blue[800],
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.file_download, color: Colors.blue[800]),
            tooltip: 'Excel formatiga eksport',
            onPressed: () => Navigator.push(
                context, MaterialPageRoute(builder: (_) => ExportScreen())),
          ),
          IconButton(
            icon: Icon(Icons.analytics_outlined, color: Colors.blue[800]),
            tooltip: 'Statistika',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AnalyticsScreen()),
              );
            },
          ),
          IconButton(
            icon: Icon(Icons.settings_outlined, color: Colors.blue[800]),
            tooltip: 'Sozlamalar',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar with filter options
          Container(
            padding: EdgeInsets.fromLTRB(16, 8, 16, 16),
            color: Colors.white,
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Bemor ismini qidirish...',
                    prefixIcon: Icon(Icons.search, color: Colors.blue[800]),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: Colors.grey[100],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
                SizedBox(height: 12),
                // SingleChildScrollView(
                //   scrollDirection: Axis.horizontal,
                //   child: Row(
                //     children: [
                //       _filterChip(label: 'Bugun', isSelected: false),
                //       _filterChip(label: 'Ushbu hafta', isSelected: false),
                //       _filterChip(label: 'A-Z', isSelected: true),
                //       _filterChip(label: 'Eng yangi', isSelected: false),
                //       _filterChip(
                //           label: 'To\'lov qilinmagan', isSelected: false),
                //     ],
                //   ),
                // ),
              ],
            ),
          ),

          // Patient list with ValueListenableBuilder
          Expanded(
            child: RefreshIndicator(
              onRefresh: _refreshData,
              child: ValueListenableBuilder(
                valueListenable: box.listenable(),
                builder: (context, box, widget) {
                  if (_isLoading) {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  }

                  final filteredPatients = _getFilteredPatients();

                  if (box.isEmpty) {
                    return _buildEmptyState();
                  } else if (filteredPatients.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.search_off,
                              size: 64, color: Colors.grey[400]),
                          SizedBox(height: 16),
                          Text(
                            'Qidiruv natijasi topilmadi',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    );
                  } else {
                    return ListView.builder(
                      itemCount: filteredPatients.length,
                      padding: EdgeInsets.all(16),
                      physics: const AlwaysScrollableScrollPhysics(
                        parent: BouncingScrollPhysics(),
                      ),
                      // Optimized cache settings for better performance
                      cacheExtent:
                          2000, // Increased cache for smoother scrolling
                      addAutomaticKeepAlives: false, // Reduce memory usage
                      addRepaintBoundaries:
                          true, // Improve rendering performance
                      addSemanticIndexes:
                          false, // Disable if not needed for accessibility
                      itemBuilder: (context, index) {
                        final patient = filteredPatients[index];
                        return _buildOptimizedPatientCard(
                            context, patient, index);
                      },
                    );
                  }
                },
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.push(
              context, MaterialPageRoute(builder: (_) => AddPatientScreen()));
          // Clear cache when returning from add patient screen
          if (result == true) {
            _clearCache();
          }
        },
        backgroundColor: Colors.blue[800],
        icon: Icon(Icons.person_add_alt_1_rounded),
        label: Text('Yangi bemor'),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Lottie.asset(
            'assets/empty.json', // Add this asset to your project
            width: 180,
            height: 180,
            fit: BoxFit.contain,
          ),
          SizedBox(height: 24),
          Text(
            'Sizda hali bemorlar mavjud emas',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          SizedBox(height: 12),
          Text(
            'Yangi bemor qo\'shish uchun pastdagi tugmani bosing',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => AddPatientScreen()),
              );
            },
            icon: Icon(Icons.person_add),
            label: Text('Yangi bemor qo\'shish'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue[800],
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Optimized patient card with better performance
  Widget _buildOptimizedPatientCard(
      BuildContext context, Patient patient, int index) {
    // Check if patient has recent visit (within last 7 days) - cached calculation
    final bool hasRecentVisit = patient.visitDates.isNotEmpty &&
        patient.lastVisitDate
            .isAfter(DateTime.now().subtract(const Duration(days: 7)));

    return RepaintBoundary(
      child: Card(
        key: ValueKey('patient_${patient.key}'),
        elevation: 2,
        margin: const EdgeInsets.only(bottom: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PatientDetailsScreen(patient: patient),
                ),
              );
            },
            child: _buildPatientCardContent(patient, hasRecentVisit, index),
          ),
        ),
      ),
    );
  }

  Widget _buildPatientCardContent(
      Patient patient, bool hasRecentVisit, int index) {
    // Pre-calculate values to avoid repeated computations
    final initials = _getInitials(patient.fullName);
    final lastVisitFormatted = _formatDate(patient.lastVisitDate);

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          // Patient avatar or initials - optimized with const where possible
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
                        patient.fullName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (hasRecentVisit) ...[
                      const SizedBox(width: 8),
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
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.phone, size: 14, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        patient.phoneNumber,
                        style: TextStyle(
                          color: Colors.grey[600],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Optimized metadata row with fixed height
                SizedBox(
                  height: 30,
                  child: Row(
                    children: [
                      Flexible(
                        child: _buildInfoChip(Icons.calendar_today,
                            'So\'nggi: $lastVisitFormatted'),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: _buildInfoChip(
                            Icons.medical_services, patient.complaint),
                      ),
                    ],
                  ),
                )
              ],
            ),
          ),
          // Actions
          IconButton(
            icon: Icon(Icons.edit_outlined, color: Colors.blue[600]),
            tooltip: 'Tahrirlash',
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PatientEdit(patientIndex: index),
                ),
              );
              if (result == true) {
                _clearCache(); // Refresh the list
              }
            },
          ),
          IconButton(
            icon: Icon(Icons.delete_outline, color: Colors.red[400]),
            tooltip: 'O\'chirish',
            onPressed: () {
              _showDeleteConfirmation(context, patient, index);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: Colors.grey[700]),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[700],
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: Colors.blue[800],
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.medical_services,
                  size: 48,
                  color: Colors.white,
                ),
                SizedBox(height: 16),
                Text(
                  'StomoTrack',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Bemorlar boshqaruvi',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.home),
            title: const Text('Bosh sahifa'),
            onTap: () => Navigator.pop(context),
          ),
          ListTile(
            leading: const Icon(Icons.calendar_today),
            title: const Text('Uchrashuvlar'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AppointmentsScreen()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.analytics),
            title: const Text('Statistika'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AnalyticsScreen()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.file_download),
            title: const Text('Eksport'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => ExportScreen()),
              );
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('Sozlamalar'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
            },
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final formatter = DateFormat('dd.MM.yyyy');
    return formatter.format(date);
  }

  String _getInitials(String fullName) {
    if (fullName.isEmpty) return '';

    List<String> names = fullName.split(' ');
    String initials = '';

    for (var name in names) {
      if (name.isNotEmpty) {
        initials += name[0].toUpperCase();

        if (initials.length >= 2) break;
      }
    }

    return initials;
  }

  void _showDeleteConfirmation(
      BuildContext context, Patient patient, int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Bemorni o\'chirish'),
        content: Text(
            'Haqiqatan ham ${patient.fullName} ma\'lumotlarini o\'chirishni xohlaysizmi?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Bekor qilish'),
          ),
          TextButton(
            onPressed: () {
              // Delete patient logic
              patient
                  .delete(); // Use patient.delete() instead of box.deleteAt(index) for better performance
              Navigator.pop(context);

              // Clear cache after deletion
              _clearCache();

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${patient.fullName} o\'chirildi'),
                ),
              );
            },
            child: Text(
              'O\'chirish',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}
