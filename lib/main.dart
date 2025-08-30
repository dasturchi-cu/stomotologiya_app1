import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'routes.dart';
import 'models/patient.dart';
import 'package:flutter/foundation.dart';
import 'package:stomotologiya_app/service/patient_service.dart';
import 'package:stomotologiya_app/service/supabase_auth_servise.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting();

  // Initialize Hive
  await Hive.initFlutter();

  try {
    await Supabase.initialize(
      url: 'https://ptosfyxqkvtmbmwdxzna.supabase.co',
      anonKey:
          'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InB0b3NmeXhxa3Z0bWJtd2R4em5hIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTYzMDI1ODgsImV4cCI6MjA3MTg3ODU4OH0.QG6lOXG_NhQdjDmALd7JJQk9WoPuFMZ_Hzr8RAizIvI',
      debug: true,
      authOptions: const FlutterAuthClientOptions(
        authFlowType: AuthFlowType.pkce,
        detectSessionInUri: true,
      ),
      realtimeClientOptions: const RealtimeClientOptions(
        logLevel: RealtimeLogLevel.info,
        timeout: Duration(seconds: 30),
      ),
    );

    // Initialize AuthService
    await AuthService().initialize();

    // faqat initialize muvaffaqiyatli bo‘lsa
    Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      final AuthChangeEvent event = data.event;
      if (event == AuthChangeEvent.signedIn) {
        debugPrint('User signed in!');
      } else if (event == AuthChangeEvent.signedOut) {
        debugPrint('User signed out!');
      }
    });

    if (kDebugMode) {
      print('Supabase initialized successfully');
    }
  } catch (e) {
    if (kDebugMode) {
      print('Error initializing Supabase: $e');
    }
    return; // ❌ initialize bo‘lmasa, davom ettirmaymiz
  }

  // Initialize Hive with proper error handling
  try {
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

    // Open Hive box with error recovery
    try {
      // Open the patients box with correct type
      final box = await Hive.openBox<Patient>('patients');

      // Initialize PatientService with Supabase
      final patientService = PatientService();
      await patientService.initialize();

      if (kDebugMode) {
        print('Hive and PatientService initialized successfully');
      }

      // Clean up test data if any exists
      await box.delete('test_key');
      await box.delete('recovery_test');

      // Run database migration if needed
      await migrateDatabase();
    } catch (boxError) {
      if (kDebugMode) {
        print('Error initializing Hive box: $boxError');
      }

      // If error occurs, delete and recreate the box
      try {
        await Hive.deleteBoxFromDisk('patients');
        await Hive.deleteBoxFromDisk('patients_v2');

        // Recreate the box
        await Hive.openBox<Map<dynamic, dynamic>>('patients_v2');

        // Reinitialize PatientService
        final patientService = PatientService();
        await patientService.initialize();

        if (kDebugMode) {
          print('Successfully recreated patients_v2 box');
        }
      } catch (recoveryError) {
        if (kDebugMode) {
          print('Failed to recover Hive box: $recoveryError');
        }

        // Last resort - create a fallback box
        try {
          await Hive.openBox('patients_fallback');
          if (kDebugMode) {
            print('Created fallback box as last resort');
          }
        } catch (fallbackError) {
          if (kDebugMode) {
            print('Complete Hive failure: $fallbackError');
          }
          rethrow;
        }
      }
    }
  } catch (generalError) {
    if (kDebugMode) {
      print('General Hive initialization error: $generalError');
    }
    throw Exception('Hive initialization failed: $generalError');
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      localizationsDelegates: [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: [
        const Locale('en', 'US'),
        const Locale('uz', 'UZ'),
      ],
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.blue,
      ),

      // 🔑 Asosiy route
      onGenerateRoute: AppRoutes.onGenerateRoute, // ✅ katta A bilan
      initialRoute: AppRoutes.wrapper,

      onUnknownRoute: (settings) => MaterialPageRoute(
        builder: (_) => Scaffold(
          appBar: AppBar(title: const Text('Route topilmadi')),
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                "Noma'lum route: ${settings.name}\nIltimos routes.dart faylini tekshiring.",
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

Future<void> migrateDatabase() async {
  try {
    if (kDebugMode) {
      print('Starting database migration check...');
    }

    // Skip migration for now to avoid box conflicts
    if (kDebugMode) {
      print('Database migration check completed');
    }
  } catch (e) {
    if (kDebugMode) {
      print('Error during database migration: $e');
    }
  }
}

//yaxshisi eng yaxshisi shu
