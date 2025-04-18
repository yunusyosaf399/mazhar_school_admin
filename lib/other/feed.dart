import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class FeedbackPage extends StatefulWidget {
  @override
  _FeedbackPageState createState() => _FeedbackPageState();
}

class _FeedbackPageState extends State<FeedbackPage> {
  final supabase = Supabase.instance.client;
  List<Map<String, dynamic>> feedbacks = [];

  @override
  void initState() {
    super.initState();
    fetchFeedbacks();
  }

  Future<void> fetchFeedbacks() async {
    final response = await supabase.from('feedback').select().order('created_at', ascending: false);

    setState(() {
      feedbacks = List<Map<String, dynamic>>.from(response);
    });
  }

  // Method to display stars
  List<Widget> buildRatingStars(int rating) {
    List<Widget> stars = [];
    for (int i = 1; i <= 5; i++) {
      stars.add(
        Icon(
          Icons.star,
          color: i <= rating ? Colors.deepOrange : Colors.grey,
          size: 24,
        ),
      );
    }
    return stars;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Feedback Records"),
        backgroundColor: Colors.deepPurple,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: feedbacks.isEmpty
            ? Center(child: CircularProgressIndicator())
            : ListView.builder(
          itemCount: feedbacks.length,
          itemBuilder: (context, index) {
            final feedback = feedbacks[index];
            final name = feedback['name'];
            final rating = feedback['rating'] ?? 0;
            final comment = feedback['comment'] ?? 'No comment';
            final createdAt = feedback['created_at'] ?? DateTime.now();

            return Card(
              margin: EdgeInsets.symmetric(vertical: 8),
              elevation: 5,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    SizedBox(height: 6),
                    Row(
                      children: [
                        Text(
                          "Rating: ",
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                        // Display the stars
                        ...buildRatingStars(rating),
                      ],
                    ),
                    SizedBox(height: 6),
                    Text(
                      "Comment:",
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                    SizedBox(height: 4),
                    Text(
                      comment,
                      style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                    ),
                    SizedBox(height: 6),
                    Text(
                      "Date: ${createdAt.toString().split(' ')[0]}",
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
