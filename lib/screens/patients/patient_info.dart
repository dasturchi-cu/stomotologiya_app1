import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../routes.dart';

import '../../models/patient.dart';

class PatientDetailsScreen extends StatefulWidget {
  final Patient patient;

  const PatientDetailsScreen({super.key, required this.patient});

  @override
  State<PatientDetailsScreen> createState() => _PatientDetailsScreenState();
}

class _PatientDetailsScreenState extends State<PatientDetailsScreen> {
  @override
  Widget build(BuildContext context) {
    final formatter = DateFormat('yyyy-MM-dd');
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.patient.fullName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.photo_library),
            tooltip: 'Rasmlarni tahrirlash',
            onPressed: () => _editPatientImages(context),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showAddVisitDialog(context);
        },
        child: Icon(Icons.add),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Card(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              elevation: 6,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Patient Images Gallery
                    if (widget.patient.imagePaths.isNotEmpty) ...[
                      const Text(
                        "Tibbiy Rasmlar",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 200,
                        child: _buildImageGallery(context),
                      ),
                      const SizedBox(height: 20),
                    ],

                    // Patient Information
                    _buildInfoTile(
                        Icons.phone, 'Telefon', widget.patient.phoneNumber),
                    _buildInfoTile(Icons.cake, 'Tug\'ilgan sana',
                        formatter.format(widget.patient.birthDate)),
                    _buildInfoTile(Icons.calendar_today, 'Birinchi tashrif',
                        formatter.format(widget.patient.firstVisitDate)),
                    _buildInfoTile(Icons.report_problem, 'Shikoyat',
                        widget.patient.complaint),
                    _buildInfoTile(
                        Icons.home, 'Manzil', widget.patient.address),
                  ],
                ),
              ),
            ),
            Card(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              elevation: 6,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  spacing: 10,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Kelgan sanalari",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    _buildVisitDatesList()
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVisitDatesList() {
    if (widget.patient.visitDates.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text("Hali tashriflar yo'q"),
        ),
      );
    }

    // Sort dates newest first
    final sortedDates = List<DateTime>.from(widget.patient.visitDates)
      ..sort((a, b) => b.compareTo(a));

    final formatter = DateFormat('yyyy-MM-dd');

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: sortedDates.length,
      itemBuilder: (context, index) {
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: const Icon(Icons.calendar_month),
            title: Text(
              formatter.format(sortedDates[index]),
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            trailing: IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              onPressed: () => _removeVisitDate(context, sortedDates[index]),
            ),
          ),
        );
      },
    );
  }

  void _showAddVisitDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AddVisitDialog(
        onAddVisit: (date) {
          _addVisitDate(context, date);
        },
      ),
    );
  }

  void _addVisitDate(BuildContext context, DateTime date) async {
    widget.patient.addVisitDate(date);

    // Show success message
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Yangi tashrif qo\'shildi')),
    );

    // Optional: Refresh the UI
    if (context.mounted) {
      setState(() {}); // If using StatefulWidget
    }
  }

  void _removeVisitDate(BuildContext context, DateTime date) {
    // Confirm deletion
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tashrifni o\'chirish'),
        content: const Text('Haqiqatan ham bu tashrifni o\'chirmoqchimisiz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('YO\'Q'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              // Remove the visit date
              widget.patient.visitDates.removeWhere((visitDate) =>
                  visitDate.year == date.year &&
                  visitDate.month == date.month &&
                  visitDate.day == date.day);

              // Save changes to Hive
              widget.patient.save();

              // Close dialog
              Navigator.of(context).pop();

              // Show success message
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Tashrif o\'chirildi')),
              );

              // Refresh the screen
              if (context.mounted) {
                Navigator.pushReplacementNamed(
                  context,
                  AppRoutes.patientDetails,
                  arguments: widget.patient,
                );
              }
            },
            child: const Text('HA', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildImageGallery(BuildContext context) {
    return widget.patient.imagePaths.isEmpty
        ? const Center(child: Text("Rasmlar yo'q"))
        : PageView.builder(
            itemCount: widget.patient.imagePaths.length,
            itemBuilder: (context, index) {
              return GestureDetector(
                onTap: () => _showFullScreenImage(context, index),
                child: Card(
                  margin: const EdgeInsets.symmetric(horizontal: 8.0),
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      widget.patient.imagePaths[index],
                      fit: BoxFit.cover,
                      width: double.infinity,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Center(
                          child: CircularProgressIndicator(
                            value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded /
                                    loadingProgress.expectedTotalBytes!
                                : null,
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: Colors.grey[300],
                          child: const Icon(
                            Icons.broken_image,
                            size: 50,
                            color: Colors.grey,
                          ),
                        );
                      },
                    ),
                  ),
                ),
              );
            },
          );
  }

  void _showFullScreenImage(BuildContext context, int initialIndex) {
    Navigator.of(context).pushNamed(
      AppRoutes.imageViewer,
      arguments: {
        'imagePaths': widget.patient.imagePaths,
        'initialIndex': initialIndex,
      },
    );
  }

  void _editPatientImages(BuildContext context) async {
    final result = await Navigator.of(context).pushNamed(
      AppRoutes.patientImagesEdit,
      arguments: widget.patient,
    );

    // Refresh the screen if images were updated
    if (result == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Rasmlar yangilandi')),
      );
    }
  }

  Widget _buildInfoTile(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.blueAccent),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: Colors.grey,
                    )),
                const SizedBox(height: 4),
                Text(value,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    )),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Full screen image viewer for when user taps on an image
class FullScreenImageViewer extends StatefulWidget {
  final List<String> imagePaths;
  final int initialIndex;

  const FullScreenImageViewer({
    super.key,
    required this.imagePaths,
    required this.initialIndex,
  });

  @override
  State<FullScreenImageViewer> createState() => _FullScreenImageViewerState();
}

class _FullScreenImageViewerState extends State<FullScreenImageViewer> {
  late PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          '${_currentIndex + 1}/${widget.imagePaths.length}',
          style: const TextStyle(color: Colors.white),
        ),
      ),
      body: PageView.builder(
        controller: _pageController,
        itemCount: widget.imagePaths.length,
        onPageChanged: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        itemBuilder: (context, index) {
          return InteractiveViewer(
            minScale: 0.5,
            maxScale: 4.0,
            child: Center(
              child: Image.network(
                widget.imagePaths[index],
                fit: BoxFit.contain,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Center(
                    child: CircularProgressIndicator(
                      value: loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded /
                              loadingProgress.expectedTotalBytes!
                          : null,
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) => Container(
                  color: Colors.grey[800],
                  child: const Center(
                    child: Icon(
                      Icons.broken_image,
                      color: Colors.grey,
                      size: 50,
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class AddVisitDialog extends StatefulWidget {
  final Function(DateTime) onAddVisit;

  const AddVisitDialog({super.key, required this.onAddVisit});

  @override
  State<AddVisitDialog> createState() => _AddVisitDialogState();
}

class _AddVisitDialogState extends State<AddVisitDialog> {
  DateTime _selectedDate = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final formatter = DateFormat('yyyy-MM-dd');

    return AlertDialog(
      title: const Text('Yangi Tashrif Qo\'shish'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: _selectDate,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(formatter.format(_selectedDate)),
                  const Icon(Icons.calendar_today),
                ],
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('BEKOR QILISH'),
        ),
        ElevatedButton(
          onPressed: () {
            widget.onAddVisit(_selectedDate);
            Navigator.of(context).pop();
          },
          child: const Text('QO\'SHISH'),
        ),
      ],
    );
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now()
          .add(const Duration(days: 365)), // Allow future appointments
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }
}
