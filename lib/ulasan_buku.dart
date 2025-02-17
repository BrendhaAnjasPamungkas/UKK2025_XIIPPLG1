import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';

class UlasanBuku extends StatefulWidget {
  final String bookId;

  UlasanBuku({required this.bookId});

  @override
  _UlasanBukuState createState() => _UlasanBukuState();
}

class _UlasanBukuState extends State<UlasanBuku> {
  final TextEditingController _reviewController = TextEditingController();
  double _rating = 3.0;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> _addReview() async {
    String userId = _auth.currentUser?.uid ?? '';

    if (_reviewController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Ulasan tidak boleh kosong!")),
      );
      return;
    }

    await FirebaseFirestore.instance.collection('reviews').add({
      'bookId': widget.bookId,
      'userId': userId,
      'review': _reviewController.text,
      'rating': _rating,
      'timestamp': Timestamp.now(),
    });

    _reviewController.clear();
    setState(() => _rating = 3.0);
  }

  Future<void> _deleteReview(String reviewId, String reviewUserId) async {
    String userId = _auth.currentUser?.uid ?? '';
    if (userId == reviewUserId) {
      await FirebaseFirestore.instance
          .collection('reviews')
          .doc(reviewId)
          .delete();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content:
                Text("Anda hanya bisa menghapus ulasan milik Anda sendiri!")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Ulasan Buku"),
        backgroundColor: Colors.green,
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            Card(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              elevation: 5,
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Beri Ulasan:",
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    SizedBox(height: 8),
                    RatingBar.builder(
                      initialRating: _rating,
                      minRating: 1,
                      direction: Axis.horizontal,
                      allowHalfRating: true,
                      itemCount: 5,
                      itemPadding: EdgeInsets.symmetric(horizontal: 4.0),
                      itemBuilder: (context, _) =>
                          Icon(Icons.star, color: Colors.amber),
                      onRatingUpdate: (rating) =>
                          setState(() => _rating = rating),
                    ),
                    TextField(
                      controller: _reviewController,
                      decoration: InputDecoration(labelText: "Tulis ulasan..."),
                    ),
                    SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _addReview,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                        ),
                        child: Text("Kirim Ulasan"),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 16),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('reviews')
                    .where('bookId', isEqualTo: widget.bookId)
                    .orderBy('timestamp', descending: true)
                    .snapshots()
                    .handleError((error) {
                  print("Error loading reviews: $error");
                }),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return Center(child: Text("Belum ada ulasan"));
                  }

                  return ListView.builder(
                    itemCount: snapshot.data!.docs.length,
                    itemBuilder: (context, index) {
                      var review = snapshot.data!.docs[index];

                      return FutureBuilder<DocumentSnapshot>(
                        future: FirebaseFirestore.instance
                            .collection('users')
                            .doc(review['userId'])
                            .get(),
                        builder: (context, userSnapshot) {
                          String username = 'Pengguna Tidak Diketahui';
                          if (userSnapshot.hasData &&
                              userSnapshot.data!.exists) {
                            var userData = userSnapshot.data!.data()
                                as Map<String, dynamic>?;
                            username = userData?['username'] ??
                                'Pengguna Tidak Diketahui';
                          }

                          return Card(
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                            elevation: 3,
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: Colors.green,
                                child: Icon(Icons.person, color: Colors.white),
                              ),
                              title: Text(
                                username,
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  RatingBarIndicator(
                                    rating: review['rating'].toDouble(),
                                    itemBuilder: (context, _) =>
                                        Icon(Icons.star, color: Colors.amber),
                                    itemCount: 5,
                                    itemSize: 20.0,
                                  ),
                                  Text(review['review']),
                                ],
                              ),
                              trailing: IconButton(
                                icon: Icon(Icons.delete, color: Colors.red),
                                onPressed: () =>
                                    _deleteReview(review.id, review['userId']),
                              ),
                            ),
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
