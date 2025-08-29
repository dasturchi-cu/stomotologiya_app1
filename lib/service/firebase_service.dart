// import 'dart:io'; // kerak bo'ladi
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_storage/firebase_storage.dart';
// import 'package:stomotologiya_app/models/patient.dart';

// class FirebaseService {
//   static final FirebaseService _instance = FirebaseService._internal();
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;
//   final FirebaseStorage _storage = FirebaseStorage.instance;

//   factory FirebaseService() {
//     return _instance;
//   }

//   FirebaseService._internal();

//   // Patient CRUD Operations
//   Stream<List<Patient>> getPatients() {
//     return _firestore
//         .collection(Patient.collectionName)
//         .orderBy('lastUpdated', descending: true)
//         .snapshots()
//         .map((snapshot) =>
//             snapshot.docs.map((doc) => Patient.fromFirestore(doc)).toList());
//   }

//   Future<void> addPatient(Patient patient) async {
//     await _firestore
//         .collection(Patient.collectionName)
//         .add(patient.toFirestore());
//   }

//   Future<void> updatePatient(Patient patient) async {
//     if (patient.reference != null) {
//       await patient.reference!.update(patient.toFirestore());
//     }
//   }

//   Future<void> deletePatient(String id) async {
//     await _firestore.collection(Patient.collectionName).doc(id).delete();
//   }

//   // ✅ File Upload fix
//   Future<String> uploadFile(String path, String fileName) async {
//     try {
//       final ref = _storage.ref().child('patient_images/$fileName');

//       final file = File(path); // String path dan File obyekt
//       await ref.putFile(file);

//       return await ref.getDownloadURL();
//     } catch (e) {
//       throw Exception('Failed to upload file: $e');
//     }
//   }

//   // Search
//   Stream<List<Patient>> searchPatients(String query) {
//     return _firestore
//         .collection(Patient.collectionName)
//         .where('searchTerms', arrayContains: query.toLowerCase())
//         .snapshots()
//         .map((snapshot) =>
//             snapshot.docs.map((doc) => Patient.fromFirestore(doc)).toList());
//   }
// }
