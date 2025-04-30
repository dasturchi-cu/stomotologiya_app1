import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'patient.dart'; // Yaratilgan modelga import
import 'patient_edit.dart'; // Tahrirlash sahifasiga import

class PatientList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Bemorlar Ro‘yxati')),
      body: ValueListenableBuilder(
        valueListenable: Hive.box<Patient>('patients').listenable(),
        builder: (context, Box<Patient> box, _) {
          if (box.isEmpty) {
            return Center(child: Text('Hali bemorlar ro‘yxatga olinmagan.'));
          }

          return ListView.builder(
            itemCount: box.length,
            itemBuilder: (context, index) {
              Patient patient = box.getAt(index)!;
              return ListTile(
                title: Text(patient.fullName),
                subtitle: Text('Telefon: ${patient.phoneNumber}'),
                onTap: () {
                  // Bemorni tahrir qilish sahifasiga o‘tkazish
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PatientEdit(patientIndex: index),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
