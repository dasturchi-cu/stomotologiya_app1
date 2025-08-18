import 'package:flutter/material.dart';

import 'screens/app_wrapper.dart';
import 'screens/home.dart';
import 'screens/analytics_screen.dart';
import 'screens/export.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'payment/payment.dart';
import 'screens/patients/add_patient_screen.dart';
import 'screens/patients/patient_info.dart';
import 'screens/patients/patient_screen.dart';
import 'screens/patients/patient_edit_screen.dart';

import 'models/patient.dart';

class AppRoutes {
  AppRoutes._();

  static const String wrapper = '/';
  static const String home = '/home';
  static const String login = '/login';
  static const String register = '/register';
  static const String payment = '/payment';
  static const String analytics = '/analytics';
  static const String export = '/export';

  static const String addPatient = '/patients/add';
  static const String patientDetails = '/patients/details';
  static const String patientEdit = '/patients/edit';
  static const String patientImagesEdit = '/patients/images-edit';
  static const String imageViewer = '/images/viewer';

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case wrapper:
        return MaterialPageRoute(builder: (_) => const AppWrapper());
      case home:
        return MaterialPageRoute(builder: (_) => const HomeScreen());
      case analytics:
        return MaterialPageRoute(builder: (_) => const AnalyticsScreen());
      case export:
        return MaterialPageRoute(builder: (_) => const ExportScreen());
      case login:
        return MaterialPageRoute(builder: (_) => const LoginScreen());
      case register:
        return MaterialPageRoute(builder: (_) => const RegisterScreen());
      case payment:
        return MaterialPageRoute(builder: (_) => const PaymentScreen());
      case addPatient:
        return MaterialPageRoute(builder: (_) => AddPatientScreen());
      case patientDetails:
        final arg = settings.arguments;
        if (arg is Patient) {
          return MaterialPageRoute(
            builder: (_) => PatientDetailsScreen(patient: arg),
          );
        }
        return _errorRoute('PatientDetailsScreen: noto\'g\'ri argument');
      case patientEdit:
        final arg2 = settings.arguments;
        if (arg2 is int) {
          return MaterialPageRoute(
              builder: (_) => PatientEdit(patientIndex: arg2));
        }
        return _errorRoute('PatientEdit: index (int) argument kerak');
      case patientImagesEdit:
        final arg3 = settings.arguments;
        if (arg3 is Patient) {
          return MaterialPageRoute(
              builder: (_) => PatientImagesEditScreen(patient: arg3));
        }
        return _errorRoute('PatientImagesEdit: Patient argument kerak');
      case imageViewer:
        final arg4 = settings.arguments;
        if (arg4 is Map &&
            arg4['paths'] is List<String> &&
            arg4['index'] is int) {
          return MaterialPageRoute(
            builder: (_) => FullScreenImageViewer(
              imagePaths: List<String>.from(arg4['paths'] as List),
              initialIndex: arg4['index'] as int,
            ),
          );
        }
        return _errorRoute(
            'ImageViewer: {paths: List<String>, index: int} kerak');
      default:
        return _errorRoute('Noma\'lum route: ${settings.name}');
    }
  }

  static Route<dynamic> _errorRoute(String message) {
    return MaterialPageRoute(
      builder: (_) => Scaffold(
        appBar: AppBar(title: const Text('Route xatosi')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(message, textAlign: TextAlign.center),
          ),
        ),
      ),
    );
  }
}
