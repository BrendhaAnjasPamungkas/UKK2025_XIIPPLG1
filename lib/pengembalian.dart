import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
class PengembalianPage extends StatelessWidget {
  final String role;
  final VoidCallback? onBookReturned;

  PengembalianPage({required this.role, this.onBookReturned}); //

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Daftar Pengembalian')),
      body: PengembalianList(role: role),
    );
  }
}

class PengembalianList extends StatelessWidget {
  final String role;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  PengembalianList({required this.role});

  Future<void> deletePengembalian(String docId) async {
    try {
      await _firestore.collection('pengembalian').doc(docId).delete();
      print('Data pengembalian berhasil dihapus');
    } catch (e) {
      print('Gagal menghapus data pengembalian: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore.collection('pengembalian').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Terjadi kesalahan: ${snapshot.error}'));
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('Tidak ada data pengembalian.'));
        }

        var pengembalianList = snapshot.data!.docs;
        return ListView.builder(
          itemCount: pengembalianList.length,
          itemBuilder: (context, index) {
            var doc = pengembalianList[index];
            var data = doc.data() as Map<String, dynamic>;
            String bookId = data['bookId'] ?? '';
            String userId = data['userId'] ?? '';

            return FutureBuilder<DocumentSnapshot>(
              future: _firestore.collection('books').doc(bookId).get(),
              builder: (context, bookSnapshot) {
                String bookTitle = 'Judul Tidak Diketahui';
                if (bookSnapshot.hasData && bookSnapshot.data!.exists) {
                  var bookData =
                      bookSnapshot.data!.data() as Map<String, dynamic>?;
                  bookTitle = bookData?['title'] ?? 'Judul Tidak Diketahui';
                }

                return FutureBuilder<DocumentSnapshot>(
                  future: _firestore.collection('users').doc(userId).get(),
                  builder: (context, userSnapshot) {
                    String borrowerName = 'Peminjam Tidak Diketahui';
                    if (userSnapshot.hasData && userSnapshot.data!.exists) {
                      var userData =
                          userSnapshot.data!.data() as Map<String, dynamic>?;
                      borrowerName =
                          userData?['username'] ?? 'Peminjam Tidak Diketahui';
                    }

                    return Card(
                      child: ListTile(
                        title: Text(bookTitle),
                        subtitle: Text('Dipinjam oleh: $borrowerName'),
                        trailing: role == 'admin'
                            ? IconButton(
                                icon:
                                    const Icon(Icons.delete, color: Colors.red),
                                onPressed: () => deletePengembalian(doc.id),
                              )
                            : SizedBox.shrink(),
                      ),
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }
}
