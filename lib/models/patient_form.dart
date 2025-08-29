import 'dart:io';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:stomotologiya_app/models/patient.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
  bool _isUploading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
        title: const Text(
          'Yangi Bemor Qo\'shish',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header section with gradient
            Container(
              width: double.infinity,
              padding: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blue[600]!, Colors.blue[400]!],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
              child: const Column(
                children: [
                  SizedBox(height: 10),
                  Icon(
                    Icons.person_add_rounded,
                    size: 60,
                    color: Colors.white,
                  ),
                  SizedBox(height: 10),
                  Text(
                    'Bemor ma\'lumotlarini kiriting',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            // Form section
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildModernTextField(
                    controller: fullNameController,
                    label: 'To\'liq ismi',
                    icon: Icons.person_rounded,
                    hint: 'Bemor ismini kiriting',
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: birthDateController,
                          decoration:
                              InputDecoration(labelText: 'Tug‘ilgan sana'),
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
                  _buildDatePickerField(
                    controller: firstVisitDateController,
                    label: 'Birinchi tashrif sanasi',
                    icon: Icons.calendar_today_rounded,
                    onTap: () => _pickFirstVisitDate(context),
                  ),
                  const SizedBox(height: 20),
                  _buildModernTextField(
                    controller: phoneNumberController,
                    label: 'Telefon raqami',
                    icon: Icons.phone_rounded,
                    hint: '+998 XX XXX XX XX',
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 20),
                  _buildModernTextField(
                    controller: complaintController,
                    label: 'Shikoyati',
                    icon: Icons.medical_services_rounded,
                    hint: 'Bemor shikoyatini kiriting',
                    maxLines: 3,
                  ),
                  const SizedBox(height: 20),
                  // Rasm yuklash qismi
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Bemor rasmlari:',
                          style: TextStyle(fontWeight: FontWeight.bold)),
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
                                          border:
                                              Border.all(color: Colors.grey),
                                          borderRadius:
                                              BorderRadius.circular(8),
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
                                          icon: Icon(Icons.close,
                                              color: Colors.red),
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
                  _buildModernTextField(
                    controller: addressController,
                    label: 'Manzil',
                    icon: Icons.location_on_rounded,
                    hint: 'Yashash manzilini kiriting',
                    maxLines: 2,
                  ),
                  const SizedBox(height: 25),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _isUploading ? null : _savePatient,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue[600],
                        foregroundColor: Colors.white,
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: _isUploading
                          ? const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white),
                                  ),
                                ),
                                SizedBox(width: 12),
                                Text(
                                  'Saqlanmoqda...',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            )
                          : const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.save_rounded),
                                SizedBox(width: 8),
                                Text(
                                  'Bemorni Saqlash',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Modern text field widget
  Widget _buildModernTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? hint,
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: Icon(icon, color: Colors.blue[600]),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 16,
          ),
          labelStyle: TextStyle(
            color: Colors.grey[700],
            fontWeight: FontWeight.w500,
          ),
          hintStyle: TextStyle(
            color: Colors.grey[400],
          ),
        ),
      ),
    );
  }

  // Date picker field widget
  Widget _buildDatePickerField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        readOnly: true,
        onTap: onTap,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: Colors.blue[600]),
          suffixIcon: Icon(Icons.arrow_drop_down, color: Colors.blue[600]),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 16,
          ),
          labelStyle: TextStyle(
            color: Colors.grey[700],
            fontWeight: FontWeight.w500,
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Iltimos, bemor ismini kiriting')),
        );
      }
      return;
    }

    if (phoneNumberController.text.trim().isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Iltimos, telefon raqamini kiriting')),
        );
      }
      return;
    }

    if (!mounted) return;
    setState(() {
      _isUploading = true;
    });

    try {
      debugPrint('Bemor saqlash boshlandi...');

      // Create patient object with all required fields
      final newPatient = Patient(
        ismi: fullNameController.text.trim(),
        tugilganSana: birthDate ??
            DateTime.now().subtract(const Duration(days: 365 * 30)),
        telefonRaqami: phoneNumberController.text.trim(),
        birinchiKelganSana: firstVisitDate ?? DateTime.now(),
        shikoyat: complaintController.text.trim(),
        manzil: addressController.text.trim(),
        rasmlarManzillari: [],
      );

      debugPrint('Bemor obyekti yaratildi: ${newPatient.ismi}');

      // Save to Supabase
      debugPrint('Supabase ga saqlash...');
      await newPatient.saveToSupabase();
      debugPrint('Supabase ga saqlandi. ID: ${newPatient.id}');

      // Upload images to Supabase Storage if any
      if (_images.isNotEmpty) {
        for (final image in _images) {
          try {
            final fileName =
                '${newPatient.id ?? 'temp'}_${DateTime.now().millisecondsSinceEpoch}.jpg';
            final bytes = await image.readAsBytes();
            await Supabase.instance.client.storage
                .from('patient-images')
                .uploadBinary(fileName, bytes);

            final imageUrl = Supabase.instance.client.storage
                .from('patient-images')
                .getPublicUrl(fileName);

            // Update patient with the new image URL
            newPatient.rasmlarManzillari.add(imageUrl);
            await newPatient.saveToSupabase();
          } catch (e) {
            debugPrint('Rasm yuklashda xatolik: $e');
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                    content: Text('Rasm yuklashda xatolik: ${e.toString()}')),
              );
            }
          }
        }
      }

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Bemor muvaffaqiyatli saqlandi!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      debugPrint('Xatolik yuz berdi: $e');
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
      final ImagePicker picker = ImagePicker();
      final List<XFile>? pickedFiles = await picker.pickMultiImage(
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85,
      );

      if (pickedFiles != null && mounted) {
        setState(() {
          _images.addAll(pickedFiles.map((file) => File(file.path)));
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Rasm yuklashda xatolik: $e')),
        );
      }
    }
  }

  void _removeImage(int index) {
    if (!mounted) return;
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
