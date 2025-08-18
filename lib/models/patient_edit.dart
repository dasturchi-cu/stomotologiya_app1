// import 'package:flutter/material.dart';
// import 'package:hive_flutter/hive_flutter.dart';
// import 'package:image_picker/image_picker.dart';
// import 'package:intl/intl.dart'; // Sana formatlash uchun import

// import 'patient.dart'; // Modelga import

// class PatientEdit extends StatefulWidget {
//   final int patientIndex; // Tahrir qilinayotgan bemorning indeksi

//   const PatientEdit({super.key, required this.patientIndex});

//   @override
//   _PatientEditState createState() => _PatientEditState();
// }

// class _PatientEditState extends State<PatientEdit> {
//   late TextEditingController fullNameController;
//   late TextEditingController phoneNumberController;
//   late TextEditingController complaintController;
//   late TextEditingController addressController;
//   late TextEditingController birthDateController;
//   late TextEditingController firstVisitDateController;
//   late bool speaksRussian;
//   late bool speaksEnglish;
//   late DateTime? birthDate;
//   late DateTime? firstVisitDate;
//   late String imagePath = '';

//   @override
//   void initState() {
//     super.initState();

//     // Tanlangan bemorni olish
//     var box = Hive.box<Patient>('patients');
//     var patient = box.getAt(widget.patientIndex);

//     fullNameController = TextEditingController(text: patient?.fullName ?? '');
//     phoneNumberController =
//         TextEditingController(text: patient?.phoneNumber ?? '');
//     complaintController = TextEditingController(text: patient?.complaint ?? '');
//     addressController = TextEditingController(text: patient?.address ?? '');

//     // Sana formatini to'g'irlash
//     birthDate = patient?.birthDate;
//     firstVisitDate = patient?.firstVisitDate;
//     birthDateController = TextEditingController(
//         text: birthDate != null ? formatDate(birthDate!) : '');
//     firstVisitDateController = TextEditingController(
//         text: firstVisitDate != null ? formatDate(firstVisitDate!) : '');
//   }

//   // Sana formatlash
//   String formatDate(DateTime date) {
//     return DateFormat('yyyy-MM-dd').format(date);
//   }

//   // Sana tanlash
//   Future<void> _selectDate(BuildContext context, bool isBirthDate) async {
//     final DateTime? picked = await showDatePicker(
//       context: context,
//       initialDate: DateTime.now(),
//       firstDate: DateTime(1900),
//       lastDate: DateTime(2100),
//     );
//     if (picked != null) {
//       setState(() {
//         if (isBirthDate) {
//           birthDate = picked;
//           birthDateController.text = formatDate(birthDate!);
//         } else {
//           firstVisitDate = picked;
//           firstVisitDateController.text = formatDate(firstVisitDate!);
//         }
//       });
//     }
//   }

//   // Rasmni tanlash
//   Future<void> _pickImage() async {
//     final picker = ImagePicker();
//     final XFile? pickedFile =
//         await picker.pickImage(source: ImageSource.gallery);
//     if (pickedFile != null) {
//       setState(() {
//         imagePath = pickedFile.path;
//       });
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: Text('Bemorni Tahrir qilish')),
//       body: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             TextField(
//               controller: fullNameController,
//               decoration: InputDecoration(labelText: 'To\'liq ismi'),
//             ),
//             Row(
//               children: [
//                 Expanded(
//                   child: TextField(
//                     controller: birthDateController,
//                     decoration: InputDecoration(labelText: 'Tug‘ilgan sana'),
//                     readOnly: true,
//                   ),
//                 ),
//                 ElevatedButton(
//                   onPressed: () => _selectDate(context, true),
//                   child: Text('Sana tanlash'),
//                 ),
//               ],
//             ),
//             Row(
//               children: [
//                 Expanded(
//                   child: TextField(
//                     controller: firstVisitDateController,
//                     decoration:
//                         InputDecoration(labelText: 'Birinchi tashrif sanasi'),
//                     readOnly: true,
//                   ),
//                 ),
//                 ElevatedButton(
//                   onPressed: () => _selectDate(context, false),
//                   child: Text('Sana tanlash'),
//                 ),
//               ],
//             ),
//             TextField(
//               controller: phoneNumberController,
//               decoration: InputDecoration(labelText: 'Telefon raqami'),
//             ),
//             TextField(
//               controller: complaintController,
//               decoration: InputDecoration(labelText: 'Bemor shikoyati'),
//             ),
//             Row(
//               children: [
//                 Checkbox(
//                   value: speaksRussian,
//                   onChanged: (value) {
//                     setState(() {
//                       speaksRussian = value!;
//                     });
//                   },
//                 ),
//                 Text('Rus tili'),
//                 Checkbox(
//                   value: speaksEnglish,
//                   onChanged: (value) {
//                     setState(() {
//                       speaksEnglish = value!;
//                     });
//                   },
//                 ),
//                 Text('Ingliz tili'),
//               ],
//             ),
//             TextField(
//               controller: addressController,
//               decoration: InputDecoration(labelText: 'Kerak adres'),
//             ),
//             Row(
//               children: [
//                 Text(imagePath.isEmpty ? 'Rasm tanlanmagan' : 'Rasm tanlandi'),
//                 IconButton(
//                   onPressed: _pickImage,
//                   icon: Icon(Icons.photo),
//                 ),
//               ],
//             ),
//             SizedBox(height: 20),
//             ElevatedButton(
//               onPressed: () async {
//                 // Tahrirlangan bemor ma'lumotlarini olish
//                 final patient = Patient(
//                   fullName: fullNameController.text,
//                   birthDate: birthDate ?? DateTime.now(),
//                   phoneNumber: phoneNumberController.text,
//                   firstVisitDate: firstVisitDate ?? DateTime.now(),
//                   complaint: complaintController.text,

//                   address: addressController.text,
//                   imagePath: imagePath,
//                   speaksRussian: '',
//                   speaksEnglish: '',
//                   speaksUzbek: '', // Rasm pathini saqlash
//                 );

//                 // Hive box-ga ma'lumotlarni yangilash
//                 var box = await Hive.openBox<Patient>('patients');
//                 await box.putAt(
//                     widget.patientIndex, patient); // Indeks bo‘yicha yangilash
//                 //mana
//                 // Ma'lumotlar saqlandi // nima qilmayapdi dediz shunde qoldim ? rasm bemor shikoyati kelgan sana nomerlardi saxranit qmayaptida
//                 ScaffoldMessenger.of(context).showSnackBar(
//                     SnackBar(content: Text('Bemor ma\'lumotlari yangilandi!')));
//                 Navigator.pop(context); // Ortga qaytish
//               },
//               child: Text('Saqlash'),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
