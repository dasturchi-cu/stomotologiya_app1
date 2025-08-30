import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:intl/intl.dart';
import 'package:stomotologiya_app/models/patient.dart';
import 'package:stomotologiya_app/service/supabase_storage_service.dart';
import 'package:stomotologiya_app/service/patient_service.dart';
import 'package:stomotologiya_app/service/error_handler.dart';

class AddPatientScreen extends StatefulWidget {
  const AddPatientScreen({super.key});

  @override
  State<AddPatientScreen> createState() => AddPatientScreenState();
}

class AddPatientScreenState extends State<AddPatientScreen> {
  final _formKey = GlobalKey<FormState>();
  final _patientService = PatientService();
  final _errorHandler = ErrorHandler();
  final _storageService = SupabaseStorageService();
  final _picker = ImagePicker();

  // Form controllers
  final _fullnameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _complaintController = TextEditingController();
  final _addressController = TextEditingController();

  // ScrollController qo'shildi
  final ScrollController _scrollController = ScrollController();

  // Form state
  DateTime? _birthDate;
  DateTime? _firstVisitDate;
  final List<File> _images = [];
  bool _isSaving = false;

  // Form variables qo'shildi
  String fullname = '';
  String phoneNumber = '';
  String complaint = '';
  String address = '';
  DateTime? birthDate;
  DateTime? firstVisitDate;

  // Form field focus nodes
  final _nameFocusNode = FocusNode();
  final _phoneFocusNode = FocusNode();
  final _complaintFocusNode = FocusNode();
  final _addressFocusNode = FocusNode();

  @override
  void dispose() {
    _scrollController.dispose();
    _fullnameController.dispose();
    _phoneController.dispose();
    _complaintController.dispose();
    _addressController.dispose();
    _nameFocusNode.dispose();
    _phoneFocusNode.dispose();
    _complaintFocusNode.dispose();
    _addressFocusNode.dispose();
    super.dispose();
  }

  // Rasmlarni tanlash
  Future<void> _pickImage(ImageSource source) async {
    Navigator.of(context).pop(); // Close the modal bottom sheet

    try {
      if (source == ImageSource.camera) {
        // Check if we're on Windows and camera is not supported
        if (Theme.of(context).platform == TargetPlatform.windows) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Kamera Windows platformasida qo\'llab-quvvatlanmaydi. Galereyadan tanlang.'),
                backgroundColor: Colors.orange,
              ),
            );
          }
          return;
        }
        
        // For camera, add a single image
        final XFile? image = await _picker.pickImage(
          source: source,
          imageQuality: 80,
        );

        if (image != null) {
          setState(() {
            _images.add(File(image.path));
          });
        }
      } else {
        // For gallery, allow multiple selection
        final List<XFile> images = await _picker.pickMultiImage(
          imageQuality: 80,
        );

        if (images.isNotEmpty) {
          setState(() {
            _images.addAll(images.map((xFile) => File(xFile.path)));
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Rasm tanlashda xatolik: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showImageSourceOptions() {
    final isWindows = Theme.of(context).platform == TargetPlatform.windows;
    
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!isWindows)
              ListTile(
                leading: Icon(Icons.photo_camera, color: Colors.blue[800]),
                title: const Text('Kameradan olish'),
                onTap: () => _pickImage(ImageSource.camera),
              ),
            ListTile(
              leading: Icon(Icons.photo_library, color: Colors.blue[800]),
              title: const Text('Galereyadan tanlang'),
              onTap: () => _pickImage(ImageSource.gallery),
            ),
            if (_images.isNotEmpty)
              ListTile(
                leading: Icon(Icons.delete, color: Colors.red[400]),
                title: const Text('Barcha rasmlarni o\'chirish'),
                onTap: () {
                  Navigator.of(context).pop();
                  setState(() {
                    _images.clear();
                  });
                },
              ),
          ],
        ),
      ),
    );
  }

  void _removeImage(int index) {
    if (index >= 0 && index < _images.length) {
      setState(() {
        _images.removeAt(index);
      });
    }
  }

  // Sana tanlash uchun metod
  Future<void> _selectDate(BuildContext context, bool isBirthDate) async {
    final DateTime initialDate = isBirthDate
        ? (_birthDate ??
        DateTime.now().subtract(const Duration(
            days: 365 * 30))) // Default to 30 years ago for birth date
        : (_firstVisitDate ?? DateTime.now());

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(1900),
      lastDate: DateTime.now().add(const Duration(
          days: 365)), // Allow setting appointments 1 year in advance
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Colors.blue[800]!,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        if (isBirthDate) {
          _birthDate = picked;
          birthDate = picked;
        } else {
          _firstVisitDate = picked;
          firstVisitDate = picked;
        }
      });
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    return DateFormat('dd.MM.yyyy').format(date);
  }

  Future<void> _savePatient() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      _scrollToTop();
      return;
    }

    _formKey.currentState?.save();

    setState(() {
      _isSaving = true;
    });

    try {
      // Upload images first if there are any
      final List<String> uploadedImageUrls = [];
      if (_images.isNotEmpty) {
        debugPrint('📸 ${_images.length} ta rasm yuklanmoqda...');
        
        for (int i = 0; i < _images.length; i++) {
          final imageFile = _images[i];
          try {
            // Use a temporary ID for upload path
            final tempId = DateTime.now().millisecondsSinceEpoch.toString();
            final imageUrl = await _storageService.uploadPatientImage(tempId, imageFile);
            if (imageUrl != null) {
              uploadedImageUrls.add(imageUrl);
              debugPrint('✅ Rasm ${i + 1} yuklandi: $imageUrl');
            }
          } catch (imageError) {
            debugPrint('❌ Rasm ${i + 1} yuklashda xatolik: $imageError');
            // Continue with other images even if one fails
          }
        }
      }

      // Create patient object with uploaded image URLs
      final newPatient = Patient(
        ismi: fullname,
        tugilganSana: birthDate ??
            DateTime.now().subtract(const Duration(days: 365 * 30)),
        telefonRaqami: phoneNumber,
        birinchiKelganSana: firstVisitDate ?? DateTime.now(),
        shikoyat: complaint,
        manzil: address,
        rasmlarManzillari: uploadedImageUrls,
      );

      debugPrint('💾 Bemor ma\'lumotlari saqlanmoqda...');
      debugPrint('🖼️ Rasmlar soni: ${uploadedImageUrls.length}');
      
      // Save patient to Supabase with image URLs
      await newPatient.saveToSupabase();

      if (newPatient.id == null) {
        throw Exception('Bemor ID raqamini olib bo\'lmadi.');
      }

      debugPrint('✅ Bemor saqlandi. ID: ${newPatient.id}');

      if (mounted) {
        final message = _images.isNotEmpty && uploadedImageUrls.isEmpty
            ? '$fullname qo\'shildi (rasmlar yuklanmadi)'
            : uploadedImageUrls.isNotEmpty 
                ? '$fullname va ${uploadedImageUrls.length} ta rasm muvaffaqiyatli qo\'shildi'
                : '$fullname muvaffaqiyatli qo\'shildi';
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: Colors.green[700],
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.of(context)
            .pushNamedAndRemoveUntil('/home', (route) => false);
      }
    } catch (e) {
      debugPrint('❌ Bemor saqlashda xatolik: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Xatolik yuz berdi: $e'),
            backgroundColor: Colors.red[700],
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  void _scrollToTop() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.blue[800],
        title: const Text(
          'Yangi bemor',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white, size: 24),
          onPressed: () {
            Navigator.of(context).pushNamedAndRemoveUntil('/home', (route) => false);
          },
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          TextButton.icon(
            onPressed: _isSaving ? null : _savePatient,
            icon: _isSaving
                ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
                : const Icon(Icons.check, color: Colors.white),
            label: Text(
              'Saqlash',
              style: TextStyle(
                color: _isSaving ? Colors.grey : Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        controller: _scrollController,
        padding: const EdgeInsets.all(0),
        physics: const BouncingScrollPhysics(),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Patient photos section
              Container(
                width: double.infinity,
                color: Colors.white,
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Image selection button
                    GestureDetector(
                      onTap: _showImageSourceOptions,
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                          image: _images.isNotEmpty
                              ? DecorationImage(
                            image: FileImage(_images[0]),
                            fit: BoxFit.cover,
                          )
                              : null,
                        ),
                        child: _images.isEmpty
                            ? Icon(
                          Icons.add_a_photo,
                          size: 40,
                          color: Colors.grey[500],
                        )
                            : null,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Bemor rasmlari',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),

                    // Show selected images in a horizontal list
                    if (_images.isNotEmpty)
                      Container(
                        height: 100,
                        margin: const EdgeInsets.only(top: 16),
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: _images.length,
                          itemBuilder: (context, index) {
                            return Container(
                              width: 80,
                              margin: const EdgeInsets.only(right: 8),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                image: DecorationImage(
                                  image: FileImage(_images[index]),
                                  fit: BoxFit.cover,
                                ),
                              ),
                              child: Stack(
                                alignment: Alignment.topRight,
                                children: [
                                  InkWell(
                                    onTap: () => _removeImage(index),
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: const BoxDecoration(
                                        color: Colors.red,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.close,
                                        size: 16,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),

                    // Add more images button
                    if (_images.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 16),
                        child: ElevatedButton.icon(
                          onPressed: _showImageSourceOptions,
                          icon: const Icon(Icons.add_photo_alternate),
                          label: const Text('Rasm qo\'shish'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue[800],
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // Personal information section
              _buildSectionHeader('Shaxsiy ma\'lumotlar'),
              Container(
                padding: const EdgeInsets.all(16),
                color: Colors.white,
                child: Column(
                  children: [
                    _buildTextField(
                      controller: _fullnameController,
                      label: 'To\'liq ismi',
                      hint: 'Masalan: Abdullayev Abdullo',
                      icon: Icons.person_outline,
                      validator: (value) => (value == null || value.isEmpty)
                          ? 'Ismni kiriting'
                          : null,
                      onSaved: (value) => fullname = value ?? '',
                    ),
                    const SizedBox(height: 16),
                    _buildDateField(
                      label: 'Tug\'ilgan sana',
                      value: _birthDate != null ? _formatDate(_birthDate) : null,
                      icon: Icons.cake_outlined,
                      onTap: () => _selectDate(context, true),
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _phoneController,
                      label: 'Telefon raqami',
                      hint: '+998 XX XXX XX XX',
                      icon: Icons.phone_outlined,
                      keyboardType: TextInputType.phone,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Telefon raqamini kiriting';
                        }
                        // Simple validation for Uzbekistan phone numbers
                        if (!value.contains(RegExp(r'\d{9}'))) {
                          return 'Noto\'g\'ri telefon raqami';
                        }
                        return null;
                      },
                      onSaved: (value) => phoneNumber = value ?? '',
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _addressController,
                      label: 'Manzil',
                      hint: 'Shahar, Tuman, Ko\'cha, Uy',
                      icon: Icons.location_on_outlined,
                      onSaved: (value) => address = value ?? '',
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // Medical information section
              _buildSectionHeader('Tibbiy ma\'lumotlar'),
              Container(
                padding: const EdgeInsets.all(16),
                color: Colors.white,
                child: Column(
                  children: [
                    _buildDateField(
                      label: 'Birinchi tashrif sanasi',
                      value: _firstVisitDate != null
                          ? _formatDate(_firstVisitDate)
                          : null,
                      icon: Icons.calendar_today_outlined,
                      onTap: () => _selectDate(context, false),
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _complaintController,
                      label: 'Bemor shikoyati',
                      hint: 'Bemorning shikoyati va tashxisni kiriting',
                      icon: Icons.medical_services_outlined,
                      maxLines: 3,
                      onSaved: (value) => complaint = value ?? '',
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // Save button
              Padding(
                padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _savePatient,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[800],
                    minimumSize: const Size(double.infinity, 56),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                  child: _isSaving
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                    'SAQLASH',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, bottom: 8, top: 8),
      child: Text(
        title,
        style: TextStyle(
          color: Colors.blue[800],
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? hint,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
    void Function(String?)? onSaved,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: Colors.blue[800]),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.blue[800]!, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.red[400]!, width: 1),
        ),
        filled: true,
        fillColor: Colors.grey[50],
        contentPadding:
        const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      ),
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: validator,
      onSaved: onSaved,
    );
  }

  Widget _buildDateField({
    required String label,
    required IconData icon,
    String? value,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(12),
          color: Colors.grey[50],
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.blue[800]),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value == null || value.isEmpty ? 'Tanlang' : value,
                    style: TextStyle(
                      fontSize: 16,
                      color: value == null || value.isEmpty
                          ? Colors.grey[400]
                          : Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_drop_down, color: Colors.grey[600]),
          ],
        ),
      ),
    );
  }
}