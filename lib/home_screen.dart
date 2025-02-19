import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:project_ukk/taskHistory.dart';
import 'task_list.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'main.dart';
import 'profil.dart';

class HomeScreen extends StatefulWidget {
  final String role;
  HomeScreen({required this.role});

  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  late String userId;

  @override
  void initState() {
    super.initState();
    setupFirebaseMessaging();
    getUserId();
  }

  void getUserId() {
    userId = _auth.currentUser?.uid ?? '';
  }

  void setupFirebaseMessaging() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (message.notification != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '\${message.notification!.title}: \${message.notification!.body}',
              style: GoogleFonts.poppins(),
            ),
            duration: Duration(seconds: 5),
          ),
        );
      }
    });
  }

  void refreshTaskList() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('To-Do List Bren',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        backgroundColor: Colors.green,
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            UserAccountsDrawerHeader(
              accountName: Text("Brendha",
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w500)),
              accountEmail:
                  Text("Brendha@gmail.com", style: GoogleFonts.poppins()),
              currentAccountPicture: CircleAvatar(
                backgroundImage: AssetImage('assets/images/bren.jpg'),
                backgroundColor: Colors.white,
                onBackgroundImageError: (exception, stackTrace) {
                  print("Gagal memuat gambar: \$exception");
                },
              ),
              decoration: BoxDecoration(color: Colors.green),
            ),
            ListTile(
              leading: Icon(Icons.person),
              title: Text('Profil', style: GoogleFonts.poppins()),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => ProfileScreen()),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.add_circle),
              title: Text('Tambah Tugas', style: GoogleFonts.poppins()),
              onTap: () {
                showDialog(
                  context: context,
                  builder: (context) => AddTaskDialog(),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.history),
              title: Text('Riwayat Tugas', style: GoogleFonts.poppins()),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => TaskHistory()),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.logout),
              title: Text('Logout', style: GoogleFonts.poppins()),
              onTap: () async {
                await FirebaseAuth.instance.signOut();
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => AuthScreen()),
                );
              },
            ),
          ],
        ),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            Expanded(
              child: TaskList(role: widget.role),
            ),
          ],
        ),
      ),
    );
  }
}

class AddTaskDialog extends StatefulWidget {
  @override
  _AddTaskDialogState createState() => _AddTaskDialogState();
}

class _AddTaskDialogState extends State<AddTaskDialog> {
  final TextEditingController _taskController = TextEditingController();
  String selectedCategory = "Pilih Kategori";
  List<String> categories = [
    "Penting & Mendesak",
    "Penting tapi Tidak Mendesak",
    "Tidak Penting tapi Mendesak",
    "Tidak Penting & Tidak Mendesak",
    "Pekerjaan",
    "Pendidikan",
    "Keuangan",
    "Kesehatan",
    "Rumah Tangga",
    "Sosial & Keluarga",
    "Hobi & Pengembangan Diri",
    "Harian",
    "Mingguan",
    "Bulanan",
    "Belum Dikerjakan",
    "Sedang Dikerjakan",
    "Selesai",
    "Dibatalkan/Ditunda"
  ];

  void addTask() {
    if (_taskController.text.isNotEmpty &&
        selectedCategory != "Pilih Kategori") {
      FirebaseFirestore.instance.collection('tasks').add({
        'title': _taskController.text,
        'category': selectedCategory,
        'completed': false,
        'status': 'Belum Dikerjakan',
        'timestamp': Timestamp.now(),
      });
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Tambah Tugas', style: GoogleFonts.poppins()),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _taskController,
            decoration: InputDecoration(hintText: 'Masukkan tugas'),
          ),
          SizedBox(height: 10),
          DropdownButton<String>(
            value: selectedCategory,
            isExpanded: true,
            onChanged: (String? newValue) {
              setState(() {
                selectedCategory = newValue!;
              });
            },
            items: ["Pilih Kategori", ...categories].map((String category) {
              return DropdownMenuItem<String>(
                value: category,
                child: Text(category, style: GoogleFonts.poppins()),
              );
            }).toList(),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Batal', style: GoogleFonts.poppins()),
        ),
        TextButton(
          onPressed: addTask,
          child: Text('Tambah', style: GoogleFonts.poppins()),
        ),
      ],
    );
  }
}
