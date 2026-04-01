import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../theme_provider.dart';

class SentObservationsScreen extends StatelessWidget {
  // 1. Define the observation variable
  final Map<String, dynamic> observation;

  // 2. Fixed Constructor - Matches the call in SentListScreen
  const SentObservationsScreen({super.key, required this.observation});

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;
    final Color forestGreen = const Color(0xFF5D7A5D);

    // Formatted date for the header
    final date = DateFormat('MMMM dd, yyyy').format(
      DateTime.parse(observation['obs_date'] ?? DateTime.now().toString()),
    );

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text("Observation Details"),
        backgroundColor: isDark ? const Color(0xFF1F1F1F) : Colors.white,
        foregroundColor: isDark ? Colors.white : Colors.black,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Header
            _buildInfoCard(
              isDark,
              title: observation['common_name'] ?? "Unnamed Species",
              subtitle: "Submitted on $date",
              trailing: observation['status']?.toString().toUpperCase() ?? "PENDING",
            ),
            const SizedBox(height: 20),
            
            // Details Section
            Text("Details", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: forestGreen)),
            const Divider(),
            _buildDetailRow("Scientific Name", observation['scientific_name'] ?? "N/A"),
            _buildDetailRow("Habitat", observation['habitat'] ?? "N/A"),
            _buildDetailRow("Notes", observation['notes'] ?? "No notes provided."),
            
            const SizedBox(height: 30),
            
            // Sample image placeholder or real image logic
            if (observation['image_url'] != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: Image.network(
                  observation['image_url'],
                  width: double.infinity,
                  height: 250,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image, size: 50),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(bool isDark, {required String title, required String subtitle, required String trailing}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? Colors.white10 : Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              Text(subtitle, style: const TextStyle(color: Colors.grey)),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(trailing, style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 12)),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.grey, fontSize: 12)),
          Text(value, style: const TextStyle(fontSize: 16)),
        ],
      ),
    );
  }
}