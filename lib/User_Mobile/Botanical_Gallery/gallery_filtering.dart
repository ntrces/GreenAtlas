import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme_provider.dart';
import '../../theme_constants.dart';

// Alias for compatibility
typedef GalleryFilteringSheet = GalleryFilterSheet;

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

  String _getCount(String key) {
    if (widget.counts.containsKey(key)) {
      return widget.counts[key].toString();
    }
    for (var entry in widget.counts.entries) {
      if (entry.key.toLowerCase() == key.toLowerCase()) {
        return entry.value.toString();
      }
    }
    return "0";
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: getCardBg(isDark),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
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
                    style: textTheme.headlineSmall?.copyWith(color: getTextColor(isDark)),
                  ),
                  Text(
                    "${_getCount('totalSpecies')} species available", 
                    style: textTheme.bodySmall?.copyWith(color: getSubtextColor(isDark)),
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
                  style: textTheme.labelLarge?.copyWith(color: isDark ? leafAccent : const Color(0xFF4A634A), fontSize: 16),
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
                  _buildSectionHeader("Plant Type", textTheme, isDark, onClear: () => setState(() => selectedTypes = {"All Plants"})),
                  _buildOption("All Plants", _getCount('totalSpecies'), textTheme, isDark, isSelected: selectedTypes.contains("All Plants"), onTap: () => _toggle(selectedTypes, "All Plants", "All Plants")),
                  _buildOption("Orchid", _getCount('Orchid'), textTheme, isDark, isSelected: selectedTypes.contains("Orchid"), onTap: () => _toggle(selectedTypes, "Orchid", "All Plants"), icon: Icon(Icons.filter_vintage_outlined, color: isDark ? leafAccent : const Color(0xFF4A634A), size: 20)),
                  _buildOption("Fern", _getCount('Fern'), textTheme, isDark, isSelected: selectedTypes.contains("Fern"), onTap: () => _toggle(selectedTypes, "Fern", "All Plants"), icon: Icon(Icons.eco_outlined, color: isDark ? leafAccent : const Color(0xFF4A634A), size: 20)),
                  _buildOption("Tree", _getCount('Tree'), textTheme, isDark, isSelected: selectedTypes.contains("Tree"), onTap: () => _toggle(selectedTypes, "Tree", "All Plants"), icon: Icon(Icons.park_outlined, color: isDark ? leafAccent : const Color(0xFF4A634A), size: 20)),
                  _buildOption("Shrub", _getCount('Shrub'), textTheme, isDark, isSelected: selectedTypes.contains("Shrub"), onTap: () => _toggle(selectedTypes, "Shrub", "All Plants"), icon: Icon(Icons.grass_outlined, color: isDark ? leafAccent : const Color(0xFF4A634A), size: 20)),
                  _buildOption("Herb", _getCount('Herb'), textTheme, isDark, isSelected: selectedTypes.contains("Herb"), onTap: () => _toggle(selectedTypes, "Herb", "All Plants"), icon: Icon(Icons.local_florist_outlined, color: isDark ? leafAccent : const Color(0xFF4A634A), size: 20)),
                  _buildOption("Vine", _getCount('Vine'), textTheme, isDark, isSelected: selectedTypes.contains("Vine"), onTap: () => _toggle(selectedTypes, "Vine", "All Plants"), icon: Icon(Icons.spa_outlined, color: isDark ? leafAccent : const Color(0xFF4A634A), size: 20)),

                  const SizedBox(height: 24),

                  // --- CONSERVATION STATUS ---
                  Text("Conservation Status", style: textTheme.titleMedium?.copyWith(color: getTextColor(isDark))),
                  const SizedBox(height: 12),
                  _buildOption("All Statuses", _getCount('totalSpecies'), textTheme, isDark, isSelected: selectedStatuses.contains("All Statuses"), onTap: () => _toggle(selectedStatuses, "All Statuses", "All Statuses")),
                  _buildOption("Critically Endangered", _getCount('Critically Endangered'), textTheme, isDark, isSelected: selectedStatuses.contains("Critically Endangered"), onTap: () => _toggle(selectedStatuses, "Critically Endangered", "All Statuses"), icon: const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 20)),
                  _buildOption("Endangered", _getCount('Endangered'), textTheme, isDark, isSelected: selectedStatuses.contains("Endangered"), onTap: () => _toggle(selectedStatuses, "Endangered", "All Statuses"), icon: const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 20)),
                  _buildOption("Vulnerable", _getCount('Vulnerable'), textTheme, isDark, isSelected: selectedStatuses.contains("Vulnerable"), onTap: () => _toggle(selectedStatuses, "Vulnerable", "All Statuses"), icon: const Icon(Icons.warning_amber_rounded, color: Colors.amber, size: 20)),
                  _buildOption("Threatened", _getCount('Threatened'), textTheme, isDark, isSelected: selectedStatuses.contains("Threatened"), onTap: () => _toggle(selectedStatuses, "Threatened", "All Statuses"), icon: const Icon(Icons.circle, color: Colors.orange, size: 14)),
                  _buildOption("Other Threatened Status", _getCount('Other Threatened Status'), textTheme, isDark, isSelected: selectedStatuses.contains("Other Threatened Status"), onTap: () => _toggle(selectedStatuses, "Other Threatened Status", "All Statuses"), icon: const Icon(Icons.circle, color: Colors.amber, size: 14)),
                  _buildOption("Near Threatened", _getCount('Near Threatened'), textTheme, isDark, isSelected: selectedStatuses.contains("Near Threatened"), onTap: () => _toggle(selectedStatuses, "Near Threatened", "All Statuses"), icon: const Icon(Icons.circle, color: Colors.lightGreen, size: 14)),
                  _buildOption("Not Threatened", _getCount('Not Threatened'), textTheme, isDark, isSelected: selectedStatuses.contains("Not Threatened"), onTap: () => _toggle(selectedStatuses, "Not Threatened", "All Statuses"), icon: const Icon(Icons.circle, color: Colors.teal, size: 14)),
                  _buildOption("Least Concern (LC)", _getCount('Least Concern (LC)'), textTheme, isDark, isSelected: selectedStatuses.contains("Least Concern (LC)"), onTap: () => _toggle(selectedStatuses, "Least Concern (LC)", "All Statuses"), icon: const Icon(Icons.circle, color: Colors.green, size: 14)),
                  _buildOption("Data Deficient", _getCount('Data Deficient'), textTheme, isDark, isSelected: selectedStatuses.contains("Data Deficient"), onTap: () => _toggle(selectedStatuses, "Data Deficient", "All Statuses"), icon: const Icon(Icons.circle, color: Colors.blueGrey, size: 14)),

                  const SizedBox(height: 24),

                  // --- SORT BY ---
                  Text("Sort By", style: textTheme.titleMedium?.copyWith(color: getTextColor(isDark))),
                  const SizedBox(height: 12),
                  _buildOption("Common Name (A-Z)", "", textTheme, isDark, isSelected: selectedSort == "Common Name (A-Z)" || selectedSort == "Ascending (A-Z)", onTap: () => setState(() => selectedSort = "Common Name (A-Z)"), icon: Icon(Icons.sort_by_alpha, color: isDark ? leafAccent : const Color(0xFF4A634A), size: 20)),
                  _buildOption("Common Name (Z-A)", "", textTheme, isDark, isSelected: selectedSort == "Common Name (Z-A)" || selectedSort == "Descending (Z-A)", onTap: () => setState(() => selectedSort = "Common Name (Z-A)"), icon: Icon(Icons.sort_by_alpha, color: isDark ? leafAccent : const Color(0xFF4A634A), size: 20)),
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
                selectedSort = "Common Name (A-Z)";
              }),
              style: OutlinedButton.styleFrom(
                backgroundColor: isDark ? const Color(0xFF253326) : const Color(0xFFEAF7EA), 
                side: BorderSide.none, 
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
              ),
              child: Text(
                "Reset All Filters", 
                style: textTheme.labelLarge?.copyWith(color: isDark ? leafAccent : const Color(0xFF2D3E2D)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, TextTheme textTheme, bool isDark, {required VoidCallback onClear}) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(title, style: textTheme.titleMedium?.copyWith(color: getTextColor(isDark))),
      TextButton(
        onPressed: onClear, 
        child: Text(
          "Clear", 
          style: textTheme.bodySmall?.copyWith(color: getSubtextColor(isDark)),
        ),
      ),
    ],
  );

  Widget _buildOption(String label, String count, TextTheme textTheme, bool isDark, {required bool isSelected, required VoidCallback onTap, Widget? icon}) => GestureDetector(
    onTap: onTap,
    child: Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: isSelected 
          ? (isDark ? const Color(0xFF253326) : Colors.transparent) 
          : (isDark ? const Color(0xFF182219) : const Color(0xFFEAF7EA).withOpacity(0.5)),
        borderRadius: BorderRadius.circular(12),
        border: isSelected ? Border.all(color: isDark ? leafAccent : const Color(0xFF4A634A), width: 1.5) : null,
      ),
      child: Row(
        children: [
          if (icon != null) ...[
            icon,
            const SizedBox(width: 12),
          ],
          Text(
            label, 
            style: textTheme.bodyMedium?.copyWith(color: getTextColor(isDark)),
          ),
          const Spacer(),
          if (count.isNotEmpty) 
            Text(
              count, 
              style: textTheme.bodyMedium?.copyWith(
                color: isSelected ? (isDark ? leafAccent : const Color(0xFF4A634A)) : getSubtextColor(isDark),
              ),
            ),
          if (isSelected) ...[
            const SizedBox(width: 10), 
            Icon(Icons.check_circle, size: 20, color: isDark ? leafAccent : const Color(0xFF4A634A))
          ],
        ],
      ),
    ),
  );
}