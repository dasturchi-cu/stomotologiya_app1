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
      id: fields[0] as String?,
      ismi: fields[1] as String,
      tugilganSana: fields[2] as DateTime,
      telefonRaqami: fields[3] as String,
      birinchiKelganSana: fields[4] as DateTime,
      shikoyat: fields[5] as String,
      manzil: fields[6] as String,
      rasmManzili: fields[7] as String,
      rasmlarManzillari: (fields[8] as List?)?.cast<String>(),
      tashrifSanalari: (fields[9] as List?)?.cast<String>(),
      createdAt: fields[10] as DateTime?,
      updatedAt: fields[11] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, Patient obj) {
    writer
      ..writeByte(12)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.ismi)
      ..writeByte(2)
      ..write(obj.tugilganSana)
      ..writeByte(3)
      ..write(obj.telefonRaqami)
      ..writeByte(4)
      ..write(obj.birinchiKelganSana)
      ..writeByte(5)
      ..write(obj.shikoyat)
      ..writeByte(6)
      ..write(obj.manzil)
      ..writeByte(7)
      ..write(obj.rasmManzili)
      ..writeByte(8)
      ..write(obj.rasmlarManzillari)
      ..writeByte(9)
      ..write(obj.tashrifSanalari)
      ..writeByte(10)
      ..write(obj.createdAt)
      ..writeByte(11)
      ..write(obj.updatedAt);
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
