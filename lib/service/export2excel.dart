import 'dart:async';
import 'dart:io';
import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:excel/excel.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'patient_service.dart';

/// Service for exporting patient data to Excel format

class ExportService {
  // Format date to readable string in local timezone
  static String _formatDate(DateTime? date) {
    if (date == null) return 'Noma\'lum';
    try {
      return DateFormat('dd.MM.yyyy HH:mm').format(date.toLocal());
    } catch (e) {
      developer.log('Error formatting date: $e');
      return 'Xatolik';
    }
  }

  /// Exports patients data to Excel file and returns the file path
  /// Returns null if export fails or no patients found
  static Future<String?> exportPatientsToExcel(BuildContext context) async {
    // Check if context is still valid
    if (!context.mounted) return null;

    // Show loading indicator
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    scaffoldMessenger.showSnackBar(
      SnackBar(
        content: Row(
          children: [
            SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
            SizedBox(width: 16),
            Text(
              'Ma\'lumotlar yuklanmoqda...',
              style: TextStyle(fontSize: 14),
            ),
          ],
        ),
        duration: Duration(seconds: 5),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );

    try {
      // Initialize patient service
      final patientService = PatientService();
      await patientService.initialize();

      // Get patients using PatientService with timeout
      final patients = await patientService.getAllPatients().timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw TimeoutException('Serverga ulanishda kechikish yuz berdi');
        },
      );

      // Check if we have patients to export
      if (patients.isEmpty) {
        if (context.mounted) {
          scaffoldMessenger.hideCurrentSnackBar();
          scaffoldMessenger.showSnackBar(
            const SnackBar(
              content: Text('Eksport qilish uchun bemorlar mavjud emas'),
              backgroundColor: Colors.orange,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        return null;
      }

      // Create Excel workbook and sheet
      final excel = Excel.createExcel();
      final sheet = excel['Bemorlar'];

      // Define column headers with Uzbek labels
      final headers = [
        'T/r',
        'F.I.O',
        'Tug\'ilgan sana',
        'Telefon raqami',
        'Birinchi tashrif',
        'Oxirgi tashrif',
        'Tashriflar soni',
        'Shikoyat',
        'Manzil',
        'Yaratilgan sana',
      ];

      // Style for header row
      final headerStyle = CellStyle(
        bold: true,
        backgroundColorHex: ExcelColor.blue,
        fontColorHex: ExcelColor.white,
        horizontalAlign: HorizontalAlign.Center,
        verticalAlign: VerticalAlign.Center,
      );

      // Add headers to the sheet
      for (var i = 0; i < headers.length; i++) {
        final cell = sheet.cell(CellIndex.indexByColumnRow(
          columnIndex: i,
          rowIndex: 0,
        ));
        cell.value = TextCellValue(headers[i]);
        cell.cellStyle = headerStyle;
      }

      // Add patient data rows
      for (var i = 0; i < patients.length; i++) {
        final patient = patients[i];
        final row = i + 1; // +1 for header row

        // Get visit dates and process them
        final visitDates = patient.tashrifSanalari ?? [];
        final firstVisit = patient.birinchiKelganSana;
        final lastVisit =
            visitDates.isNotEmpty ? DateTime.tryParse(visitDates.last) : null;

        // Prepare row data
        final rowData = [
          (i + 1).toString(), // T/r
          patient.ismi, // F.I.O
          _formatDate(patient.tugilganSana), // Tug'ilgan sana
          patient.telefonRaqami, // Telefon raqami
          patient.telefonRaqami, // Telefon raqami
          _formatDate(firstVisit), // Birinchi tashrif
          _formatDate(lastVisit), // Oxirgi tashrif
          visitDates.length.toString(), // Tashriflar soni
          patient.shikoyat, // Shikoyat
          patient.manzil, // Manzil
          _formatDate(patient.createdAt), // Yaratilgan sana
        ];

        // Add row data to the sheet
        for (var j = 0; j < rowData.length; j++) {
          if (j < headers.length) {
            // Ensure we don't exceed header count
            final cell = sheet.cell(CellIndex.indexByColumnRow(
              columnIndex: j,
              rowIndex: row,
            ));
            cell.value = TextCellValue(rowData[j].toString());

            // Add some basic styling
            if (j == 1) {
              // Make patient names bold
              cell.cellStyle = CellStyle(bold: true);
            }

            // Right-align numeric columns
            if (j == 0 || j == 6) {
              // T/r and Tashriflar soni
              cell.cellStyle = CellStyle(
                  horizontalAlign: HorizontalAlign.Right,
                  verticalAlign: VerticalAlign.Center);
            }
          }
        }
      }

      for (var i = 0; i < headers.length; i++) {
        sheet.setColumnWidth(i, 20.0);
      }

      final directory = await getApplicationDocumentsDirectory();
      final now = DateTime.now();
      final formattedDate = DateFormat('yyyy-MM-dd_HH-mm').format(now);
      final fileName = 'bemor_malumotlari_$formattedDate.xlsx';
      final filePath = '${directory.path}/$fileName';
      final file = File(filePath);
      final fileBytes = excel.encode();

      if (fileBytes == null) {
        throw Exception("Excel faylni kodlashda xatolik");
      }

      await file.writeAsBytes(fileBytes);

      // Show success message
      if (context.mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Fayl muvaffaqiyatli yuklab olindi'),
            action: SnackBarAction(
              label: 'Ulashish',
              onPressed: () => shareExcelFile(filePath),
            ),
            duration: const Duration(seconds: 4),
          ),
        );
      }

      if (kDebugMode) {
        developer.log('Excel file saved to: $filePath');
      }

      return filePath;
    } catch (e, stackTrace) {
      developer.log('Error exporting to Excel',
          error: e, stackTrace: stackTrace);
      if (context.mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e.toString().contains('timeout')
                  ? 'Serverga ulanishda kechikish yuz berdi. Iltimos, internet aloqasini tekshiring.'
                  : 'Xatolik yuz berdi: ${e.toString()}',
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
      return null;
    }
  }

  /// Shares the exported Excel file using device's share dialog
  static Future<void> shareExcelFile(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        throw Exception('Fayl topilmadi');
      }

      final fileSize = await file.length();
      if (fileSize == 0) {
        throw Exception('Fayl bo\'sh');
      }

      final fileName =
          'bemor_malumotlari_${DateTime.now().millisecondsSinceEpoch}.xlsx';

      await Share.shareXFiles(
        [
          XFile(
            filePath,
            name: fileName,
            mimeType:
                'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
            length: fileSize,
            lastModified: await file.lastModified(),
          )
        ],
        subject: 'Bemorlar ro\'yxati',
        text:
            'Stomatologiya shifoxonasi bemorlari ro\'yxati\nFayl hajmi: ${(fileSize / 1024).toStringAsFixed(2)} KB',
      );
    } catch (e) {
      rethrow;
    }
  }
}
