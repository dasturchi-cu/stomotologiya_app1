import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:stomotologiya_app/models/patient.dart';
import 'package:stomotologiya_app/service/export2excel.dart';
import 'package:stomotologiya_app/service/patient_service.dart';

// TODO: Uncomment when patient info screen is implemented
// import 'package:stomotologiya_app/screens/patients/patient_info.dart';

class PatientListScreen extends StatefulWidget {
  const PatientListScreen({Key? key}) : super(key: key);

  @override
  _PatientListScreenState createState() => _PatientListScreenState();
}

class _PatientListScreenState extends State<PatientListScreen> {
  final PatientService _patientService = PatientService();
  final TextEditingController _searchController = TextEditingController();

  List<Patient> _patients = [];
  bool _isLoading = true;
  String? _error;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _patientService.initialize();
    _loadPatients();
  }

  Future<void> _loadPatients() async {
    try {
      if (!mounted) return;
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final patients = await _patientService.getAllPatients();

      if (mounted) {
        setState(() {
          _patients = patients;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Bemorlarni yuklashda xatolik yuz berdi: ${e.toString()}';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _searchPatients(String query) async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Perform searches in parallel
      final nameSearch = _patientService.searchByName(query);
      final phoneSearch = _patientService.searchByPhone(query);
      final results = await Future.wait([nameSearch, phoneSearch]);

      final nameResults = results[0];
      final phoneResults = results[1];

      // Combine and deduplicate results using a Map
      final allResults = <String, Patient>{};
      for (var p in nameResults) {
        allResults[p.id!] = p;
      }
      for (var p in phoneResults) {
        allResults[p.id!] = p;
      }

      if (mounted) {
        setState(() {
          _patients = allResults.values.toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Qidirishda xatolik: ${e.toString()}';
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  // Export patients to Excel
  Future<void> _exportToExcel() async {
    try {
      await ExportService.exportPatientsToExcel(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Eksport qilishda xatolik: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Refresh patient list
  Future<void> _refreshPatients() async {
    await _loadPatients();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Xatolik')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              _error!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: _loadPatients,
          child: const Icon(Icons.refresh),
        ),
      );
    }

    final patients = _patients;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bemorlar Ro\'yxati'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshPatients,
            tooltip: 'Yangilash',
          ),
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: _exportToExcel,
            tooltip: 'Excelga yuklab olish',
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: 'Qidirish...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(10.0)),
                ),
              ),
              onChanged: (value) {
                if (_debounce?.isActive ?? false) _debounce!.cancel();
                _debounce = Timer(const Duration(milliseconds: 500), () {
                  final query = value.trim();
                  if (query.isNotEmpty) {
                    _searchPatients(query);
                  } else {
                    _loadPatients();
                  }
                });
              },
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _refreshPatients,
              child: patients.isEmpty
                  ? const Center(
                      child: Text(
                        'Bemorlar topilmadi',
                        style: TextStyle(fontSize: 16),
                      ),
                    )
                  : ListView.builder(
                      itemCount: patients.length,
                      itemBuilder: (context, index) {
                        final patient = patients[index];
                        final lastVisit = patient.tashrifSanalari.isNotEmpty
                            ? DateFormat('dd.MM.yyyy').format(
                                DateTime.parse(patient.tashrifSanalari.last))
                            : 'Tashrif mavjud emas';

                        return Card(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 8.0,
                            vertical: 4.0,
                          ),
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                          child: ListTile(
                            title: Text(
                              patient.ismi,
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                                                Text(
                                  patient.telefonRaqami ?? 'Raqam kiritilmagan',
                                  style: const TextStyle(color: Colors.grey),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Oxirgi tashrif: $lastVisit',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.blueGrey,
                                  ),
                                ),
                              ],
                            ),
                            trailing:
                                const Icon(Icons.arrow_forward_ios, size: 16),
                            onTap: () {
                              // TODO: Navigate to patient details screen
                              Navigator.pushNamed(
                                context,
                                '/patient_details',
                                arguments: patient.id,
                              );
                            },
                          ),
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.pushNamed(context, '/add_patient').then((_) {
            _loadPatients();
          });
        },
        icon: const Icon(Icons.person_add),
        label: const Text('Bemor qo\'shish'),
        backgroundColor: Theme.of(context).primaryColor,
      ),
    );
  }
}
