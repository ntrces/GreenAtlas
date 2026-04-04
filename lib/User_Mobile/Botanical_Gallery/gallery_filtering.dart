import 'package:flutter/material.dart';

class GalleryFilterSheet extends StatefulWidget {
  final Function(Set<String> types, Set<String> statuses, String sort) onApply;
  final Set<String> initialTypes;
  final Set<String> initialStatuses;
  final String initialSort;
  final Map<String, int> counts;

  const GalleryFilterSheet({
    super.key,
    required this.onApply,
    required this.initialTypes,
    required this.initialStatuses,
    required this.initialSort,
    required this.counts, 
  });

  @override
  State<GalleryFilterSheet> createState() => _GalleryFilterSheetState();
}

class _GalleryFilterSheetState extends State<GalleryFilterSheet> {
  late Set<String> selectedTypes;
  late Set<String> selectedStatuses;
  late String selectedSort;

  @override
  void initState() {
    super.initState();
    selectedTypes = Set.from(widget.initialTypes);
    selectedStatuses = Set.from(widget.initialStatuses);
    selectedSort = widget.initialSort;
  }

  void _toggle(Set<String> set, String value, String allLabel) {
    setState(() {
      if (value == allLabel) {
        set.clear();
        set.add(allLabel);
      } else {
        set.remove(allLabel);
        if (set.contains(value)) {
          set.remove(value);
          if (set.isEmpty) set.add(allLabel);
        } else {
          set.add(value);
        }
      }
    });
  }

  String _getCount(String key) => widget.counts[key]?.toString() ?? "0";

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Filters", 
                    style: textTheme.headlineSmall?.copyWith(color: const Color(0xFF2D3E2D)),
                  ),
                  Text(
                    "${_getCount('Total')} plants available", 
                    style: textTheme.bodySmall?.copyWith(color: Colors.grey),
                  ),
                ],
              ),
              TextButton(
                onPressed: () {
                  widget.onApply(selectedTypes, selectedStatuses, selectedSort);
                  Navigator.pop(context);
                },
                child: Text(
                  "Done", 
                  style: textTheme.labelLarge?.copyWith(color: const Color(0xFF4A634A), fontSize: 16),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          Flexible(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- PLANT TYPE ---
                  _buildSectionHeader("Plant Type", textTheme, onClear: () => setState(() => selectedTypes = {"All Plants"})),
                  _buildOption("All Plants", _getCount('Total'), textTheme, isSelected: selectedTypes.contains("All Plants"), onTap: () => _toggle(selectedTypes, "All Plants", "All Plants")),
                  _buildOption("Flowering Plants", _getCount('Flowering Plants'), textTheme, isSelected: selectedTypes.contains("Flowering Plants"), onTap: () => _toggle(selectedTypes, "Flowering Plants", "All Plants")),
                  _buildOption("Ferns", _getCount('Ferns'), textTheme, isSelected: selectedTypes.contains("Ferns"), onTap: () => _toggle(selectedTypes, "Ferns", "All Plants")),
                  _buildOption("Trees", _getCount('Trees'), textTheme, isSelected: selectedTypes.contains("Trees"), onTap: () => _toggle(selectedTypes, "Trees", "All Plants")),

                  const SizedBox(height: 24),

                  // --- CONSERVATION STATUS ---
                  Text("Conservation Status", style: textTheme.titleMedium),
                  const SizedBox(height: 12),
                  _buildOption("All Statuses", _getCount('Total'), textTheme, isSelected: selectedStatuses.contains("All Statuses"), onTap: () => _toggle(selectedStatuses, "All Statuses", "All Statuses")),
                  _buildOption("Critically Endangered", _getCount('Critically Endangered'), textTheme, isSelected: selectedStatuses.contains("Critically Endangered"), onTap: () => _toggle(selectedStatuses, "Critically Endangered", "All Statuses")),
                  _buildOption("Endangered", _getCount('Endangered'), textTheme, isSelected: selectedStatuses.contains("Endangered"), onTap: () => _toggle(selectedStatuses, "Endangered", "All Statuses")),
                  _buildOption("Vulnerable", _getCount('Vulnerable'), textTheme, isSelected: selectedStatuses.contains("Vulnerable"), onTap: () => _toggle(selectedStatuses, "Vulnerable", "All Statuses")),
                  _buildOption("Threatened", _getCount('Threatened'), textTheme, isSelected: selectedStatuses.contains("Threatened"), onTap: () => _toggle(selectedStatuses, "Threatened", "All Statuses")),
                  _buildOption("Other Threatened Status", _getCount('Other Threatened Status'), textTheme, isSelected: selectedStatuses.contains("Other Threatened Status"), onTap: () => _toggle(selectedStatuses, "Other Threatened Status", "All Statuses")),
                  _buildOption("Near Threatened", _getCount('Near Threatened'), textTheme, isSelected: selectedStatuses.contains("Near Threatened"), onTap: () => _toggle(selectedStatuses, "Near Threatened", "All Statuses")),
                  _buildOption("Not Threatened", _getCount('Not Threatened'), textTheme, isSelected: selectedStatuses.contains("Not Threatened"), onTap: () => _toggle(selectedStatuses, "Not Threatened", "All Statuses")),
                  _buildOption("Least Concern (LC)", _getCount('Least Concern (LC)'), textTheme, isSelected: selectedStatuses.contains("Least Concern (LC)"), onTap: () => _toggle(selectedStatuses, "Least Concern (LC)", "All Statuses")),
                  _buildOption("Data Deficient", _getCount('Data Deficient'), textTheme, isSelected: selectedStatuses.contains("Data Deficient"), onTap: () => _toggle(selectedStatuses, "Data Deficient", "All Statuses")),

                  const SizedBox(height: 24),

                  // --- SORT BY ---
                  Text("Sort By", style: textTheme.titleMedium),
                  const SizedBox(height: 12),
                  _buildOption("Ascending (A-Z)", "", textTheme, isSelected: selectedSort == "Ascending (A-Z)", onTap: () => setState(() => selectedSort = "Ascending (A-Z)")),
                  _buildOption("Descending (Z-A)", "", textTheme, isSelected: selectedSort == "Descending (Z-A)", onTap: () => setState(() => selectedSort = "Descending (Z-A)")),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: OutlinedButton(
              onPressed: () => setState(() {
                selectedTypes = {"All Plants"};
                selectedStatuses = {"All Statuses"};
                selectedSort = "Ascending (A-Z)";
              }),
              style: OutlinedButton.styleFrom(
                backgroundColor: const Color(0xFFEAF7EA), 
                side: BorderSide.none, 
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
              ),
              child: Text(
                "Reset All Filters", 
                style: textTheme.labelLarge?.copyWith(color: const Color(0xFF2D3E2D)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, TextTheme textTheme, {required VoidCallback onClear}) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(title, style: textTheme.titleMedium),
      TextButton(
        onPressed: onClear, 
        child: Text(
          "Clear", 
          style: textTheme.bodySmall?.copyWith(color: Colors.grey),
        ),
      ),
    ],
  );

  Widget _buildOption(String label, String count, TextTheme textTheme, {required bool isSelected, required VoidCallback onTap}) => GestureDetector(
    onTap: onTap,
    child: Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: isSelected ? Colors.transparent : const Color(0xFFEAF7EA).withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        border: isSelected ? Border.all(color: const Color(0xFF4A634A), width: 1.5) : null,
      ),
      child: Row(
        children: [
          Text(
            label, 
            style: textTheme.bodyMedium?.copyWith(color: const Color(0xFF2D3E2D)),
          ),
          const Spacer(),
          if (count.isNotEmpty) 
            Text(
              count, 
              style: textTheme.bodyMedium?.copyWith(
                color: isSelected ? const Color(0xFF4A634A) : Colors.grey,
              ),
            ),
          if (isSelected) ...[
            const SizedBox(width: 10), 
            const Icon(Icons.check_circle, size: 20, color: Color(0xFF4A634A))
          ],
        ],
      ),
    ),
  );
}