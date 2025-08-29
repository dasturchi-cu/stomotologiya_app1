import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseStorageService {
  static final SupabaseStorageService _instance =
      SupabaseStorageService._internal();
  final SupabaseClient _supabase = Supabase.instance.client;
  static const String bucketName = 'rasmlar';
  bool _initialized = false;

  factory SupabaseStorageService() {
    return _instance;
  }

  SupabaseStorageService._internal();

  // Initialize the storage service
  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true; // Mark as initialized to prevent multiple calls
    debugPrint('Supabase Storage initialization bypassed - bucket check removed');
    return; // Skip the bucket check completely
  }

  // Sign in with email and password
  Future<void> signInWithEmail(String email, String password) async {
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
      debugPrint('User signed in: ${response.user?.email}');
    } catch (e) {
      debugPrint('Error signing in: $e');
      rethrow;
    }
  }

  // Sign up with email and password
  Future<void> signUpWithEmail(String email, String password) async {
    try {
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
      );
      debugPrint('User signed up: ${response.user?.email}');
    } catch (e) {
      debugPrint('Error signing up: $e');
      rethrow;
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await _supabase.auth.signOut();
      debugPrint('User signed out');
    } catch (e) {
      debugPrint('Error signing out: $e');
      rethrow;
    }
  }

  // Get current user email
  String? getCurrentUserEmail() {
    return _supabase.auth.currentUser?.email;
  }

  // Check if user is signed in
  bool isSignedIn() {
    return _supabase.auth.currentUser != null;
  }

  // Rasm yuklash uchun metod
  Future<String?> uploadPatientImage(String patientId, File imageFile) async {
    const maxRetries = 3;
    var attempt = 0;
    Exception? lastError;

    while (attempt < maxRetries) {
      try {
        // Ensure user is authenticated
        final user = _supabase.auth.currentUser;
        if (user == null) {
          throw Exception('Foydalanuvchi tizimga kirishini tekshiring');
        }

        // Ensure storage is initialized
        await initialize();

        // Convert patientId to string to avoid Hive key issues
        final patientIdStr = patientId.toString();

        // Check if file exists and is not empty
        if (!await imageFile.exists()) {
          throw Exception('Rasm fayli topilmadi');
        }

        final fileLength = await imageFile.length();
        if (fileLength == 0) {
          throw Exception('Rasm fayli bo\'sh');
        }

        // Create file path with timestamp
        final fileExt = imageFile.path.split('.').last;
        final fileName = '${DateTime.now().millisecondsSinceEpoch}.$fileExt';
        final filePath = '$patientIdStr/$fileName';

        // Read file bytes
        final bytes = await imageFile.readAsBytes();

        // Upload file to Supabase Storage
        await _supabase.storage.from(bucketName).uploadBinary(filePath, bytes);

        // Get public URL of the uploaded file
        final publicUrl =
            _supabase.storage.from(bucketName).getPublicUrl(filePath);

        if (publicUrl.isEmpty) {
          throw Exception('Rasm URL manzili olinmadi');
        }

        debugPrint('Rasm muvaffaqiyatli yuklandi: $publicUrl');
        return publicUrl;
      } catch (e) {
        lastError = e is Exception ? e : Exception(e.toString());
        attempt++;
        debugPrint('Rasm yuklashda xatolik (urush $attempt/$maxRetries): $e');

        if (attempt < maxRetries) {
          // Exponential backoff
          await Future.delayed(Duration(seconds: attempt * 2));
        }
      }
    }

    // If we get here, all retries failed
    throw lastError ?? Exception('Rasm yuklashda noma\'lum xatolik yuz berdi');
  }

  // Rasmni o'chirish
  Future<void> deleteImage(String imageUrl) async {
    try {
      // Supabase public URL formati odatda:
      // https://<project>.supabase.co/storage/v1/object/public/<bucketName>/<path>
      // Bizga <path> qismi kerak (folder/filename.ext)
      final uri = Uri.parse(imageUrl);
      final segments = uri.pathSegments;
      final publicIdx = segments.indexOf('public');
      if (publicIdx == -1 ||
          publicIdx + 1 >= segments.length ||
          segments[publicIdx + 1] != bucketName) {
        throw Exception("Noto'g'ri Supabase Storage URL: $imageUrl");
      }
      final filePath = segments.sublist(publicIdx + 2).join('/');
      if (filePath.isEmpty) {
        throw Exception('URL dan fayl yo\'li aniqlanmadi');
      }
      await _supabase.storage.from(bucketName).remove([filePath]);
    } catch (e) {
      print('Rasmni o\'chirishda xatolik: $e');
      rethrow;
    }
  }
}
