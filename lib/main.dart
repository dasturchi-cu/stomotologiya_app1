import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:stomotologiya_app/service/patient_service.dart';
import 'package:stomotologiya_app/auth_wrapper.dart';
import 'package:stomotologiya_app/models/patient.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    // Initialize date formatting
    await initializeDateFormatting();

    // Initialize Hive with error handling
    await _initializeHive();

    // Initialize Supabase
    await Supabase.initialize(
      url: 'https://ptosfyxqkvtmbmwdxzna.supabase.co',
      anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InB0b3NmeXhxa3Z0bWJtd2R4em5hIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTYzMDI1ODgsImV4cCI6MjA3MTg3ODU4OH0.QG6lOXG_NhQdjDmALd7JJQk9WoPuFMZ_Hzr8RAizIvI',
      debug: true,
      authOptions: const FlutterAuthClientOptions(
        authFlowType: AuthFlowType.pkce,
        detectSessionInUri: true,
      ),
    );

    // Initialize Patient Service
    await PatientService().initialize();

    runApp(const MyApp());
  } catch (e) {
    debugPrint('Error during initialization: $e');
    runApp(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: Text('Dasturni ishga tushirishda xatolik: $e'),
          ),
        ),
      ),
    );
  }
}

Future<void> _initializeHive() async {
  try {
    // Initialize Hive
    await Hive.initFlutter();
    
    // Register adapters
    if (!Hive.isAdapterRegistered(PatientAdapter().typeId)) {
      Hive.registerAdapter(PatientAdapter());
    }

    // Close existing boxes if open
    if (Hive.isBoxOpen('patients')) {
      await Hive.box('patients').close();
    }
    if (Hive.isBoxOpen('patients_v2')) {
      await Hive.box('patients_v2').close();
    }

    // Try to open the patients box
    try {
      final box = await Hive.openBox<Patient>('patients');
      await box.delete('test_key');
      await box.delete('recovery_test');
    } catch (e) {
      // If error occurs, try to recover
      debugPrint('Error initializing Hive box: $e');
      await _recoverHiveBox();
    }
  } catch (e) {
    debugPrint('Failed to initialize Hive: $e');
    rethrow;
  }
}

Future<void> _recoverHiveBox() async {
  try {
    await Hive.deleteBoxFromDisk('patients');
    await Hive.deleteBoxFromDisk('patients_v2');
    await Hive.openBox<Map<dynamic, dynamic>>('patients_v2');
    debugPrint('Successfully recreated patients_v2 box');
  } catch (e) {
    debugPrint('Failed to recover Hive box: $e');
    try {
      await Hive.openBox('patients_fallback');
      debugPrint('Created fallback box as last resort');
    } catch (e) {
      debugPrint('Complete Hive failure: $e');
      rethrow;
    }
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Stomotologiya',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        colorScheme: ColorScheme.dark(
          primary: Colors.blue[300]!,
          secondary: Colors.blue[200]!,
          surface: const Color(0xFF121212),
          background: const Color(0xFF121212),
        ),
        scaffoldBackgroundColor: const Color(0xFF121212),
        cardColor: const Color(0xFF1E1E1E),
        dividerColor: Colors.white24,
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1E1E1E),
          elevation: 0,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue[700],
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF2D2D2D),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
      home: const AuthWrapper(),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('uz', 'UZ'),
        Locale('ru', 'RU'),
        Locale('en', 'US'),
      ],
      locale: const Locale('uz', 'UZ'),
    );
  }
}

// Database migration function if needed in the future
Future<void> migrateDatabase() async {
  try {
    if (kDebugMode) {
      print('Starting database migration check...');
    }
    // Migration logic here
    if (kDebugMode) {
      print('Database migration check completed');
    }
  } catch (e) {
    if (kDebugMode) {
      print('Error during database migration: $e');
    }
  }
}
