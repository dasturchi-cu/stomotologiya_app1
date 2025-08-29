import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart'; // Sana formatlash uchun import
import 'package:stomotologiya_app/models/patient.dart';

class PatientEdit extends StatefulWidget {
  final int patientIndex; // Tahrir qilinayotgan bemorning indeksi

  const PatientEdit({super.key, required this.patientIndex});

  @override
  _PatientEditState createState() => _PatientEditState();
}

class _PatientEditState extends State<PatientEdit> {
  late TextEditingController fullNameController;
  late TextEditingController phoneNumberController;
  late TextEditingController complaintController;
  late TextEditingController addressController;
  late TextEditingController birthDateController;
  late TextEditingController firstVisitDateController;
  late DateTime? birthDate;
  late DateTime? firstVisitDate;
  String imagePath = ''; // 'final' o'rniga o'zgaruvchi
  List<String> imagePaths = [];

  @override
  void initState() {
    super.initState();

    var box = Hive.box<Patient>('patients');
    var patient = box.getAt(widget.patientIndex);

    fullNameController = TextEditingController(text: patient?.ismi ?? '');
    phoneNumberController =
        TextEditingController(text: patient?.telefonRaqami ?? '');
    complaintController = TextEditingController(text: patient?.shikoyat ?? '');
    addressController = TextEditingController(text: patient?.manzil ?? '');

    birthDate = patient?.tugilganSana;
    firstVisitDate = patient?.birinchiKelganSana;
    birthDateController = TextEditingController(
        text: birthDate != null ? formatDate(birthDate!) : '');
    firstVisitDateController = TextEditingController(
        text: firstVisitDate != null ? formatDate(firstVisitDate!) : '');

    // Initialize image paths
    imagePath = patient?.rasmManzili ?? '';
    imagePaths = patient?.rasmlarManzillari ?? [];
  }

  String formatDate(DateTime date) {
    return DateFormat('yyyy-MM-dd').format(date);
  }

  Future<void> _selectDate(BuildContext context, bool isBirthDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        if (isBirthDate) {
          birthDate = picked;
          birthDateController.text = formatDate(birthDate!);
        } else {
          firstVisitDate = picked;
          firstVisitDateController.text = formatDate(firstVisitDate!);
        }
      });
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final XFile? pickedFile =
        await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        imagePath = pickedFile.path;
      });
    }
  }

  void _saveChanges() {
    var box = Hive.box<Patient>('patients');
    var patient = box.getAt(widget.patientIndex);

    if (patient != null) {
      patient.ismi = fullNameController.text;
      patient.telefonRaqami = phoneNumberController.text;
      patient.shikoyat = complaintController.text;
      patient.manzil = addressController.text;
      patient.tugilganSana = birthDate ?? DateTime.now();
      patient.birinchiKelganSana = firstVisitDate ?? DateTime.now();

      if (imagePath.isNotEmpty) {
        patient.rasmManzili = imagePath;
        if (!patient.rasmlarManzillari.contains(imagePath)) {
          patient.rasmlarManzillari.add(imagePath);
        }
      }

      box.putAt(widget.patientIndex, patient);

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bemor ma\'lumotlari yangilandi')),
      );

      // Go back to previous screen
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Bemorni Tahrir qilish')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: fullNameController,
              decoration: InputDecoration(labelText: 'F.I.Sh'),
            ),
            SizedBox(height: 12),
            TextField(
              controller: phoneNumberController,
              decoration: InputDecoration(labelText: 'Telefon raqami'),
              keyboardType: TextInputType.phone,
            ),
            SizedBox(height: 12),
            TextField(
              controller: complaintController,
              decoration: InputDecoration(labelText: 'Shikoyat'),
              maxLines: 3,
            ),
            SizedBox(height: 12),
            TextField(
              controller: addressController,
              decoration: InputDecoration(labelText: 'Manzil'),
            ),
            SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: birthDateController,
                    decoration: InputDecoration(labelText: 'Tug\'ilgan sana'),
                    readOnly: true,
                    onTap: () => _selectDate(context, true),
                  ),
                ),
                IconButton(
                  onPressed: () => _selectDate(context, true),
                  icon: Icon(Icons.calendar_today),
                ),
              ],
            ),
            SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: firstVisitDateController,
                    decoration:
                        InputDecoration(labelText: 'Birinchi kelgan sana'),
                    readOnly: true,
                    onTap: () => _selectDate(context, false),
                  ),
                ),
                IconButton(
                  onPressed: () => _selectDate(context, false),
                  icon: Icon(Icons.calendar_today),
                ),
              ],
            ),
            SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(imagePath.isEmpty ? 'Rasm tanlanmagan' : 'Rasm tanlandi'),
                IconButton(
                  onPressed: _pickImage,
                  icon: Icon(Icons.photo),
                ),
              ],
            ),
            if (imagePath.isNotEmpty)
              Image.network(
                imagePath,
                height: 200,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saveChanges,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12.0),
                  child: Text('Saqlash'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
