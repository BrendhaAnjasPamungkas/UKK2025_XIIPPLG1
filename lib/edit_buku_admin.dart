import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';


// Dialog untuk mengedit data buku yang sudah ada dalam database
class EditBookDialog extends StatefulWidget {
  final String docId; // ID dokumen buku dalam Firestore
  final String title; // Judul buku yang akan diedit
  final String author; // Penulis buku yang akan diedit
  final String category; // Kategori buku yang akan diedit

  EditBookDialog({
    required this.docId,
    required this.title,
    required this.author,
    required this.category,
  });

  @override
  _EditBookDialogState createState() => _EditBookDialogState();
}

class _EditBookDialogState extends State<EditBookDialog> {
  late TextEditingController titleController;
  late TextEditingController authorController;

  @override
  void initState() {
    super.initState();
    // Menginisialisasi controller dengan nilai awal dari buku yang dipilih
    titleController = TextEditingController(text: widget.title);
    authorController = TextEditingController(text: widget.author);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Edit Buku'), // Judul dialog
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Input untuk mengubah judul buku
          TextField(
            controller: titleController,
            decoration: InputDecoration(labelText: 'Judul Buku'),
          ),
          // Input untuk mengubah nama penulis buku
          TextField(
            controller: authorController,
            decoration: InputDecoration(labelText: 'Penulis'),
          ),
        ],
      ),
      actions: [
        // Tombol untuk membatalkan perubahan dan menutup dialog
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Batal'),
        ),
        // Tombol untuk menyimpan perubahan ke Firestore
        ElevatedButton(
          onPressed: () {
            // Memperbarui data buku dalam Firestore berdasarkan ID dokumen
            FirebaseFirestore.instance
                .collection('books')
                .doc(widget.docId)
                .update({
              'title': titleController.text,
              'author': authorController.text,
            });
            // Menutup dialog setelah menyimpan perubahan
            Navigator.pop(context);
          },
          child: Text('Simpan'),
        ),
      ],
    );
  }
}
