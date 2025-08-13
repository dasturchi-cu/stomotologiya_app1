// import 'package:flutter/material.dart';
// import 'package:hive_flutter/hive_flutter.dart';
// import '../models/patient.dart';
// import '../service/auth_service.dart';

// class SettingsScreen extends StatefulWidget {
//   const SettingsScreen({super.key});

//   @override
//   State<SettingsScreen> createState() => _SettingsScreenState();
// }

// class _SettingsScreenState extends State<SettingsScreen> {
//   final _authService = AuthService();
//   final box = Hive.box<Patient>('patients');

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text(
//           'Sozlamalar',
//           style: TextStyle(fontWeight: FontWeight.bold),
//         ),
//         backgroundColor: Colors.blue[800],
//         foregroundColor: Colors.white,
//         elevation: 0,
//       ),
//       body: ListView(
//         padding: const EdgeInsets.all(16),
//         children: [
//           _buildSection(
//             'Ma\'lumotlar',
//             [
//               _buildSettingsTile(
//                 icon: Icons.backup,
//                 title: 'Ma\'lumotlarni zaxiralash',
//                 subtitle: 'Bemorlar ma\'lumotlarini zaxiralash',
//                 onTap: () => _showBackupDialog(),
//               ),
//               _buildSettingsTile(
//                 icon: Icons.restore,
//                 title: 'Ma\'lumotlarni tiklash',
//                 subtitle: 'Zaxira nusxasidan tiklash',
//                 onTap: () => _showRestoreDialog(),
//               ),
//               _buildSettingsTile(
//                 icon: Icons.delete_forever,
//                 title: 'Barcha ma\'lumotlarni o\'chirish',
//                 subtitle: 'Ehtiyot bo\'ling! Bu amalni bekor qilib bo\'lmaydi',
//                 onTap: () => _showDeleteAllDialog(),
//                 isDestructive: true,
//               ),
//             ],
//           ),
//           const SizedBox(height: 24),
//           _buildSection(
//             'Ilova',
//             [
//               _buildSettingsTile(
//                 icon: Icons.info_outline,
//                 title: 'Ilova haqida',
//                 subtitle: 'Versiya va ma\'lumotlar',
//                 onTap: () => _showAboutDialog(),
//               ),
//               _buildSettingsTile(
//                 icon: Icons.help_outline,
//                 title: 'Yordam',
//                 subtitle: 'Foydalanish bo\'yicha ko\'rsatmalar',
//                 onTap: () => _showHelpDialog(),
//               ),
//             ],
//           ),
//           const SizedBox(height: 24),
//           _buildSection(
//             'Hisob',
//             [
//               _buildSettingsTile(
//                 icon: Icons.logout,
//                 title: 'Tizimdan chiqish',
//                 subtitle: 'Hisobingizdan chiqish',
//                 onTap: () => _showLogoutDialog(),
//                 isDestructive: true,
//               ),
//             ],
//           ),
//           const SizedBox(height: 32),
//           _buildAppInfo(),
//         ],
//       ),
//     );
//   }

//   Widget _buildSection(String title, List<Widget> children) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Text(
//           title,
//           style: TextStyle(
//             fontSize: 18,
//             fontWeight: FontWeight.bold,
//             color: Colors.blue[800],
//           ),
//         ),
//         const SizedBox(height: 12),
//         Card(
//           elevation: 2,
//           shape: RoundedRectangleBorder(
//             borderRadius: BorderRadius.circular(12),
//           ),
//           child: Column(children: children),
//         ),
//       ],
//     );
//   }

//   Widget _buildSettingsTile({
//     required IconData icon,
//     required String title,
//     required String subtitle,
//     required VoidCallback onTap,
//     bool isDestructive = false,
//   }) {
//     return ListTile(
//       leading: Icon(
//         icon,
//         color: isDestructive ? Colors.red[600] : Colors.blue[600],
//       ),
//       title: Text(
//         title,
//         style: TextStyle(
//           color: isDestructive ? Colors.red[600] : null,
//           fontWeight: FontWeight.w500,
//         ),
//       ),
//       subtitle: Text(subtitle),
//       trailing: Icon(
//         Icons.chevron_right,
//         color: Colors.grey[400],
//       ),
//       onTap: onTap,
//     );
//   }

//   Widget _buildAppInfo() {
//     return Card(
//       elevation: 2,
//       shape: RoundedRectangleBorder(
//         borderRadius: BorderRadius.circular(12),
//       ),
//       child: Padding(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           children: [
//             Icon(
//               Icons.medical_services,
//               size: 48,
//               color: Colors.blue[800],
//             ),
//             const SizedBox(height: 12),
//             Text(
//               'StomoTrack',
//               style: TextStyle(
//                 fontSize: 20,
//                 fontWeight: FontWeight.bold,
//                 color: Colors.blue[800],
//               ),
//             ),
//             const SizedBox(height: 4),
//             const Text(
//               'Versiya 1.0.0',
//               style: TextStyle(
//                 color: Colors.grey,
//               ),
//             ),
//             const SizedBox(height: 8),
//             const Text(
//               'Stomatologiya bemorlarini boshqarish tizimi',
//               textAlign: TextAlign.center,
//               style: TextStyle(
//                 color: Colors.grey,
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   void _showBackupDialog() {
//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: const Text('Ma\'lumotlarni zaxiralash'),
//         content: const Text(
//           'Hozircha bu funksiya ishlab chiqilmoqda. Tez orada qo\'shiladi.',
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context),
//             child: const Text('OK'),
//           ),
//         ],
//       ),
//     );
//   }

//   void _showRestoreDialog() {
//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: const Text('Ma\'lumotlarni tiklash'),
//         content: const Text(
//           'Hozircha bu funksiya ishlab chiqilmoqda. Tez orada qo\'shiladi.',
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context),
//             child: const Text('OK'),
//           ),
//         ],
//       ),
//     );
//   }

//   void _showDeleteAllDialog() {
//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: const Text('Barcha ma\'lumotlarni o\'chirish'),
//         content: const Text(
//           'Haqiqatan ham barcha bemorlar ma\'lumotlarini o\'chirishni xohlaysizmi? Bu amalni bekor qilib bo\'lmaydi!',
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context),
//             child: const Text('Bekor qilish'),
//           ),
//           TextButton(
//             onPressed: () async {
//               await box.clear();
//               if (mounted) {
//                 Navigator.pop(context);
//                 ScaffoldMessenger.of(context).showSnackBar(
//                   const SnackBar(
//                     content: Text('Barcha ma\'lumotlar o\'chirildi'),
//                     backgroundColor: Colors.red,
//                   ),
//                 );
//               }
//             },
//             child: const Text(
//               'O\'chirish',
//               style: TextStyle(color: Colors.red),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   void _showAboutDialog() {
//     showAboutDialog(
//       context: context,
//       applicationName: 'StomoTrack',
//       applicationVersion: '1.0.0',
//       applicationIcon: Icon(
//         Icons.medical_services,
//         size: 48,
//         color: Colors.blue[800],
//       ),
//       children: [
//         const Text(
//           'Stomatologiya bemorlarini boshqarish uchun mo\'ljallangan ilova. '
//           'Bemorlar ma\'lumotlarini saqlash, tashrif sanalarini kuzatish va '
//           'hisobotlar yaratish imkonini beradi.',
//         ),
//       ],
//     );
//   }

//   void _showHelpDialog() {
//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: const Text('Yordam'),
//         content: const SingleChildScrollView(
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               Text(
//                 'Asosiy funksiyalar:',
//                 style: TextStyle(fontWeight: FontWeight.bold),
//               ),
//               SizedBox(height: 8),
//               Text('• Yangi bemor qo\'shish'),
//               Text('• Bemorlar ro\'yxatini ko\'rish'),
//               Text('• Bemor ma\'lumotlarini tahrirlash'),
//               Text('• Tashrif sanalarini qo\'shish'),
//               Text('• Rasmlar yuklash'),
//               Text('• Excel formatiga eksport qilish'),
//               Text('• Statistika ko\'rish'),
//               SizedBox(height: 16),
//               Text(
//                 'Qo\'shimcha yordam uchun dasturchi bilan bog\'laning.',
//               ),
//             ],
//           ),
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context),
//             child: const Text('OK'),
//           ),
//         ],
//       ),
//     );
//   }

//   void _showLogoutDialog() {
//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: const Text('Tizimdan chiqish'),
//         content: const Text('Haqiqatan ham tizimdan chiqishni xohlaysizmi?'),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context),
//             child: const Text('Bekor qilish'),
//           ),
//           TextButton(
//             onPressed: () async {
//               await _authService.signOut();
//               if (mounted) {
//                 Navigator.pop(context);
//               }
//             },
//             child: const Text(
//               'Chiqish',
//               style: TextStyle(color: Colors.red),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
