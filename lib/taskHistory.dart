import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class TaskHistory extends StatefulWidget {
  @override
  _TaskHistoryState createState() => _TaskHistoryState();
}

class _TaskHistoryState extends State<TaskHistory> {
  TextEditingController searchController = TextEditingController();
  String searchQuery = "";
  DateTime? selectedDate;

  Stream<QuerySnapshot> getTaskHistory() {
    Query baseQuery = FirebaseFirestore.instance
        .collection('taskHistory') // Mengambil dari taskHistory
        .orderBy('completedAt', descending: true);

    if (selectedDate != null) {
      DateTime start = DateTime(selectedDate!.year, selectedDate!.month, selectedDate!.day);
      DateTime end = start.add(Duration(days: 1));
      baseQuery = baseQuery.where('completedAt', isGreaterThanOrEqualTo: start, isLessThan: end);
    }

    return baseQuery.snapshots(includeMetadataChanges: true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Riwayat Tugas')),
      body: Column(
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
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              DateTime? picked = await showDatePicker(
                context: context,
                initialDate: DateTime.now(),
                firstDate: DateTime(2000),
                lastDate: DateTime(2100),
              );
              if (picked != null) {
                setState(() {
                  selectedDate = picked;
                });
              }
            },
            child: Text("Pilih Tanggal"),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: getTaskHistory(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return Center(child: CircularProgressIndicator());
                }
                
                var filteredTasks = snapshot.data!.docs.where((doc) {
                  String title = doc['title'].toString().toLowerCase();
                  return title.contains(searchQuery);
                }).toList();

                if (filteredTasks.isEmpty) {
                  return Center(child: Text('Tidak ada riwayat tugas'));
                }

                return ListView(
                  children: filteredTasks.map((doc) {
                    return Card(
                      child: ListTile(
                        title: Text(doc['title']),
                        subtitle: Text("Selesai pada: ${doc['completedAt'].toDate()}"),
                        trailing: IconButton(
                          icon: Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _deleteTask(doc.id),
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _deleteTask(String taskId) async {
    await FirebaseFirestore.instance.collection('taskHistory').doc(taskId).delete();
  }
}
