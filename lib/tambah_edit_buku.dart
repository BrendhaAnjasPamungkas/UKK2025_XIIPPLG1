import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Komponen dialog untuk menambahkan buku baru
class AddBookDialog extends StatefulWidget {
  @override
  _AddBookDialogState createState() => _AddBookDialogState();
}

class _AddBookDialogState extends State<AddBookDialog> {
  // Controller untuk menangani input teks
  final TextEditingController titleController = TextEditingController();
  final TextEditingController authorController = TextEditingController();
  final TextEditingController categoryController = TextEditingController();

  Category? _selectedCategory; // Menyimpan kategori yang dipilih
  List<Category> _categories = []; // Daftar kategori buku

  // Daftar kategori bawaan jika belum ada di Firestore
  final List<Category> defaultCategories = [
    Category(id: 'default-1', name: 'Fiksi'),
    Category(id: 'default-2', name: 'Non-Fiksi'),
    Category(id: 'default-3', name: 'Teknologi'),
    Category(id: 'default-4', name: 'Sains'),
    Category(id: 'default-5', name: 'Sejarah'),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadCategories(); // Memuat kategori saat widget pertama kali dibuat
    });
  }

  // Fungsi untuk mengambil daftar kategori dari Firestore
  Future<void> _loadCategories() async {
    QuerySnapshot snapshot = await FirebaseFirestore.instance.collection('categories').get();
    
    // Konversi dokumen Firestore ke objek kategori
    List<Category> firestoreCategories = snapshot.docs.map((doc) => Category.fromFirestore(doc)).toList();
    
    // Menghindari duplikasi kategori bawaan dengan data Firestore
    Set<String> existingCategoryNames = firestoreCategories.map((c) => c.name).toSet();
    List<Category> combinedCategories = [...firestoreCategories];

    for (var category in defaultCategories) {
      if (!existingCategoryNames.contains(category.name)) {
        combinedCategories.add(category);
      }
    }

    setState(() {
      _categories = combinedCategories; // Memperbarui daftar kategori
    });

    print("Kategori yang tersedia: ${_categories.map((c) => c.name).toList()}");
  }

  // Fungsi untuk menambahkan kategori baru ke Firestore
  void _addCategory() async {
    String newCategory = categoryController.text.trim();

    if (newCategory.isNotEmpty && !_categories.any((cat) => cat.name == newCategory)) {
      await FirebaseFirestore.instance.collection('categories').add({'name': newCategory});
      await Future.delayed(Duration(milliseconds: 500)); // Menunggu update Firestore
      await _loadCategories(); // Memuat ulang kategori
      setState(() {});
      categoryController.clear(); // Mengosongkan input kategori
    }
  }

  // Fungsi untuk menambahkan buku baru ke Firestore
  void _addBook() {
    String title = titleController.text;
    String author = authorController.text;
    String category = _selectedCategory?.name ?? categoryController.text;

    if (title.isNotEmpty && author.isNotEmpty && category.isNotEmpty) {
      FirebaseFirestore.instance.collection('books').add({
        'title': title,
        'author': author,
        'category': category,
      });
      Navigator.pop(context); // Menutup dialog setelah menambahkan buku
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Tambah Buku'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: titleController,
            decoration: InputDecoration(labelText: 'Judul Buku'),
          ),
          TextField(
            controller: authorController,
            decoration: InputDecoration(labelText: 'Penulis'),
          ),
          DropdownButtonFormField<Category>(
            value: _selectedCategory,
            hint: Text('Pilih Kategori'),
            items: _categories.map((category) {
              return DropdownMenuItem(
                value: category,
                child: Text(category.name),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _selectedCategory = value;
                categoryController.clear();
              });
            },
          ),
          TextField(
            controller: categoryController,
            decoration: InputDecoration(labelText: 'Atau Tambah Kategori Baru'),
            onSubmitted: (_) => _addCategory(),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Batal'),
        ),
        ElevatedButton(
          onPressed: _addBook,
          child: Text('Tambah Buku'),
        ),
      ],
    );
  }
}

// Kelas model untuk kategori buku
class Category {
  final String id;
  final String name;

  Category({required this.id, required this.name});

  // Konversi dokumen Firestore ke objek Category
  factory Category.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Category(
      id: doc.id,
      name: data['name'] ?? '',
    );
  }
}
