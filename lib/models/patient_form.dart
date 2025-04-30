import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'package:stomotologiya_app/models/patient.dart';


class PatientForm extends StatefulWidget {
  @override
  _PatientFormState createState() => _PatientFormState();
}

class _PatientFormState extends State<PatientForm> {
  final fullNameController = TextEditingController();
  final birthDateController = TextEditingController();
  final phoneNumberController = TextEditingController();
  final firstVisitDateController = TextEditingController();
  final complaintController = TextEditingController();
  final addressController = TextEditingController();
  bool speaksRussian = false;
  bool speaksEnglish = false;
  bool speaksUzbek = false; // Uzbek tili uchun

  DateTime? birthDate;
  DateTime? firstVisitDate;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Bemorni Ro‘yxatga Olish')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: fullNameController,
                decoration: InputDecoration(labelText: 'To\'liq ismi'),
              ),
              SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: birthDateController,
                      decoration: InputDecoration(labelText: 'Tug‘ilgan sana'),
                      readOnly: true,
                    ),
                  ),
                  SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () => _pickBirthDate(context),
                    child: Text('Tanlash'),
                  ),
                ],
              ),
              SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: firstVisitDateController,
                      decoration: InputDecoration(labelText: 'Birinchi tashrif sanasi'),
                      readOnly: true,
                    ),
                  ),
                  SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () => _pickFirstVisitDate(context),
                    child: Text('Tanlash'),
                  ),
                ],
              ),
              SizedBox(height: 10),
              TextField(
                controller: phoneNumberController,
                decoration: InputDecoration(labelText: 'Telefon raqami'),
              ),
              SizedBox(height: 10),
              TextField(
                controller: complaintController,
                decoration: InputDecoration(labelText: 'Shikoyati'),
              ),
              SizedBox(height: 10),
              Row(
                children: [
                  Checkbox(
                    value: speaksRussian,
                    onChanged: (value) {
                      setState(() {
                        speaksRussian = value ?? false;
                      });
                    },
                  ),
                  Text('Rus tili'),
                  Checkbox(
                    value: speaksEnglish,
                    onChanged: (value) {
                      setState(() {
                        speaksEnglish = value ?? false;
                      });
                    },
                  ),
                  Text('Ingliz tili'),
                  Checkbox(
                    value: speaksUzbek,
                    onChanged: (value) {
                      setState(() {
                        speaksUzbek = value ?? false;
                      });
                    },
                  ),
                  Text('O‘zbek tili'),
                ],
              ),
              TextField(
                controller: addressController,
                decoration: InputDecoration(labelText: 'Manzil'),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _savePatient,
                child: Text('Saqlash'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Tug‘ilgan sana tanlash
  Future<void> _pickBirthDate(BuildContext context) async {
    final DateTime? picked = await _selectDate(context);
    if (picked != null) {
      setState(() {
        birthDate = picked;
        birthDateController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  // Birinchi tashrif sanasini tanlash
  Future<void> _pickFirstVisitDate(BuildContext context) async {
    final DateTime? picked = await _selectDate(context);
    if (picked != null) {
      setState(() {
        firstVisitDate = picked;
        firstVisitDateController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  // Sana tanlash funksiyasi
  Future<DateTime?> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
    );
    return picked;
  }

  // Bemorni saqlash funksiyasi
  Future<void> _savePatient() async {
    if (fullNameController.text.isEmpty ||
        birthDate == null ||
        firstVisitDate == null ||
        phoneNumberController.text.isEmpty ||
        complaintController.text.isEmpty ||
        addressController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Iltimos, barcha maydonlarni to‘ldiring!')),
      );
      return;
    }

    final patient = Patient(
      fullName: fullNameController.text,
      birthDate: birthDate!,
      phoneNumber: phoneNumberController.text,
      firstVisitDate: firstVisitDate!,
      complaint: complaintController.text,
      speaksRussian: speaksRussian ? 'yes' : 'no',
      speaksEnglish: speaksEnglish ? 'yes' : 'no',
      speaksUzbek: speaksUzbek ? 'yes' : 'no',
      address: addressController.text,
      imagePath: '', // Agar rasm tanlansa, shu yerga path qo'yasiz
    );

    var box = await Hive.openBox<Patient>('patients');
    await box.add(patient);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Bemor ma\'lumotlari saqlandi!')),
    );

    // Formani tozalash
    fullNameController.clear();
    birthDateController.clear();
    phoneNumberController.clear();
    firstVisitDateController.clear();
    complaintController.clear();
    addressController.clear();
    setState(() {
      birthDate = null;
      firstVisitDate = null;
      speaksRussian = false;
      speaksEnglish = false;
      speaksUzbek = false;
    });
  }
}
