import 'dart:io';

import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:stomotologiya_app/screens/home.dart';
import 'screens/patients/add_patient_screen.dart';
import 'models/patient.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();

  // PatientAdapter ni ro'yxatdan o'tkazish
  Hive.registerAdapter(PatientAdapter());
  await Hive.openBox<Patient>('patients');
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: HomeScreen(),
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorSchemeSeed: Colors.blue),
    );
  }
}
