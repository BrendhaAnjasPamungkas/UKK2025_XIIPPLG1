import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'ulasan_buku.dart';
import 'admin_pengembalian.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'firebase_options.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'pengembalian.dart';
import 'tambah_edit_buku.dart';
import 'task_list.dart';
import 'notifikasi.dart';
import 'home_screen.dart';

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print("Pesan diterima di background: ${message.messageId}");
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Dashboard TDL BREN',
      theme: ThemeData(
        primarySwatch: Colors.green,
      ),
      home: AuthScreen(),
    );
  }
}

// ===================== AUTH SCREEN =====================
class AuthScreen extends StatefulWidget {
  @override
  _AuthScreenState createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController alamatController = TextEditingController();
  final TextEditingController noTelpController = TextEditingController();
  String role = 'peminjam';
  bool isLogin = true;

  Future<void> authenticate() async {
    try {
      if (isLogin) {
        UserCredential userCredential = await _auth.signInWithEmailAndPassword(
          email: emailController.text,
          password: passwordController.text,
        );

        String uid = userCredential.user!.uid;
        DocumentSnapshot userDoc =
            await FirebaseFirestore.instance.collection('users').doc(uid).get();

        if (userDoc.exists) {
          String role = userDoc['role'];
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => HomeScreen(role: role)),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Data pengguna tidak ditemukan di Firestore')),
          );
        }
      } else {
        UserCredential userCredential =
            await _auth.createUserWithEmailAndPassword(
          email: emailController.text,
          password: passwordController.text,
        );

        await FirebaseFirestore.instance
            .collection('users')
            .doc(userCredential.user!.uid)
            .set({
          'username': usernameController.text,
          'email': emailController.text,
          'alamat': alamatController.text,
          'noTelp': noTelpController.text,
          'role': role,
        });

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => HomeScreen(role: role)),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> resetPassword() async {
    if (emailController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Masukkan email untuk mereset password.')),
      );
      return;
    }
    try {
      await _auth.sendPasswordResetEmail(email: emailController.text);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Email reset password telah dikirim.')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.green[50],
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.library_books, size: 100, color: Colors.green),
                SizedBox(height: 20),
                Text(
                  isLogin ? 'TDL BREN' : 'Daftar Akun',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.green[800]),
                ),
                SizedBox(height: 20),
                if (!isLogin)
                  TextField(
                    controller: usernameController,
                    decoration: InputDecoration(labelText: 'Username', border: OutlineInputBorder()),
                  ),
                SizedBox(height: 10),
                TextField(
                  controller: emailController,
                  decoration: InputDecoration(labelText: 'Email', border: OutlineInputBorder()),
                ),
                SizedBox(height: 10),
                TextField(
                  controller: passwordController,
                  decoration: InputDecoration(labelText: 'Password', border: OutlineInputBorder()),
                  obscureText: true,
                ),
                SizedBox(height: 10),
                if (!isLogin)
                  TextField(
                    controller: alamatController,
                    decoration: InputDecoration(labelText: 'Alamat', border: OutlineInputBorder()),
                  ),
                SizedBox(height: 10),
                if (!isLogin)
                  TextField(
                    controller: noTelpController,
                    decoration: InputDecoration(labelText: 'No. Telepon', border: OutlineInputBorder()),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  ),
                SizedBox(height: 10),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                  ),
                  onPressed: authenticate,
                  child: Text(isLogin ? 'Login' : 'Register'),
                ),
                if (isLogin)
                  TextButton(
                    onPressed: resetPassword,
                    child: Text('Lupa Password?'),
                  ),
                TextButton(
                  onPressed: () => setState(() => isLogin = !isLogin),
                  child: Text(isLogin ? 'Daftar' : 'Login'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}