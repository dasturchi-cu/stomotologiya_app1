import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/adapters.dart';
import 'add_patient_screen.dart';
import 'models/patient.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();

  // PatientAdapter ni ro'yxatdan o'tkazish
  Hive.registerAdapter(PatientAdapter());
  await Hive.openBox<Patient>('patients');

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: HomeScreen(),
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorSchemeSeed: Colors.blue),
    );
  }
}

// HomeScreen to'liq shaklda
class HomeScreen extends StatefulWidget {
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Bemorlar Ro‘yxati'),
      ),
      body: FutureBuilder(
        future: Hive.openBox('patients'),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            print(snapshot.error);
            return Center(child: Text('Xatolik yuz berdi'));
          } else {
            var box = Hive.box('patients');
            return ValueListenableBuilder(
              valueListenable: box.listenable(),
              builder: (context, box, widget) {
                return ListView.builder(
                  itemCount: box.length,
                  itemBuilder: (context, index) {
                    final patient = box.getAt(index); // getAt() afzalroq
                    return ListTile(
                      title: Text(patient.fullName),
                      subtitle: Text(patient.phoneNumber),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                PatientDetailsScreen(patient: patient),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            );
          }
        },
      ),

      // FutureBuilder(
      //   future: Hive.openBox<Patient>('patients'),
      //   builder: (context, snapshot) {
      //     if (snapshot.connectionState == ConnectionState.waiting) {
      //       return Center(child: CircularProgressIndicator());
      //     } else if (snapshot.hasError) {
      //       return Center(child: Text('Xatolik yuz berdi!'));
      //     } else {
      //       var box = Hive.box<Patient>('patients');
      //       var patients = box.values.toList();
      //
      //       if (patients.isEmpty) {
      //         return Center(
      //           child: Text("Sizda xali bemorlar mavjud emas"),
      //         );
      //       } else {
      //         return ListView.builder(
      //           itemCount: patients.length,
      //           itemBuilder: (context, index) {
      //             final patient = patients[index];
      //             return ListTile(
      //               title: Text(patient.fullName),
      //               subtitle: Text(patient.phoneNumber),
      //               onTap: () {
      //                 // Bemorning detallarini ko'rsatish
      //                 Navigator.push(
      //                   context,
      //                   MaterialPageRoute(
      //                     builder: (context) =>
      //                         PatientDetailsScreen(patient: patient),
      //                   ),
      //                 );
      //               },
      //             );
      //           },
      //         );
      //       }
      //     }
      //   },
      // ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
              context, MaterialPageRoute(builder: (_) => AddPatientScreen()));
        },
        child: Icon(Icons.person_add_alt_1_rounded),
      ),
    );
  }
}

// Bemor ma'lumotlarini ko'rsatish ekrani
class PatientDetailsScreen extends StatelessWidget {
  final Patient patient;

  const PatientDetailsScreen({super.key, required this.patient});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(patient.fullName),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Telefon: ${patient.phoneNumber}'),
            Text('Tug‘ilgan sana: ${patient.birthDate}'),
            Text('Birinchi tashrif sanasi: ${patient.firstVisitDate}'),
            Text('Shikoyat: ${patient.complaint}'),
            Text('Address: ${patient.address}'),
          ],
        ),
      ),
    );
  }
}
