import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/patient.dart';

class PatientDetailsScreen extends StatelessWidget {
  final Patient patient;

  const PatientDetailsScreen({super.key, required this.patient});

  @override
  Widget build(BuildContext context) {
    final formatter = DateFormat('yyyy-MM-dd');
    return Scaffold(
      appBar: AppBar(
        title: Text(
          patient.fullName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Card(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 6,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: patient.imagePath.isNotEmpty
                      ? Image.file(
                          File(patient.imagePath),
                          height: 200,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        )
                      : Icon(
                          Icons.person,
                          size: 44,
                        ),
                ),
                const SizedBox(height: 20),
                _buildInfoTile(Icons.phone, 'Telefon', patient.phoneNumber),
                _buildInfoTile(Icons.cake, 'Tug‘ilgan sana',
                    formatter.format(patient.birthDate)),
                _buildInfoTile(Icons.calendar_today, 'Birinchi tashrif',
                    formatter.format(patient.firstVisitDate)),
                _buildInfoTile(
                    Icons.report_problem, 'Shikoyat', patient.complaint),
                _buildInfoTile(Icons.home, 'Manzil', patient.address),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoTile(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.blueAccent),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: Colors.grey,
                    )),
                const SizedBox(height: 4),
                Text(value,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    )),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
