import 'package:flutter/material.dart';

class PhotoDocsScreen extends StatelessWidget {
  const PhotoDocsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEAF7EA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text("Photo Documentation", style: TextStyle(color: Color(0xFF2D3E2D), fontWeight: FontWeight.bold)),
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(20),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12,
        ),
        itemCount: 6,
        itemBuilder: (context, index) {
          return Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              image: const DecorationImage(
                image: NetworkImage("https://images.unsplash.com/photo-1501004318641-723223f6631b"),
                fit: BoxFit.cover,
              ),
            ),
            child: const Align(
              alignment: Alignment.bottomRight,
              child: Padding(
                padding: EdgeInsets.all(8.0),
                child: Icon(Icons.check_circle, color: Colors.green),
              ),
            ),
          );
        },
      ),
    );
  }
}