import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:stomotologiya_app/models/patient.dart';
import 'package:flutter/foundation.dart';

class PatientService {
  bool _isInitialized = false;
  final SupabaseClient _supabase = Supabase.instance.client;
  final String _tableName = Patient.tableName;

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Verify Supabase connection
      await _supabase.from(_tableName).select().limit(1).maybeSingle();
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

  // Barcha bemorlarni olish (real vaqtda yangilanadigan)
  Stream<List<Patient>> getPatients() {
    if (!_isInitialized) {
      throw StateError(
          'PatientService is not initialized. Call initialize() first.');
    }

    return _supabase
        .from(_tableName)
        .stream(primaryKey: ['id'])
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

  // ID bo'yicha bitta bemorni olish
  Future<Patient?> getPatientById(String id) async {
    if (!_isInitialized) {
      throw StateError(
          'PatientService is not initialized. Call initialize() first.');
    }

    try {
      final response =
          await _supabase.from(_tableName).select().eq('id', id).single();
      return Patient.fromMap(Map<String, dynamic>.from(response));
    } catch (e) {
      if (kDebugMode) {
        print('Error in getPatientById: $e');
      }
      return null;
    }
  }

  // Yangi bemor qo'shish
  Future<Patient> addPatient(Patient patient) async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      final response = await _supabase
          .from(_tableName)
          .insert(patient.toJson())
          .select()
          .single();

      return Patient.fromJson(response);
    } on PostgrestException catch (e) {
      throw Exception('Bemor qo\'shishda xatolik: ${e.message}');
    } catch (e) {
      throw Exception('Xatolik yuz berdi: $e');
    }
  }

  // Bemor ma'lumotlarini yangilash
  Future<Patient> updatePatient(Patient patient) async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      if (patient.id == null) {
        throw Exception('Bemor ID si topilmadi');
      }

      final response = await _supabase
          .from(_tableName)
          .update(patient.toJson())
          .eq('id', patient.id!)
          .select()
          .single();

      return Patient.fromJson(response);
    } on PostgrestException catch (e) {
      throw Exception('Bemorni yangilashda xatolik: ${e.message}');
    } catch (e) {
      throw Exception('Xatolik yuz berdi: $e');
    }
  }

  // Bemor ma'lumotlarini o'chirish
  Future<void> deletePatient(String id) async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      await _supabase
          .from(_tableName)
          .delete()
          .eq('id', id);
    } on PostgrestException catch (e) {
      throw Exception('Bemorni o\'chirishda xatolik: ${e.message}');
    } catch (e) {
      throw Exception('Xatolik yuz berdi: $e');
    }
  }

  // Telefon raqami orqali qidirish
  Stream<List<Patient>> searchByPhone(String phone) {
    return _supabase
        .from(_tableName)
        .stream(primaryKey: ['id'])
        .map((data) => data
            .where((item) =>
                (item['telefon_raqami'] as String?)
                    ?.toLowerCase()
                    .contains(phone.toLowerCase()) ??
                false)
            .map((json) => Patient.fromMap(Map<String, dynamic>.from(json)))
            .toList());
  }

  // Ism orqali qidirish
  Stream<List<Patient>> searchByName(String name) {
    return _supabase
        .from(_tableName)
        .stream(primaryKey: ['id'])
        .map((data) => data
            .where((item) =>
                (item['ismi'] as String?)
                    ?.toLowerCase()
                    .contains(name.toLowerCase()) ??
                false)
            .map((json) => Patient.fromMap(Map<String, dynamic>.from(json)))
            .toList());
  }
}
