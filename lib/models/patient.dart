import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

part 'patient.g.dart';

/// Hive type id – change only if it collides with another type in your app.
@HiveType(typeId: 0)
class Patient extends HiveObject {
  // -------------------------------------------------
  // 1️⃣  Table name – must exist in Supabase
  // -------------------------------------------------
  static const String tableName = 'patients';

  // -------------------------------------------------
  // 2️⃣  Columns – names must match the columns in Supabase
  // -------------------------------------------------
  @HiveField(0)
  String? id; // uuid primary key

  @HiveField(1)
  String ismi;
//maana
  @HiveField(2)
  DateTime tugilganSana;

  @HiveField(3)
  String? telefonRaqami;

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

  @HiveField(12)
  String? userId; // User ID to associate patient with specific user

  // -------------------------------------------------
  // 3️⃣  Constructor
  // -------------------------------------------------
  Patient({
    this.id,
    required this.ismi,
    required this.tugilganSana,
    this.telefonRaqami,
    required this.birinchiKelganSana,
    required this.shikoyat,
    required this.manzil,
    this.rasmManzili = '',
    List<String>? rasmlarManzillari,
    List<String>? tashrifSanalari,
    this.createdAt,
    this.updatedAt,
    this.userId,
  })  : rasmlarManzillari = rasmlarManzillari ?? [],
        tashrifSanalari = tashrifSanalari ?? [];

  Patient copyWith({
    String? id,
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
    String? userId,
  }) {
    return Patient(
      id: id ?? this.id,
      ismi: ismi ?? this.ismi,
      tugilganSana: tugilganSana ?? this.tugilganSana,
      telefonRaqami: telefonRaqami ?? this.telefonRaqami,
      birinchiKelganSana: birinchiKelganSana ?? this.birinchiKelganSana,
      shikoyat: shikoyat ?? this.shikoyat,
      manzil: manzil ?? this.manzil,
      rasmManzili: rasmManzili ?? this.rasmManzili,
      rasmlarManzillari: rasmlarManzillari ?? this.rasmlarManzillari,
      tashrifSanalari: tashrifSanalari ?? this.tashrifSanalari,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      userId: userId ?? this.userId,
    );
  }

  // -------------------------------------------------
  // 4️⃣  Helper methods
  // -------------------------------------------------
  /// Returns all image paths, merging the legacy `rasmManzili`
  /// with the list stored in `rasmlarManzillari`.
  List<String> getAllImagePaths() {
    final all = List<String>.from(rasmlarManzillari);
    if (rasmManzili.isNotEmpty && !all.contains(rasmManzili)) {
      all.add(rasmManzili);
    }
    return all;
  }

  /// Append a new visit date (stored as ISO‑8601 string) and persist
  /// the change locally (Hive).
  void addVisitDate(DateTime date) {
    tashrifSanalari.add(date.toIso8601String());
    if (isInBox) {
      save(); // Hive persistence
    } else if (Hive.isBoxOpen('patients')) {
      Hive.box<Patient>('patients').add(this);
    }
  }

  /// The most recent visit date, falling back to the first‑visit date.
  DateTime get lastVisitDate {
    if (tashrifSanalari.isEmpty) return birinchiKelganSana;
    return tashrifSanalari
        .map(DateTime.parse)
        .reduce((a, b) => a.isAfter(b) ? a : b);
  }

  // -------------------------------------------------
  // 5️⃣  (De)serialization – keep DB column names exactly
  // -------------------------------------------------
  factory Patient.fromMap(Map<String, dynamic> map) => Patient(
        id: map['id'] as String?,
        ismi: map['ismi'] as String,
        tugilganSana: DateTime.parse(map['tugilgan_sana'] as String),
        telefonRaqami: map['telefon_raqami'] as String?,
        birinchiKelganSana:
            DateTime.parse(map['birinchi_kelgan_sana'] as String),
        shikoyat: map['shikoyat'] as String,
        manzil: map['manzil'] as String,
        rasmManzili: map['rasm_manzili'] as String? ?? '',
        rasmlarManzillari:
            (map['rasmlar_manzillari'] as List<dynamic>?)?.cast<String>() ?? [],
        tashrifSanalari:
            (map['tashrif_sanalari'] as List<dynamic>?)?.cast<String>() ?? [],
        createdAt: map['created_at'] != null
            ? DateTime.parse(map['created_at'] as String)
            : null,
        updatedAt: map['updated_at'] != null
            ? DateTime.parse(map['updated_at'] as String)
            : null,
        userId: map['user_id'] as String?,
      );

  /// Supabase expects timestamps as `yyyy‑MM‑dd HH:mm:ss` (UTC).
  Map<String, dynamic> toMap() {
    final fmt = DateFormat('yyyy-MM-dd HH:mm:ss');
    final map = <String, dynamic>{
      'ismi': ismi,
      'tugilgan_sana': fmt.format(tugilganSana.toUtc()),
      'telefon_raqami': telefonRaqami,
      'birinchi_kelgan_sana': fmt.format(birinchiKelganSana.toUtc()),
      'shikoyat': shikoyat,
      'manzil': manzil,
      'rasm_manzili': rasmManzili,
      'rasmlar_manzillari': rasmlarManzillari,
      'tashrif_sanalari': tashrifSanalari,
    };
    if (id != null) map['id'] = id;
    if (createdAt != null) map['created_at'] = fmt.format(createdAt!.toUtc());
    if (updatedAt != null) map['updated_at'] = fmt.format(updatedAt!.toUtc());
    map['user_id'] = userId;
    return map;
  }

  /// Alias required by many serialization libraries.
  Map<String, dynamic> toJson() => toMap();

  // -------------------------------------------------
  // 6️⃣  Save / update in Supabase
  // -------------------------------------------------
  Future<void> saveToSupabase() async {
    final supabase = Supabase.instance.client;
    // Ensure userId is populated from the authenticated user before persisting
    final currentUid = supabase.auth.currentUser?.id;
    if (userId == null && currentUid != null) {
      userId = currentUid;
    }
    final payload = toMap();

    try {
      if (id == null) {
        // ---------- INSERT ----------
        final response =
            await supabase.from(tableName).insert(payload).select().single();

        // Supabase returns the generated `id`
        id = response['id'] as String?;
        debugPrint('✅ Patient created – id=$id');

        // Keep the local Hive cache in sync
        if (isInBox) {
          await save();
        } else if (Hive.isBoxOpen('patients')) {
          await Hive.box<Patient>('patients').add(this);
        }
      } else {
        // ---------- UPDATE ----------
        await supabase.from(tableName).update(payload).eq('id', id!);
        debugPrint('✅ Patient updated – id=$id');

        // Optional: keep Hive up‑to‑date
        if (isInBox) {
          await save();
        } else if (Hive.isBoxOpen('patients')) {
          await Hive.box<Patient>('patients').add(this);
        }
      }
    } on PostgrestException catch (e) {
      // eski: e.statusCode ❌
      debugPrint('❌ Supabase error (code=${e.code}): ${e.message}');
      if (e.details != null) {
        debugPrint('🔎 Details: ${e.details}');
      }
      rethrow;
    } catch (e) {
      debugPrint('❌ Unexpected error: $e');
      rethrow;
    }
  }
}
