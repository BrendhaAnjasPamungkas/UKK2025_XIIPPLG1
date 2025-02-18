import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class TaskList extends StatefulWidget {
  final String role;
  const TaskList({Key? key, required this.role}) : super(key: key);

  @override
  _TaskListState createState() => _TaskListState();
}

class _TaskListState extends State<TaskList> {
  String searchQuery = "";
  TextEditingController searchController = TextEditingController();

  Stream<QuerySnapshot> getTaskStream() {
    if (widget.role == 'admin') {
      return FirebaseFirestore.instance
          .collection('tasks')
          .orderBy('timestamp', descending: true)
          .snapshots();
    } else {
      return FirebaseFirestore.instance
          .collection('tasks')
          .where('userId', isEqualTo: FirebaseAuth.instance.currentUser?.uid)
          .orderBy('timestamp', descending: true)
          .snapshots();
    }
  }

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
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: getTaskStream(),
            builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
              if (!snapshot.hasData) {
                return Center(child: CircularProgressIndicator());
              }

              var filteredTasks = snapshot.data!.docs.where((doc) {
                String title = doc['title'].toString().toLowerCase();
                return title.contains(searchQuery);
              }).toList();

              if (filteredTasks.isEmpty) {
                return Center(
                  child: Text(
                    'Tidak ada tugas yang tersedia',
                    style: TextStyle(fontSize: 16),
                  ),
                );
              }

              return ListView(
                children: filteredTasks.map((doc) {
                  String taskId = doc.id;
                  bool isCompleted = doc['completed'] ?? false;
                  String completedTime =
                      doc.data().toString().contains('completedAt') &&
                              doc['completedAt'] != null
                          ? "Selesai pada: ${doc['completedAt'].toDate()}"
                          : "";

                  return Card(
                    child: ListTile(
                      title: Text(
                        doc['title'],
                        style: TextStyle(
                          decoration:
                              isCompleted ? TextDecoration.lineThrough : null,
                        ),
                      ),
                      subtitle: Text(
                        'Dibuat pada: ${(doc['timestamp'] as Timestamp).toDate()}'
                        '${completedTime.isNotEmpty ? '\n$completedTime' : ''}',
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (!isCompleted)
                            IconButton(
                              icon: Icon(Icons.edit, color: Colors.blue),
                              onPressed: () => _editTask(taskId, doc['title']),
                            ),
                          if (!isCompleted)
                            ElevatedButton(
                              onPressed: () => _markTaskCompleted(taskId),
                              child: Text('Tandai Selesai'),
                            ),
                          IconButton(
                            icon: Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _deleteTask(taskId),
                          ),
                        ],
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

  void _editTask(String taskId, String currentTitle) {
    TextEditingController editController =
        TextEditingController(text: currentTitle);
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Edit Tugas"),
          content: TextField(
            controller: editController,
            decoration: InputDecoration(hintText: "Masukkan judul tugas baru"),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("Batal"),
            ),
            ElevatedButton(
              onPressed: () {
                _updateTask(taskId, editController.text);
                Navigator.pop(context);
              },
              child: Text("Simpan"),
            ),
          ],
        );
      },
    );
  }

  void _updateTask(String taskId, String newTitle) async {
    if (newTitle.isNotEmpty) {
      await FirebaseFirestore.instance
          .collection('tasks')
          .doc(taskId)
          .update({'title': newTitle});
    }
  }

  void _markTaskCompleted(String taskId) async {
    try {
      await FirebaseFirestore.instance.collection('tasks').doc(taskId).update({
        'completed': true,
        'completedAt': FieldValue.serverTimestamp(),
      });
      setState(() {}); // Update UI setelah perubahan
    } catch (e) {
      print("Error menandai tugas selesai: \$e");
    }
  }

  void _deleteTask(String taskId) async {
    await FirebaseFirestore.instance.collection('tasks').doc(taskId).delete();
  }
}
