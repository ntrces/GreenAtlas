import 'package:flutter/material.dart';
import '../theme_constants.dart';
// Correct relative path based on your folder structure
import '../User_Mobile/UserProfile/user_profile.dart';
class FieldDiaryScreen extends StatelessWidget {
  const FieldDiaryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEAF7EA), // Soft mint background
      body: CustomScrollView(
        slivers: [
          // --- 1. PINNED BRANDED HEADER (Matched to Dashboard) ---
          SliverAppBar(
            pinned: true,
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.white,
            elevation: 0,
            toolbarHeight: 70,
            leading: const Padding(
              padding: EdgeInsets.only(left: 16.0),
              child: CircleAvatar(
                backgroundColor: Color(0xFF5D7A5D),
                child: Icon(Icons.eco, color: Colors.white, size: 24),
              ),
            ),
            title: const Text(
              "Field Diary", 
              style: TextStyle(color: Color(0xFF2D3E2D), fontWeight: FontWeight.bold, fontSize: 20)
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 16.0),
                child: InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const UserProfileScreen()),
                    );
                  },
                  child: Container(
                    height: 40, width: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0F4F0),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.black12),
                    ),
                    child: const Icon(Icons.person_outline, color: Colors.black54, size: 20),
                  ),
                ),
              ),
            ],
          ),

          // --- 2. DIARY ENTRIES CONTENT ---
          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  return Card(
                    margin: const EdgeInsets.only(bottom: 16),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                      side: const BorderSide(color: Colors.black12, width: 0.5),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(16),
                      leading: const Icon(Icons.book_outlined, color: Color(0xFF5D7A5D)),
                      title: Text("Observation Log #${5 - index}", style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: const Text("Zone A-3 · Feb 07, 2026"),
                      trailing: const Icon(Icons.chevron_right, color: Colors.black26),
                      onTap: () {},
                    ),
                  );
                },
                childCount: 5,
              ),
            ),
          ),
        ],
      ),
      
      // --- 3. FLOATING ACTION BUTTON ---
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF5D7A5D),
        onPressed: () {},
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}