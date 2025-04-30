import 'dart:io';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';
import 'package:excel/excel.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';
import '../models/patient.dart';

class ExportService {
  // Format date to readable string
  static String _formatDate(DateTime date) {
    return DateFormat('dd.MM.yyyy').format(date);
  }

  // Export patients data to Excel file
  static Future<String?> exportPatientsToExcel(BuildContext context) async {
    try {
      final patientsBox = Hive.box<Patient>('patients');
      final patients = patientsBox.values.toList();

      if (patients.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Eksport qilish uchun bemorlar mavjud emas.")),
        );
        return null;
      }

      final excel = Excel.createExcel();
      final sheet = excel['Patients'];

      final headers = [
        'ID', 'F.I.O', 'Tug‘ilgan sana', 'Telefon raqami', 'Birinchi tashrif', 'Shikoyat', 'Manzil',
      ];

      for (var i = 0; i < headers.length; i++) {
        final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0));
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

        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row)).value = TextCellValue((i + 1).toString());
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: row)).value = TextCellValue(patient.fullName);
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: row)).value = TextCellValue(_formatDate(patient.birthDate));
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: row)).value = TextCellValue(patient.phoneNumber);
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: row)).value = TextCellValue(_formatDate(patient.firstVisitDate));
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: row)).value = TextCellValue(patient.complaint);
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: row)).value = TextCellValue(patient.address);
      }

      for (var i = 0; i < headers.length; i++) {
        sheet.setColumnWidth(i, 20.0);
      }

      final directory = await getApplicationDocumentsDirectory();
      final now = DateTime.now();
      final formattedDate = DateFormat('yyyy-MM-dd_HH-mm').format(now);
      final filePath = '${directory.path}/bemor_malumotlari_$formattedDate.xlsx';
      final file = File(filePath);
      final fileBytes = excel.encode();

      if (fileBytes != null) {
        await file.writeAsBytes(fileBytes);
        return filePath;
      } else {
        throw Exception("Excel faylni kodlashda xatolik");
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Xatolik yuz berdi: $e")),
      );
      return null;
    }
  }

  // Share the exported Excel file
  static Future<void> shareExcelFile(
      BuildContext context, String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        await Share.shareXFiles(
          [XFile(filePath)],
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
