import 'dart:async';

import 'package:flutter/material.dart';
import 'package:stomotologiya_app/models/patient.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PatientListScreen extends StatefulWidget {
  const PatientListScreen({Key? key}) : super(key: key);

  @override
  _PatientListScreenState createState() => _PatientListScreenState();
}

class _PatientListScreenState extends State<PatientListScreen> {
  final SupabaseClient _supabase = Supabase.instance.client;
  final TextEditingController _searchController = TextEditingController();
  
  List<Patient> _patients = [];
  bool _isLoading = true;
  String? _error;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadPatients();
  }

  Future<void> _loadPatients() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      // Load patients from Supabase
      final response = await _supabase
          .from('patients')
          .select()
          .order('created_at', ascending: false);

      if (response == null) {
        throw Exception('Failed to load patients');
      }

      final List<dynamic> data = List<dynamic>.from(response);
      setState(() {
        _patients = data.map((json) => Patient.fromJson(json)).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Bemorlarni yuklashda xatolik: $e';
        _isLoading = false;
      });
    }
  }

  List<Patient> get _filteredPatients {
    if (_searchQuery.isEmpty) return _patients;
    
    return _patients.where((patient) {
      return patient.ismi.toLowerCase().contains(_searchQuery) ||
          (patient.telefonRaqami?.toLowerCase().contains(_searchQuery) ?? false);
    }).toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
    
    final patients = _filteredPatients;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bemorlar Ro\'yxati'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadPatients,
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
                setState(() {
                  _searchQuery = value.toLowerCase().trim();
                });
              },
            ),
          ),
          Expanded(
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
                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 8.0,
                          vertical: 4.0,
                        ),
                        child: ListTile(
                          title: Text(
                            patient.ismi,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            patient.telefonRaqami ?? 'Telefon raqami kiritilmagan',
                            style: const TextStyle(color: Colors.grey),
                          ),
                          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                          onTap: () {
                            // TODO: Navigate to patient details
                            // Navigator.pushNamed(
                            //   context,
                            //   '/patient_details',
                            //   arguments: patient.id,
                            // );
                          },
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // TODO: Navigate to add patient screen
          // Navigator.pushNamed(context, '/add_patient');
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
