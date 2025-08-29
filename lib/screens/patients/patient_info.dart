import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:hive/hive.dart';
import 'package:stomotologiya_app/models/patient.dart';
import '../../routes.dart';

class PatientDetailsScreen extends StatefulWidget {
  final Patient patient;

  const PatientDetailsScreen({super.key, required this.patient});

  @override
  State<PatientDetailsScreen> createState() => _PatientDetailsScreenState();
}

class _PatientDetailsScreenState extends State<PatientDetailsScreen> {
  @override
  Widget build(BuildContext context) {
    final formatter = DateFormat('dd.MM.yyyy');
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: CustomScrollView(
        slivers: [
          // Modern SliverAppBar with gradient
          SliverAppBar(
            expandedHeight: 200,
            floating: false,
            pinned: true,
            elevation: 0,
            backgroundColor: Colors.blue[600],
            foregroundColor: Colors.white,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.blue[600]!, Colors.blue[400]!],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 40),
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            spreadRadius: 2,
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          _getInitials(widget.patient.ismi),
                          style: TextStyle(
                            color: Colors.blue[600],
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      widget.patient.ismi,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Bemor ma\'lumotlari',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit_rounded),
                tooltip: 'Tahrirlash',
                onPressed: () {
                  Navigator.pushNamed(
                    context,
                    AppRoutes.patientEdit,
                    arguments: widget.patient,
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.photo_library_rounded),
                tooltip: 'Rasmlar',
                onPressed: () => _editPatientImages(context),
              ),
            ],
          ),
          // Main content
          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Patient Information Card
                _buildModernInfoCard(
                  title: 'Asosiy Ma\'lumotlar',
                  icon: Icons.person_rounded,
                  children: [
                    _buildModernInfoTile(
                      icon: Icons.phone_rounded,
                      label: 'Telefon raqami',
                      value: widget.patient.telefonRaqami ?? "",
                      color: Colors.green,
                    ),
                    _buildModernInfoTile(
                      icon: Icons.cake_rounded,
                      label: 'Tug\'ilgan sana',
                      value: formatter.format(widget.patient.tugilganSana),
                      color: Colors.orange,
                    ),
                    _buildModernInfoTile(
                      icon: Icons.calendar_today_rounded,
                      label: 'Birinchi tashrif',
                      value:
                          formatter.format(widget.patient.birinchiKelganSana),
                      color: Colors.blue,
                    ),
                    _buildModernInfoTile(
                      icon: Icons.location_on_rounded,
                      label: 'Manzil',
                      value: widget.patient.manzil,
                      color: Colors.red,
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                // Medical Information Card
                _buildModernInfoCard(
                  title: 'Tibbiy Ma\'lumotlar',
                  icon: Icons.medical_services_rounded,
                  children: [
                    _buildModernInfoTile(
                      icon: Icons.report_problem_rounded,
                      label: 'Shikoyat',
                      value: widget.patient.shikoyat,
                      color: Colors.purple,
                      isExpandable: true,
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                // Images Gallery Card
                if (widget.patient.rasmlarManzillari.isNotEmpty)
                  _buildModernInfoCard(
                    title: 'Tibbiy Rasmlar',
                    icon: Icons.photo_library_rounded,
                    children: [
                      SizedBox(
                        height: 200,
                        child: _buildModernImageGallery(context),
                      ),
                    ],
                  ),
                if (widget.patient.rasmlarManzillari.isNotEmpty)
                  const SizedBox(height: 20),
                // Visit History Card
                _buildModernInfoCard(
                  title: 'Tashrif Tarixi',
                  icon: Icons.history_rounded,
                  children: [
                    if (widget.patient.tashrifSanalari.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          children: [
                            Icon(
                              Icons.event_busy_rounded,
                              size: 48,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Hozircha qo\'shimcha tashriflar yo\'q',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      ...widget.patient.tashrifSanalari.map(
                        (date) => _buildVisitTile(date),
                      ),
                  ],
                ),
              ]),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddVisitDialog(context),
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text(
          'Tashrif qo\'shish',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  // Get initials from name
  String _getInitials(String fullName) {
    if (fullName.isEmpty) return '?';
    return fullName
        .split(' ')
        .where((s) => s.isNotEmpty)
        .map((s) => s[0].toUpperCase())
        .take(2)
        .join('');
  }

  // Modern info card widget
  Widget _buildModernInfoCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue[50]!, Colors.blue[100]!],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue[600],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[800],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: children,
            ),
          ),
        ],
      ),
    );
  }

  // Modern info tile widget
  Widget _buildModernInfoTile({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    bool isExpandable = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: color,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                  maxLines: isExpandable ? null : 2,
                  overflow: isExpandable ? null : TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Modern image gallery widget
  Widget _buildModernImageGallery(BuildContext context) {
    return ListView.builder(
      scrollDirection: Axis.horizontal,
      itemCount: widget.patient.rasmlarManzillari.length,
      itemBuilder: (context, index) {
        return Container(
          width: 150,
          margin: const EdgeInsets.only(right: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.2),
                spreadRadius: 1,
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              widget.patient.rasmlarManzillari[index],
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: Colors.grey[200],
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.broken_image_rounded,
                        size: 40,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Rasm yuklanmadi',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  // Visit tile widget
  Widget _buildVisitTile(String date) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.green.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.check_circle_rounded,
            color: Colors.green[600],
            size: 20,
          ),
          const SizedBox(width: 12),
          Text(
            DateFormat('dd.MM.yyyy').format(DateTime.parse(date)),
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  void _showAddVisitDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Yangi Tashrif'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Yangi tashrif sanasini tanlang:'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now(),
                );
                if (date != null) {
                  Navigator.of(context).pop();
                  _addVisitDate(context, date);
                }
              },
              child: const Text('Sana tanlash'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Bekor qilish'),
          ),
        ],
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
            onPressed: () async {
              // Remove the visit date
              widget.patient.tashrifSanalari.removeWhere((dateStr) {
                final visitDate = DateTime.parse(dateStr);
                return visitDate.year == date.year &&
                    visitDate.month == date.month &&
                    visitDate.day == date.day;
              });

              // Save changes to Hive (guard if object is not in a box)
              if (widget.patient.isInBox) {
                await widget.patient.save();
              } else if (Hive.isBoxOpen('patients')) {
                final box = Hive.box<Patient>('patients');
                // Try to find and update by id if present; otherwise add
                if (widget.patient.id != null) {
                  final index = box.values.toList().indexWhere(
                    (p) => p.id == widget.patient.id,
                  );
                  if (index != -1) {
                    await box.putAt(index, widget.patient);
                  } else {
                    await box.add(widget.patient);
                  }
                } else {
                  await box.add(widget.patient);
                }
              }

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

  void _showFullScreenImage(BuildContext context, int initialIndex) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.black,
        child: Stack(
          children: [
            PageView.builder(
              itemCount: widget.patient.rasmlarManzillari.length,
              controller: PageController(initialPage: initialIndex),
              itemBuilder: (context, index) {
                return InteractiveViewer(
                  child: Image.network(
                    widget.patient.rasmlarManzillari[index],
                    fit: BoxFit.contain,
                  ),
                );
              },
            ),
            Positioned(
              top: 40,
              right: 20,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 30),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _editPatientImages(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Rasm tahrirlash funksiyasi tez orada qo\'shiladi'),
        backgroundColor: Colors.blue,
      ),
    );
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
                      color: Colors.black87,
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
