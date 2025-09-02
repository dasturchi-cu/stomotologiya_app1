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
          Container(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 2,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TextField(
              controller: _searchController,
              style: const TextStyle(fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Bemor ismi yoki telefon raqami...',
                hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 14),
                prefixIcon: Icon(Icons.search, color: Colors.grey.shade500, size: 20),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                isDense: true,
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

                        final hasPhone = patient.telefonRaqami?.isNotEmpty ?? false;
                        
                        return Container(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 6.0,
                            vertical: 2.0,
                          ),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade200, width: 1),
                            borderRadius: BorderRadius.circular(6.0),
                            color: index % 2 == 0 ? Colors.white : Colors.grey.shade50,
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(6.0),
                              onTap: () {
                                Navigator.pushNamed(
                                  context,
                                  '/patient_details',
                                  arguments: patient.id,
                                );
                              },
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12.0,
                                  vertical: 8.0,
                                ),
                                child: Row(
                                  children: [
                                    // Initials avatar
                                    Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        color: Theme.of(context).primaryColor.withOpacity(0.1),
                                        shape: BoxShape.circle,
                                      ),
                                      alignment: Alignment.center,
                                      child: Text(
                                        patient.ismi.isNotEmpty 
                                            ? patient.ismi[0].toUpperCase()
                                            : '?',
                                        style: TextStyle(
                                          color: Theme.of(context).primaryColor,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    // Patient details
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            patient.ismi,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 15,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 2),
                                          if (hasPhone) Row(
                                            children: [
                                              const Icon(
                                                Icons.phone_android,
                                                size: 12,
                                                color: Colors.grey,
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                patient.telefonRaqami!,
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 2),
                                          Row(
                                            children: [
                                              const Icon(
                                                Icons.calendar_today,
                                                size: 12,
                                                color: Colors.blueGrey,
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                lastVisit,
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.blueGrey,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    // Status indicator
                                    Container(
                                      width: 8,
                                      height: 8,
                                      decoration: BoxDecoration(
                                        color: patient.tashrifSanalari.length > 1 
                                            ? Colors.green
                                            : Colors.orange,
                                        shape: BoxShape.circle,
                                      ),
                                      margin: const EdgeInsets.only(left: 8),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
      floatingActionButton: SizedBox(
        height: 48,
        child: FloatingActionButton.extended(
          onPressed: () {
            Navigator.pushNamed(context, '/add_patient').then((_) {
              _loadPatients();
            });
          },
          icon: const Icon(Icons.add, size: 20),
          label: const Text('YANGI', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8.0),
          ),
        ),
      ),
    );
  }
}
