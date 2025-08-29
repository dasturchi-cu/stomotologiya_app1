import 'package:stomotologiya_app/models/patient.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';

class PatientService {
  bool _isInitialized = false;
  SupabaseClient? _supabase;
  final String _tableName = Patient.tableName;

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Initialize Supabase client
      _supabase = Supabase.instance.client;

      // Verify Supabase connection
      await _supabase!.from(_tableName).select().limit(1).maybeSingle();
      _isInitialized = true;

      if (kDebugMode) {
        print('PatientService initialized successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error initializing PatientService: $e');
      }
      rethrow;
    }
  }

  /// Fetches all patients as a stream (real-time updates)
  Stream<List<Patient>> getPatients() {
    if (!_isInitialized || _supabase == null) {
      throw StateError(
          'PatientService is not initialized. Call initialize() first.');
    }

    return _supabase!
        .from(_tableName)
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .map((data) => data
            .map((json) => Patient.fromMap(Map<String, dynamic>.from(json)))
            .toList())
        .handleError((error) {
          if (kDebugMode) {
            print('Error in getPatients: $error');
          }
          return <Patient>[];
        });
  }

  /// Fetches all patients at once (for exports, reports, etc.)
  /// Returns an empty list if no patients found or an error occurs
  Future<List<Patient>> getAllPatients() async {
    if (!_isInitialized || _supabase == null) {
      await initialize();
    }

    try {
      final response = await _supabase!
          .from(_tableName)
          .select()
          .order('created_at', ascending: false);

      if (response == null) return [];

      final patients = <Patient>[];
      for (final item in (response as List)) {
        try {
          final patientData = Map<String, dynamic>.from(item as Map);
          patients.add(Patient.fromMap(patientData));
        } catch (e) {
          if (kDebugMode) {
            print('Error parsing patient data: $e');
          }
          continue;
        }
      }

      return patients;
    } catch (e) {
      if (kDebugMode) {
        print('Error in getAllPatients: $e');
      }
      return [];
    }
  }

  // ID bo'yicha bitta bemorni olish
  Future<Patient?> getPatientById(String id) async {
    if (!_isInitialized || _supabase == null) {
      throw StateError(
          'PatientService is not initialized. Call initialize() first.');
    }

    try {
      final response =
          await _supabase!.from(_tableName).select().eq('id', id).single();
      return Patient.fromMap(Map<String, dynamic>.from(response));
    } catch (e) {
      if (kDebugMode) {
        print('Error in getPatientById: $e');
      }
      return null;
    }
  }

  // Yangi bemor qo'shish
  Future<String> addPatient(Patient patient) async {
    if (!_isInitialized || _supabase == null) {
      throw StateError(
          'PatientService is not initialized. Call initialize() first.');
    }

    try {
      final response = await _supabase!
          .from(_tableName)
          .insert(patient.toMap())
          .select()
          .single();
      return response['id'] as String;
    } on PostgrestException catch (e) {
      throw Exception('Bemor qo\'shishda xatolik: ${e.message}');
    } catch (e) {
      throw Exception('Xatolik yuz berdi: $e');
    }
  }

  // Bemor ma'lumotlarini yangilash
  Future<Patient> updatePatient(Patient patient) async {
    if (!_isInitialized || _supabase == null) {
      await initialize();
    }

    try {
      if (patient.id == null) {
        throw Exception('Bemor ID si topilmadi');
      }

      final response = await _supabase!
          .from(_tableName)
          .update(patient.toMap())
          .eq('id', patient.id!)
          .select()
          .single();

      return Patient.fromMap(response);
    } on PostgrestException catch (e) {
      throw Exception('Bemorni yangilashda xatolik: ${e.message}');
    } catch (e) {
      throw Exception('Xatolik yuz berdi: $e');
    }
  }

  // Bemor ma'lumotlarini o'chirish
  Future<void> deletePatient(String id) async {
    if (!_isInitialized || _supabase == null) {
      await initialize();
    }

    try {
      await _supabase!.from(_tableName).delete().eq('id', id);
    } on PostgrestException catch (e) {
      throw Exception('Bemorni o\'chirishda xatolik: ${e.message}');
    } catch (e) {
      throw Exception('Xatolik yuz berdi: $e');
    }
  }

  // Telefon raqami orqali qidirish
  Future<List<Patient>> searchByPhone(String phone) async {
    if (!_isInitialized || _supabase == null) {
      await initialize();
    }

    try {
      final response = await _supabase!
          .from(_tableName)
          .select()
          .ilike('telefon_raqami', '%$phone%');

      final patients = <Patient>[];
      for (final item in (response as List)) {
        patients.add(Patient.fromMap(Map<String, dynamic>.from(item as Map)));
      }
      return patients;
    } catch (e) {
      if (kDebugMode) {
        print('Error in searchByPhone: $e');
      }
      return [];
    }
  }

  // Ism orqali qidirish
  Future<List<Patient>> searchByName(String name) async {
    if (!_isInitialized || _supabase == null) {
      await initialize();
    }

    try {
      final response =
          await _supabase!.from(_tableName).select().ilike('ismi', '%$name%');

      final patients = <Patient>[];
      for (final item in (response as List)) {
        patients.add(Patient.fromMap(Map<String, dynamic>.from(item as Map)));
      }
      return patients;
    } catch (e) {
      if (kDebugMode) {
        print('Error in searchByName: $e');
      }
      return [];
    }
  }
}
