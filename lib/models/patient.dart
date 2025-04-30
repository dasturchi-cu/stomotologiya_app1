import 'package:hive/hive.dart';

part 'patient.g.dart'; // To'g'ri yozilishi

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
  String imagePath;

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
  });
}
