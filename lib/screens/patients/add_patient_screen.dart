import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import '../../models/patient.dart';

class AddPatientScreen extends StatefulWidget {
  const AddPatientScreen({super.key});

  @override
  State<AddPatientScreen> createState() => AddPatientScreenState();
}

class AddPatientScreenState extends State<AddPatientScreen> {
  final _formKey = GlobalKey<FormState>();
  final _scrollController = ScrollController();

  // Form fields
  String fullname = '';
  DateTime? birthDate;
  String phoneNumber = '';
  DateTime? firstVisitDate;
  String complaint = '';
  String address = '';
  final List<File> _images = []; // Changed to list of images
  bool _isSaving = false;

  // Controllers for text fields
  final TextEditingController _fullnameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _complaintController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();

  final ImagePicker _picker = ImagePicker();

  @override
  void dispose() {
    _scrollController.dispose();
    _fullnameController.dispose();
    _phoneController.dispose();
    _complaintController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  // Rasmlarni tanlash
  Future<void> _pickImage(ImageSource source) async {
    Navigator.of(context).pop(); // Close the modal bottom sheet

    if (source == ImageSource.camera) {
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

      if (images != null && images.isNotEmpty) {
        setState(() {
          _images.addAll(images.map((xFile) => File(xFile.path)));
        });
      }
    }
  }

  void _showImageSourceOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.photo_camera, color: Colors.blue[800]),
              title: const Text('Kameradan olish'),
              onTap: () => _pickImage(ImageSource.camera),
            ),
            ListTile(
              leading: Icon(Icons.photo_library, color: Colors.blue[800]),
              title: const Text('Galereyadan tanlash'),
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
        ? (birthDate ??
            DateTime.now().subtract(const Duration(
                days: 365 * 30))) // Default to 30 years ago for birth date
        : (firstVisitDate ?? DateTime.now());

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
          birthDate = picked;
        } else {
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
      // Scroll to the first error
      _scrollToTop();
      return;
    }

    _formKey.currentState?.save();

    setState(() {
      _isSaving = true;
    });

    try {
      final patientsBox = Hive.box<Patient>('patients');

      // Create patient object
      final newPatient = Patient(
        fullName: fullname,
        birthDate: birthDate ??
            DateTime.now().subtract(const Duration(days: 365 * 30)),
        phoneNumber: phoneNumber,
        firstVisitDate: firstVisitDate ?? DateTime.now(),
        complaint: complaint,
        address: address,
        imagePaths: [], // Initialize with empty list
        speaksRussian: '', // Empty strings for language fields
        speaksEnglish: '',
        speaksUzbek: '',
      );

      // Save images if selected
      if (_images.isNotEmpty) {
        final directory = await getApplicationDocumentsDirectory();
        final imageDirectory = Directory('${directory.path}/patient_images');

        if (!await imageDirectory.exists()) {
          await imageDirectory.create(recursive: true);
        }

        final List<String> savedImagePaths = [];

        // Save each image
        for (int i = 0; i < _images.length; i++) {
          final imagePath =
              '${imageDirectory.path}/${DateTime.now().millisecondsSinceEpoch}_$i.jpg';
          await _images[i].copy(imagePath);
          savedImagePaths.add(imagePath);
        }

        // Set the image paths
        newPatient.imagePaths = savedImagePaths;
      }

      // Save to database
      await patientsBox.add(newPatient);

      // Show success and navigate back
      // ...existing code...
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$fullname muvaffaqiyatli qo\'shildi'),
            backgroundColor: Colors.green[700],
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.of(context)
            .pushNamedAndRemoveUntil('/home', (route) => false);
      }
// ...existing code...
    } catch (e) {
      // Show error
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
        backgroundColor: Colors.white,
        title: Text(
          'Yangi bemor',
          style: TextStyle(
            color: Colors.blue[800],
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.blue[800]),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          TextButton.icon(
            onPressed: _isSaving ? null : _savePatient,
            icon: _isSaving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(Icons.check, color: Colors.green[700]),
            label: Text(
              'Saqlash',
              style: TextStyle(
                color: _isSaving ? Colors.grey : Colors.green[700],
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
                              color: Colors.black.withValues(alpha: 0.1),
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
                      value: birthDate != null ? _formatDate(birthDate) : null,
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
                      value: firstVisitDate != null
                          ? _formatDate(firstVisitDate)
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
