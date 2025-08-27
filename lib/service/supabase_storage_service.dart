import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseStorageService {
  static final SupabaseStorageService _instance = SupabaseStorageService._internal();
  final SupabaseClient _supabase = Supabase.instance.client;
  static const String bucketName = 'rasmlar';

  factory SupabaseStorageService() {
    return _instance;
  }

  SupabaseStorageService._internal();

  // Rasm yuklash uchun metod
  Future<String?> uploadPatientImage(String patientId, File imageFile) async {
    try {
      final fileName = 'patient_${patientId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final filePath = '$patientId/$fileName';
      
      // Faylni yuklash
      await _supabase
          .storage
          .from(bucketName)
          .upload(filePath, imageFile);
      
      // Rasm manzilini olish
      final String publicUrl = _supabase
          .storage
          .from(bucketName)
          .getPublicUrl(filePath);
          
      return publicUrl;
    } catch (e) {
      print('Rasm yuklashda xatolik: $e');
      return null;
    }
  }

  // Rasmni o'chirish
  Future<void> deleteImage(String imageUrl) async {
    try {
      // URL dan fayl nomini ajratib olish
      final filePath = imageUrl.split('/').last;
      await _supabase
          .storage
          .from(bucketName)
          .remove([filePath]);
    } catch (e) {
      print('Rasmni o\'chirishda xatolik: $e');
      rethrow;
    }
  }
}
