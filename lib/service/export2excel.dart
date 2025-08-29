import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:excel/excel.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/patient.dart';

class ExportService {
  // Format date to readable string
  static String _formatDate(DateTime date) {
    return DateFormat('dd.MM.yyyy').format(date);
  }

  // Export patients data to Excel file
  static Future<String?> exportPatientsToExcel(BuildContext context) async {
    try {
      // Get patients from Supabase
      final response = await Supabase.instance.client
          .from(Patient.tableName)
          .select()
          .order('created_at', ascending: false);

      if (response.isEmpty) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text("Eksport qilish uchun bemorlar mavjud emas.")),
          );
        }
        return null;
      }

      final patients = (response as List)
          .map((json) => Patient.fromJson(json))
          .toList();

      final excel = Excel.createExcel();
      final sheet = excel['Patients'];

      final headers = [
        'ID',
        'F.I.O',
        'Tug‘ilgan sana',
        'Telefon raqami',
        'Birinchi tashrif',
        'Shikoyat',
        'Manzil',
      ];

      for (var i = 0; i < headers.length; i++) {
        final cell =
            sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0));
        cell.value = TextCellValue(headers[i]);
        cell.cellStyle = CellStyle(
          bold: true,
          backgroundColorHex: ExcelColor.blue,
          fontColorHex: ExcelColor.white,
        );
      }

      for (var i = 0; i < patients.length; i++) {
        final patient = patients[i];
        final row = i + 1;

        sheet
            .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row))
            .value = TextCellValue((i + 1).toString());
        sheet
            .cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: row))
            .value = TextCellValue(patient.ismi);
        sheet
            .cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: row))
            .value = TextCellValue(_formatDate(patient.tugilganSana));
        sheet
            .cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: row))
            .value = TextCellValue(patient.telefonRaqami);
        sheet
            .cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: row))
            .value = TextCellValue(_formatDate(patient.birinchiKelganSana));
        sheet
            .cell(CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: row))
            .value = TextCellValue(patient.shikoyat);
        sheet
            .cell(CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: row))
            .value = TextCellValue(patient.manzil);
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
      
      // Share the file
      if (context.mounted) {
        await Share.shareXFiles([XFile(filePath)], text: 'Bemorlar ro\'yxati');
      }
      
      return filePath;
    } catch (e, stackTrace) {
      debugPrint('Error exporting to Excel: $e\n$stackTrace');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Xatolik yuz berdi: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return null;
    }
  }

  // Share the exported Excel file
  static Future<void> shareExcelFile(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        // Ensure correct filename and MIME type for better compatibility
        final fileName = file.uri.pathSegments.isNotEmpty
            ? file.uri.pathSegments.last
            : 'export.xlsx';
        await Share.shareXFiles(
          [
            XFile(
              filePath,
              name: fileName,
              mimeType:
                  'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
            )
          ],
          subject: 'Bemorlar ro\'yxati',
          text: 'Bemorlar ma\'lumotlari',
        );
      } else {
        throw Exception("Excel file not found");
      }
    } catch (e) {
      rethrow;
    }
  }
}
