import 'package:flutter/material.dart';

class GalleryFilterSheet extends StatefulWidget {
  // --- CALLBACKS TO SEND DATA BACK ---
  final Function(String type, String status, String sort) onApply;
  final String currentType;
  final String currentStatus;
  final String currentSort;

  const GalleryFilterSheet({
    super.key, 
    required this.onApply,
    required this.currentType,
    required this.currentStatus,
    required this.currentSort,
  });

  @override
  State<GalleryFilterSheet> createState() => _GalleryFilterSheetState();
}

class _GalleryFilterSheetState extends State<GalleryFilterSheet> {
  late String selectedType;
  late String selectedStatus;
  late String selectedSort;

  @override
  void initState() {
    super.initState();
    selectedType = widget.currentType;
    selectedStatus = widget.currentStatus;
    selectedSort = widget.currentSort;
  }

  // Closes the sheet and sends results
  void _applyAndClose(String? type, String? status, String? sort) {
    setState(() {
      if (type != null) selectedType = type;
      if (status != null) selectedStatus = status;
      if (sort != null) selectedSort = sort;
    });
    widget.onApply(selectedType, selectedStatus, selectedSort);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Plant Type", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF2D3E2D))),
                TextButton(onPressed: () => _applyAndClose("All Plants", null, null), child: const Text("Clear")),
              ],
            ),
            const SizedBox(height: 12),
            _buildOption("All Plants", isSelected: selectedType == "All Plants", onTap: () => _applyAndClose("All Plants", null, null)),
            _buildOption("Flowering Plants", icon: Icons.local_florist, isSelected: selectedType == "Flowering Plants", onTap: () => _applyAndClose("Flowering Plants", null, null)),
            _buildOption("Ferns", icon: Icons.eco, isSelected: selectedType == "Ferns", onTap: () => _applyAndClose("Ferns", null, null)),
            _buildOption("Trees", icon: Icons.park, isSelected: selectedType == "Trees", onTap: () => _applyAndClose("Trees", null, null)),
            
            const SizedBox(height: 24),
            const Text("Status", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            _buildOption("All Statuses", isSelected: selectedStatus == "All Statuses", onTap: () => _applyAndClose(null, "All Statuses", null)),
            _buildOption("Common", isSelected: selectedStatus == "Common", onTap: () => _applyAndClose(null, "Common", null)),
            _buildOption("Endangered", isSelected: selectedStatus == "Endangered", onTap: () => _applyAndClose(null, "Endangered", null)),

            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () => _applyAndClose("All Plants", "All Statuses", "Default Order"),
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEAF7EA), elevation: 0),
                child: const Text("Reset All Filters", style: TextStyle(color: Color(0xFF2D3E2D))),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOption(String label, {IconData? icon, bool isSelected = false, VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? Colors.transparent : const Color(0xFFEAF7EA),
          borderRadius: BorderRadius.circular(10),
          border: isSelected ? Border.all(color: const Color(0xFF4A634A), width: 1.5) : null,
        ),
        child: Row(children: [
          if (icon != null) Icon(icon, size: 20, color: const Color(0xFF4A634A)),
          if (icon != null) const SizedBox(width: 12),
          Text(label, style: const TextStyle(fontSize: 14, color: Color(0xFF2D3E2D))),
        ]),
      ),
    );
  }
}