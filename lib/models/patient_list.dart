import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:stomotologiya_app/models/patient.dart';
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
                  backgroundColor: const Color.fromRGBO(0, 0, 0, 0.1),
                  child: Text(
                    (patient.ismi.isNotEmpty ? patient.ismi[0] : '?')
                        .toUpperCase(),
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                title: Text(patient.ismi),
                subtitle: Text('Telefon: ${patient.telefonRaqami}'),
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
