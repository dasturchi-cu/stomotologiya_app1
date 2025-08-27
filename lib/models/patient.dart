import 'package:hive/hive.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

part 'patient.g.dart';

@HiveType(typeId: 0)
class Patient extends HiveObject {
  static const String collectionName = 'patients';

  // Firestore integration fields
  @HiveField(12, defaultValue: null)
  String? id;

  @HiveField(13, defaultValue: null)
  DocumentReference? reference;

  @HiveField(14, defaultValue: null)
  DateTime? lastUpdated;

  @HiveField(15, defaultValue: false)
  bool syncedWithFirestore;

  @HiveField(0)
  final String fullName;

  @HiveField(1)
  final DateTime birthDate;

  @HiveField(2)
  final String phoneNumber;

  @HiveField(3)
  final DateTime firstVisitDate;

  @HiveField(4)
  final String complaint;

  @HiveField(5)
  final String speaksRussian;

  @HiveField(6)
  final String speaksEnglish;

  @HiveField(7)
  final String speaksUzbek;

  @HiveField(8)
  final String address;

  @HiveField(9)
  String imagePath; // Eski versiyalar bilan moslik uchun

  @HiveField(10)
  List<String> imagePaths; // Bir nechta rasm uchun

  @HiveField(11)
  List<DateTime> visitDates; // Bemor tashriflari tarixi

  // For Firestore document ID
  String? get documentId => id ?? reference?.id;

  // Create Patient from Firestore document
  factory Patient.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    return Patient(
      id: doc.id,
      fullName: data['fullName'] ?? '',
      birthDate: (data['birthDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      phoneNumber: data['phoneNumber'] ?? '',
      firstVisitDate: (data['firstVisitDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      complaint: data['complaint'] ?? '',
      address: data['address'] ?? '',
      speaksRussian: data['speaksRussian'] ?? 'Yo\'q',
      speaksEnglish: data['speaksEnglish'] ?? 'Yo\'q',
      speaksUzbek: data['speaksUzbek'] ?? 'Ha',
      imagePath: data['imagePath'] ?? '',
      imagePaths: List<String>.from(data['imagePaths'] ?? []),
      visitDates: (data['visitDates'] as List<dynamic>?)
          ?.map((e) => (e as Timestamp).toDate())
          .toList() ?? [DateTime.now()],
      lastUpdated: (data['lastUpdated'] as Timestamp?)?.toDate(),
      syncedWithFirestore: data['syncedWithFirestore'] ?? true,
    )..reference = doc.reference;
  }

  // Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'fullName': fullName,
      'birthDate': Timestamp.fromDate(birthDate),
      'phoneNumber': phoneNumber,
      'firstVisitDate': Timestamp.fromDate(firstVisitDate),
      'complaint': complaint,
      'speaksRussian': speaksRussian,
      'speaksEnglish': speaksEnglish,
      'speaksUzbek': speaksUzbek,
      'address': address,
      'imagePath': imagePath,
      'imagePaths': imagePaths,
      'visitDates': visitDates.map((date) => Timestamp.fromDate(date)).toList(),
      'lastUpdated': FieldValue.serverTimestamp(),
      'syncedWithFirestore': syncedWithFirestore,
    };
  }

  Patient({
    this.id,
    required this.fullName,
    required this.birthDate,
    required this.phoneNumber,
    required this.firstVisitDate,
    required this.complaint,
    required this.speaksRussian,
    required this.speaksEnglish,
    required this.speaksUzbek,
    required this.address,
    this.imagePath = '',
    this.imagePaths = const [],
    List<DateTime>? visitDates,
    this.lastUpdated,
    this.syncedWithFirestore = false,
  }) : visitDates = visitDates ?? [firstVisitDate];

  /// Barcha rasmlar ro‘yxatini qaytaradi
  List<String> getAllImagePaths() {
    List<String> allPaths = List.from(imagePaths);
    if (imagePath.isNotEmpty && !imagePaths.contains(imagePath)) {
      allPaths.add(imagePath);
    }
    return allPaths;
  }

  /// Yangi tashrif qo‘shish
  void addVisitDate(DateTime visitDate) {
    visitDates.add(visitDate);
    save(); // Hive’da avtomatik saqlash
  }

  /// Oxirgi tashrif sanasi
  DateTime get lastVisitDate {
    if (visitDates.isEmpty) {
      return firstVisitDate;
    }
    return visitDates.reduce((max, date) => date.isAfter(max) ? date : max);
  }

  /// Bemor obyektidan nusxa olish (copyWith)
  Patient copyWith({
    String? id,
    String? fullName,
    DateTime? birthDate,
    String? phoneNumber,
    DateTime? firstVisitDate,
    String? complaint,
    String? speaksRussian,
    String? speaksEnglish,
    String? speaksUzbek,
    String? address,
    String? imagePath,
    List<String>? imagePaths,
    List<DateTime>? visitDates,
    DateTime? lastUpdated,
    bool? syncedWithFirestore,
    DocumentReference? reference,
  }) {
    return Patient(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      birthDate: birthDate ?? this.birthDate,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      firstVisitDate: firstVisitDate ?? this.firstVisitDate,
      complaint: complaint ?? this.complaint,
      speaksRussian: speaksRussian ?? this.speaksRussian,
      speaksEnglish: speaksEnglish ?? this.speaksEnglish,
      speaksUzbek: speaksUzbek ?? this.speaksUzbek,
      address: address ?? this.address,
      imagePath: imagePath ?? this.imagePath,
      imagePaths: imagePaths ?? List.from(this.imagePaths),
      visitDates: visitDates ?? List.from(this.visitDates),
      lastUpdated: lastUpdated ?? this.lastUpdated,
      syncedWithFirestore: syncedWithFirestore ?? this.syncedWithFirestore,
    )..reference = reference ?? this.reference;
  }


  // Generate search terms for better search functionality
  List<String> _generateSearchTerms() {
    final terms = <String>[];
    terms.addAll(fullName.toLowerCase().split(' '));
    terms.add(phoneNumber.replaceAll(RegExp(r'[^0-9]'), ''));
    terms.addAll(complaint.toLowerCase().split(' '));
    terms.addAll(address.toLowerCase().split(' '));
    return terms.where((term) => term.length > 2).toSet().toList();
  }


  // Firestore'ga yangilash
  Future<void> updateFirestore() async {
    if (reference != null) {
      await reference!.update(toFirestore());
    }
  }

  // Firestore'ga yangi bemor qo'shish
  Future<DocumentReference> addToFirestore() async {
    final docRef = await FirebaseFirestore.instance
        .collection(collectionName)
        .add(toFirestore());
    reference = docRef;
    return docRef;
  }

  // Firestore'dan o'chirish
  Future<void> deleteFromFirestore() async {
    if (reference != null) {
      await reference!.delete();
    }
  }
}
