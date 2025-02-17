import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class TaskList extends StatefulWidget {
  final String role; // Menentukan peran pengguna (admin atau user)

  const TaskList({Key? key, required this.role}) : super(key: key);

  @override
  _TaskListState createState() => _TaskListState();
}

class _TaskListState extends State<TaskList> {
  String searchQuery = ""; // Menyimpan teks pencarian
  TextEditingController searchController = TextEditingController();
  TextEditingController taskController = TextEditingController(); // Untuk input tugas baru

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.all(8.0),
          child: TextField(
            controller: searchController,
            onChanged: (value) {
              setState(() {
                searchQuery = value.toLowerCase();
              });
            },
            decoration: InputDecoration(
              labelText: "Cari tugas...",
              hintText: "Masukkan judul tugas",
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ),
        if (widget.role == 'admin') _buildAddTaskButton(),
        Expanded(
          child: StreamBuilder(
            stream: FirebaseFirestore.instance.collection('tasks').snapshots(),
            builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
              if (!snapshot.hasData) {
                return Center(child: CircularProgressIndicator());
              }

              // Filter tugas berdasarkan pencarian
              var filteredTasks = snapshot.data!.docs.where((doc) {
                String title = doc['title'].toString().toLowerCase();
                return title.contains(searchQuery);
              }).toList();

              return ListView(
                children: filteredTasks.map((doc) {
                  String taskId = doc.id;
                  bool isCompleted = doc['status'] == 'completed';

                  return Card(
                    child: ListTile(
                      title: Text(
                        doc['title'],
                        style: TextStyle(
                          decoration: isCompleted ? TextDecoration.lineThrough : null,
                        ),
                      ),
                      trailing: widget.role == 'admin'
                          ? Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: Icon(Icons.delete, color: Colors.red),
                                  onPressed: () => _deleteTask(taskId),
                                ),
                              ],
                            )
                          : ElevatedButton(
                              onPressed: isCompleted ? null : () => _markTaskCompleted(taskId),
                              child: Text(isCompleted ? 'Selesai' : 'Tandai Selesai'),
                            ),
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ),
      ],
    );
  }

  // Tombol tambah tugas untuk admin
  Widget _buildAddTaskButton() {
    return Padding(
      padding: EdgeInsets.all(8.0),
      child: ElevatedButton.icon(
        onPressed: () => _showAddTaskDialog(),
        icon: Icon(Icons.add),
        label: Text("Tambah Tugas"),
      ),
    );
  }

  // Dialog untuk menambahkan tugas baru
  void _showAddTaskDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Tambah Tugas Baru"),
          content: TextField(
            controller: taskController,
            decoration: InputDecoration(hintText: "Masukkan judul tugas"),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("Batal"),
            ),
            ElevatedButton(
              onPressed: () {
                _addTask(taskController.text);
                Navigator.pop(context);
              },
              child: Text("Tambah"),
            ),
          ],
        );
      },
    );
  }

  // Fungsi untuk menambahkan tugas baru ke Firestore
  void _addTask(String title) async {
    if (title.isNotEmpty) {
      await FirebaseFirestore.instance.collection('tasks').add({
        'title': title,
        'status': 'pending',
        'userId': FirebaseAuth.instance.currentUser!.uid,
        'timestamp': Timestamp.now(),
      });
      taskController.clear();
    }
  }

  // Fungsi untuk menandai tugas sebagai selesai
  void _markTaskCompleted(String taskId) async {
    await FirebaseFirestore.instance.collection('tasks').doc(taskId).update({
      'status': 'completed',
    });
  }

  // Fungsi untuk menghapus tugas
  void _deleteTask(String taskId) async {
    await FirebaseFirestore.instance.collection('tasks').doc(taskId).delete();
  }
}
