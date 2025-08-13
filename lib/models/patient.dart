import 'package:hive/hive.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

part 'patient.g.dart';

@HiveType(typeId: 0)
class Patient extends HiveObject {
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
  String imagePath; // Kept for backward compatibility

  @HiveField(10)
  List<String> imagePaths; // Field for multiple images

  @HiveField(11)
  List<DateTime> visitDates; // New field for tracking visit dates

  Patient({
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
  }) : visitDates = visitDates ?? [firstVisitDate];

  // Helper method to get all image paths (including legacy single path)
  List<String> getAllImagePaths() {
    List<String> allPaths = List.from(imagePaths);
    if (imagePath.isNotEmpty && !imagePaths.contains(imagePath)) {
      allPaths.add(imagePath);
    }
    return allPaths;
  }

  // Add a new visit date
  void addVisitDate(DateTime visitDate) {
    visitDates.add(visitDate);
    save(); // Auto-save when adding a visit date
  }

  // Get the most recent visit date
  DateTime get lastVisitDate {
    if (visitDates.isEmpty) {
      return firstVisitDate;
    }
    return visitDates.reduce((max, date) => date.isAfter(max) ? date : max);
  }

  // Convert Patient to Firestore Map
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
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  // Create Patient from Firestore Document
  factory Patient.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Patient(
      fullName: data['fullName'] ?? '',
      birthDate: (data['birthDate'] as Timestamp).toDate(),
      phoneNumber: data['phoneNumber'] ?? '',
      firstVisitDate: (data['firstVisitDate'] as Timestamp).toDate(),
      complaint: data['complaint'] ?? '',
      speaksRussian: data['speaksRussian'] ?? '',
      speaksEnglish: data['speaksEnglish'] ?? '',
      speaksUzbek: data['speaksUzbek'] ?? '',
      address: data['address'] ?? '',
      imagePath: data['imagePath'] ?? '',
      imagePaths: List<String>.from(data['imagePaths'] ?? []),
      visitDates: (data['visitDates'] as List<dynamic>?)
              ?.map((timestamp) => (timestamp as Timestamp).toDate())
              .toList() ??
          [],
    );
  }

  // Get Firestore document ID (for updates)
  String? get firestoreId => box?.key as String?;

  Patient copyWith({
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
  }) {
    return Patient(
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
      imagePaths: imagePaths ?? this.imagePaths,
      visitDates: visitDates ?? this.visitDates,
    );
  }
}
