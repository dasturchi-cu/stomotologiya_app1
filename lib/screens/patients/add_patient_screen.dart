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
  File? _image;
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

  // Rasmni tanlash
  Future<void> _pickImage(ImageSource source) async {
    Navigator.of(context).pop(); // Close the modal bottom sheet

    final XFile? image = await _picker.pickImage(
      source: source,
      imageQuality: 80, // Optimize image quality
    );

    if (image != null) {
      setState(() {
        _image = File(image.path);
      });
    }
  }

  void _showImageSourceOptions() {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.photo_camera, color: Colors.blue[800]),
              title: Text('Kameradan olish'),
              onTap: () => _pickImage(ImageSource.camera),
            ),
            ListTile(
              leading: Icon(Icons.photo_library, color: Colors.blue[800]),
              title: Text('Galereyadan tanlash'),
              onTap: () => _pickImage(ImageSource.gallery),
            ),
            if (_image != null)
              ListTile(
                leading: Icon(Icons.delete, color: Colors.red[400]),
                title: Text('Rasmni o\'chirish'),
                onTap: () {
                  Navigator.of(context).pop();
                  setState(() {
                    _image = null;
                  });
                },
              ),
          ],
        ),
      ),
    );
  }

  // Sana tanlash uchun metod
  Future<void> _selectDate(BuildContext context, bool isBirthDate) async {
    final DateTime initialDate = isBirthDate
        ? (birthDate ??
            DateTime.now().subtract(Duration(
                days: 365 * 30))) // Default to 30 years ago for birth date
        : (firstVisitDate ?? DateTime.now());

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(1900),
      lastDate: DateTime.now().add(
          Duration(days: 365)), // Allow setting appointments 1 year in advance
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
        birthDate:
            birthDate ?? DateTime.now().subtract(Duration(days: 365 * 30)),
        phoneNumber: phoneNumber,
        firstVisitDate: firstVisitDate ?? DateTime.now(),
        complaint: complaint,
        address: address,
        imagePath: '',
        speaksRussian: '', // Empty strings for language fields
        speaksEnglish: '',
        speaksUzbek: '',
      );

      // Save image if selected
      if (_image != null) {
        final directory = await getApplicationDocumentsDirectory();
        final imageDirectory = Directory('${directory.path}/patient_images');

        if (!await imageDirectory.exists()) {
          await imageDirectory.create(recursive: true);
        }

        final imagePath =
            '${imageDirectory.path}/${DateTime.now().millisecondsSinceEpoch}.jpg';
        await _image!.copy(imagePath);

        newPatient.imagePath = imagePath;
      }

      // Save to database
      await patientsBox.add(newPatient);

      // Show success and navigate back
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${fullname} muvaffaqiyatli qo\'shildi'),
            backgroundColor: Colors.green[700],
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context);
      }
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
        duration: Duration(milliseconds: 500),
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
                ? SizedBox(
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
        physics: BouncingScrollPhysics(),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Patient photo section
              Container(
                width: double.infinity,
                color: Colors.white,
                padding: EdgeInsets.all(16),
                child: Column(
                  children: [
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
                              offset: Offset(0, 2),
                            ),
                          ],
                          image: _image != null
                              ? DecorationImage(
                                  image: FileImage(_image!),
                                  fit: BoxFit.cover,
                                )
                              : null,
                        ),
                        child: _image == null
                            ? Icon(
                                Icons.add_a_photo,
                                size: 40,
                                color: Colors.grey[500],
                              )
                            : null,
                      ),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Bemor rasmi',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 12),

              // Personal information section
              _buildSectionHeader('Shaxsiy ma\'lumotlar'),
              Container(
                padding: EdgeInsets.all(16),
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
                    SizedBox(height: 16),
                    _buildDateField(
                      label: 'Tug\'ilgan sana',
                      value: birthDate != null ? _formatDate(birthDate) : null,
                      icon: Icons.cake_outlined,
                      onTap: () => _selectDate(context, true),
                    ),
                    SizedBox(height: 16),
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
                    SizedBox(height: 16),
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

              SizedBox(height: 12),

              // Medical information section
              _buildSectionHeader('Tibbiy ma\'lumotlar'),
              Container(
                padding: EdgeInsets.all(16),
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
                    SizedBox(height: 16),
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

              SizedBox(height: 12),

              SizedBox(height: 12),

              // Save button
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _savePatient,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[800],
                    minimumSize: Size(double.infinity, 56),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                  child: _isSaving
                      ? CircularProgressIndicator(color: Colors.white)
                      : Text(
                          'SAQLASH',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),

              SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: EdgeInsets.only(left: 16, bottom: 8, top: 8),
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
        contentPadding: EdgeInsets.symmetric(vertical: 16, horizontal: 16),
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
        padding: EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(12),
          color: Colors.grey[50],
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.blue[800]),
            SizedBox(width: 12),
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
                  SizedBox(height: 4),
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

// Language switch widget removed
}
