import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:stomotologiya_app/models/patient.dart';
import 'package:stomotologiya_app/service/supabase_storage_service.dart';
import 'package:firebase_core/firebase_core.dart';

class PatientForm extends StatefulWidget {
  const PatientForm({super.key});

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
  
  final List<File> _images = [];
  final ImagePicker _picker = ImagePicker();
  bool _isUploading = false;

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
                      decoration:
                          InputDecoration(labelText: 'Birinchi tashrif sanasi'),
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
              // Rasm yuklash qismi
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Bemor rasmlari:', style: TextStyle(fontWeight: FontWeight.bold)),
                  SizedBox(height: 8),
                  _images.isEmpty
                      ? Text('Rasmlar qo\'shilmagan')
                      : SizedBox(
                          height: 100,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: _images.length,
                            itemBuilder: (context, index) {
                              return Stack(
                                children: [
                                  Container(
                                    width: 100,
                                    height: 100,
                                    margin: EdgeInsets.only(right: 8),
                                    decoration: BoxDecoration(
                                      border: Border.all(color: Colors.grey),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Image.file(
                                      _images[index],
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                  Positioned(
                                    right: 0,
                                    top: 0,
                                    child: IconButton(
                                      icon: Icon(Icons.close, color: Colors.red),
                                      onPressed: () => _removeImage(index),
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ),
                  SizedBox(height: 8),
                  ElevatedButton.icon(
                    onPressed: _pickImages,
                    icon: Icon(Icons.add_photo_alternate),
                    label: Text('Rasm qo\'shish'),
                  ),
                ],
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
                onPressed: _isUploading ? null : _savePatient,
                child: _isUploading 
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Text('Saqlash'),
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
    // Validate required fields
    if (fullNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Iltimos, bemor ismini kiriting')),
      );
      return;
    }

    if (phoneNumberController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Iltimos, telefon raqamini kiriting')),
      );
      return;
    }

    setState(() {
      _isUploading = true;
    });

    try {
      setState(() {
        _isUploading = true;
      });

      // Create patient object with all required fields
      final newPatient = Patient(
        fullName: fullNameController.text.trim(),
        birthDate: birthDate ?? DateTime.now().subtract(const Duration(days: 365 * 30)),
        phoneNumber: phoneNumberController.text.trim(),
        firstVisitDate: firstVisitDate ?? DateTime.now(),
        complaint: complaintController.text.trim(),
        address: addressController.text.trim(),
        speaksRussian: speaksRussian ? 'Ha' : 'Yo\'q',
        speaksEnglish: speaksEnglish ? 'Ha' : 'Yo\'q',
        speaksUzbek: speaksUzbek ? 'Ha' : 'Yo\'q',
        imagePaths: [],
      );

      // Save to Firestore first to get document ID
      DocumentReference docRef;
      try {
        docRef = await newPatient.addToFirestore();
        newPatient.reference = docRef;
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Firestore-ga saqlashda xatolik: $e')),
          );
        }
        return;
      }

      // Upload images to Supabase Storage if any
      if (_images.isNotEmpty) {
        final storageService = SupabaseStorageService();
        final List<String> savedImageUrls = [];
        
        for (int i = 0; i < _images.length; i++) {
          try {
            final imageUrl = await storageService.uploadPatientImage(docRef.id, _images[i]);
            if (imageUrl != null) {
              savedImageUrls.add(imageUrl);
            } else {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Rasm yuklashda xatolik (${i + 1}/${_images.length})')),
                );
              }
            }
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Rasm yuklashda xatolik: $e')),
              );
            }
          }
        }
        
        if (savedImageUrls.isNotEmpty) {
          try {
            // Update patient with image URLs
            newPatient.imagePaths = savedImageUrls;
            await docRef.update({
              'imagePaths': savedImageUrls,
              'lastUpdated': FieldValue.serverTimestamp(),
            });
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Rasmlarni yangilashda xatolik: $e')),
              );
            }
          }
        }
      }

      // Save to local storage
      try {
        final patientsBox = Hive.box<Patient>('patients');
        await patientsBox.add(newPatient);
        
        if (mounted) {
          Navigator.pop(context, true);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Lokal xotiraga saqlashda xatolik: $e')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Xatolik yuz berdi: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  Future<void> _pickImages() async {
    try {
      final List<XFile>? pickedFiles = await _picker.pickMultiImage(
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85,
      );

      if (pickedFiles != null) {
        setState(() {
          _images.addAll(pickedFiles.map((file) => File(file.path)));
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Rasm yuklashda xatolik: $e')),
      );
    }
  }

  void _removeImage(int index) {
    setState(() {
      _images.removeAt(index);
    });
  }

  @override
  void dispose() {
    fullNameController.dispose();
    birthDateController.dispose();
    phoneNumberController.dispose();
    firstVisitDateController.dispose();
    complaintController.dispose();
    addressController.dispose();
    super.dispose();
  }
}
