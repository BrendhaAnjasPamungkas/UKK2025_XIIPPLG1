import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'task_list.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'main.dart';

class HomeScreen extends StatefulWidget {
  final String role; // Tambahkan variabel role

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
        title: Text('To-Do List Bren', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        backgroundColor: Colors.green,
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            UserAccountsDrawerHeader(
              accountName: Text("Pengguna", style: GoogleFonts.poppins(fontWeight: FontWeight.w500)),
              accountEmail: Text("pengguna@gmail.com", style: GoogleFonts.poppins()),
              currentAccountPicture: CircleAvatar(
                backgroundColor: Colors.white,
                child: Icon(Icons.person, size: 40.0, color: Colors.green),
              ),
              decoration: BoxDecoration(color: Colors.green),
            ),
            ListTile(
              leading: Icon(Icons.dashboard),
              title: Text('Dashboard', style: GoogleFonts.poppins()),
              onTap: () => Navigator.pop(context),
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
                  MaterialPageRoute(builder: (context) => TaskHistoryScreen()),
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
              child: TaskList(role: widget.role), // Kirim dari HomeScreen ke TaskList
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

  void addTask() {
    if (_taskController.text.isNotEmpty) {
      FirebaseFirestore.instance.collection('tasks').add({
        'title': _taskController.text,
        'task': _taskController.text,
        'completed': false,
        'status': 'Belum Selesai',
        'timestamp': Timestamp.now(),
      });
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Tambah Tugas', style: GoogleFonts.poppins()),
      content: TextField(
        controller: _taskController,
        decoration: InputDecoration(hintText: 'Masukkan tugas'),
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

class TaskHistoryScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Riwayat Tugas', style: GoogleFonts.poppins()),
        backgroundColor: Colors.green,
      ),
      body: StreamBuilder(
        stream: FirebaseFirestore.instance
            .collection('tasks')
            .where('completed', isEqualTo: true)
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }
          var tasks = snapshot.data!.docs;
          return ListView.builder(
            itemCount: tasks.length,
            itemBuilder: (context, index) {
              var task = tasks[index];
              return ListTile(
                title: Text(task['task'], style: GoogleFonts.poppins()),
                subtitle: Text('Selesai pada: ${task['timestamp'].toDate()}'),
              );
            },
          );
        },
      ),
    );
  }
}
