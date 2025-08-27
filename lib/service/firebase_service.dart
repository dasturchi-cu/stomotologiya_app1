import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:stomotologiya_app/models/patient.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class FirebaseService {
  static final FirebaseService _instance = FirebaseService._internal();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final SupabaseClient _supabase = Supabase.instance.client;

  factory FirebaseService() {
    return _instance;
  }

  FirebaseService._internal();

  // Patient CRUD Operations
  Stream<List<Patient>> getPatients() {
    return _firestore
        .collection(Patient.collectionName)
        .orderBy('lastUpdated', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Patient.fromFirestore(doc)).toList());
  }

  Future<DocumentReference> addPatient(Patient patient) async {
    final docRef = await _firestore
        .collection(Patient.collectionName)
        .add(patient.toFirestore());
    return docRef;
  }

  Future<void> updatePatient(Patient patient) async {
    if (patient.reference != null) {
      await patient.reference!.update(patient.toFirestore());
    }
  }

  Future<void> deletePatient(String id) async {
    await _firestore.collection(Patient.collectionName).doc(id).delete();
  }

  // Rasmni yuklash va URL manzilini qaytarish (Supabase Storage orqali)
  Future<String> uploadPatientImage(String patientId, File imageFile) async {
    try {
      final fileName = 'patient_${patientId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final filePath = 'patient_images/$patientId/$fileName';
      
      // Faylni Supabase Storage ga yuklash
      await _supabase.storage
          .from('patient_images')
          .upload(filePath, imageFile);
      
      // Ommaviy URL manzilini olish
      final String publicUrl = _supabase.storage
          .from('patient_images')
          .getPublicUrl(filePath);
          
      return publicUrl;
    } catch (e) {
      throw Exception('Rasm yuklashda xatolik yuz berdi: $e');
    }
  }

  // Search patients
  Stream<List<Patient>> searchPatients(String query) {
    return _firestore
        .collection(Patient.collectionName)
        .where('searchTerms', arrayContains: query.toLowerCase())
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Patient.fromFirestore(doc)).toList());
  }
}
