import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

import 'models/patient.dart'; // Rasmni saqlash uchun

// Patient modelini import qilish

class AddPatientScreen extends StatefulWidget {
  const AddPatientScreen({super.key});

  @override
  State<AddPatientScreen> createState() => AddPatientScreenState();
}

class AddPatientScreenState extends State<AddPatientScreen> {
  final _formKey = GlobalKey<FormState>();

  String fullname = '';
  DateTime? birthDate;
  String phoneNumber = '';
  DateTime? firstVisitDate;
  String complaint = '';
  bool speaksRussian = false; // Bool tipida
  bool speaksEnglish = false; // Bool tipida
  bool speaksUzbek = false; // Bool tipida
  String address = '';
  File? _image; // Tanlangan rasmni saqlash uchun

  final ImagePicker _picker = ImagePicker();

  // Rasmni tanlash
  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _image = File(image.path); // Tanlangan rasmni faylga saqlash
      });
    }
  }

  // Sana tanlash uchun metod
  Future<void> _selectDate(BuildContext context, bool isBirthDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        if (isBirthDate) {
          birthDate = picked;
        } else {
          firstVisitDate = picked;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final patientsBox = Hive.box<Patient>('patients');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Yangi Bemor Qo\'shish'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                decoration: const InputDecoration(labelText: 'To\'liq ismi'),
                onSaved: (value) => fullname = value ?? '',
                validator: (value) =>
                    (value == null || value.isEmpty) ? 'Ismni kiriting' : null,
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      birthDate == null
                          ? 'Tug‘ilgan sana tanlanmagan'
                          : 'Tug‘ilgan sana: ${birthDate!.toLocal()}'
                              .split(' ')[0],
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () => _selectDate(context, true),
                    child: const Text('Sana tanlash'),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Telefon raqami'),
                keyboardType: TextInputType.phone,
                onSaved: (value) => phoneNumber = value ?? '',
                validator: (value) => (value == null || value.isEmpty)
                    ? 'Telefon raqam kiriting'
                    : null,
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      firstVisitDate == null
                          ? 'Birinchi tashrif sanasi tanlanmagan'
                          : 'Birinchi tashrif: ${firstVisitDate!.toLocal()}'
                              .split(' ')[0],
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () => _selectDate(context, false),
                    child: const Text('Sana tanlash'),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Bemor shikoyati'),
                onSaved: (value) => complaint = value ?? '',
                maxLines: 3,
              ),
              const SizedBox(height: 10),
              SwitchListTile(
                title: const Text('Rus tili'),
                value: speaksRussian,
                onChanged: (value) {
                  setState(() {
                    speaksRussian = value;
                  });
                },
              ),
              const SizedBox(height: 10),
              SwitchListTile(
                title: const Text('Ingliz tili'),
                value: speaksEnglish,
                onChanged: (value) {
                  setState(() {
                    speaksEnglish = value;
                  });
                },
              ),
              const SizedBox(height: 10),
              SwitchListTile(
                title: const Text('O\'zbek tili'),
                value: speaksUzbek,
                onChanged: (value) {
                  setState(() {
                    speaksUzbek = value;
                  });
                },
              ),
              const SizedBox(height: 10),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Manzil'),
                onSaved: (value) => address = value ?? '',
              ),
              const SizedBox(height: 20),

              // Rasmni tanlash uchun tugma
              ElevatedButton(
                onPressed: _pickImage,
                child: const Text('Rasm tanlash'),
              ),

              const SizedBox(height: 10),

              // Tanlangan rasmni ko'rsatish
              _image != null
                  ? Image.file(_image!) // Tanlangan rasmni ko'rsatish
                  : const Text('Rasm tanlanmagan'),

              const SizedBox(height: 20),

              ElevatedButton(
                onPressed: () async {
                  if (_formKey.currentState?.validate() ?? false) {
                    _formKey.currentState?.save();

                    final newPatient = Patient(
                      fullName: fullname,
                      birthDate: birthDate ?? DateTime.now(),
                      // Agar sanalar bo'sh bo'lsa
                      phoneNumber: phoneNumber,
                      firstVisitDate: firstVisitDate ?? DateTime.now(),
                      // Agar sanalar bo'sh bo'lsa
                      complaint: complaint,
                      address: address,
                      imagePath: '',
                      speaksRussian: '',
                      speaksEnglish: '',
                      speaksUzbek:
                          '', // Rasm yo'lini faqat saqlashda aniqlaymiz
                    );

                    // Agar rasm tanlangan bo'lsa, uni saqlash
                    if (_image != null) {
                      final directory =
                          await getApplicationDocumentsDirectory();
                      final imageDirectory =
                          Directory('${directory.path}/patient_images');

                      // Directory mavjud emas bo'lsa, yaratish
                      if (!await imageDirectory.exists()) {
                        await imageDirectory.create();
                      }

                      final imagePath =
                          '${imageDirectory.path}/${DateTime.now().millisecondsSinceEpoch}.jpg';
                      await _image!.copy(imagePath);

                      newPatient.imagePath = imagePath; // Rasm yo'lini saqlash
                    }

                    // Bemorni saqlash
                    await patientsBox.add(newPatient);


                    Navigator.pop(context);

                    print("Qoshildi ... ");
                  }
                },
                child: const Text('Saqlash'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
