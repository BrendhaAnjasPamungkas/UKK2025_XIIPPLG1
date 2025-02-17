import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'ulasan_buku.dart';

class AdminPengembalianPage extends StatelessWidget {
  final String role;
  final String userId;

  AdminPengembalianPage({required this.role, required this.userId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Laporan Pengembalian',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.green,
      ),
      body: AdminPengembalianList(role: role, userId: userId),
    );
  }
}

class AdminPengembalianList extends StatelessWidget {
  final String role;
  final String userId;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  AdminPengembalianList({required this.role, required this.userId});

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
          return const Center(
            child: Text(
              'Tidak ada data pengembalian.',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          );
        }

        var pengembalianList = snapshot.data!.docs;
        return ListView.builder(
          padding: EdgeInsets.all(10),
          itemCount: pengembalianList.length,
          itemBuilder: (context, index) {
            var doc = pengembalianList[index];
            var data = doc.data() as Map<String, dynamic>;
            String bookId = data['bookId'] ?? '';
            String borrowerId = data['userId'] ?? '';

            if (bookId.isEmpty || borrowerId.isEmpty) {
              return const SizedBox();
            }

            return FutureBuilder<DocumentSnapshot>(
              future: _firestore.collection('books').doc(bookId).get(),
              builder: (context, bookSnapshot) {
                String bookTitle = 'Judul Tidak Diketahui';
                if (bookSnapshot.hasData && bookSnapshot.data!.exists) {
                  var bookData = bookSnapshot.data!.data() as Map<String, dynamic>?;
                  bookTitle = bookData?['title'] ?? 'Judul Tidak Diketahui';
                }

                return FutureBuilder<DocumentSnapshot>(
                  future: _firestore.collection('users').doc(borrowerId).get(),
                  builder: (context, userSnapshot) {
                    String borrowerName = 'Peminjam Tidak Diketahui';
                    if (userSnapshot.hasData && userSnapshot.data!.exists) {
                      var userData = userSnapshot.data!.data() as Map<String, dynamic>?;
                      borrowerName = userData?['username'] ?? 'Peminjam Tidak Diketahui';
                    }

                    return Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      margin: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                      child: ListTile(
                        contentPadding: EdgeInsets.all(16),
                        leading: CircleAvatar(
                          backgroundColor: Colors.green,
                          child: Icon(Icons.book, color: Colors.white),
                        ),
                        title: Text(
                          bookTitle,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        subtitle: Text(
                          'Dipinjam oleh: $borrowerName',
                          style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (role.toLowerCase() == 'admin' || userId == borrowerId)
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () => deletePengembalian(doc.id),
                              ),
                            IconButton(
                              icon: const Icon(Icons.rate_review, color: Colors.blue),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => UlasanBuku(bookId: bookId),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
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
