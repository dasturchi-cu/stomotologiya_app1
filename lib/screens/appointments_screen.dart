import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import '../models/patient.dart';
import 'patients/patient_info.dart';

class AppointmentsScreen extends StatefulWidget {
  const AppointmentsScreen({super.key});

  @override
  State<AppointmentsScreen> createState() => _AppointmentsScreenState();
}

class _AppointmentsScreenState extends State<AppointmentsScreen> {
  final box = Hive.box<Patient>('patients');
  DateTime selectedDate = DateTime.now();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Uchrashuvlar',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.blue[800],
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: () => _selectDate(),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildDateSelector(),
          Expanded(
            child: ValueListenableBuilder(
              valueListenable: box.listenable(),
              builder: (context, box, widget) {
                final appointments = _getAppointmentsForDate(selectedDate);

                if (appointments.isEmpty) {
                  return _buildEmptyState();
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: appointments.length,
                  itemBuilder: (context, index) {
                    final appointment = appointments[index];
                    return _buildAppointmentCard(appointment);
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddAppointmentDialog(),
        backgroundColor: Colors.blue[800],
        icon: const Icon(Icons.add),
        label: const Text('Uchrashuvni rejalashtirish'),
      ),
    );
  }

  Widget _buildDateSelector() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.blue[50],
      child: Row(
        children: [
          IconButton(
            onPressed: () {
              setState(() {
                selectedDate = selectedDate.subtract(const Duration(days: 1));
              });
            },
            icon: const Icon(Icons.chevron_left),
          ),
          Expanded(
            child: Center(
              child: GestureDetector(
                onTap: () => _selectDate(),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue[200]!),
                  ),
                  child: Text(
                    DateFormat('dd MMMM yyyy, EEEE', 'uz').format(selectedDate),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.blue[800],
                    ),
                  ),
                ),
              ),
            ),
          ),
          IconButton(
            onPressed: () {
              setState(() {
                selectedDate = selectedDate.add(const Duration(days: 1));
              });
            },
            icon: const Icon(Icons.chevron_right),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.event_available,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Bu kun uchun uchrashuvlar yo\'q',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Yangi uchrashuvni rejalashtirish uchun pastdagi tugmani bosing',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppointmentCard(AppointmentInfo appointment) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  PatientDetailsScreen(patient: appointment.patient),
            ),
          );
        },
        leading: CircleAvatar(
          backgroundColor: Colors.blue[100],
          child: Text(
            appointment.patient.fullName.isNotEmpty
                ? appointment.patient.fullName[0].toUpperCase()
                : '?',
            style: TextStyle(
              color: Colors.blue[800],
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          appointment.patient.fullName,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  DateFormat('HH:mm').format(appointment.dateTime),
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.phone, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  appointment.patient.phoneNumber,
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
          ],
        ),
        trailing: PopupMenuButton(
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'complete',
              child: Row(
                children: [
                  Icon(Icons.check, color: Colors.green),
                  SizedBox(width: 8),
                  Text('Bajarildi'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'reschedule',
              child: Row(
                children: [
                  Icon(Icons.schedule, color: Colors.orange),
                  SizedBox(width: 8),
                  Text('Vaqtini o\'zgartirish'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'cancel',
              child: Row(
                children: [
                  Icon(Icons.cancel, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Bekor qilish'),
                ],
              ),
            ),
          ],
          onSelected: (value) => _handleAppointmentAction(appointment, value),
        ),
      ),
    );
  }

  List<AppointmentInfo> _getAppointmentsForDate(DateTime date) {
    // For now, we'll simulate appointments based on patient visit dates
    // In a real app, you'd have a separate appointments storage
    final patients = box.values.toList();
    final appointments = <AppointmentInfo>[];

    for (final patient in patients) {
      // Check if patient has visits on this date
      for (final visitDate in patient.visitDates) {
        if (visitDate.year == date.year &&
            visitDate.month == date.month &&
            visitDate.day == date.day) {
          appointments.add(AppointmentInfo(
            patient: patient,
            dateTime: visitDate,
          ));
        }
      }
    }

    // Sort by time
    appointments.sort((a, b) => a.dateTime.compareTo(b.dateTime));
    return appointments;
  }

  Future<void> _selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (date != null) {
      setState(() {
        selectedDate = date;
      });
    }
  }

  void _showAddAppointmentDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Uchrashuvni rejalashtirish'),
        content: const Text(
          'Hozircha bu funksiya ishlab chiqilmoqda. '
          'Bemorlar ma\'lumotlariga tashrif sanasini qo\'shish orqali '
          'uchrashuvlarni kuzatishingiz mumkin.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _handleAppointmentAction(AppointmentInfo appointment, String action) {
    switch (action) {
      case 'complete':
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                '${appointment.patient.fullName} uchun uchrashuvni bajarildi deb belgilandi'),
            backgroundColor: Colors.green,
          ),
        );
        break;
      case 'reschedule':
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content:
                Text('Vaqtni o\'zgartirish funksiyasi tez orada qo\'shiladi'),
          ),
        );
        break;
      case 'cancel':
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                '${appointment.patient.fullName} uchun uchrashuvni bekor qilindi'),
            backgroundColor: Colors.red,
          ),
        );
        break;
    }
  }
}

class AppointmentInfo {
  final Patient patient;
  final DateTime dateTime;

  AppointmentInfo({
    required this.patient,
    required this.dateTime,
  });
}
