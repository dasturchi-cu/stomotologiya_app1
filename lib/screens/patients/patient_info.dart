import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
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
      backgroundColor: const Color(0xFFF8FAFC),
      body: CustomScrollView(
        slivers: [
          // Enhanced SliverAppBar with better gradient and animations
          SliverAppBar(
            expandedHeight: 180,
            floating: false,
            pinned: true,
            elevation: 0,
            backgroundColor: const Color(0xFF2563EB),
            foregroundColor: Colors.white,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color(0xFF3B82F6),
                      Color(0xFF1E40AF),
                      Color(0xFF1E3A8A)
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    stops: [0.0, 0.6, 1.0],
                  ),
                ),
                child: SafeArea(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final isDesktop = constraints.maxWidth > 800;
                      final avatarSize = isDesktop ? 70.0 : 60.0;
                      
                      return Padding(
                        padding: EdgeInsets.only(
                          top: isDesktop ? 20 : 15,
                          bottom: isDesktop ? 10 : 8,
                          left: 16,
                          right: 16,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Hero(
                              tag: 'patient_avatar_${widget.patient.id}',
                              child: Container(
                                width: avatarSize,
                                height: avatarSize,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      spreadRadius: 1,
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Center(
                                  child: Text(
                                    _getInitials(widget.patient.ismi),
                                    style: TextStyle(
                                      color: const Color(0xFF2563EB),
                                      fontSize: isDesktop ? 22 : 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(height: isDesktop ? 6 : 4),
                            Flexible(
                              child: Text(
                                widget.patient.ismi,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: isDesktop ? 18 : 16,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                              ),
                            ),
                            SizedBox(height: isDesktop ? 3 : 2),
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: isDesktop ? 6 : 4,
                                vertical: isDesktop ? 2 : 1,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                'Bemor ma\'lumotlari',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.95),
                                  fontSize: isDesktop ? 10 : 9,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
            actions: [
              Container(
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
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
              ),
              Container(
                margin: const EdgeInsets.only(right: 16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  icon: const Icon(Icons.photo_library_rounded),
                  tooltip: 'Rasmlar',
                  onPressed: () {
                    Navigator.pushNamed(
                      context,
                      AppRoutes.patientImagesEdit,
                      arguments: widget.patient,
                    );
                  },
                ),
              ),
            ],
          ),
          // Main content with enhanced spacing and design
          SliverPadding(
            padding: const EdgeInsets.all(24),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Enhanced Patient Information Card
                _buildModernInfoCard(
                  title: 'Asosiy Ma\'lumotlar',
                  icon: Icons.person_rounded,
                  gradient: const LinearGradient(
                    colors: [Color(0xFFEBF8FF), Color(0xFFDBEAFE)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  children: [
                    _buildModernInfoTile(
                      icon: Icons.phone_rounded,
                      label: 'Telefon raqami',
                      value: widget.patient.telefonRaqami ?? "Kiritilmagan",
                      color: const Color(0xFF10B981),
                    ),
                    _buildModernInfoTile(
                      icon: Icons.cake_rounded,
                      label: 'Tug\'ilgan sana',
                      value: formatter.format(widget.patient.tugilganSana),
                      color: const Color(0xFFF59E0B),
                    ),
                    _buildModernInfoTile(
                      icon: Icons.calendar_today_rounded,
                      label: 'Birinchi tashrif',
                      value:
                          formatter.format(widget.patient.birinchiKelganSana),
                      color: const Color(0xFF3B82F6),
                    ),
                    _buildModernInfoTile(
                      icon: Icons.location_on_rounded,
                      label: 'Manzil',
                      value: widget.patient.manzil,
                      color: const Color(0xFFEF4444),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                // Enhanced Medical Information Card
                _buildModernInfoCard(
                  title: 'Tibbiy Ma\'lumotlar',
                  icon: Icons.medical_services_rounded,
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFEF3F2), Color(0xFFFECDD3)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  children: [
                    _buildModernInfoTile(
                      icon: Icons.report_problem_rounded,
                      label: 'Shikoyat',
                      value: widget.patient.shikoyat,
                      color: const Color(0xFF8B5CF6),
                      isExpandable: true,
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                // Enhanced Images Gallery Card
                _buildEnhancedImageGallery(context),
                const SizedBox(height: 24),
                // Enhanced Visit History Card
                _buildModernInfoCard(
                  title: 'Tashrif Tarixi',
                  icon: Icons.history_rounded,
                  gradient: const LinearGradient(
                    colors: [Color(0xFFF0FDF4), Color(0xFFDCFCE7)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  children: [
                    if (widget.patient.tashrifSanalari.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.grey.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Icon(
                                Icons.event_busy_rounded,
                                size: 48,
                                color: Colors.grey[400],
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Hozircha qo\'shimcha tashriflar yo\'q',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Yangi tashrif qo\'shish uchun pastdagi tugmani bosing',
                              style: TextStyle(
                                color: Colors.grey[500],
                                fontSize: 14,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      )
                    else
                      ...widget.patient.tashrifSanalari.asMap().entries.map(
                            (entry) =>
                                _buildEnhancedVisitTile(entry.value, entry.key),
                          ),
                  ],
                ),
                const SizedBox(height: 100), // Space for FAB
              ]),
            ),
          ),
        ],
      ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF3B82F6).withOpacity(0.3),
              spreadRadius: 1,
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: FloatingActionButton.extended(
          onPressed: () async {
            final DateTime? picked = await showDatePicker(
              context: context,
              initialDate: DateTime.now(),
              firstDate: DateTime(2000),
              lastDate: DateTime(2101),
            );
            if (picked != null) {
              setState(() {
                widget.patient.addVisitDate(picked);
              });
              try {
                await widget.patient.saveToSupabase();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content:
                            Text('Tashrif sanasi muvaffaqiyatli saqlandi')),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Xatolik: ${e.toString()}')),
                  );
                }
              }
            }
          },
          backgroundColor: const Color(0xFF3B82F6),
          foregroundColor: Colors.white,
          icon: const Icon(Icons.add_rounded, size: 24),
          label: const Text(
            'Tashrif qo\'shish',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
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

  // Enhanced modern info card widget
  Widget _buildModernInfoCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
    Gradient? gradient,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.08),
            spreadRadius: 0,
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: gradient ??
                  LinearGradient(
                    colors: [Colors.blue[50]!, Colors.blue[100]!],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF3B82F6),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF3B82F6).withOpacity(0.3),
                        spreadRadius: 0,
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(
                    icon,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E3A8A),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: children,
            ),
          ),
        ],
      ),
    );
  }

  // Enhanced modern info tile widget
  Widget _buildModernInfoTile({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    bool isExpandable = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withOpacity(0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withOpacity(0.15),
          width: 1.5,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: color,
              size: 22,
            ),
          ),
          const SizedBox(width: 16),
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
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                    height: 1.4,
                  ),
                  maxLines: isExpandable ? null : 3,
                  overflow: isExpandable ? null : TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Simplified image gallery widget
  Widget _buildEnhancedImageGallery(BuildContext context) {
    final images = widget.patient.rasmlarManzillari;

    return _buildModernInfoCard(
      title: 'Tibbiy Rasmlar (${images.length})',
      icon: Icons.photo_library_rounded,
      gradient: const LinearGradient(
        colors: [Color(0xFFF0F9FF), Color(0xFFE0F2FE)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      children: [
        if (images.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24.0),
            child: Column(
              children: [
                Icon(
                  Icons.photo_library_outlined,
                  size: 48,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  'Hozircha rasmlar mavjud emas',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          )
        else
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 1.0,
            ),
            itemCount: images.length,
            itemBuilder: (context, index) =>
                _buildImageThumbnail(context, index),
          ),
      ],
    );
  }

  // Simple image thumbnail with tap to view
  Widget _buildImageThumbnail(BuildContext context, int index) {
    return GestureDetector(
      onTap: () => _showFullScreenImage(context, index),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Stack(
            fit: StackFit.expand,
            children: [
              (() {
                final path = widget.patient.rasmlarManzillari[index];
                final isNetwork =
                    path.startsWith('http') || path.startsWith('https');

                if (isNetwork) {
                  return Image.network(
                    path,
                    fit: BoxFit.cover,
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
                      color: Colors.grey[200],
                      child: const Icon(Icons.broken_image_rounded,
                          color: Colors.grey),
                    ),
                  );
                } else {
                  // Handle local file paths
                  File file;
                  if (path.startsWith('file://')) {
                    file = File.fromUri(Uri.parse(path));
                  } else if (path.startsWith('/')) {
                    // Absolute path
                    file = File(path);
                  } else {
                    // Relative path - shouldn't happen but handle gracefully
                    file = File(path);
                  }

                  return Image.file(
                    file,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: Colors.grey[200],
                      child: const Icon(Icons.broken_image_rounded,
                          color: Colors.grey),
                    ),
                  );
                }
              })(),
              const Positioned.fill(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    splashColor: Colors.black26,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Enhanced image tile with better interaction
  Widget _buildEnhancedImageTile(BuildContext context, int index) {
    return GestureDetector(
      onTap: () => _showFullScreenImage(context, index),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.15),
              spreadRadius: 1,
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            fit: StackFit.expand,
            children: [
              (() {
                final path = widget.patient.rasmlarManzillari[index];
                final isNetwork = path.startsWith('http');
                final errorWidget = Container(
                  color: Colors.grey[100],
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
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                );

                if (isNetwork) {
                  return Image.network(
                    path,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        color: Colors.grey[100],
                        child: Center(
                          child: CircularProgressIndicator(
                            value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded /
                                    loadingProgress.expectedTotalBytes!
                                : null,
                            strokeWidth: 2,
                            color: const Color(0xFF8B5CF6),
                          ),
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) => errorWidget,
                  );
                } else {
                  // Handle local file paths
                  File file;
                  if (path.startsWith('file://')) {
                    file = File.fromUri(Uri.parse(path));
                  } else if (path.startsWith('/')) {
                    // Absolute path
                    file = File(path);
                  } else {
                    // Relative path - shouldn't happen but handle gracefully
                    file = File(path);
                  }

                  return Image.file(
                    file,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => errorWidget,
                  );
                }
              })(),
              // Overlay with zoom icon
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.zoom_in_rounded,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Enhanced visit tile widget
  Widget _buildEnhancedVisitTile(String date, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF10B981).withOpacity(0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF10B981).withOpacity(0.2),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.check_circle_rounded,
              color: Color(0xFF10B981),
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  DateFormat('dd.MM.yyyy').format(DateTime.parse(date)),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                Text(
                  '${index + 1}-tashrif',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => _removeVisitDate(context, DateTime.parse(date)),
            icon: Icon(
              Icons.delete_outline_rounded,
              color: Colors.red[400],
              size: 20,
            ),
            tooltip: 'Tashrifni o\'chirish',
          ),
        ],
      ),
    );
  }

  void _showFullScreenImage(BuildContext context, int initialIndex) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FullScreenImageViewer(
          imagePaths: widget.patient.rasmlarManzillari,
          initialIndex: initialIndex,
        ),
      ),
    );
  }

  void _removeVisitDate(BuildContext context, DateTime date) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.warning_rounded,
                color: Colors.red,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Tashrifni o\'chirish',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: const Text('Haqiqatan ham bu tashrifni o\'chirmoqchimisiz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'YO\'Q',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () async {
              widget.patient.tashrifSanalari.removeWhere((dateStr) {
                final visitDate = DateTime.parse(dateStr);
                return visitDate.year == date.year &&
                    visitDate.month == date.month &&
                    visitDate.day == date.day;
              });

              try {
                await widget.patient.saveToSupabase();
                setState(() {});
                if (mounted) {
                  Navigator.of(context).pop(); // Close dialog
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Tashrif muvaffaqiyatli o\'chirildi')),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Xatolik: ${e.toString()}')),
                  );
                }
              }
            },
            child: const Text('HA'),
          ),
        ],
      ),
    );
  }
}

// Enhanced Full screen image viewer for when user taps on an image
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

class _FullScreenImageViewerState extends State<FullScreenImageViewer>
    with SingleTickerProviderStateMixin {
  late PageController _pageController;
  late int _currentIndex;
  late AnimationController _animationController;
  bool _isVisible = true;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _toggleVisibility() {
    setState(() {
      _isVisible = !_isVisible;
    });
    if (_isVisible) {
      _animationController.forward();
    } else {
      _animationController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: _toggleVisibility,
        child: Stack(
          children: [
            // Main image viewer
            PageView.builder(
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
                    child: Hero(
                      tag: 'image_$index',
                      child: (() {
                        final path = widget.imagePaths[index];
                        final isNetwork = path.startsWith('http');
                        final loadingWidget = Center(
                          child: Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.7),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const CircularProgressIndicator(
                                  strokeWidth: 3,
                                  color: Colors.white,
                                ),
                                const SizedBox(height: 16),
                                const Text(
                                  'Rasm yuklanmoqda...',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                        final errorWidget = Center(
                          child: Container(
                            padding: const EdgeInsets.all(32),
                            decoration: BoxDecoration(
                              color: Colors.grey[800],
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: const [
                                Icon(
                                  Icons.broken_image_rounded,
                                  color: Colors.grey,
                                  size: 64,
                                ),
                                SizedBox(height: 16),
                                Text(
                                  'Rasm yuklanmadi',
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );

                        if (isNetwork) {
                          return Image.network(
                            path,
                            fit: BoxFit.contain,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return loadingWidget;
                            },
                            errorBuilder: (context, error, stackTrace) =>
                                errorWidget,
                          );
                        } else {
                          // Handle local file paths
                          File file;
                          if (path.startsWith('file://')) {
                            file = File.fromUri(Uri.parse(path));
                          } else if (path.startsWith('/')) {
                            // Absolute path
                            file = File(path);
                          } else {
                            // Relative path - shouldn't happen but handle gracefully
                            file = File(path);
                          }

                          return Image.file(
                            file,
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) =>
                                errorWidget,
                          );
                        }
                      })(),
                    ),
                  ),
                );
              },
            ),
            // Top app bar with animation
            AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                return Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: Transform.translate(
                    offset: Offset(0, -100 * (1 - _animationController.value)),
                    child: Container(
                      padding: EdgeInsets.only(
                        top: MediaQuery.of(context).padding.top + 8,
                        left: 16,
                        right: 16,
                        bottom: 16,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withOpacity(0.7),
                            Colors.transparent,
                          ],
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.5),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: IconButton(
                              icon: const Icon(
                                Icons.arrow_back_rounded,
                                color: Colors.white,
                                size: 24,
                              ),
                              onPressed: () => Navigator.pop(context),
                            ),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.5),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '${_currentIndex + 1} / ${widget.imagePaths.length}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          const Spacer(),
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.5),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: IconButton(
                              icon: const Icon(
                                Icons.share_rounded,
                                color: Colors.white,
                                size: 24,
                              ),
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Row(
                                      children: [
                                        const Icon(Icons.info_outline_rounded,
                                            color: Colors.white),
                                        const SizedBox(width: 12),
                                        const Text(
                                            'Ulashish funksiyasi tez orada qo\'shiladi'),
                                      ],
                                    ),
                                    backgroundColor: const Color(0xFF3B82F6),
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(12)),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
            // Bottom indicator with animation
            if (widget.imagePaths.length > 1)
              AnimatedBuilder(
                animation: _animationController,
                builder: (context, child) {
                  return Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Transform.translate(
                      offset: Offset(0, 100 * (1 - _animationController.value)),
                      child: Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: [
                              Colors.black.withOpacity(0.7),
                              Colors.transparent,
                            ],
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(
                            widget.imagePaths.length,
                            (index) => AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              width: index == _currentIndex ? 24 : 8,
                              height: 8,
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              decoration: BoxDecoration(
                                color: index == _currentIndex
                                    ? Colors.white
                                    : Colors.white.withOpacity(0.4),
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF3B82F6).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.add_circle_outline_rounded,
              color: Color(0xFF3B82F6),
            ),
          ),
          const SizedBox(width: 12),
          const Text(
            'Yangi Tashrif Qo\'shish',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: _selectDate,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFF3B82F6)),
                borderRadius: BorderRadius.circular(12),
                color: const Color(0xFF3B82F6).withOpacity(0.05),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    formatter.format(_selectedDate),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const Icon(
                    Icons.calendar_today_rounded,
                    color: Color(0xFF3B82F6),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            'BEKOR QILISH',
            style: TextStyle(color: Colors.grey[600]),
          ),
        ),
        ElevatedButton(
          onPressed: () {
            widget.onAddVisit(_selectedDate);
            Navigator.of(context).pop();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF3B82F6),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: const Text(
            'QO\'SHISH',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF3B82F6),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }
}
