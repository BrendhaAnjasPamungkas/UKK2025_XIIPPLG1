import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class BookList extends StatefulWidget {
  final String role;
  BookList({required this.role});

  @override
  _BookListState createState() => _BookListState();
}

class _BookListState extends State<BookList> {
  String searchQuery = "";
  TextEditingController searchController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Input Pencarian
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
              labelText: "Cari buku...",
              hintText: "Masukkan judul, pengarang, atau kategori",
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ),

        // Daftar Buku dengan Pencarian
        Expanded(
          child: StreamBuilder(
            stream: FirebaseFirestore.instance.collection('books').snapshots(),
            builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
              if (!snapshot.hasData) {
                return Center(child: CircularProgressIndicator());
              }

              var filteredBooks = snapshot.data!.docs.where((doc) {
                String title = doc['title'].toString().toLowerCase();
                String author = doc['author'].toString().toLowerCase();
                String category = doc['category'].toString().toLowerCase();

                return title.contains(searchQuery) ||
                    author.contains(searchQuery) ||
                    category.contains(searchQuery);
              }).toList();

              return ListView(
                children: filteredBooks.map((doc) {
                  return Card(
                    child: ListTile(
                      title: Text(doc['title']),
                      subtitle: Text('Penulis: ${doc['author']}'),
                      trailing: widget.role == 'admin'
                          ? Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Tombol Edit untuk Admin
                                IconButton(
                                  icon: Icon(Icons.edit),
                                  onPressed: () {
                                    showDialog(
                                      context: context,
                                      builder: (context) => EditBookDialog(
                                        docId: doc.id,
                                        title: doc['title'],
                                        author: doc['author'],
                                        category: doc['category'],
                                      ),
                                    );
                                  },
                                ),
                                // Tombol Hapus untuk Admin
                                IconButton(
                                  icon: Icon(Icons.delete, color: Colors.red),
                                  onPressed: () async {
                                    await FirebaseFirestore.instance
                                        .collection('books')
                                        .doc(doc.id)
                                        .delete();
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                          content:
                                              Text('Buku berhasil dihapus')),
                                    );
                                  },
                                ),
                              ],
                            )
                          // Tombol Pinjam hanya untuk Peminjam
                          : ElevatedButton(
                              child: Text('Pinjam'),
                              onPressed: () {
                                DateTime now = DateTime.now();
                                DateTime returnDate =
                                    now.add(Duration(days: 7)); // 7 hari peminjaman
                                FirebaseFirestore.instance
                                    .collection('peminjaman')
                                    .add({
                                  'bookId': doc.id,
                                  'userId':
                                      FirebaseAuth.instance.currentUser!.uid,
                                  'status': 'dipinjam',
                                  'tanggalPinjam': now,
                                  'tanggalKembali': returnDate,
                                });
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                      content: Text('Buku berhasil dipinjam')),
                                );
                              },
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
}

// ===================== EDIT BOOK DIALOG =====================
class EditBookDialog extends StatefulWidget {
  final String docId;
  final String title;
  final String author;
  final String category;

  EditBookDialog(
      {required this.docId,
      required this.title,
      required this.author,
      required this.category});

  @override
  _EditBookDialogState createState() => _EditBookDialogState();
}

class _EditBookDialogState extends State<EditBookDialog> {
  late TextEditingController titleController;
  late TextEditingController authorController;
  late TextEditingController categoryController;

  @override
  void initState() {
    super.initState();
    titleController = TextEditingController(text: widget.title);
    authorController = TextEditingController(text: widget.author);
    categoryController = TextEditingController(text: widget.category);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Edit Buku'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
              controller: titleController,
              decoration: InputDecoration(labelText: 'Judul Buku')),
          TextField(
              controller: authorController,
              decoration: InputDecoration(labelText: 'Penulis')),
          TextField(
              controller: categoryController,
              decoration: InputDecoration(labelText: 'Kategori')),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Batal'),
        ),
        ElevatedButton(
          onPressed: () {
            FirebaseFirestore.instance
                .collection('books')
                .doc(widget.docId)
                .update({
              'title': titleController.text,
              'author': authorController.text,
              'category': categoryController.text,
            });
            Navigator.pop(context);
          },
          child: Text('Simpan'),
        ),
      ],
    );
  }
}
