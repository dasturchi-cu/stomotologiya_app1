import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:stomotologiya_app/models/patient.dart';
import 'package:stomotologiya_app/service/patient_service.dart';

class PatientEditFullScreen extends StatefulWidget {
  final Patient patient;

  const PatientEditFullScreen({super.key, required this.patient});

  @override
  State<PatientEditFullScreen> createState() => _PatientEditFullScreenState();
}

class _PatientEditFullScreenState extends State<PatientEditFullScreen> {
  final _formKey = GlobalKey<FormState>();
  final _patientService = PatientService();
  final _picker = ImagePicker();
  
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _complaintController;
  late TextEditingController _addressController;
  
  late DateTime? _birthDate;
  late DateTime? _firstVisitDate;
  final List<File> _images = [];
  
  bool _isLoading = false;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.patient.ismi);
    _phoneController = TextEditingController(text: widget.patient.telefonRaqami ?? '');
    _complaintController = TextEditingController(text: widget.patient.shikoyat);
    _addressController = TextEditingController(text: widget.patient.manzil);
    
    _birthDate = widget.patient.tugilganSana;
    _firstVisitDate = widget.patient.birinchiKelganSana;
    
    // Add listeners to track changes
    _nameController.addListener(_checkForChanges);
    _phoneController.addListener(_checkForChanges);
    _complaintController.addListener(_checkForChanges);
    _addressController.addListener(_checkForChanges);
  }
  
  void _checkForChanges() {
    final hasTextChanges = _nameController.text != widget.patient.ismi ||
        _phoneController.text != (widget.patient.telefonRaqami ?? '') ||
        _complaintController.text != widget.patient.shikoyat ||
        _addressController.text != widget.patient.manzil;
    
    final hasDateChanges = _birthDate != widget.patient.tugilganSana ||
        _firstVisitDate != widget.patient.birinchiKelganSana;
    
    final hasImageChanges = _images.isNotEmpty;
    
    setState(() {
      _hasChanges = hasTextChanges || hasDateChanges || hasImageChanges;
    });
  }
  
  Future<bool> _confirmExit() async {
    if (_isLoading) return false;
    if (!_hasChanges) return true;

    final shouldPop = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('O\'zgarishlarni saqlamay chiqish'),
        content: const Text(
            'Agar siz hozir chiqib ketsangiz, o\'zgarishlaringiz saqlanmaydi. Davom etishni xohlaysizmi?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Bekor qilish'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Chiqish'),
          ),
        ],
      ),
    );
    return shouldPop ?? false;
  }

  String _formatDate(DateTime date) {
    return DateFormat('dd.MM.yyyy').format(date);
  }

  Future<void> _selectDate(bool isBirthDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isBirthDate ? (_birthDate ?? DateTime.now()) : (_firstVisitDate ?? DateTime.now()),
      firstDate: DateTime(1900),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    
    if (picked != null) {
      setState(() {
        if (isBirthDate) {
          _birthDate = picked;
        } else {
          _firstVisitDate = picked;
        }
      });
      _checkForChanges();
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    Navigator.of(context).pop();
    
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
        
        final XFile? image = await _picker.pickImage(
          source: source,
          imageQuality: 80,
        );

        if (image != null) {
          setState(() {
            _images.add(File(image.path));
          });
          _checkForChanges();
        }
      } else {
        final List<XFile> images = await _picker.pickMultiImage(
          imageQuality: 80,
        );

        if (images.isNotEmpty) {
          setState(() {
            _images.addAll(images.map((xFile) => File(xFile.path)));
          });
          _checkForChanges();
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
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!isWindows)
              ListTile(
                leading: const Icon(Icons.photo_camera, color: Colors.blue),
                title: const Text('Kameradan olish'),
                onTap: () => _pickImage(ImageSource.camera),
              ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: Colors.blue),
              title: const Text('Galereyadan tanlash'),
              onTap: () => _pickImage(ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate() || _isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Keep existing images
      final allImagePaths = List<String>.from(widget.patient.rasmlarManzillari);
      
      // Upload new images if any
      if (_images.isNotEmpty) {
        for (final imageFile in _images) {
          try {
            final fileName = 'patient_${widget.patient.id}_${DateTime.now().millisecondsSinceEpoch}.jpg';
            
            // Read file as bytes for upload
            final bytes = await imageFile.readAsBytes();
            
            final response = await Supabase.instance.client.storage
                .from('patient-images')
                .uploadBinary(fileName, bytes);
            
            if (kDebugMode) {
              print('Upload response: $response');
            }
            
            // Get the public URL for the uploaded image
            final imageUrl = Supabase.instance.client.storage
                .from('patient-images')
                .getPublicUrl(fileName);
            
            allImagePaths.add(imageUrl);
            
            if (kDebugMode) {
              print('Image uploaded successfully: $imageUrl');
            }
          } catch (uploadError) {
            if (kDebugMode) {
              print('Error uploading image: $uploadError');
            }
            // For now, add local path as fallback
            allImagePaths.add(imageFile.path);
          }
        }
      }

      final updatedPatient = widget.patient.copyWith(
        ismi: _nameController.text.trim(),
        telefonRaqami: _phoneController.text.trim(),
        shikoyat: _complaintController.text.trim(),
        manzil: _addressController.text.trim(),
        tugilganSana: _birthDate,
        birinchiKelganSana: _firstVisitDate,
        rasmlarManzillari: allImagePaths,
      );

      await _patientService.updatePatient(updatedPatient);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Bemor ma\'lumotlari muvaffaqiyatli yangilandi'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
        
        // Clear the images list after successful save
        _images.clear();
        _hasChanges = false;
        
        // Navigate back to patient info screen
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Saqlashda xatolik: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_hasChanges,
      onPopInvoked: (didPop) async {
        if (!didPop && _hasChanges) {
          final shouldPop = await _confirmExit();
          if (shouldPop && context.mounted) {
            Navigator.of(context).pop();
          }
        }
      },
      child: Scaffold(
      appBar: AppBar(
        title: const Text('Bemorni Tahrirlash'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'F.I.Sh',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'F.I.Sh kiritish majburiy';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(
                  labelText: 'Telefon raqami',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _complaintController,
                decoration: const InputDecoration(
                  labelText: 'Shikoyat',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(
                  labelText: 'Manzil',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      decoration: InputDecoration(
                        labelText: 'Tug\'ilgan sana',
                        border: const OutlineInputBorder(),
                        hintText: _birthDate != null ? _formatDate(_birthDate!) : 'Sanani tanlang',
                      ),
                      readOnly: true,
                      onTap: () => _selectDate(true),
                    ),
                  ),
                  IconButton(
                    onPressed: () => _selectDate(true),
                    icon: const Icon(Icons.calendar_today),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      decoration: InputDecoration(
                        labelText: 'Birinchi tashrif',
                        border: const OutlineInputBorder(),
                        hintText: _firstVisitDate != null ? _formatDate(_firstVisitDate!) : 'Sanani tanlang',
                      ),
                      readOnly: true,
                      onTap: () => _selectDate(false),
                    ),
                  ),
                  IconButton(
                    onPressed: () => _selectDate(false),
                    icon: const Icon(Icons.calendar_today),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Rasmlar',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    onPressed: _showImageSourceOptions,
                    icon: const Icon(Icons.add_photo_alternate, color: Colors.blue),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (_images.isNotEmpty)
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                    childAspectRatio: 1,
                  ),
                  itemCount: _images.length,
                  itemBuilder: (context, index) {
                    return Stack(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey[300]!),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.file(
                              _images[index],
                              fit: BoxFit.cover,
                              width: double.infinity,
                              height: double.infinity,
                            ),
                          ),
                        ),
                        Positioned(
                          top: 4,
                          right: 4,
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _images.removeAt(index);
                              });
                            },
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
                    );
                  },
                ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveChanges,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'Saqlash',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _complaintController.dispose();
    _addressController.dispose();
    super.dispose();
  }
}
