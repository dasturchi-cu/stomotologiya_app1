import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'patient.dart'; // Yaratilgan modelga import
import '../routes.dart';

class PatientList extends StatelessWidget {
  const PatientList({super.key});

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
                leading: CircleAvatar(
                  backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.15),
                  child: Text(
                    (patient.fullName.isNotEmpty ? patient.fullName[0] : '?').toUpperCase(),
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                title: Text(patient.fullName),
                subtitle: Text('Telefon: ${patient.phoneNumber}'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.pushNamed(
                    context,
                    AppRoutes.patientDetails,
                    arguments: patient,
                  );
                },

                // Bemorni tahrir qilish sahifasiga o‘tkazish (named route)
                //   Navigator.pushNamed(
                //     context,
                //     AppRoutes.patientEdit,
                //     arguments: index,
                //   );
                // },
              );
            },
          );
        },
      ),
    );
  }
}
