import 'dart:async';
import 'package:flutter/material.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';
import 'package:stomotologiya_app/routes.dart';
import '../models/patient.dart';
import '../service/auth_service.dart';

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
  final _authService = AuthService();

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
        });
      }
    });
  }

  Future<void> _refreshData() async {
    setState(() {
      _isLoading = true;
    });

    // Simulate a small delay for refresh animation
    await Future.delayed(const Duration(milliseconds: 300));

    setState(() {
      _isLoading = false;
    });
  }

  void _clearCache() {}

  List<Patient> _getFilteredPatients() {
    if (_searchQuery.isEmpty) {
      return box.values.toList();
    }
    final query = _searchQuery.toLowerCase();
    return box.values.where((patient) {
      final fullNameLower = patient.fullName.toLowerCase();
      final phoneNumber = patient.phoneNumber;
      final complaintLower = patient.complaint.toLowerCase();
      return fullNameLower.contains(query) ||
          phoneNumber.contains(_searchQuery) ||
          complaintLower.contains(query);
    }).toList();
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
            onPressed: () => Navigator.pushNamed(context, AppRoutes.export),
          ),
          IconButton(
            icon: Icon(Icons.analytics_outlined, color: Colors.blue[800]),
            tooltip: 'Statistika',
            onPressed: () {
              Navigator.pushNamed(context, AppRoutes.analytics);
            },
          ),
          // IconButton(
          //   icon: Icon(Icons.settings_outlined, color: Colors.blue[800]),
          //   tooltip: 'Sozlamalar',
          //   onPressed: () {
          //     Navigator.push(
          //       context,
          //       MaterialPageRoute(builder: (_) => const SettingsScreen()),
          //     );
          //   },
          // ),
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
          final result =
              await Navigator.pushNamed(context, AppRoutes.addPatient);
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
              Navigator.pushNamed(context, AppRoutes.addPatient);
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
              Navigator.pushNamed(
                context,
                AppRoutes.patientDetails,
                arguments: patient,
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
          // Actions (edit removed by request)
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
    final user = _authService.currentUser;

    return Drawer(
      backgroundColor: Colors.grey[50],
      child: SafeArea(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            Container(
              margin: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(
                  colors: [
                    Colors.blue[700]!,
                    Colors.blue[400]!,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.withOpacity(0.25),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 26,
                    backgroundColor: Colors.white.withOpacity(0.2),
                    child: const Icon(
                      Icons.medical_services,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'StomoTrack',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.3,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          user?.displayName?.isNotEmpty == true
                              ? user!.displayName!
                              : 'Bemorlar boshqaruvi',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 13,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: _buildDrawerItem(
                context,
                icon: Icons.home_rounded,
                label: 'Bosh sahifa',
                onTap: () => Navigator.pop(context),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: _buildDrawerItem(
                context,
                icon: Icons.analytics_rounded,
                label: 'Statistika',
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, AppRoutes.analytics);
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: _buildDrawerItem(
                context,
                icon: Icons.file_download_rounded,
                label: 'Eksport',
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, AppRoutes.export);
                },
              ),
            ),

            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(child: Divider(color: Colors.grey[300]!, height: 1)),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // Logout (hozircha yashirilgan)
            // Padding(
            //   padding: const EdgeInsets.symmetric(horizontal: 12),
            //   child: _buildDrawerItem(
            //     context,
            //     icon: Icons.logout_rounded,
            //     label: 'Tizimdan chiqish',
            //     iconColor: Colors.red,
            //     textColor: Colors.red,
            //     onTap: () => _showLogoutDialog(),
            //   ),
            // ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    Color? iconColor,
    Color? textColor,
    required VoidCallback onTap,
  }) {
    final baseIconColor = iconColor ?? Colors.blueGrey[700];
    final baseTextColor = textColor ?? Colors.blueGrey[900];
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ListTile(
        leading: Icon(icon, color: baseIconColor),
        title: Text(
          label,
          style: TextStyle(
            color: baseTextColor,
            fontWeight: FontWeight.w600,
          ),
        ),
        trailing: Icon(Icons.chevron_right_rounded, color: Colors.grey[400]),
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
