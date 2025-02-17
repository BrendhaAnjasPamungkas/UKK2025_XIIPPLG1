
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'task_list.dart';
import 'admin_pengembalian.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart';
import 'tambah_edit_buku.dart';
import 'deskripsi_buku.dart';
import 'main.dart';

// Widget utama untuk menampilkan layar utama aplikasi
class HomeScreen extends StatefulWidget {
  final String role; // Menyimpan peran pengguna (admin atau peminjam)
  HomeScreen({required this.role});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance; // Instance Firebase Authentication
  late String userId; // Menyimpan user ID pengguna

  @override
  void initState() {
    super.initState();
    setupFirebaseMessaging(); // Konfigurasi Firebase Messaging untuk notifikasi
    getFCMToken(); // Mengambil token FCM untuk notifikasi push
    getUserId(); // Mendapatkan user ID dari pengguna yang sedang login
  }

  // Mengambil user ID pengguna yang sedang login
  void getUserId() {
    userId = _auth.currentUser?.uid ?? ''; // Jika pengguna tidak ditemukan, gunakan string kosong
  }

  // Mengatur Firebase Cloud Messaging untuk menangani notifikasi yang diterima saat aplikasi aktif
  void setupFirebaseMessaging() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (message.notification != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${message.notification!.title}: ${message.notification!.body}',
              style: GoogleFonts.poppins(),
            ),
            duration: Duration(seconds: 5),
          ),
        );
      }
    });
  }

  // Mengambil token Firebase Cloud Messaging (FCM) untuk keperluan notifikasi push
  void getFCMToken() async {
    String? token = await FirebaseMessaging.instance.getToken();
    print("🔥 FCM Token: $token"); // Mencetak token ke konsol untuk debugging
  }

  // Fungsi untuk memperbarui tampilan daftar buku setelah buku dikembalikan
  void refreshBookList() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Dashboard Perpustakaan', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        backgroundColor: Colors.green,
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            // Header drawer yang menampilkan informasi pengguna
            UserAccountsDrawerHeader(
              accountName: Text("Pengguna", style: GoogleFonts.poppins(fontWeight: FontWeight.w500)),
              accountEmail: Text(widget.role, style: GoogleFonts.poppins()),
              currentAccountPicture: CircleAvatar(
                backgroundColor: Colors.white,
                child: Icon(Icons.person, size: 40.0, color: Colors.green),
              ),
              decoration: BoxDecoration(color: Colors.green),
            ),
            // Menu Dashboard
            ListTile(
              leading: Icon(Icons.dashboard),
              title: Text('Dashboard', style: GoogleFonts.poppins()),
              onTap: () => Navigator.pop(context),
            ),
            // Menu Tambah Buku (Hanya ditampilkan untuk admin)
            if (widget.role == 'admin')
              ListTile(
                leading: Icon(Icons.add_circle),
                title: Text('Tambah Buku', style: GoogleFonts.poppins()),
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (context) => AddBookDialog(),
                  );
                },
              ),
            // Menu Lihat Pengembalian
            ListTile(
              leading: Icon(Icons.history),
              title: Text('Lihat Pengembalian', style: GoogleFonts.poppins()),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AdminPengembalianPage(
                      role: widget.role,
                      userId: userId,
                    ),
                  ),
                );
              },
            ),
            // Menu Logout
            ListTile(
              leading: Icon(Icons.logout),
              title: Text('Logout', style: GoogleFonts.poppins()),
              onTap: () async {
                await FirebaseAuth.instance.signOut(); // Logout pengguna
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