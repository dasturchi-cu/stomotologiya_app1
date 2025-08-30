import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:stomotologiya_app/models/patient.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../service/error_handler.dart';

class PatientImagesEditScreen extends StatefulWidget {
  final Patient patient;

  const PatientImagesEditScreen({super.key, required this.patient});

  @override
  State<PatientImagesEditScreen> createState() =>
      _PatientImagesEditScreenState();
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

  Future<void> _confirmDeleteImage(int index) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rasmni o\'chirish'),
        content: const Text('Bu rasmni o\'chirishni istaysizmi?'),
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
    if (widget.patient.id == null || widget.patient.id!.isEmpty) {
      _errorHandler.showError('Bemor ID topilmadi. Avval bemorni saqlang.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final uploadedImageUrls = await _uploadNewImages();

      final updated = await Supabase.instance.client
          .from('patients')
          .update({
            'rasmlar_manzillari': uploadedImageUrls,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', widget.patient.id!)
          .select('id, rasmlar_manzillari')
          .maybeSingle();

      if (updated == null) {
        throw Exception('Server javobi bo\'sh. RLS yoki ID mos emas bo\'lishi mumkin.');
      }

      final updatedUrls = List<String>.from(updated['rasmlar_manzillari'] ?? []);
      widget.patient.rasmlarManzillari
        ..clear()
        ..addAll(updatedUrls);

      if (mounted) {
        _errorHandler.showSuccess('Rasmlar muvaffaqiyatli yangilandi');
        _hasChanges = false;
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        _errorHandler.showError('Saqlashda xatolik: ${e.toString()}');
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

    uploadedUrls.addAll(_imagePaths.where((path) => path.startsWith('http')));

    for (final imagePath in newImageFiles) {
      final file = File(imagePath);
      final fileName =
          '${widget.patient.id}_${DateTime.now().millisecondsSinceEpoch}.jpg';

      final bytes = await file.readAsBytes();
      await Supabase.instance.client.storage
          .from('rasmlar')
          .uploadBinary(fileName, bytes);

      final url = Supabase.instance.client.storage
          .from('rasmlar')
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
        backgroundColor: const Color(0xFFF8FAFC),
        body: CustomScrollView(
          slivers: [
            SliverAppBar(
              title: const Text('Rasmlarni Tahrirlash'),
              pinned: true,
              floating: true,
              backgroundColor: const Color(0xFF2563EB),
              foregroundColor: Colors.white,
              actions: [
                if (_hasChanges)
                  Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: TextButton(
                      onPressed: _isLoading ? null : _saveChanges,
                      style: TextButton.styleFrom(
                        backgroundColor: Colors.white.withOpacity(0.2),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Text('Saqlash', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
              ],
            ),
            _buildBody(),
          ],
        ),
        floatingActionButton: _isLoading
            ? null
            : FloatingActionButton.extended(
                onPressed: _showImageSourceOptions,
                icon: const Icon(Icons.add_a_photo_rounded),
                label: const Text('Rasm Qo\'shish'),
                backgroundColor: const Color(0xFF3B82F6),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading && _imagePaths.isEmpty) {
      return const SliverFillRemaining(
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_imagePaths.isEmpty) {
      return SliverFillRemaining(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.photo_library_outlined,
                size: 80,
                color: Colors.grey[300],
              ),
              const SizedBox(height: 24),
              Text(
                'Hech qanday rasm mavjud emas',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Colors.grey[600]),
              ),
              const SizedBox(height: 8),
              Text(
                'Yangi rasm qo\'shish uchun \n pastdagi tugmani bosing.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.grey[500]),
              ),
            ],
          ),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.all(16.0),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 0.8,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            return _buildImageTile(index);
          },
          childCount: _imagePaths.length,
        ),
      ),
    );
  }

  Widget _buildImageTile(int index) {
    final path = _imagePaths[index];
    final isLocalImage = !path.startsWith('http') && !path.startsWith('https');

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          fit: StackFit.expand,
          children: [
            isLocalImage
                ? Image.file(
                    path.startsWith('file://') 
                        ? File.fromUri(Uri.parse(path))
                        : File(path),
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        const Center(child: Icon(Icons.broken_image, color: Colors.grey)),
                  )
                : Image.network(
                    path,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return const Center(child: CircularProgressIndicator());
                    },
                    errorBuilder: (context, error, stackTrace) =>
                        const Center(child: Icon(Icons.broken_image, color: Colors.grey)),
                  ),
            Positioned(
              top: 8,
              right: 8,
              child: Material(
                color: Colors.black54,
                shape: const CircleBorder(),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: _isLoading ? null : () => _confirmDeleteImage(index),
                  child: const SizedBox(
                    width: 32,
                    height: 32,
                    child: Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                ),
              ),
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

