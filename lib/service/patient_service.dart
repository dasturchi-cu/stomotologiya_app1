import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:stomotologiya_app/models/patient.dart';

class PatientService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collectionName = Patient.collectionName;

  // Barcha bemorlarni olish (real vaqtda yangilanadigan)
  Stream<List<Patient>> getPatients() {
    return _firestore
        .collection(_collectionName)
        .orderBy('lastUpdated', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Patient.fromFirestore(doc))
            .toList());
  }

  // ID bo'yicha bitta bemorni olish
  Future<Patient?> getPatientById(String id) async {
    final doc = await _firestore.collection(_collectionName).doc(id).get();
    if (doc.exists) {
      return Patient.fromFirestore(doc);
    }
    return null;
  }

  // Yangi bemor qo'shish
  Future<DocumentReference> addPatient(Patient patient) async {
    return await patient.addToFirestore();
  }

  // Bemor ma'lumotlarini yangilash
  Future<void> updatePatient(Patient patient) async {
    await patient.updateFirestore();
  }

  // Bemor ma'lumotlarini o'chirish
  Future<void> deletePatient(String id) async {
    await _firestore.collection(_collectionName).doc(id).delete();
  }

  // Telefon raqami orqali qidirish
  Stream<List<Patient>> searchByPhone(String phone) {
    return _firestore
        .collection(_collectionName)
        .where('phoneNumber', isGreaterThanOrEqualTo: phone)
        .where('phoneNumber', isLessThan: '${phone}z')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Patient.fromFirestore(doc))
            .toList());
  }

  // Ism orqali qidirish
  Stream<List<Patient>> searchByName(String name) {
    return _firestore
        .collection(_collectionName)
        .where('fullName', isGreaterThanOrEqualTo: name)
        .where('fullName', isLessThan: '${name}z')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Patient.fromFirestore(doc))
            .toList());
  }
}
