import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:intl/intl.dart';
import 'package:open_filex/open_filex.dart';
import '../models/patient.dart';
import '../service/export2excel.dart';

class ExportScreen extends StatefulWidget {
  const ExportScreen({super.key});

  @override
  State<ExportScreen> createState() => _ExportScreenState();
}

class _ExportScreenState extends State<ExportScreen> {
  DateTime? startDate;
  DateTime? endDate;
  bool isExporting = false;
  String? exportError;
  String? exportedFilePath;
  int patientCount = 0;

  @override
  void initState() {
    super.initState();
    _updatePatientCount();
  }

  void _updatePatientCount() {
    final box = Hive.box<Patient>('patients');
    setState(() {
      patientCount = box.length;
    });
  }

  Future<void> _selectDate(BuildContext context, bool isStart) async {
    final DateTime now = DateTime.now();
    final DateTime initialDate = isStart
        ? (startDate ?? now.subtract(Duration(days: 30)))
        : (endDate ?? now);

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2020),
      lastDate: now,
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
        if (isStart) {
          startDate = picked;
          // If end date is before start date, update end date
          if (endDate != null && endDate!.isBefore(startDate!)) {
            endDate = startDate;
          }
        } else {
          endDate = picked;
          // If start date is after end date, update start date
          if (startDate != null && startDate!.isAfter(endDate!)) {
            startDate = endDate;
          }
        }
      });
    }
  }

  Future<void> _exportData() async {
    setState(() {
      isExporting = true;
      exportError = null;
      exportedFilePath = null;
    });

    try {
      final filePath = await ExportService.exportPatientsToExcel(context);
      if (filePath != null) {
        setState(() {
          exportedFilePath = filePath;
          isExporting = false;
        });
        // Immediately open share sheet for convenience
        if (!mounted) return;
        await ExportService.shareExcelFile(filePath);
      } else {
        setState(() {
          isExporting = false;
          exportError = 'Eksport bekor qilindi yoki xatolik yuz berdi.';
        });
      }
    } catch (e) {
      setState(() {
        exportError = e.toString();
        isExporting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: Text(
          'Ma\'lumotlarni eksport qilish',
          style: TextStyle(
            color: Colors.blue[800],
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.blue[800]),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoCard(),
            SizedBox(height: 16),
            // Date filter section
            _buildSectionHeader('Sana bo\'yicha filtrlash'),
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _buildDateSelector(
                          label: 'Boshlanish sanasi',
                          date: startDate,
                          onTap: () => _selectDate(context, true),
                        ),
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: _buildDateSelector(
                          label: 'Tugash sanasi',
                          date: endDate,
                          onTap: () => _selectDate(context, false),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () {
                      setState(() {
                        startDate = null;
                        endDate = null;
                      });
                    },
                    icon: Icon(Icons.clear),
                    label: Text('Filtrni tozalash'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[200],
                      foregroundColor: Colors.grey[800],
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 24),
            // Export options section
            _buildSectionHeader('Eksport parametrlari'),
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  _buildExportOption(
                    title: 'Excel (.xlsx)',
                    icon: Icons.table_chart,
                    description:
                        'Bemorlar ma\'lumotlarini Excel formatida eksport qilish',
                    isSelected: true,
                  ),
                  Divider(),
                  _buildExportOption(
                    title: 'CSV',
                    icon: Icons.insert_drive_file,
                    description:
                        'Bemorlar ma\'lumotlarini CSV formatida eksport qilish',
                    isSelected: false,
                    isDisabled: true,
                  ),
                  Divider(),
                  _buildExportOption(
                    title: 'PDF',
                    icon: Icons.picture_as_pdf,
                    description:
                        'Bemorlar ma\'lumotlarini PDF formatida eksport qilish',
                    isSelected: false,
                    isDisabled: true,
                  ),
                ],
              ),
            ),
            SizedBox(height: 24),

            if (exportError != null)
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red[400]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: Colors.red[700]),
                    SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        'Xatolik: $exportError',
                        style: TextStyle(color: Colors.red[700]),
                      ),
                    ),
                  ],
                ),
              ),

            if (exportedFilePath != null)
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green[400]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.check_circle_outline,
                            color: Colors.green[700]),
                        SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            'Eksport muvaffaqiyatli yakunlandi!',
                            style: TextStyle(
                              color: Colors.green[700],
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Fayl joylashgan: $exportedFilePath',
                      style: TextStyle(fontSize: 12),
                    ),
                    SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        OutlinedButton.icon(
                          onPressed: exportedFilePath != null
                              ? () async {
                                  final result =
                                      await OpenFilex.open(exportedFilePath!);
                                  if (result.type != ResultType.done &&
                                      mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'Faylni ochishda xatolik: ${result.message}',
                                        ),
                                      ),
                                    );
                                  }
                                }
                              : null,
                          icon: Icon(Icons.folder_open),
                          label: Text('Papkani ochish'),
                        ),
                        SizedBox(width: 12),
                        ElevatedButton.icon(
                          onPressed: () {
                            if (exportedFilePath != null) {
                              ExportService.shareExcelFile(exportedFilePath!);
                            }
                          },
                          icon: Icon(Icons.share),
                          label: Text('Ulashish'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue[800],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

            SizedBox(height: 32),

            // Export button
            ElevatedButton(
              onPressed: isExporting ? null : _exportData,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[800],
                minimumSize: Size(double.infinity, 56),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: isExporting
                  ? Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        ),
                        SizedBox(width: 16),
                        Text('Eksport qilinmoqda...'),
                      ],
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.file_download),
                        SizedBox(width: 16),
                        Text(
                          'EKSPORT QILISH',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
            ),

            SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.people_alt_outlined,
              color: Colors.blue[800],
              size: 32,
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Barcha bemorlar',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[800],
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Sizning bazangizda $patientCount ta bemor mavjud',
                  style: TextStyle(
                    color: Colors.blue[800],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: EdgeInsets.only(left: 4, bottom: 8),
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

  Widget _buildDateSelector({
    required String label,
    required DateTime? date,
    required VoidCallback onTap,
  }) {
    final formattedDate =
        date != null ? DateFormat('dd.MM.yyyy').format(date) : 'Tanlanmagan';

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(8),
        ),
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  formattedDate,
                  style: TextStyle(
                    fontWeight:
                        date != null ? FontWeight.bold : FontWeight.normal,
                    color: date != null ? Colors.black87 : Colors.grey[500],
                  ),
                ),
                Icon(
                  Icons.calendar_today,
                  size: 16,
                  color: Colors.blue[800],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExportOption({
    required String title,
    required IconData icon,
    required String description,
    required bool isSelected,
    bool isDisabled = false,
  }) {
    return Opacity(
      opacity: isDisabled ? 0.5 : 1.0,
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isSelected ? Colors.blue[50] : Colors.grey[100],
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: isSelected ? Colors.blue[800] : Colors.grey[700],
          ),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isDisabled ? Colors.grey[600] : Colors.black87,
          ),
        ),
        subtitle: Text(
          description,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
        trailing: isSelected
            ? Icon(Icons.check_circle, color: Colors.blue[800])
            : (isDisabled
                ? Text(
                    'Tez orada',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[500],
                    ),
                  )
                : Icon(Icons.radio_button_unchecked, color: Colors.grey[400])),
        onTap: isDisabled
            ? null
            : () {
                // Toggle selection logic here
              },
      ),
    );
  }
}
