import 'package:hive/hive.dart';

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
