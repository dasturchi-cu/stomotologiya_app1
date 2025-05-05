// Screen for editing patient images
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:image_picker/image_picker.dart';

import '../../models/patient.dart';

class PatientImagesEditScreen extends StatefulWidget {
  final Patient patient;

  const PatientImagesEditScreen({Key? key, required this.patient})
      : super(key: key);

  @override
  State<PatientImagesEditScreen> createState() =>
      _PatientImagesEditScreenState();
}

class _PatientImagesEditScreenState extends State<PatientImagesEditScreen> {
  late List<String> _imagePaths;
  bool _hasChanges = false;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    // Create a copy of the list to work with
    _imagePaths = List<String>.from(widget.patient.imagePaths);
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
          _imagePaths.add(File(image.path).path);
          _hasChanges = true;
        });
      }
    } else {
      // For gallery, allow multiple selection
      final List<XFile>? images = await _picker.pickMultiImage(
        imageQuality: 80,
      );

      if (images != null && images.isNotEmpty) {
        setState(() {
          _imagePaths.addAll(images.map((xFile) => File(xFile.path).path));
          _hasChanges = true;
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
            if (_imagePaths.isNotEmpty)
              ListTile(
                leading: Icon(Icons.delete, color: Colors.red[400]),
                title: const Text('Barcha rasmlarni o\'chirish'),
                onTap: () {
                  Navigator.of(context).pop();
                  setState(() {
                    _imagePaths.clear();
                  });
                },
              ),
          ],
        ),
      ),
    );
  }

  void _removeImage(int index) {
    if (index >= 0 && index < _imagePaths.length) {
      setState(() {
        _imagePaths.removeAt(index);
        _hasChanges = true;
      });
    }
  }

  void _saveChanges() async {
    try {
      // Create updated patient with new image paths
      final updatedPatient = widget.patient.copyWith(imagePaths: _imagePaths);

      // Get patients box from Hive
      final patientsBox = Hive.box<Patient>('patients');

      // Find the patient in the box and update it
      final patientKey = patientsBox.keyAt(patientsBox.values
          .toList()
          .indexWhere((patient) => patient == widget.patient));

      if (patientKey != null) {
        print(patientKey);
        // Update the patient in the database
        await patientsBox.put(patientKey, updatedPatient!);

        // Update the patient object reference to reflect changes
        widget.patient.imagePaths = _imagePaths;

        // Show success feedback and return to previous screen
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Rasmlar muvaffaqiyatli saqlandi')),
          );
          Navigator.of(context).pop(true);
        }
      } else {
        throw Exception('Patient not found in database');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Saqlashda xatolik yuz berdi: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rasmlarni tahrirlash'),
        actions: [
          if (_hasChanges)
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: _saveChanges,
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _imagePaths.isEmpty
                ? const Center(child: Text('Rasmlar yo\'q'))
                : GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                    ),
                    itemCount: _imagePaths.length,
                    itemBuilder: (context, index) {
                      return Stack(
                        fit: StackFit.expand,
                        children: [
                          Card(
                            elevation: 4,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.file(
                                File(_imagePaths[index]),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          Positioned(
                            top: 8,
                            right: 8,
                            child: CircleAvatar(
                              radius: 16,
                              backgroundColor: Colors.red.withOpacity(0.7),
                              child: IconButton(
                                padding: EdgeInsets.zero,
                                iconSize: 20,
                                icon: const Icon(Icons.delete,
                                    color: Colors.white),
                                onPressed: () => _removeImage(index),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showImageSourceOptions,
        child: const Icon(Icons.add_a_photo),
      ),
    );
  }
}
