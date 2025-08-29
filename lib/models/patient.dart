import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

part 'patient.g.dart';

@HiveType(typeId: 0)
class Patient extends HiveObject {
  static const String tableName = 'User';

  @HiveField(0)
  String? id;

  @HiveField(1)
  String ismi;

  @HiveField(2)
  DateTime tugilganSana;

  @HiveField(3)
  String telefonRaqami;

  @HiveField(4)
  DateTime birinchiKelganSana;

  @HiveField(5)
  String shikoyat;

  @HiveField(6)
  String manzil;

  @HiveField(7)
  String rasmManzili;

  @HiveField(8)
  List<String> rasmlarManzillari;

  @HiveField(9)
  List<String> tashrifSanalari;

  @HiveField(10)
  DateTime? createdAt;

  @HiveField(11)
  DateTime? updatedAt;

  Patient({
    this.id,
    required this.ismi,
    required this.tugilganSana,
    required this.telefonRaqami,
    required this.birinchiKelganSana,
    required this.shikoyat,
    required this.manzil,
    this.rasmManzili = '',
    List<String>? rasmlarManzillari,
    List<String>? tashrifSanalari,
    this.createdAt,
    this.updatedAt,
  })  : rasmlarManzillari = rasmlarManzillari ?? [],
        tashrifSanalari = tashrifSanalari ?? [];

  /// Get all image paths including the legacy imagePath
  List<String> getAllImagePaths() {
    final allPaths = List<String>.from(rasmlarManzillari);
    if (rasmManzili.isNotEmpty && !rasmlarManzillari.contains(rasmManzili)) {
      allPaths.add(rasmManzili);
    }
    return allPaths;
  }

  /// Add a new visit date
  void addVisitDate(DateTime visitDate) {
    tashrifSanalari.add(visitDate.toString());
    save();
  }

  /// Get the most recent visit date
  DateTime get lastVisitDate {
    if (tashrifSanalari.isEmpty) return birinchiKelganSana;
    return DateTime.parse(tashrifSanalari.reduce((max, date) =>
        DateTime.parse(date).isAfter(DateTime.parse(max)) ? date : max));
  }

  /// Create a copy of the patient with updated fields
  Patient copyWith({
    String? ismi,
    DateTime? tugilganSana,
    String? telefonRaqami,
    DateTime? birinchiKelganSana,
    String? shikoyat,
    String? manzil,
    String? rasmManzili,
    List<String>? rasmlarManzillari,
    List<String>? tashrifSanalari,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? id,
  }) {
    return Patient(
      ismi: ismi ?? this.ismi,
      tugilganSana: tugilganSana ?? this.tugilganSana,
      telefonRaqami: telefonRaqami ?? this.telefonRaqami,
      birinchiKelganSana: birinchiKelganSana ?? this.birinchiKelganSana,
      shikoyat: shikoyat ?? this.shikoyat,
      manzil: manzil ?? this.manzil,
      rasmManzili: rasmManzili ?? this.rasmManzili,
      rasmlarManzillari: rasmlarManzillari ?? List.from(this.rasmlarManzillari),
      tashrifSanalari: tashrifSanalari ?? List.from(this.tashrifSanalari),
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Parse date from various formats
  static DateTime _parseDate(dynamic date) {
    if (date == null) return DateTime.now();
    if (date is DateTime) return date;
    if (date is String) return DateTime.tryParse(date) ?? DateTime.now();
    return DateTime.now();
  }

  // Parse list of dates
  static List<DateTime> _parseDateList(dynamic value) {
    if (value == null) return [];
    if (value is List) {
      return value.map((e) => _parseDate(e)).toList();
    }
    return [];
  }

  // Create Patient from a Map (for Hive/Supabase)
  factory Patient.fromMap(Map<String, dynamic> map) {
    return Patient(
      id: map['id'] as String?,
      ismi: map['ismi'] as String,
      tugilganSana: DateTime.parse(map['tugilgan_sana'] as String),
      telefonRaqami: map['telefon_raqami'] as String,
      birinchiKelganSana: DateTime.parse(map['birinchi_kelgan'] as String),
      shikoyat: map['shikoyat'] as String,
      manzil: map['manzil'] as String,
      rasmManzili: map['rasm_manzili'] as String? ?? '',
      rasmlarManzillari: (map['rasmlar_manzillari'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      tashrifSanalari: (map['tashrif_sanalari'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      createdAt: null,
      updatedAt: null,
    );
  }

  // Convert to Map (for Hive/Supabase)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'ismi': ismi,
      'tugilgan_sana': tugilganSana.toIso8601String(),
      'telefon_raqami': telefonRaqami,
      'birinchi_kelgan': birinchiKelganSana.toIso8601String(),
      'shikoyat': shikoyat,
      'manzil': manzil,
      'rasm_manzili': rasmManzili,
      'rasmlar_manzillari': rasmlarManzillari,
      'tashrif_sanalari': tashrifSanalari,
    };
  }

  // Alias for toMap for backward compatibility
  Map<String, dynamic> toJson() => toMap();

  // JSON dan Patient yaratish
  factory Patient.fromJson(Map<String, dynamic> json) {
    return Patient(
      id: json['id'] as String?,
      ismi: json['ismi'] as String,
      tugilganSana: DateTime.parse(json['tugilgan_sana'] as String),
      telefonRaqami: json['telefon_raqami'] as String,
      birinchiKelganSana: DateTime.parse(json['birinchi_kelgan'] as String),
      shikoyat: json['shikoyat'] as String,
      manzil: json['manzil'] as String,
      rasmManzili: json['rasm_manzili'] as String? ?? '',
      rasmlarManzillari: (json['rasmlar_manzillari'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      tashrifSanalari: (json['tashrif_sanalari'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      createdAt: null,
      updatedAt: null,
    );
  }

  // Create Patient from Hive data
  factory Patient.fromHive(Map<dynamic, dynamic> map) {
    return Patient.fromMap(Map<String, dynamic>.from(map));
  }

  // Save to Supabase
  Future<void> saveToSupabase() async {
    try {
      final supabase = Supabase.instance.client;
      final data = toMap();

      debugPrint('Saqlash uchun ma\'lumotlar: $data');

      if (key == null) {
        // Create new record
        debugPrint('Yangi bemor yaratish...');
        final response =
            await supabase.from('User').insert(data).select().single();

        debugPrint('Supabase javob: $response');

        // Update the patient object with the ID from Supabase
        id = response['id'] as String;
        debugPrint('Yangi ID: $id');

        // Save to Hive with the new ID
        await save();
        debugPrint('Hive ga saqlandi');
      } else {
        // Update existing record
        debugPrint('Mavjud bemorni yangilash...');
        await supabase.from('User').update(data).eq('id', key);
        debugPrint('Supabase da yangilandi');
      }
    } catch (e) {
      debugPrint('saveToSupabase xatolik: $e');
      rethrow;
    }
  }
}
