import 'dart:io';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:lottie/lottie.dart';
import 'package:stomotologiya_app/screens/export.dart';
import 'package:stomotologiya_app/screens/patients/add_patient_screen.dart';
import 'package:stomotologiya_app/screens/patients/patient_info.dart';
import '../models/patient.dart';
import '../service/export2excel.dart';

class HomeScreen extends StatefulWidget {
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  var box = Hive.box<Patient>('patients');

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Patient> _getFilteredPatients() {
    if (_searchQuery.isEmpty) {
      return box.values.toList();
    }

    return box.values.where((patient) {
      return patient.fullName
              .toLowerCase()
              .contains(_searchQuery.toLowerCase()) ||
          patient.phoneNumber.contains(_searchQuery);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
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
            onPressed: () {
              // Show analytics dashboard
              ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Statistika tez orada qo\'shiladi')));
            },
          ),
          IconButton(
            icon: Icon(Icons.settings_outlined, color: Colors.blue[800]),
            onPressed: () {
              // Navigate to settings screen
              ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Sozlamalar tez orada qo\'shiladi')));
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
            child: ValueListenableBuilder(
              valueListenable: box.listenable(),
              builder: (context, box, widget) {
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
                    itemBuilder: (context, index) {
                      final patient = filteredPatients[index];
                      return _buildPatientCard(context, patient, index);
                    },
                  );
                }
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
              context, MaterialPageRoute(builder: (_) => AddPatientScreen()));
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

  Widget _buildPatientCard(BuildContext context, Patient patient, int index) {
    final bool hasUpcomingAppointment = false; // Replace with actual logic

    return Card(
      elevation: 1,
      margin: EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
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
        child: Padding(
          padding: EdgeInsets.all(12),
          child: Row(
            children: [
              // Patient avatar or initials
              CircleAvatar(
                radius: 24,
                backgroundColor: Colors.blue[100],
                child: Text(
                  _getInitials(patient.fullName),
                  style: TextStyle(
                    color: Colors.blue[800],
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              SizedBox(width: 16),
              // Patient details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          patient.fullName,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        if (hasUpcomingAppointment) ...[
                          SizedBox(width: 8),
                          Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.green[100],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'Bugun',
                              style: TextStyle(
                                color: Colors.green[800],
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.phone, size: 14, color: Colors.grey[600]),
                        SizedBox(width: 4),
                        Text(
                          patient.phoneNumber,
                          style: TextStyle(
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    // Additional metadata (can be dynamically added based on patient data)
                    Container(
                      height: 30,
                      width: MediaQuery.sizeOf(context).width,
                      child: ListView(
                        physics: BouncingScrollPhysics(),
                        scrollDirection: Axis.horizontal,
                        children: [
                          _buildInfoChip(
                              Icons.calendar_today, 'So\'nggi: 12.04.2025'),
                          SizedBox(width: 12),
                          _buildInfoChip(
                              Icons.medical_services, patient.complaint),
                        ],
                      ),
                    )
                  ],
                ),
              ),
              // Actions
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: Icon(Icons.delete_outline, color: Colors.red[400]),
                    onPressed: () {
                      _showDeleteConfirmation(context, patient, index);
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: Colors.grey[700]),
          SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }

  Widget _filterChip({required String label, required bool isSelected}) {
    return Container(
      margin: EdgeInsets.only(right: 8),
      child: FilterChip(
        selected: isSelected,
        label: Text(label),
        onSelected: (selected) {
          // Implement filter logic
          setState(() {
            // Update filter state
          });
        },
        backgroundColor: Colors.grey[200],
        selectedColor: Colors.blue[100],
        checkmarkColor: Colors.blue[800],
        labelStyle: TextStyle(
          color: isSelected ? Colors.blue[800] : Colors.grey[800],
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
    );
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
              box.deleteAt(index);
              Navigator.pop(context);

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
