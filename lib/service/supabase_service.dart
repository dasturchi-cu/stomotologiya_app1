import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  static final SupabaseService _instance = SupabaseService._internal();
  final SupabaseClient _supabase = Supabase.instance.client;
  static const String bucketName = 'patient-images';

  factory SupabaseService() {
    return _instance;
  }

  SupabaseService._internal();

  // Upload image to Supabase Storage and return public URL
  Future<String?> uploadPatientImage(String patientId, File imageFile) async {
    try {
      final fileName = 'patient_${patientId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final filePath = '$patientId/$fileName';
      
      // Upload the file
      await _supabase
          .storage
          .from(bucketName)
          .upload(filePath, imageFile);
      
      // Get the public URL
      final String publicUrl = _supabase
          .storage
          .from(bucketName)
          .getPublicUrl(filePath);
          
      return publicUrl;
    } catch (e) {
      print('Error uploading image to Supabase: $e');
      return null;
    }
  }

  // Delete image from Supabase Storage
  Future<void> deleteImage(String imageUrl) async {
    try {
      // Extract the file path from the URL
      final filePath = imageUrl.split('/').last;
      await _supabase
          .storage
          .from(bucketName)
          .remove([filePath]);
    } catch (e) {
      print('Error deleting image from Supabase: $e');
      rethrow;
    }
  }
}
