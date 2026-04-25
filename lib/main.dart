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
import 'package:stomotologiya_app/routes.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:io';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    await dotenv.load(fileName: ".env");

    // Initialize date formatting
    await initializeDateFormatting();

    // Initialize Hive with error handling
    await _initializeHive();

    // Initialize Supabase
    final supabaseUrl = dotenv.env['SUPABASE_URL'];
    final supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY'];
    if (supabaseUrl == null || supabaseUrl.isEmpty) {
      throw Exception('SUPABASE_URL .env da topilmadi');
    }
    if (supabaseAnonKey == null || supabaseAnonKey.isEmpty) {
      throw Exception('SUPABASE_ANON_KEY .env da topilmadi');
    }

    // Help debug wrong project URL / DNS issues
    debugPrint('SUPABASE_URL=$supabaseUrl');
    final parsed = Uri.tryParse(supabaseUrl);
    if (parsed == null || !parsed.hasScheme || parsed.host.isEmpty) {
      throw Exception('SUPABASE_URL noto‘g‘ri: $supabaseUrl');
    }
    if (!supabaseUrl.startsWith('https://')) {
      throw Exception('SUPABASE_URL https:// bilan boshlanishi kerak: $supabaseUrl');
    }

    // DNS sanity check (real device troubleshooting)
    try {
      final addrs = await InternetAddress.lookup(parsed.host);
      debugPrint('DNS OK for ${parsed.host}: ${addrs.map((a) => a.address).toList()}');
    } catch (e) {
      debugPrint('DNS FAIL for ${parsed.host}: $e');
    }

    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
      debug: true,
      authOptions: const FlutterAuthClientOptions(
        authFlowType: AuthFlowType.pkce,
        detectSessionInUri: true,
      ),
    );

    // Initialize Patient Service (non-blocking).
    // If network/DNS is temporarily unavailable, app should still open.
    try {
      await PatientService().initialize();
    } catch (e) {
      debugPrint('PatientService init skipped: $e');
    }

    runApp(const MyApp());
  } catch (e) {
    final errorText = e.toString();
    final friendly = (errorText.contains('Failed host lookup') ||
            errorText.contains('SocketException'))
        ? 'Internet yoki DNS xatosi. Telefoningizda Private DNS/VPN ni o\'chirib, qayta urinib ko\'ring.'
        : errorText;
    debugPrint('Error during initialization: $e');
    runApp(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: Text('Dasturni ishga tushirishda xatolik: $friendly'),
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
      theme: ThemeData.light().copyWith(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.indigo,
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: Colors.grey.shade50,
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Colors.grey.shade900,
          elevation: 0,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.indigo.shade600,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          hintStyle: TextStyle(color: Colors.grey.shade600),
          labelStyle: TextStyle(color: Colors.grey.shade800),
          prefixIconColor: Colors.grey.shade700,
          suffixIconColor: Colors.grey.shade700,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.indigo.shade600, width: 1.6),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
      home: const AuthWrapper(),
      onGenerateRoute: AppRoutes.onGenerateRoute,
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
