import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/patient.dart';
import '../../service/error_handler.dart';

class PatientImagesEditScreen extends StatefulWidget {
  final Patient patient;

  const PatientImagesEditScreen({super.key, required this.patient});

  @override
  State<PatientImagesEditScreen> createState() => _PatientImagesEditScreenState();
}

class _PatientImagesEditScreenState extends State<PatientImagesEditScreen> {
  late List<String> _imagePaths;
  bool _hasChanges = false;
  bool _isLoading = false;
  final ImagePicker _picker = ImagePicker();
  final ErrorHandler _errorHandler = ErrorHandler();

  @override
  void initState() {
    super.initState();
    _imagePaths = List<String>.from(widget.patient.rasmlarManzillari);
  }

  Future<bool> _confirmExit() async {
    if (!_hasChanges) return true;

    final shouldPop = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('O\'zgarishlarni saqlamay chiqish'),
        content: const Text('Agar siz hozir chiqib ketsangiz, o\'zgarishlaringiz saqlanmaydi. Davom etishni xohlaysizmi?'),
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

  Future<void> _confirmDeleteImage(int index) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rasmini o\'chirish'),
        content: const Text('Bu rasmini o\'chirishni istaysizmi?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Bekor qilish'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('O\'chirish'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      setState(() {
        _imagePaths.removeAt(index);
        _hasChanges = true;
      });
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      if (!mounted) return;
      
      Navigator.of(context).pop();
      setState(() => _isLoading = true);

      if (source == ImageSource.camera) {
        final XFile? image = await _picker.pickImage(
          source: source,
          imageQuality: 80,
        );

        if (image != null && mounted) {
          setState(() {
            _imagePaths.add(File(image.path).path);
            _hasChanges = true;
          });
        }
      } else {
        final List<XFile> images = await _picker.pickMultiImage(
          imageQuality: 80,
        );

        if (images.isNotEmpty && mounted) {
          setState(() {
            _imagePaths.addAll(images.map((xFile) => File(xFile.path).path));
            _hasChanges = true;
          });
        }
      }
    } catch (e) {
      _errorHandler.showError('Rasm yuklashda xatolik: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _showImageSourceOptions() async {
    if (_isLoading) return;

    await showModalBottomSheet(
      context: context,
      isDismissible: !_isLoading,
      enableDrag: !_isLoading,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: CircularProgressIndicator(),
              )
            else ...[
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
              if (_imagePaths.isNotEmpty)
                ListTile(
                  leading: const Icon(Icons.delete, color: Colors.red),
                  title: const Text('Barcha rasmlarni o\'chirish'),
                  onTap: () {
                    Navigator.of(context).pop();
                    _confirmDeleteAllImages();
                  },
                ),
            ],
          ],
        ),
      ),
    );
  }
  
  Future<void> _confirmDeleteAllImages() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tasdiqlash'),
        content: const Text('Barcha rasmlarni o\'chirishni istaysizmi?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Bekor qilish'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('O\'chirish'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      setState(() {
        _imagePaths.clear();
        _hasChanges = true;
      });
    }
  }

  Future<void> _saveChanges() async {
    if (!_hasChanges || _isLoading) return;

    setState(() => _isLoading = true);
    
    try {
      // Upload new images to Supabase Storage
      final uploadedImageUrls = await _uploadNewImages();
      
      // Update patient record in Supabase
      await Supabase.instance.client
          .from('patients')
          .update({
            'rasmlar_manzillari': uploadedImageUrls,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', widget.patient.id ?? '');

      if (mounted) {
        _errorHandler.showSuccess('Rasmlar muvaffaqiyatli yangilandi');
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        _errorHandler.showError('Xatolik yuz berdi: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
  
  Future<List<String>> _uploadNewImages() async {
    final newImageFiles = _imagePaths.where((path) => !path.startsWith('http'));
    final List<String> uploadedUrls = [];
    
    // Keep existing remote URLs
    uploadedUrls.addAll(_imagePaths.where((path) => path.startsWith('http')));
    
    // Upload new local images
    for (final imagePath in newImageFiles) {
      final file = File(imagePath);
      final fileName = '${widget.patient.id}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      
      // Simple file upload to Supabase storage
      final bytes = await file.readAsBytes();
      await Supabase.instance.client.storage
          .from('patient-images')
          .uploadBinary(fileName, bytes);
      
      final url = Supabase.instance.client.storage
          .from('patient-images')
          .getPublicUrl(fileName);
      
      uploadedUrls.add(url);
    }
    
    return uploadedUrls;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _confirmExit,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Rasmlarni tahrirlash'),
          actions: [
            if (_hasChanges)
              TextButton(
                onPressed: _isLoading ? null : _saveChanges,
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text('Saqlash'),
              ),
          ],
        ),
        floatingActionButton: _isLoading
            ? null
            : FloatingActionButton(
                onPressed: _showImageSourceOptions,
                child: const Icon(Icons.add_photo_alternate),
              ),
        body: _isLoading && _imagePaths.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : _imagePaths.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.photo_library,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Hech qanday rasm mavjud emas',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: _isLoading ? null : _showImageSourceOptions,
                          icon: const Icon(Icons.add_photo_alternate),
                          label: const Text('Rasm qo\'shish'),
                        ),
                      ],
                    ),
                  )
                : Stack(
                    children: [
                      GridView.builder(
                        padding: const EdgeInsets.all(8),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                          childAspectRatio: 0.75,
                        ),
                        itemCount: _imagePaths.length,
                        itemBuilder: (context, index) {
                          final isLocalImage = !_imagePaths[index].startsWith('http');
                          
                          return Stack(
                            fit: StackFit.expand,
                            children: [
                              isLocalImage
                                  ? Image.file(
                                      File(_imagePaths[index]),
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) =>
                                          const Center(child: Icon(Icons.broken_image)),
                                    )
                                  : Image.network(
                                      _imagePaths[index],
                                      fit: BoxFit.cover,
                                      loadingBuilder: (context, child, loadingProgress) {
                                        if (loadingProgress == null) return child;
                                        return const Center(
                                          child: CircularProgressIndicator(),
                                        );
                                      },
                                      errorBuilder: (context, error, stackTrace) =>
                                          const Center(child: Icon(Icons.broken_image)),
                                    ),
                              Positioned(
                                top: 4,
                                right: 4,
                                child: IconButton(
                                  icon: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: const BoxDecoration(
                                      color: Colors.black54,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.close,
                                      color: Colors.white,
                                      size: 16,
                                    ),
                                  ),
                                  onPressed: _isLoading
                                      ? null
                                      : () => _confirmDeleteImage(index),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                      if (_isLoading)
                        const Center(
                          child: CircularProgressIndicator(),
                        ),
                    ],
                  ),
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}
