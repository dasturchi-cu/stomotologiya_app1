import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Tarjima qilish uchun


class PatientEdit extends StatefulWidget {
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
  late String currentLanguage = 'uz'; // Boshlang'ich til: O'zbek
  String imagePath = ''; // Rasm uchun o'zgaruvchi

  @override
  void initState() {
    super.initState();
    fullNameController = TextEditingController();
    phoneNumberController = TextEditingController();
    complaintController = TextEditingController();
    addressController = TextEditingController();
    birthDateController = TextEditingController();
    firstVisitDateController = TextEditingController();
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
          birthDateController.text = formatDate(picked);
        } else {
          firstVisitDateController.text = formatDate(picked);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Bemorni Tahrir qilish')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Tilni tanlash dropdowni
            DropdownButton<String>(
              value: currentLanguage,
              items: [
                DropdownMenuItem(value: 'uz', child: Text('O\'zbek tili')),
                DropdownMenuItem(value: 'ru', child: Text('Русский')),
                DropdownMenuItem(value: 'en', child: Text('English')),
              ],
              onChanged: (value) {
                setState(() {
                  currentLanguage = value!;
                  // Tanlangan tilni saqlash va UI-ni yangilash
                });
              },
            ),
            // Bemorga ism kiritish
            TextField(
              controller: fullNameController,
              decoration: InputDecoration(labelText: _getLabelText('fullName')),
            ),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: birthDateController,
                    decoration:
                        InputDecoration(labelText: _getLabelText('birthDate')),
                    readOnly: true,
                  ),
                ),
                ElevatedButton(
                  onPressed: () => _selectDate(context, true),
                  child: Text(_getLabelText('chooseDate')),
                ),
              ],
            ),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: firstVisitDateController,
                    decoration: InputDecoration(
                        labelText: _getLabelText('firstVisitDate')),
                    readOnly: true,
                  ),
                ),
                ElevatedButton(
                  onPressed: () => _selectDate(context, false),
                  child: Text(_getLabelText('chooseDate')),
                ),
              ],
            ),
            TextField(
              controller: phoneNumberController,
              decoration:
                  InputDecoration(labelText: _getLabelText('phoneNumber')),
            ),
            TextField(
              controller: complaintController,
              decoration:
                  InputDecoration(labelText: _getLabelText('complaint')),
            ),
            TextField(
              controller: addressController,
              decoration: InputDecoration(labelText: _getLabelText('address')),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // Bemorni saqlash
                ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(_getLabelText('save'))));
              },
              child: Text(_getLabelText('save')),
            ),
          ],
        ),
      ),
    );
  }

  // Har bir til uchun tarjimani olish
  String _getLabelText(String key) {
    switch (currentLanguage) {
      case 'ru':
        return _getRusText(key);
      case 'en':
        return _getEngText(key);
      default:
        return _getUzText(key);
    }
  }

  // O'zbekcha tarjimalar
  String _getUzText(String key) {
    switch (key) {
      case 'fullName':
        return 'To\'liq ismi';
      case 'birthDate':
        return 'Tug‘ilgan sana';
      case 'firstVisitDate':
        return 'Birinchi tashrif sanasi';
      case 'phoneNumber':
        return 'Telefon raqami';
      case 'complaint':
        return 'Bemor shikoyati';
      case 'address':
        return 'Kerak adres';
      case 'chooseDate':
        return 'Sana tanlash';
      case 'save':
        return 'Saqlash';
      default:
        return '';
    }
  }

  // Ruscha tarjimalar
  String _getRusText(String key) {
    switch (key) {
      case 'fullName':
        return 'Полное имя';
      case 'birthDate':
        return 'Дата рождения';
      case 'firstVisitDate':
        return 'Дата первого визита';
      case 'phoneNumber':
        return 'Номер телефона';
      case 'complaint':
        return 'Жалоба';
      case 'address':
        return 'Адрес';
      case 'chooseDate':
        return 'Выбрать дату';
      case 'save':
        return 'Сохранить';
      default:
        return '';
    }
  }

  // Inglizcha tarjimalar
  String _getEngText(String key) {
    switch (key) {
      case 'fullName':
        return 'Full Name';
      case 'birthDate':
        return 'Date of Birth';
      case 'firstVisitDate':
        return 'First Visit Date';
      case 'phoneNumber':
        return 'Phone Number';
      case 'complaint':
        return 'Complaint';
      case 'address':
        return 'Address';
      case 'chooseDate':
        return 'Choose Date';
      case 'save':
        return 'Save';
      default:
        return '';
    }
  }
}
