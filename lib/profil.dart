import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class ProfileScreen extends StatefulWidget {
  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  File? _imageFile;
  String userName = "Brendha Asli Papua";
  String bio = "Developer nih bos haha priet";
  String profileImageUrl = "assets/images/bren.jpg";
  String lastActivity = "Belum ada aktivitas";

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    User? user = _auth.currentUser;
    if (user != null) {
      DocumentSnapshot userDoc =
          await _firestore.collection('users').doc(user.uid).get();
      if (userDoc.exists) {
        setState(() {
          userName = userDoc['name'] ?? "Pengguna";
          bio = userDoc['bio'] ?? "Belum ada bio";
          profileImageUrl = userDoc['profileImage'] ?? "";
        });
      }
      
      QuerySnapshot taskSnapshot = await _firestore
          .collection('tasks')
          .where('userId', isEqualTo: user.uid)
          .orderBy('timestamp', descending: true)
          .limit(1)
          .get();
      if (taskSnapshot.docs.isNotEmpty) {
        setState(() {
          lastActivity = taskSnapshot.docs.first['title'];
        });
      }
    }
  }

  Future<void> _pickImage() async {
    final pickedFile =
        await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Profil"),
        backgroundColor: Colors.green,
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            GestureDetector(
              onTap: _pickImage,
              child: CircleAvatar(
                radius: 50,
                backgroundImage: _imageFile != null
                    ? FileImage(_imageFile!)
                    : (profileImageUrl.isNotEmpty
                        ? NetworkImage(profileImageUrl) as ImageProvider
                        : AssetImage("assets/default_profile.png")),
              ),
            ),
            SizedBox(height: 10),
            Text(userName, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            SizedBox(height: 5),
            Text(bio, style: TextStyle(fontSize: 16, color: Colors.grey)),
            SizedBox(height: 20),
            Divider(),
            ListTile(
              leading: Icon(Icons.history, color: Colors.green),
              title: Text("Aktivitas Terakhir"),
              subtitle: Text(lastActivity),
            ),
          ],
        ),
      ),
    );
  }
}
