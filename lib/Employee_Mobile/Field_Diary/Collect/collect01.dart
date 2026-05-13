import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import '../Collect/observation_model.dart';
import '../../../theme_provider.dart';
import 'collect2.dart';
import '../../../UserProfile/user_profile.dart';
import '../../EmployeeNotification/employeenotif.dart';
import '../../../components/notification_badge.dart';
import '../Employee_FieldDiary.dart'; 
import '../clearentry.dart'; 

class CollectStep1Screen extends StatefulWidget {
  const CollectStep1Screen({super.key});

  @override
  State<CollectStep1Screen> createState() => _CollectStep1ScreenState();
}

class _CollectStep1ScreenState extends State<CollectStep1Screen> {
  final _supabase = Supabase.instance.client;
  bool _isMembersExpanded = true;
  Key _formKey = UniqueKey();

  final Color darkGreen = const Color(0xFF2D3E2D);
  final Color forestGreen = const Color(0xFF5D7A5D);

  // Define the roles for the dropdown
  final List<String> _userRoles = [
    'Field Observer',
    'Team Leader',
    'Data Recorder',
    'Botanist',
    'Zoologist',
    'Volunteer'
  ];

  @override
  void initState() {
    super.initState();
    final user = _supabase.auth.currentUser;
    if (user != null) {
      Future.microtask(() {
        final model = context.read<ObservationModel>();
        model.userId = user.id;
        model.observerName = "FO-12345"; 
        model.updateData();
      });
    }
  }

  void _addMember(ObservationModel model) {
    setState(() {
      model.members.add({'firstname': '', 'lastname': '', 'role': ''});
    });
  }

  void _removeMember(int index, ObservationModel model) {
    if (model.members.length > 1) {
      setState(() {
        model.members.removeAt(index);
      });
    } else {
      setState(() {
        model.members[0] = {'firstname': '', 'lastname': '', 'role': ''};
        _formKey = UniqueKey(); 
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Member entries cleared"), duration: Duration(seconds: 1)),
      );
    }
  }

  void _handleClearAll(ObservationModel model) {
    setState(() {
      model.reset();
      _formKey = UniqueKey();
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("All form entries cleared"), duration: Duration(seconds: 1)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;
    final model = Provider.of<ObservationModel>(context);
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFEAF7EA),
      body: Column(
        children: [
          _buildTopNavBar(context, isDark, textTheme),
          _buildSecondaryHeader(context, model, textTheme),
          Expanded(
            child: ListView(
              key: _formKey, 
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              children: [
                Text(
                  "Step 1 of 3", 
                  style: textTheme.labelSmall?.copyWith(color: Colors.black45)
                ),
                const SizedBox(height: 4),
                Text(
                  "Basic Information", 
                  style: textTheme.headlineSmall?.copyWith(color: darkGreen)
                ),
                const SizedBox(height: 24),
                _buildObserverCard(isDark, model, textTheme),
                const SizedBox(height: 20),
                _buildMembersSection(isDark, model, textTheme),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomStepper(context, textTheme),
    );
  }

  // --- UI COMPONENTS ---

  Widget _buildMembersSection(bool isDark, ObservationModel model, TextTheme textTheme) {
    return Container(
      decoration: _cardDecoration(isDark),
      child: Column(
        children: [
          ListTile(
            title: Text(
              "Members", 
              style: textTheme.titleLarge?.copyWith(color: darkGreen, fontSize: 16)
            ),
            trailing: Icon(_isMembersExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down),
            onTap: () => setState(() => _isMembersExpanded = !_isMembersExpanded),
          ),
          if (_isMembersExpanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Column(
                children: [
                  ...model.members.asMap().entries.map((entry) => _buildMemberBlock(entry.key, model, textTheme)),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => _addMember(model),
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text("Add Member"),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: forestGreen,
                        side: BorderSide(color: forestGreen.withOpacity(0.3)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMemberBlock(int index, ObservationModel model, TextTheme textTheme) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF9F9F9), 
        borderRadius: BorderRadius.circular(12), 
        border: Border.all(color: Colors.black.withOpacity(0.05))
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Member ${index + 1}", 
                style: textTheme.labelSmall?.copyWith(color: Colors.black38)
              ),
              GestureDetector(
                onTap: () => _removeMember(index, model),
                child: const Icon(Icons.close, size: 18, color: Colors.redAccent),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildMemberInput("Firstname", "Enter firstname", model.members[index]['firstname']!, (v) => model.members[index]['firstname'] = v, textTheme),
          const SizedBox(height: 12),
          _buildMemberInput("Lastname", "Enter lastname", model.members[index]['lastname']!, (v) => model.members[index]['lastname'] = v, textTheme),
          const SizedBox(height: 12),
          // Changed from _buildMemberInput to _buildMemberDropdown for User Role
          _buildMemberDropdown("User Role", model.members[index]['role']!, (v) => setState(() => model.members[index]['role'] = v!), textTheme),
        ],
      ),
    );
  }

  Widget _buildMemberInput(String label, String placeholder, String initialValue, Function(String) onChanged, TextTheme textTheme) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: textTheme.labelSmall?.copyWith(color: Colors.black54)),
      const SizedBox(height: 4),
      TextFormField(
        initialValue: initialValue,
        onChanged: onChanged,
        style: textTheme.bodyMedium?.copyWith(color: Colors.black87),
        decoration: InputDecoration(
          hintText: placeholder,
          hintStyle: textTheme.bodyMedium?.copyWith(color: Colors.black26, fontSize: 13),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Colors.black12)),
        ),
      ),
    ],
  );

  // New Helper for the Role Dropdown
  Widget _buildMemberDropdown(String label, String currentValue, Function(String?) onChanged, TextTheme textTheme) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: textTheme.labelSmall?.copyWith(color: Colors.black54)),
      const SizedBox(height: 4),
      DropdownButtonFormField<String>(
        value: currentValue.isEmpty ? null : currentValue,
        onChanged: onChanged,
        style: textTheme.bodyMedium?.copyWith(color: Colors.black87),
        items: _userRoles.map((role) {
          return DropdownMenuItem(
            value: role,
            child: Text(role),
          );
        }).toList(),
        decoration: InputDecoration(
          hintText: "Select role",
          hintStyle: textTheme.bodyMedium?.copyWith(color: Colors.black26, fontSize: 13),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Colors.black12)),
        ),
      ),
    ],
  );

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
            style: textTheme.titleLarge?.copyWith(
              color: isDark ? Colors.white : darkGreen,
              fontWeight: FontWeight.bold,
            )
          ),
          const Spacer(),
          EmployeeNotificationBadge(iconColor: isDark ? Colors.white70 : Colors.black87),
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
            onPressed: () => Navigator.pop(context),
          ),
          Text(
            "BMS Field Observation", 
            style: textTheme.titleSmall?.copyWith(color: Colors.white)
          ),
          TextButton(
            onPressed: () => showDialog(
              context: context,
              builder: (context) => ClearEntryDialog(
                onClear: () => _handleClearAll(model), 
              ),
            ), 
            child: Text(
              "Clear all", 
              style: textTheme.bodySmall?.copyWith(color: Colors.white70)
            )
          ),
        ],
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

  Widget _buildObserverCard(bool isDark, ObservationModel model, TextTheme textTheme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(isDark),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Observer", 
            style: textTheme.titleLarge?.copyWith(color: darkGreen, fontSize: 16)
          ),
          const SizedBox(height: 12),
          _buildLabel("User ID *", textTheme),
          const SizedBox(height: 8),
          _buildDisabledField(model.observerName, textTheme),
        ],
      ),
    );
  }

  Widget _buildBottomStepper(BuildContext context, TextTheme textTheme) {
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
            "1 of 3", 
            style: textTheme.titleSmall?.copyWith(color: Colors.black54)
          ),
          ElevatedButton(
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CollectStep2Screen())),
            style: ElevatedButton.styleFrom(
              backgroundColor: darkGreen, 
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12), 
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
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

  BoxDecoration _cardDecoration(bool d) => BoxDecoration(
    color: d ? const Color(0xFF1F1F1F) : Colors.white,
    borderRadius: BorderRadius.circular(16),
    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10)],
  );

  Widget _buildDisabledField(String value, TextTheme textTheme) => Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    decoration: BoxDecoration(color: const Color(0xFFF0F0F0), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.black.withOpacity(0.05))),
    child: Text(
      value, 
      style: textTheme.titleSmall?.copyWith(color: Colors.black87)
    ),
  );

  Widget _buildProfileIcon(BuildContext context, bool isDark) => InkWell(
    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const UserProfileScreen())),
    child: Container(
      height: 36, width: 36,
      decoration: BoxDecoration(color: const Color(0xFFF0F4F0), borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.black12)),
      child: const Icon(Icons.person_outline, color: Colors.black54, size: 20),
    ),
  );
}