import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme_provider.dart';
import '../theme_constants.dart';

class UserManualScreen extends StatelessWidget {
  final String role;

  const UserManualScreen({super.key, this.role = 'user'});

  bool get isEmployee => role.toLowerCase() == 'employee' || role.toLowerCase() == 'admin';

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFEAF7EA),
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF1F1F1F) : Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: getTextColor(isDark)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          isEmployee ? "Employee User Manual" : "User Manual",
          style: textTheme.titleMedium?.copyWith(
            fontSize: 18,
            color: getTextColor(isDark),
            fontFamily: 'Poppins-Bold',
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: isEmployee ? _buildEmployeeManual(isDark) : _buildVisitorManual(isDark),
      ),
    );
  }

  // --- VISITOR / STANDARD USER MANUAL CONTENT ---

  Widget _buildVisitorManual(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeaderCard(
          isDark: isDark,
          title: "User Dashboard",
          subtitle:
              "The User Dashboard serves as your primary hub:\n\n• Featured Species: Highlights rare, endangered, or popular flora.\n• Quick Action Bar: Fast access to the Botanical Gallery, AR Camera, and Notifications.\n• Ecological Insights: Daily tips, conservation announcements, and environmental news.",
          icon: Icons.dashboard_customize_rounded,
        ),
        const SizedBox(height: 20),
        _buildManualSection(
          isDark: isDark,
          icon: Icons.local_florist_rounded,
          title: "Botanical Gallery & Species Catalog",
          content:
              "Discover and learn about various tree and plant species (e.g., Narra, Red Rose, Paho, and other regional flora).\n\nBrowsing & Filtering\n• Tap Botanical Gallery from the dashboard.\n• Search Bar: Type the common or scientific name of a plant to find specific entries.\n• Filter & Sort: Filter species by categories such as Growth Type, Native Region, Conservation Status, or Plant Family.\n\nViewing Plant Details\nTap on any plant card to open its detailed profile, which includes:\n• Common and Scientific Names\n• Detailed Descriptions & Ecological Roles\n• Habitat & Native Growth Regions\n• Conservation Status Indicators",
        ),
        const SizedBox(height: 14),
        _buildManualSection(
          isDark: isDark,
          icon: Icons.view_in_ar_rounded,
          title: "Augmented Reality (AR) Plant Viewer & AR Camera",
          content:
              "GreenAtlas lets you project life-sized 3D interactive models of plants into your real-world environment using your smartphone camera.\n\nLaunching AR View\n• Open the AR View from the main dashboard or directly from a plant's detail page in the Botanical Gallery.\n• Grant camera and location permissions when prompted.\n\nPlacing & Interacting with 3D Models\n• Move your camera slowly around a flat horizontal surface (such as a floor, tabletop, or ground outdoors) until plane detection highlights the target area.\n• Tap on the surface screen indicator to place the selected 3D plant model (e.g., a Narra tree or Rose bush).\n• Gestures & Controls:\n   - Rotate: Pinch and rotate with two fingers to rotate the plant.\n   - Scale / Zoom: Pinch outwards or inwards to enlarge or shrink the model.\n   - Move: Drag the object along the surface.\n• AR Camera Mode: Tap the camera icon to capture snapshots of the 3D plant integrated into your real-world surroundings. Photos can be saved directly to your device gallery or shared.",
        ),
        const SizedBox(height: 14),
        _buildManualSection(
          isDark: isDark,
          icon: Icons.notifications_active_rounded,
          title: "User Notifications",
          content:
              "Stay informed with real-time updates:\n\n• Tap the Bell Icon on the top app bar to open Notifications.\n• View updates regarding new plant additions, system announcements, and conservation activities.\n• Swipe or tap to mark notifications as read.",
        ),
        const SizedBox(height: 14),
        _buildManualSection(
          isDark: isDark,
          icon: Icons.quiz_rounded,
          title: "Troubleshooting & Frequently Asked Questions (FAQ)",
          content:
              "Q1: The AR model is not appearing on my screen. What should I do?\nAnswer: Ensure you are in a well-lit environment and point your camera toward a flat, textured surface (like grass or flooring). Move your phone slowly side-to-side until the surface is detected. Also verify that camera permissions are enabled for GreenAtlas in your phone's settings.\n\nQ2: I forgot my account password. How can I reset it?\nAnswer: On the login screen, tap Forgot Password?, enter your registered email address, and follow the instructions sent to your inbox to reset your password.",
        ),
        const SizedBox(height: 30),
      ],
    );
  }

  // --- EMPLOYEE & FIELD OFFICER MANUAL CONTENT ---

  Widget _buildEmployeeManual(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeaderCard(
          isDark: isDark,
          title: "Employee Dashboard",
          subtitle:
              "Upon logging in with employee credentials, you are directed to the Employee Dashboard:\n\n• Field Diary Quick Access: View active draft entries, pending submissions, and recent field logs.\n• Upcoming Meetings: Summary of required briefings, assembly calls, and field meetings.\n• Field Statistics: Quick metrics on submitted reports and observations.",
          icon: Icons.badge_outlined,
        ),
        const SizedBox(height: 20),
        _buildManualSection(
          isDark: isDark,
          icon: Icons.edit_location_alt_outlined,
          title: "Field Diary & Observation Logging",
          content:
              "The Field Diary allows officers to record plant and environmental observations directly on-site, even without an internet connection.\n\nCollecting a New Field Observation\n• Navigate to Field Diary from the Employee Dashboard.\n• Tap Collect / New Entry.\n• Fill in the observation parameters:\n   - Species / Plant Name: Enter the identified plant or tree name.\n   - GPS Location Tag: Tap Fetch Current Location to record precise latitude and longitude coordinates via your device's GPS.\n   - Photo Evidence: Tap Add Photo to capture a photo with your device camera or select an image from your gallery.\n   - Health & Habitat Notes: Note the plant's health condition, surrounding environment, soil type, or environmental threats.\n• Choose an action:\n   - Save as Draft: Saves the entry locally on your device for editing later (ideal for low-connectivity zones).\n   - Submit / Send: Uploads the observation directly to the central database when connected to the network.\n\nManaging Drafts & Sent Entries\n• Drafts Tab: View, edit, or finalize saved offline observations before uploading.\n• Sent Tab: View history of successfully synced field observation reports.\n• Clear / Delete: Remove unnecessary local drafts or clear processed logs.",
        ),
        const SizedBox(height: 14),
        _buildManualSection(
          isDark: isDark,
          icon: Icons.event_available_outlined,
          title: "Employee Meetings & Attendance Management",
          content:
              "Stay synchronized with field operation schedules and team meetings.\n\nViewing Scheduled Meetings\n• Tap Employee Meetings on the navigation menu.\n• Browse upcoming, required, and past meeting events.\n• Tap a meeting card to view details: Agenda, Date, Time, Venue/Location, and Presenter.\n\nMarking Meeting Attendance\n• Open the target meeting from your schedule.\n• Tap Confirm Attendance or scan an event QR code if provided at the meeting venue.\n• Your attendance status will update instantly to Attended.\n\nSubmitting \"Cannot Attend\" Notices\nIf you are unable to attend a mandatory briefing or field meeting:\n• Select the specific meeting from the schedule.\n• Tap Cannot Attend.\n• Select an official reason (e.g., Active Field Duty, Medical, Official Leave) and provide a brief explanation in the reason box.\n• Tap Submit Excusal Request. Your supervisor will be notified of your absence justification.",
        ),
        const SizedBox(height: 14),
        _buildManualSection(
          isDark: isDark,
          icon: Icons.notifications_active_outlined,
          title: "Staff Notifications & Alerts",
          content:
              "Field officers receive targeted notifications regarding:\n\n• New field assignment updates.\n• Urgent meeting calls or agenda changes.\n• Sync confirmations for submitted Field Diary records.",
        ),
        const SizedBox(height: 14),
        _buildManualSection(
          isDark: isDark,
          icon: Icons.cloud_off_rounded,
          title: "Offline Access & Data Synchronization",
          content:
              "GreenAtlas is built for field reliability:\n\n• Offline Storage: Field Diary drafts, cached botanical species, and essential user settings remain accessible without internet connectivity.\n• Automatic Sync: When your device reconnects to Cellular Data or Wi-Fi, any saved offline field entries will automatically prompt for synchronization to update the central server.",
        ),
        const SizedBox(height: 14),
        _buildManualSection(
          isDark: isDark,
          icon: Icons.quiz_rounded,
          title: "Troubleshooting & Frequently Asked Questions (FAQ)",
          content:
              "Q1: How do I capture location coords when offline in the field?\nAnswer: Your mobile device's built-in GPS does not require mobile internet data to acquire latitude and longitude coordinates. Simply tap Fetch Current Location in the Field Diary while outdoors.\n\nQ2: I forgot my account password. How can I reset it?\nAnswer: On the login screen, tap Forgot Password?, enter your registered email address, and follow the instructions sent to your inbox to reset your password.",
        ),
        const SizedBox(height: 30),
      ],
    );
  }

  // --- REUSABLE UI CARDS ---

  Widget _buildHeaderCard({
    required bool isDark,
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF253326) : const Color(0xFFD4E8D4),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: isDark ? leafAccent.withValues(alpha: 0.5) : const Color(0xFF5D7A5D).withValues(alpha: 0.4),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: isDark ? leafAccent : const Color(0xFF2D3E2D), size: 28),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontFamily: 'Poppins-Bold',
                    fontSize: 16,
                    color: isDark ? Colors.white : const Color(0xFF2D3E2D),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              height: 1.4,
              color: isDark ? Colors.white70 : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildManualSection({
    required bool isDark,
    required IconData icon,
    required String title,
    required String content,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1F1F1F) : Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: isDark ? Colors.white12 : const Color(0xFF5D7A5D).withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: isDark ? leafAccent : const Color(0xFF5D7A5D), size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontFamily: 'Poppins-Bold',
                    fontSize: 14,
                    color: isDark ? Colors.white : const Color(0xFF2D3E2D),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              height: 1.4,
              color: isDark ? Colors.white70 : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}
