import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';

class TaskHistoryScreen extends StatelessWidget {
  final String userId = FirebaseAuth.instance.currentUser?.uid ?? '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Riwayat Pengerjaan Tugas', style: GoogleFonts.poppins()),
        backgroundColor: Colors.green,
      ),
      body: StreamBuilder(
        stream: FirebaseFirestore.instance
            .collection('taskHistory') // Pastikan koleksi sesuai dengan Firestore
            .where('userId', isEqualTo: userId)
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Terjadi kesalahan: ${snapshot.error}',
                style: GoogleFonts.poppins(fontSize: 14, color: Colors.red),
                textAlign: TextAlign.center,
              ),
            );
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Text(
                'Belum ada tugas yang diselesaikan.',
                style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w500),
              ),
            );
          }
          var tasks = snapshot.data!.docs;
          return ListView.builder(
            itemCount: tasks.length,
            itemBuilder: (context, index) {
              var task = tasks[index];
              return Card(
                margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  title: Text(task['task'], style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                  subtitle: Text(
                    'Selesai pada: ${task['timestamp'].toDate()}',
                    style: GoogleFonts.poppins(fontSize: 14),
                  ),
                  leading: Icon(Icons.check_circle, color: Colors.green),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
