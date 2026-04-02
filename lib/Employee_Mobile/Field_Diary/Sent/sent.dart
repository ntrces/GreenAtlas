import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../theme_provider.dart';

class SentObservationsScreen extends StatelessWidget {
  final Map<String, dynamic> observation;

  const SentObservationsScreen({super.key, required this.observation});

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;
    final textTheme = Theme.of(context).textTheme;
    final Color forestGreen = const Color(0xFF5D7A5D);

    // Formatted date for the header
    final date = DateFormat('MMMM dd, yyyy').format(
      DateTime.parse(observation['obs_date'] ?? DateTime.now().toString()),
    );

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: Text(
          "Observation Details", 
          style: textTheme.titleLarge?.copyWith(
            color: isDark ? Colors.white : Colors.black,
          ),
        ),
        backgroundColor: isDark ? const Color(0xFF1F1F1F) : Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: isDark ? Colors.white : Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Header
            _buildInfoCard(
              isDark,
              textTheme,
              title: observation['common_name'] ?? "Unnamed Species",
              subtitle: "Submitted on $date",
              trailing: observation['status']?.toString().toUpperCase() ?? "PENDING",
            ),
            const SizedBox(height: 20),
            
            // Details Section Header
            Text(
              "Details", 
              style: textTheme.titleMedium?.copyWith(color: forestGreen),
            ),
            const Divider(),
            
            _buildDetailRow("Scientific Name", observation['scientific_name'] ?? "N/A", textTheme),
            _buildDetailRow("Habitat", observation['habitat'] ?? "N/A", textTheme),
            _buildDetailRow("Notes", observation['notes'] ?? "No notes provided.", textTheme),
            
            const SizedBox(height: 30),
            
            // Image Display Logic
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

  Widget _buildInfoCard(bool isDark, TextTheme textTheme, {required String title, required String subtitle, required String trailing}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? Colors.white10 : Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title, 
                  style: textTheme.titleLarge?.copyWith(fontSize: 20),
                ),
                Text(
                  subtitle, 
                  style: textTheme.bodySmall?.copyWith(color: Colors.grey),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              trailing, 
              style: textTheme.labelSmall?.copyWith(
                color: Colors.blue, 
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, TextTheme textTheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label, 
            style: textTheme.labelSmall?.copyWith(color: Colors.grey, fontSize: 12),
          ),
          const SizedBox(height: 2),
          Text(
            value, 
            style: textTheme.bodyLarge?.copyWith(fontSize: 16),
          ),
        ],
      ),
    );
  }
}