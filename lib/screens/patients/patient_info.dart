// Bemor ma'lumotlarini ko'rsatish ekrani
import 'dart:io';

import 'package:flutter/material.dart';

import '../../models/patient.dart';

class PatientDetailsScreen extends StatelessWidget {
  final Patient patient;

  const PatientDetailsScreen({super.key, required this.patient});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(patient.fullName),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Image.file(File(patient.imagePath)),
            Text('Telefon: ${patient.phoneNumber}'),
            Text('Tug‘ilgan sana: ${patient.birthDate}'),
            Text('Birinchi tashrif sanasi: ${patient.firstVisitDate}'),
            Text('Shikoyat: ${patient.complaint}'),
            Text('Address: ${patient.address}'),
          ],
        ),
      ),
    );
  }
}
