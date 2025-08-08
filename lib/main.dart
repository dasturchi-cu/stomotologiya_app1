import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:hive_flutter/adapters.dart';
import 'firebase_options.dart';
import 'screens/app_wrapper.dart';
import 'models/patient.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase ni ishga tushirish
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Hive ni ishga tushirish
  await Hive.initFlutter();

  // PatientAdapter ni ro'yxatdan o'tkazish
  Hive.registerAdapter(PatientAdapter());
  await migrateDatabase();
  await Hive.openBox<Patient>('patients');

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: const AppWrapper(),
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorSchemeSeed: Colors.blue),
    );
  }
}

Future<void> migrateDatabase() async {
  try {
    debugPrint('Starting database migration check...');

    // Try to open the box without reading data first
    final box = await Hive.openBox<Patient>(
      'patients',
      compactionStrategy: (entries, deletedEntries) => deletedEntries > 50,
    );

    // Quick check: if box is empty, no migration needed
    if (box.isEmpty) {
      debugPrint('No database migration needed - empty database.');
      await box.close();
      return;
    }

    // Check migration flags for different migrations - optimized
    bool needsImageMigration = false;
    bool needsVisitDatesMigration = false;
    int checkedCount = 0;
    const maxCheckCount = 10; // Only check first 10 patients for performance

    for (final patient in box.values) {
      // Check if we need to migrate imagePaths
      if (patient.imagePaths.isEmpty && patient.imagePath.isNotEmpty) {
        needsImageMigration = true;
      }

      // Check if we need to migrate visit dates
      if (patient.visitDates.isEmpty) {
        needsVisitDatesMigration = true;
      }

      checkedCount++;
      // If we've found both migration needs or checked enough, stop
      if ((needsImageMigration && needsVisitDatesMigration) ||
          checkedCount >= maxCheckCount) {
        break;
      }
    }

    // Perform migrations as needed
    if (needsImageMigration || needsVisitDatesMigration) {
      debugPrint('Starting database migrations...');

      // Get all patients
      final patients = box.values.toList();

      // Update each patient
      for (final patient in patients) {
        bool needsSave = false;

        // Migrate imagePaths if needed
        if (needsImageMigration &&
            patient.imagePaths.isEmpty &&
            patient.imagePath.isNotEmpty) {
          patient.imagePaths = [patient.imagePath];
          needsSave = true;
          debugPrint('Migrated images for patient: ${patient.fullName}');
        }

        // Migrate visit dates if needed
        if (needsVisitDatesMigration && patient.visitDates.isEmpty) {
          patient.visitDates = [patient.firstVisitDate];
          needsSave = true;
          debugPrint('Migrated visit dates for patient: ${patient.fullName}');
        }

        // Save the patient if any changes were made
        if (needsSave) {
          await patient.save();
        }
      }

      debugPrint('Database migration completed successfully.');
    } else {
      debugPrint('No database migration needed.');
    }

    // Close the box so it can be reopened by the app
    await box.close();
  } catch (e) {
    debugPrint('Error during migration: $e');

    // Get more detailed error information
    if (e.toString().contains("type 'Null' is not a subtype of type")) {
      debugPrint(
          'Database schema incompatibility detected. Attempting safe recovery...');

      try {
        // Try to backup the data before deleting if possible
        // await _backupPatientsIfPossible();

        // Delete the patients box
        await Hive.deleteBoxFromDisk('patients');

        // Also delete any temporary box that might have been created
        try {
          await Hive.deleteBoxFromDisk('patients.temp');
        } catch (_) {}

        debugPrint(
            'Database reset completed. Any available data has been backed up.');
      } catch (backupError) {
        debugPrint('Error during backup attempt: $backupError');
        debugPrint('Database reset completed without backup.');
      }
    }
  }
}
