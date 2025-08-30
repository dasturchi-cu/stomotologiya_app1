import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:stomotologiya_app/models/patient.dart';
import 'package:stomotologiya_app/service/patient_service.dart';
import 'package:stomotologiya_app/service/error_handler.dart';

class AddPatientScreen extends StatefulWidget {
  const AddPatientScreen({super.key});

  @override
  State<AddPatientScreen> createState() => _AddPatientScreenState();
}

class _AddPatientScreenState extends State<AddPatientScreen> {
  final _formKey = GlobalKey<FormState>();
  final _patientService = PatientService();
  final _errorHandler = ErrorHandler();

  // Controllers
  final _fullnameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _complaintController = TextEditingController();
  final _addressController = TextEditingController();

  // State variables
  DateTime? _birthDate;
  DateTime? _firstVisitDate;
  List<File> _selectedImages = [];
  bool _isSaving = false;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _firstVisitDate = DateTime.now();
  }

  @override
  void dispose() {
    _fullnameController.dispose();
    _phoneController.dispose();
    _complaintController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  String? _validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Ism familiya kiritilishi shart';
    }
    if (value.trim().length < 2) {
      return 'Ism familiya kamida 2 ta harfdan iborat bo\'lishi kerak';
    }
    return null;
  }

  String? _validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Telefon raqami kiritilishi shart';
    }
    final phoneRegex = RegExp(r'^\+?[0-9]{9,15}$');
    if (!phoneRegex.hasMatch(value.trim())) {
      return 'Telefon raqami noto\'g\'ri formatda';
    }
    return null;
  }

  String? _validateRequired(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName kiritilishi shart';
    }
    return null;
  }

  Future<void> _selectDate(BuildContext context,
      {required bool isBirthDate}) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isBirthDate
          ? (_birthDate ??
              DateTime.now().subtract(const Duration(days: 365 * 25)))
          : (_firstVisitDate ?? DateTime.now()),
      firstDate: isBirthDate
          ? DateTime(1900)
          : DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
      locale: const Locale('uz', 'UZ'),
    );

    if (picked != null) {
      setState(() {
        if (isBirthDate) {
          _birthDate = picked;
        } else {
          _firstVisitDate = picked;
        }
      });
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Tanlanmagan';
    return DateFormat('dd.MM.yyyy').format(date);
  }

  Future<void> _pickImages() async {
    try {
      final List<XFile> images = await _picker.pickMultiImage(
        imageQuality: 80,
      );

      if (images.isNotEmpty) {
        setState(() {
          _selectedImages.addAll(images.map((xFile) => File(xFile.path)));
        });
      }
    } catch (e) {
      _errorHandler.showError('Rasm tanlashda xatolik: ${e.toString()}');
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  Future<void> _savePatient() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_birthDate == null) {
      _errorHandler.showError('Tug\'ilgan sanani tanlang');
      return;
    }

    setState(() => _isSaving = true);

    try {
      // Upload images to Supabase storage first
      List<String> uploadedImageUrls = [];
      
      if (_selectedImages.isNotEmpty) {
        for (final imageFile in _selectedImages) {
          try {
            final fileName = 'patient_${DateTime.now().millisecondsSinceEpoch}_${uploadedImageUrls.length}.jpg';
            final bytes = await imageFile.readAsBytes();
            
            await Supabase.instance.client.storage
                .from('patient-images')
                .uploadBinary(fileName, bytes);
            
            final imageUrl = Supabase.instance.client.storage
                .from('patient-images')
                .getPublicUrl(fileName);
            
            uploadedImageUrls.add(imageUrl);
          } catch (uploadError) {
            debugPrint('Image upload error: $uploadError');
            // Continue with other images even if one fails
          }
        }
      }

      final newPatient = Patient(
        id: null,
        ismi: _fullnameController.text.trim(),
        tugilganSana: _birthDate!,
        telefonRaqami: _phoneController.text.trim(),
        birinchiKelganSana: _firstVisitDate ?? DateTime.now(),
        shikoyat: _complaintController.text.trim(),
        manzil: _addressController.text.trim(),
        rasmManzili: uploadedImageUrls.isNotEmpty ? uploadedImageUrls.first : '',
        rasmlarManzillari: uploadedImageUrls,
        tashrifSanalari: [
          (_firstVisitDate ?? DateTime.now()).toIso8601String()
        ],
      );

      await _patientService.addPatient(newPatient);

      if (mounted) {
        _errorHandler.showSuccess('Bemor muvaffaqiyatli qo\'shildi');
        Navigator.of(context).pop();
      }
    } catch (e) {
      _errorHandler.showError('Xatolik yuz berdi: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Yangi bemor qo\'shish'),
        actions: [
          if (_isSaving)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else
            TextButton(
              onPressed: _savePatient,
              child: const Text('Saqlash'),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Full name field
              TextFormField(
                controller: _fullnameController,
                decoration: const InputDecoration(
                  labelText: 'Ism familiya *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
                validator: _validateName,
                enabled: !_isSaving,
              ),
              const SizedBox(height: 16),

              // Birth date field
              InkWell(
                onTap: _isSaving
                    ? null
                    : () => _selectDate(context, isBirthDate: true),
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: 'Tug\'ilgan sana *',
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.calendar_today),
                    suffixIcon: _birthDate != null
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: _isSaving
                                ? null
                                : () => setState(() => _birthDate = null),
                          )
                        : null,
                  ),
                  child: Text(
                    _formatDate(_birthDate),
                    style: TextStyle(
                      color: _birthDate == null ? Colors.grey[600] : null,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Phone field
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(
                  labelText: 'Telefon raqami *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.phone),
                  hintText: '+998901234567',
                ),
                keyboardType: TextInputType.phone,
                validator: _validatePhone,
                enabled: !_isSaving,
              ),
              const SizedBox(height: 16),

              // First visit date field
              InkWell(
                onTap: _isSaving
                    ? null
                    : () => _selectDate(context, isBirthDate: false),
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Birinchi tashrif sanasi',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.event),
                  ),
                  child: Text(_formatDate(_firstVisitDate)),
                ),
              ),
              const SizedBox(height: 16),

              // Complaint field
              TextFormField(
                controller: _complaintController,
                decoration: const InputDecoration(
                  labelText: 'Shikoyat',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.medical_services),
                ),
                maxLines: 3,
                enabled: !_isSaving,
              ),
              const SizedBox(height: 16),

              // Address field
              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(
                  labelText: 'Manzil',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.location_on),
                ),
                enabled: !_isSaving,
              ),
              const SizedBox(height: 16),

              // Images section
              const Text(
                'Rasmlar',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),

              if (_selectedImages.isNotEmpty)
                SizedBox(
                  height: 120,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _selectedImages.length,
                    itemBuilder: (context, index) {
                      return Container(
                        margin: const EdgeInsets.only(right: 8),
                        child: Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.file(
                                _selectedImages[index],
                                width: 100,
                                height: 100,
                                fit: BoxFit.cover,
                              ),
                            ),
                            Positioned(
                              top: 4,
                              right: 4,
                              child: GestureDetector(
                                onTap: () => _removeImage(index),
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(
                                    color: Colors.red,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.close,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),

              const SizedBox(height: 8),

              OutlinedButton.icon(
                onPressed: _isSaving ? null : _pickImages,
                icon: const Icon(Icons.add_photo_alternate),
                label: const Text('Rasm qo\'shish'),
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
