// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'patient.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class PatientAdapter extends TypeAdapter<Patient> {
  @override
  final int typeId = 0;

  @override
  Patient read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Patient(
      fullName: fields[0] as String,
      birthDate: fields[1] as DateTime,
      phoneNumber: fields[2] as String,
      firstVisitDate: fields[3] as DateTime,
      complaint: fields[4] as String,
      speaksRussian: fields[5] as String,
      speaksEnglish: fields[6] as String,
      speaksUzbek: fields[7] as String,
      address: fields[8] as String,
      imagePath: fields[9] as String,
      imagePaths: (fields[10] as List).cast<String>(),
      visitDates: (fields[11] as List?)?.cast<DateTime>(),
    );
  }

  @override
  void write(BinaryWriter writer, Patient obj) {
    writer
      ..writeByte(12)
      ..writeByte(0)
      ..write(obj.fullName)
      ..writeByte(1)
      ..write(obj.birthDate)
      ..writeByte(2)
      ..write(obj.phoneNumber)
      ..writeByte(3)
      ..write(obj.firstVisitDate)
      ..writeByte(4)
      ..write(obj.complaint)
      ..writeByte(5)
      ..write(obj.speaksRussian)
      ..writeByte(6)
      ..write(obj.speaksEnglish)
      ..writeByte(7)
      ..write(obj.speaksUzbek)
      ..writeByte(8)
      ..write(obj.address)
      ..writeByte(9)
      ..write(obj.imagePath)
      ..writeByte(10)
      ..write(obj.imagePaths)
      ..writeByte(11)
      ..write(obj.visitDates);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PatientAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
