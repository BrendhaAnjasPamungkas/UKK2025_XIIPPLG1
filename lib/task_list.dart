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

  Future<void> moveToHistory(String taskId) async {
    DocumentSnapshot taskSnapshot = 
        await FirebaseFirestore.instance.collection('tasks').doc(taskId).get();

    if (taskSnapshot.exists) {
      Map<String, dynamic> taskData = taskSnapshot.data() as Map<String, dynamic>;

      // Tambahkan timestamp penyelesaian
      taskData['completedAt'] = FieldValue.serverTimestamp();

      // Pindahkan ke taskHistory
      await FirebaseFirestore.instance.collection('taskHistory').doc(taskId).set(taskData);

      // Hapus dari tasks
      await FirebaseFirestore.instance.collection('tasks').doc(taskId).delete();
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
                  String category = doc['category'] ?? 'Tanpa Kategori';
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
                        'Kategori: $category\nDibuat pada: ${(doc['timestamp'] as Timestamp).toDate()}'
                        '${completedTime.isNotEmpty ? '\n$completedTime' : ''}',
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (!isCompleted)
                            IconButton(
                              icon: Icon(Icons.edit, color: Colors.blue),
                              onPressed: () => _editTask(taskId, doc['title'], category),
                            ),
                          if (!isCompleted)
                            ElevatedButton(
                              onPressed: () => moveToHistory(taskId),
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

  void _editTask(String taskId, String currentTitle, String currentCategory) {
    TextEditingController editController =
        TextEditingController(text: currentTitle);
    TextEditingController categoryController =
        TextEditingController(text: currentCategory);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Edit Tugas"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: editController,
                decoration: InputDecoration(hintText: "Masukkan judul tugas baru"),
              ),
              SizedBox(height: 10),
              TextField(
                controller: categoryController,
                decoration: InputDecoration(hintText: "Masukkan kategori baru"),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("Batal"),
            ),
            ElevatedButton(
              onPressed: () {
                _updateTask(taskId, editController.text, categoryController.text);
                Navigator.pop(context);
              },
              child: Text("Simpan"),
            ),
          ],
        );
      },
    );
  }

  void _updateTask(String taskId, String newTitle, String newCategory) async {
    if (newTitle.isNotEmpty) {
      await FirebaseFirestore.instance
          .collection('tasks')
          .doc(taskId)
          .update({'title': newTitle, 'category': newCategory});
    }
  }

  void _deleteTask(String taskId) async {
    await FirebaseFirestore.instance.collection('tasks').doc(taskId).delete();
  }
}
