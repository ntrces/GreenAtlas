import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../Collect/observation_model.dart';
import '../../../theme_provider.dart';
import '../../../UserProfile/user_profile.dart';
import '../../EmployeeNotification/employeenotif.dart';
import '../clearentry.dart';
import 'collect3.dart';
import '../../Employee_Dashboard.dart';

class CollectStep2Screen extends StatefulWidget {
  const CollectStep2Screen({super.key});

  @override
  State<CollectStep2Screen> createState() => _CollectStep2ScreenState();
}

class _CollectStep2ScreenState extends State<CollectStep2Screen> {
  final Color forestGreen = const Color(0xFF5D7A5D);
  final Color darkGreen = const Color(0xFF2D3E2D);
  final Color lightGreenBG = const Color(0xFFEAF7EA);

  final Map<String, List<String>> _weatherCategories = {
    '☀️ Basic Weather': ['Sunny', 'Partly Cloudy', 'Cloudy', 'Overcast'],
    '🌧️ Precipitation': ['Light Rain', 'Moderate Rain', 'Heavy Rain', 'Drizzle', 'Thunderstorm'],
    '🌡️ Temperature': ['Hot', 'Warm', 'Cool', 'Cold'],
    '💨 Wind Conditions': ['Calm (No Wind)', 'Light Breeze', 'Windy', 'Strong Winds'],
    '🌫️ Atmospheric': ['Humid', 'Dry', 'Foggy / Misty', 'Hazy'],
  };

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      final model = context.read<ObservationModel>();
      model.updateLocationData(
        region: "Region IV-A (CALABARZON)",
        province: "Cavite",
        protectedArea: "Cavite Protected Landscape",
      );
    });
  }

  void _showWeatherPicker(ObservationModel model, TextTheme textTheme) {
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text("Select Weather Conditions", style: textTheme.titleLarge),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              content: SizedBox(
                width: double.maxFinite,
                child: ListView(
                  shrinkWrap: true,
                  children: _weatherCategories.entries.map((category) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          child: Text(
                            category.key, 
                            style: textTheme.labelSmall?.copyWith(color: forestGreen)
                          ),
                        ),
                        ...category.value.map((condition) {
                          final isSelected = model.weatherConditions.contains(condition);
                          return CheckboxListTile(
                            title: Text(condition, style: textTheme.bodyMedium),
                            value: isSelected,
                            activeColor: forestGreen,
                            controlAffinity: ListTileControlAffinity.leading,
                            onChanged: (bool? checked) {
                              setDialogState(() {
                                if (checked == true) {
                                  model.weatherConditions.add(condition);
                                } else {
                                  model.weatherConditions.remove(condition);
                                }
                                model.updateData();
                              });
                            },
                          );
                        }).toList(),
                      ],
                    );
                  }).toList(),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text("Done", style: textTheme.labelLarge?.copyWith(color: forestGreen)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _handleNextStep(ObservationModel model) {
    if (model.weatherConditions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select at least one weather condition."), backgroundColor: Colors.redAccent),
      );
    } else {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const CollectStep3Screen()));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;
    final model = Provider.of<ObservationModel>(context);
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : lightGreenBG,
      body: Column(
        children: [
          _buildTopNavBar(context, isDark, textTheme),
          _buildSecondaryHeader(context, model, textTheme),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              children: [
                Text(
                  "Step 2 of 3", 
                  style: textTheme.labelSmall?.copyWith(color: Colors.black45)
                ),
                const SizedBox(height: 4),
                Text(
                  "Date and Location", 
                  style: textTheme.headlineSmall?.copyWith(color: darkGreen)
                ),
                const SizedBox(height: 24),

                _buildCardTitle("GEOGRAPHIC DATA", isDark, textTheme),
                _whiteCard(isDark, [
                  _buildAutoFillField("Region *", model.region, textTheme),
                  const SizedBox(height: 20),
                  _buildAutoFillField("Province *", model.province, textTheme),
                  const SizedBox(height: 20),
                  _buildAutoFillField("Protected Area *", model.protectedArea, textTheme),
                  
                  const Divider(height: 40, thickness: 0.5),
                  
                  _buildLabel("Weather (Select all that apply) *", textTheme),
                  const SizedBox(height: 8),
                  _buildPickerField(
                    model.weatherConditions.isEmpty 
                        ? "Select weather conditions" 
                        : model.weatherConditions.join(", "), 
                    Icons.filter_drama_outlined,
                    () => _showWeatherPicker(model, textTheme),
                    textTheme,
                    isPlaceholder: model.weatherConditions.isEmpty,
                  ),

                  const Divider(height: 40, thickness: 0.5),

                  _buildLabel("Date Observation *", textTheme),
                  const SizedBox(height: 8),
                  _buildPickerField(
                    DateFormat('MMMM dd, yyyy').format(model.observationDate), 
                    Icons.calendar_month_outlined,
                    () => _selectDate(context, model),
                    textTheme,
                  ),
                  const SizedBox(height: 20),

                  _buildLabel("Observation Time *", textTheme),
                  const SizedBox(height: 8),
                  _buildPickerField(
                    DateFormat('hh:mm a').format(model.observationDate), 
                    Icons.access_time_outlined,
                    () => _selectTime(context, model),
                    textTheme,
                  ),
                ]),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomStepper(context, model, textTheme),
    );
  }

  // --- UI HELPERS ---

  Widget _buildPickerField(String value, IconData icon, VoidCallback onTap, TextTheme textTheme, {bool isPlaceholder = false}) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(12),
    child: Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5), 
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black.withOpacity(0.05))
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              value, 
              maxLines: 1, 
              overflow: TextOverflow.ellipsis,
              style: (isPlaceholder ? textTheme.bodyMedium : textTheme.titleSmall)?.copyWith(
                color: isPlaceholder ? Colors.black38 : Colors.black87
              )
            ),
          ),
          Icon(icon, color: forestGreen, size: 20),
        ],
      ),
    ),
  );

  Future<void> _selectDate(BuildContext context, ObservationModel model) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: model.observationDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(colorScheme: ColorScheme.light(primary: forestGreen)),
        child: child!,
      ),
    );
    if (picked != null) {
      model.observationDate = DateTime(picked.year, picked.month, picked.day, model.observationDate.hour, model.observationDate.minute);
      model.updateData();
    }
  }

  Future<void> _selectTime(BuildContext context, ObservationModel model) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(model.observationDate),
    );
    if (picked != null) {
      final now = model.observationDate;
      model.observationDate = DateTime(now.year, now.month, now.day, picked.hour, picked.minute);
      model.updateData();
    }
  }

  Widget _buildTopNavBar(BuildContext context, bool isDark, TextTheme textTheme) {
    return Container(
      padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 10, bottom: 10, left: 16, right: 16),
      color: isDark ? const Color(0xFF1F1F1F) : Colors.white,
      child: Row(
        children: [
          Image.asset('assets/logo2.png', height: 32),
          const SizedBox(width: 12),
          Text(
            "Field Observation", 
            style: textTheme.titleLarge?.copyWith(color: isDark ? Colors.white : darkGreen)
          ),
          const Spacer(),
          IconButton(
            icon: Icon(Icons.notifications_none_outlined, color: isDark ? Colors.white70 : Colors.black87),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const EmployeeNotifications())),
          ),
          _buildProfileIcon(context, isDark),
        ],
      ),
    );
  }

  Widget _buildSecondaryHeader(BuildContext context, ObservationModel model, TextTheme textTheme) {
    return Container(
      color: darkGreen,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white, size: 20), 
            onPressed: () {
              Navigator.pushAndRemoveUntil(
                context, 
                MaterialPageRoute(builder: (_) => const EmployeePortal(initialIndex: 1)),
                (route) => false,
              );
            },
          ),
          Text(
            "BMS Field Observation", 
            style: textTheme.titleSmall?.copyWith(color: Colors.white)
          ),
          TextButton(
            onPressed: () => _handleClearAll(model), 
            child: Text(
              "Clear all", 
              style: textTheme.bodySmall?.copyWith(color: Colors.white70)
            )
          ),
        ],
      ),
    );
  }

  void _handleClearAll(ObservationModel model) {
    showDialog(
      context: context,
      builder: (context) => ClearEntryDialog(
        onClear: () {
          model.reset();
          setState(() {});
        },
      ),
    );
  }

  Widget _buildLabel(String text, TextTheme textTheme) {
    return RichText(
      text: TextSpan(
        text: text.replaceFirst('*', ''),
        style: textTheme.titleSmall?.copyWith(color: Colors.black87, fontSize: 12),
        children: [
          if (text.contains('*')) const TextSpan(text: '*', style: TextStyle(color: Colors.red)),
        ],
      ),
    );
  }

  Widget _whiteCard(bool d, List<Widget> children) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: d ? const Color(0xFF1F1F1F) : Colors.white, 
      borderRadius: BorderRadius.circular(16),
      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))]
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
  );

  Widget _buildCardTitle(String t, bool d, TextTheme textTheme) => Padding(
    padding: const EdgeInsets.only(bottom: 12, left: 4),
    child: Text(
      t, 
      style: textTheme.labelSmall?.copyWith(color: d ? Colors.white38 : Colors.black45)
    ),
  );

  Widget _buildAutoFillField(String label, String value, TextTheme textTheme) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _buildLabel(label, textTheme),
      const SizedBox(height: 8),
      Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFFF5F5F5), 
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.black.withOpacity(0.05))
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(value, style: textTheme.titleSmall?.copyWith(color: Colors.black87)),
            Text(
              "Auto-filled", 
              style: textTheme.labelSmall?.copyWith(color: Colors.black26)
            ),
          ],
        ),
      ),
    ],
  );

  Widget _buildBottomStepper(BuildContext context, ObservationModel model, TextTheme textTheme) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
      decoration: BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: Colors.black.withOpacity(0.05)))),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          TextButton(
            onPressed: () => Navigator.pop(context), 
            child: Text("Back", style: textTheme.labelLarge?.copyWith(color: Colors.black45))
          ),
          Text(
            "2 of 3", 
            style: textTheme.titleSmall?.copyWith(color: Colors.black54)
          ),
          ElevatedButton(
            onPressed: () => _handleNextStep(model),
            style: ElevatedButton.styleFrom(
              backgroundColor: darkGreen,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(
              "Next", 
              style: textTheme.labelLarge?.copyWith(color: Colors.white)
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileIcon(BuildContext context, bool isDark) => InkWell(
    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const UserProfileScreen())),
    child: Container(
      height: 36, width: 36,
      decoration: BoxDecoration(color: isDark ? Colors.white10 : const Color(0xFFF0F4F0), borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.black12)),
      child: const Icon(Icons.person_outline, color: Colors.black54, size: 20),
    ),
  );
}