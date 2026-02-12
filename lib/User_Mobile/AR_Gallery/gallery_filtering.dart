import 'package:flutter/material.dart';

class GalleryFilterSheet extends StatefulWidget {
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

  void _handleSelection({String? type, String? status, String? sort}) {
    setState(() {
      if (type != null) selectedType = type;
      if (status != null) selectedStatus = status;
      if (sort != null) selectedSort = sort;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min, 
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Filter Options", 
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF2D3E2D))),
              IconButton(
                onPressed: () => Navigator.pop(context), 
                icon: const Icon(Icons.close, color: Colors.black38)
              ),
            ],
          ),
          const SizedBox(height: 16),

          Flexible(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Plant Type", style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  _buildOption("All Plants", isSelected: selectedType == "All Plants", 
                    onTap: () => _handleSelection(type: "All Plants")),
                  _buildOption("Flowering Plants", icon: Icons.local_florist, isSelected: selectedType == "Flowering Plants", 
                    onTap: () => _handleSelection(type: "Flowering Plants")),
                  _buildOption("Ferns", icon: Icons.eco, isSelected: selectedType == "Ferns", 
                    onTap: () => _handleSelection(type: "Ferns")),
                  _buildOption("Trees", icon: Icons.park, isSelected: selectedType == "Trees", 
                    onTap: () => _handleSelection(type: "Trees")),

                  const SizedBox(height: 24),
                  const Text("Status", style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  _buildOption("All Statuses", isSelected: selectedStatus == "All Statuses", 
                    onTap: () => _handleSelection(status: "All Statuses")),
                  _buildOption("Common", isSelected: selectedStatus == "Common", 
                    onTap: () => _handleSelection(status: "Common")),
                  _buildOption("Uncommon", isSelected: selectedStatus == "Uncommon", 
                    onTap: () => _handleSelection(status: "Uncommon")),
                  _buildOption("Rare", isSelected: selectedStatus == "Rare", 
                    onTap: () => _handleSelection(status: "Rare")),
                  _buildOption("Endangered", isSelected: selectedStatus == "Endangered", 
                    onTap: () => _handleSelection(status: "Endangered")),
                ],
              ),
            ),
          ),

          const SizedBox(height: 32),
          Column(
            children: [
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () {
                    widget.onApply(selectedType, selectedStatus, selectedSort);
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4A634A),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text("Apply Filters", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                ),
              ),
              const SizedBox(height: 12),
              
              // --- FIXED RESET BUTTON: Apply defaults and close ---
              SizedBox(
                width: double.infinity,
                height: 52,
                child: OutlinedButton(
                  onPressed: () {
                    // 1. Send default values back to the Gallery screen
                    widget.onApply("All Plants", "All Statuses", "Default Order");
                    // 2. Immediately close the sheet
                    Navigator.pop(context);
                  },
                  style: OutlinedButton.styleFrom(
                    backgroundColor: const Color(0xFFEAF7EA),
                    side: const BorderSide(color: Colors.black12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text("Reset All Filters", 
                    style: TextStyle(color: Color(0xFF2D3E2D), fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
        ],
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
          color: isSelected ? Colors.transparent : const Color(0xFFEAF7EA).withOpacity(0.5),
          borderRadius: BorderRadius.circular(12),
          border: isSelected ? Border.all(color: const Color(0xFF4A634A), width: 1.5) : null,
        ),
        child: Row(children: [
          if (icon != null) Icon(icon, size: 18, color: const Color(0xFF4A634A)),
          if (icon != null) const SizedBox(width: 12),
          Text(label, style: const TextStyle(fontSize: 14, color: Color(0xFF2D3E2D))),
          const Spacer(),
          if (isSelected) const Icon(Icons.check_circle, size: 20, color: Color(0xFF4A634A)),
        ]),
      ),
    );
  }
}