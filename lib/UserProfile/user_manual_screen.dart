import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme_provider.dart';
import '../theme_constants.dart';

// ============================================================================
// DATA MODELS FOR INTERACTIVE USER MANUAL
// ============================================================================

class HotspotPinData {
  final int number;
  final String label;
  final double topPercent; // 0.0 to 1.0
  final double leftPercent; // 0.0 to 1.0
  final String tooltipPosition; // 'top', 'bottom', 'left', 'right'

  const HotspotPinData({
    required this.number,
    required this.label,
    required this.topPercent,
    required this.leftPercent,
    this.tooltipPosition = 'top',
  });
}

class ManualStepItem {
  final int number;
  final String title;
  final String desc;

  const ManualStepItem({
    required this.number,
    required this.title,
    required this.desc,
  });
}

// ============================================================================
// MAIN USER MANUAL SCREEN
// ============================================================================

class UserManualScreen extends StatefulWidget {
  final String role;

  const UserManualScreen({super.key, this.role = 'user'});

  @override
  State<UserManualScreen> createState() => _UserManualScreenState();
}

class _UserManualScreenState extends State<UserManualScreen> {
  String _selectedCategory = 'ALL';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  final Map<String, bool> _openFaqs = {};

  bool get isEmployee =>
      widget.role.toLowerCase() == 'employee' ||
      widget.role.toLowerCase() == 'admin';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _toggleFaq(String key) {
    setState(() {
      _openFaqs[key] = !(_openFaqs[key] ?? false);
    });
  }

  bool _isFaqOpen(String key) => _openFaqs[key] ?? false;

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF101410) : const Color(0xFFF3F7F3),
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF1B231C) : Colors.white,
        elevation: 0,
        scrolledUnderElevation: 1,
        shadowColor: Colors.black26,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: getTextColor(isDark)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isEmployee ? "Employee User Manual" : "Visitor User Manual",
              style: textTheme.titleMedium?.copyWith(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: getTextColor(isDark),
                fontFamily: 'Poppins-Bold',
              ),
            ),
            Text(
              "Visual Step Hotspots & Interface Guide",
              style: TextStyle(
                fontSize: 11,
                color: isDark ? leafAccent : primaryForest,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Filter & Search Controls Bar
          _buildFilterBar(isDark),

          // Main Scrollable Manual Body
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: isEmployee
                  ? _buildEmployeeManual(isDark)
                  : _buildVisitorManual(isDark),
            ),
          ),
        ],
      ),
    );
  }

  // --------------------------------------------------------------------------
  // TOP FILTER & SEARCH BAR
  // --------------------------------------------------------------------------

  Widget _buildFilterBar(bool isDark) {
    final categories = isEmployee
        ? [
            {'key': 'ALL', 'label': 'All Sections'},
            {'key': 'DASHBOARD', 'label': '1. Dashboard'},
            {'key': 'DIARY', 'label': '2. Field Diary'},
            {'key': 'MEETINGS', 'label': '3. Meetings'},
            {'key': 'SYNC', 'label': '4. Offline Sync'},
            {'key': 'FAQ', 'label': '5. FAQ'},
          ]
        : [
            {'key': 'ALL', 'label': 'All Sections'},
            {'key': 'DASHBOARD', 'label': '1. Dashboard'},
            {'key': 'GALLERY', 'label': '2. Botanical Gallery'},
            {'key': 'AR', 'label': '3. AR Plant Viewer'},
            {'key': 'NOTIFS', 'label': '4. Notifications'},
            {'key': 'FAQ', 'label': '5. FAQ'},
          ];

    return Container(
      width: double.infinity,
      color: isDark ? const Color(0xFF1B231C) : Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Column(
        children: [
          // Search Box
          Container(
            height: 40,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF242F26) : const Color(0xFFF1F5F1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark ? Colors.white12 : const Color(0xFFE0E8E0),
              ),
            ),
            child: TextField(
              controller: _searchController,
              onChanged: (val) => setState(() => _searchQuery = val.trim().toLowerCase()),
              style: TextStyle(
                fontSize: 13,
                color: isDark ? Colors.white : Colors.black87,
              ),
              decoration: InputDecoration(
                hintText: "Filter manual steps or controls...",
                hintStyle: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.white38 : Colors.grey[500],
                ),
                prefixIcon: Icon(
                  Icons.search_rounded,
                  size: 18,
                  color: isDark ? leafAccent : primaryForest,
                ),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded, size: 16),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                contentPadding: const EdgeInsets.symmetric(vertical: 8),
                border: InputBorder.none,
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Category Chips Row
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: categories.map((cat) {
                final isSelected = _selectedCategory == cat['key'];
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: FilterChip(
                    label: Text(
                      cat['label']!,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                        color: isSelected
                            ? Colors.white
                            : (isDark ? Colors.white70 : const Color(0xFF2D3E2D)),
                      ),
                    ),
                    selected: isSelected,
                    onSelected: (_) => setState(() => _selectedCategory = cat['key']!),
                    backgroundColor: isDark ? const Color(0xFF242F26) : const Color(0xFFF1F5F1),
                    selectedColor: primaryForest,
                    showCheckmark: false,
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(
                        color: isSelected
                            ? primaryForest
                            : (isDark ? Colors.white10 : Colors.transparent),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  // --------------------------------------------------------------------------
  // VISITOR / PUBLIC USER MANUAL SECTIONS
  // --------------------------------------------------------------------------

  Widget _buildVisitorManual(bool isDark) {
    final showAll = _selectedCategory == 'ALL';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Scope banner
        _buildScopeBanner(
          isDark: isDark,
          title: "Public Explorer & Sanctuary Visitor Edition",
          subtitle:
              "Navigate flora databases, launch life-sized 3D augmented reality models, and monitor live sanctuary ecological conditions.",
          icon: Icons.nature_people_rounded,
        ),
        const SizedBox(height: 16),

        // SECTION 1: DASHBOARD
        if (showAll || _selectedCategory == 'DASHBOARD')
          InteractiveManualStepCard(
            isDark: isDark,
            stepNumber: "1.1",
            title: "User Dashboard & Ecological Telemetry",
            category: "Primary Sanctuary Hub",
            icon: Icons.dashboard_customize_rounded,
            introText:
                "The central landing hub for discovering featured sanctuary species, inspecting live weather, and launching core botanical tools:",
            items: const [
              ManualStepItem(
                number: 1,
                title: "Notification Bell & System Alerts",
                desc: "Tap the Bell icon in the top header to inspect real-time announcements, severe climate warnings, and newly cataloged regional plants.",
              ),
              ManualStepItem(
                number: 2,
                title: "Real-Time Sanctuary Weather Telemetry",
                desc: "Displays live Cavite Sanctuary temperature (e.g. 29°C), humidity, and solar conditions with danger warnings when thresholds are breached.",
              ),
              ManualStepItem(
                number: 3,
                title: "Featured Botanical Species Hero Showcase",
                desc: "Spotlights rare or endangered sanctuary flora (such as the Philippine Narra tree) with conservation badges and direct profile shortcuts.",
              ),
              ManualStepItem(
                number: 4,
                title: "Quick Action Launchpad",
                desc: "One-touch launcher buttons to jump immediately into the Botanical Gallery catalog, launch the AR Camera, or view the sanctuary map.",
              ),
            ],
            pins: const [
              HotspotPinData(
                number: 1,
                label: "Notification Bell",
                topPercent: 0.12,
                leftPercent: 0.88,
                tooltipPosition: 'left',
              ),
              HotspotPinData(
                number: 2,
                label: "Cavite Weather Telemetry",
                topPercent: 0.28,
                leftPercent: 0.50,
                tooltipPosition: 'bottom',
              ),
              HotspotPinData(
                number: 3,
                label: "Featured Species Card",
                topPercent: 0.52,
                leftPercent: 0.50,
                tooltipPosition: 'bottom',
              ),
              HotspotPinData(
                number: 4,
                label: "Quick Action Launchpad",
                topPercent: 0.80,
                leftPercent: 0.50,
                tooltipPosition: 'top',
              ),
            ],
            buildMockupScreen: (ctx, activeHotspot) =>
                _buildVisitorDashboardMockup(isDark, activeHotspot),
          ),

        if (showAll || _selectedCategory == 'DASHBOARD') const SizedBox(height: 18),

        // SECTION 2: BOTANICAL GALLERY
        if (showAll || _selectedCategory == 'GALLERY')
          InteractiveManualStepCard(
            isDark: isDark,
            stepNumber: "1.2",
            title: "Botanical Gallery & Species Catalog",
            category: "Species Taxonomy & Search",
            icon: Icons.local_florist_rounded,
            introText:
                "Browse regional flora, filter species by conservation status, and inspect botanical profiles:",
            items: const [
              ManualStepItem(
                number: 1,
                title: "Botanical Search Bar",
                desc: "Search by common name (e.g. 'Narra', 'Red Rose') or scientific binomial (e.g. 'Pterocarpus indicus') to quickly locate plant entries.",
              ),
              ManualStepItem(
                number: 2,
                title: "Taxonomy & Status Filter Chips",
                desc: "Filter results by growth habit (Trees, Shrubs, Herbs) or conservation vulnerability status (Endangered, Vulnerable, Least Concern).",
              ),
              ManualStepItem(
                number: 3,
                title: "Species Identification Card",
                desc: "Displays botanical imagery, native family, region origin, and threat levels. Tap anywhere on the card to open the deep profile.",
              ),
              ManualStepItem(
                number: 4,
                title: "Launch 3D AR Viewer Button",
                desc: "Tap the emerald 'View in 3D AR' badge on any plant card to instantly project the full-scale interactive 3D model into your space.",
              ),
            ],
            pins: const [
              HotspotPinData(
                number: 1,
                label: "Species Search Bar",
                topPercent: 0.16,
                leftPercent: 0.50,
                tooltipPosition: 'bottom',
              ),
              HotspotPinData(
                number: 2,
                label: "Filter & Status Chips",
                topPercent: 0.32,
                leftPercent: 0.50,
                tooltipPosition: 'bottom',
              ),
              HotspotPinData(
                number: 3,
                label: "Botanical Plant Card",
                topPercent: 0.60,
                leftPercent: 0.50,
                tooltipPosition: 'bottom',
              ),
              HotspotPinData(
                number: 4,
                label: "View in 3D AR Button",
                topPercent: 0.74,
                leftPercent: 0.76,
                tooltipPosition: 'left',
              ),
            ],
            buildMockupScreen: (ctx, activeHotspot) =>
                _buildBotanicalGalleryMockup(isDark, activeHotspot),
          ),

        if (showAll || _selectedCategory == 'GALLERY') const SizedBox(height: 18),

        // SECTION 3: AR PLANT VIEWER & CAMERA
        if (showAll || _selectedCategory == 'AR')
          InteractiveManualStepCard(
            isDark: isDark,
            stepNumber: "1.3",
            title: "Augmented Reality (AR) Plant Viewer & Camera",
            category: "Immersive 3D Visualization",
            icon: Icons.view_in_ar_rounded,
            introText:
                "Project lifelike 3D plant models onto flat physical surfaces using mobile AR plane tracking:",
            items: const [
              ManualStepItem(
                number: 1,
                title: "Surface Plane Detection Reticle",
                desc: "Move your phone slowly over a textured floor, table, or ground. A glowing dotted green reticle indicates surface lock.",
              ),
              ManualStepItem(
                number: 2,
                title: "3D Plant Projection",
                desc: "Tap the plane reticle to spawn the life-sized 3D plant model. The model renders with realistic textures and sunlight shadows.",
              ),
              ManualStepItem(
                number: 3,
                title: "Multi-Touch Gesture Controls",
                desc: "Two-finger pinch to scale model dimensions up or down; twist fingers to rotate azimuth; drag with one finger to relocate.",
              ),
              ManualStepItem(
                number: 4,
                title: "AR Camera Shutter Button",
                desc: "Tap the circular camera shutter at the bottom center to capture high-definition snapshots of the augmented plant in your environment.",
              ),
            ],
            pins: const [
              HotspotPinData(
                number: 1,
                label: "Plane Detection Grid",
                topPercent: 0.42,
                leftPercent: 0.50,
                tooltipPosition: 'top',
              ),
              HotspotPinData(
                number: 2,
                label: "3D Holographic Model",
                topPercent: 0.48,
                leftPercent: 0.50,
                tooltipPosition: 'bottom',
              ),
              HotspotPinData(
                number: 3,
                label: "Gesture Controls Guide",
                topPercent: 0.18,
                leftPercent: 0.50,
                tooltipPosition: 'bottom',
              ),
              HotspotPinData(
                number: 4,
                label: "AR Camera Shutter Button",
                topPercent: 0.86,
                leftPercent: 0.50,
                tooltipPosition: 'top',
              ),
            ],
            buildMockupScreen: (ctx, activeHotspot) =>
                _buildArCameraMockup(isDark, activeHotspot),
          ),

        if (showAll || _selectedCategory == 'AR') const SizedBox(height: 18),

        // SECTION 4: NOTIFICATIONS
        if (showAll || _selectedCategory == 'NOTIFS')
          InteractiveManualStepCard(
            isDark: isDark,
            stepNumber: "1.4",
            title: "Sanctuary Notifications & Alerts",
            category: "Real-Time Updates",
            icon: Icons.notifications_active_rounded,
            introText:
                "Stay informed on newly cataloged botanical entries, severe climate advisories, and sanctuary activities:",
            items: const [
              ManualStepItem(
                number: 1,
                title: "Mark All as Read Action",
                desc: "Tap 'Mark all read' in the top right to clear unread notification badges in a single tap.",
              ),
              ManualStepItem(
                number: 2,
                title: "Botanical Flora Discovery Alerts",
                desc: "Notifies you when administrators publish newly verified species or update habitat profiles.",
              ),
              ManualStepItem(
                number: 3,
                title: "Sanctuary Climate Warning Advisory",
                desc: "Immediate advisory notifications dispatched when local weather sensors register temperature extremes exceeding safe thresholds.",
              ),
            ],
            pins: const [
              HotspotPinData(
                number: 1,
                label: "Mark All Read Action",
                topPercent: 0.14,
                leftPercent: 0.82,
                tooltipPosition: 'left',
              ),
              HotspotPinData(
                number: 2,
                label: "New Flora Alert Card",
                topPercent: 0.38,
                leftPercent: 0.50,
                tooltipPosition: 'bottom',
              ),
              HotspotPinData(
                number: 3,
                label: "Climate Warning Advisory",
                topPercent: 0.65,
                leftPercent: 0.50,
                tooltipPosition: 'bottom',
              ),
            ],
            buildMockupScreen: (ctx, activeHotspot) =>
                _buildVisitorNotificationsMockup(isDark, activeHotspot),
          ),

        if (showAll || _selectedCategory == 'NOTIFS') const SizedBox(height: 18),

        // SECTION 5: FAQ & TROUBLESHOOTING
        if (showAll || _selectedCategory == 'FAQ') _buildVisitorFaq(isDark),
      ],
    );
  }

  // --------------------------------------------------------------------------
  // EMPLOYEE / FIELD OFFICER MANUAL SECTIONS
  // --------------------------------------------------------------------------

  Widget _buildEmployeeManual(bool isDark) {
    final showAll = _selectedCategory == 'ALL';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Scope banner
        _buildScopeBanner(
          isDark: isDark,
          title: "Field Officer & Ranger Operational Scope",
          subtitle:
              "Field Diary collection, GPS coordinate geo-tagging, offline draft caching, team meeting attendance, and cloud synchronization.",
          icon: Icons.badge_outlined,
        ),
        const SizedBox(height: 16),

        // SECTION 1: EMPLOYEE DASHBOARD
        if (showAll || _selectedCategory == 'DASHBOARD')
          InteractiveManualStepCard(
            isDark: isDark,
            stepNumber: "2.1",
            title: "Employee Dashboard & Ranger Hub",
            category: "Operational Headquarters",
            icon: Icons.badge_rounded,
            introText:
                "Access active draft observation logs, check scheduled briefing meetings, and view individual validation metrics:",
            items: const [
              ManualStepItem(
                number: 1,
                title: "Ranger Identity & Credential Badge",
                desc: "Displays your registered Field Officer name, unique Officer ID (e.g. FO-104), and assigned sanctuary sector.",
              ),
              ManualStepItem(
                number: 2,
                title: "Field Diary Quick Launcher Card",
                desc: "Displays count of pending offline drafts. Tap anywhere to open the observation collection pipeline.",
              ),
              ManualStepItem(
                number: 3,
                title: "Upcoming Briefing & Meetings Card",
                desc: "Shows time and agenda for upcoming mandatory field team meetings with direct attendance shortcuts.",
              ),
              ManualStepItem(
                number: 4,
                title: "Specimen Validation Metric Cards",
                desc: "Live counts of your submitted field observations, showing verified/approved counts versus pending QC reviews.",
              ),
            ],
            pins: const [
              HotspotPinData(
                number: 1,
                label: "Officer ID Badge",
                topPercent: 0.16,
                leftPercent: 0.50,
                tooltipPosition: 'bottom',
              ),
              HotspotPinData(
                number: 2,
                label: "Field Diary Launcher",
                topPercent: 0.38,
                leftPercent: 0.50,
                tooltipPosition: 'bottom',
              ),
              HotspotPinData(
                number: 3,
                label: "Upcoming Meeting Card",
                topPercent: 0.60,
                leftPercent: 0.50,
                tooltipPosition: 'bottom',
              ),
              HotspotPinData(
                number: 4,
                label: "Personal Validation Metrics",
                topPercent: 0.82,
                leftPercent: 0.50,
                tooltipPosition: 'top',
              ),
            ],
            buildMockupScreen: (ctx, activeHotspot) =>
                _buildEmployeeDashboardMockup(isDark, activeHotspot),
          ),

        if (showAll || _selectedCategory == 'DASHBOARD') const SizedBox(height: 18),

        // SECTION 2: FIELD DIARY & OBSERVATION LOGGING
        if (showAll || _selectedCategory == 'DIARY')
          InteractiveManualStepCard(
            isDark: isDark,
            stepNumber: "2.2",
            title: "Field Diary & Specimen Data Logging",
            category: "Data Collection & Geo-Tagging",
            icon: Icons.edit_location_alt_outlined,
            introText:
                "Log plant specimens directly in the field, fetch device GPS coordinates, attach camera evidence, and save offline drafts:",
            items: const [
              ManualStepItem(
                number: 1,
                title: "+ New Entry Action Button",
                desc: "Tap the prominent '+' button on the top right or floating button to start recording a new botanical observation.",
              ),
              ManualStepItem(
                number: 2,
                title: "Plant / Species Name Input",
                desc: "Input preliminary species identification or common name (e.g. 'Narra Sapling Sector 4') with habitat notes.",
              ),
              ManualStepItem(
                number: 3,
                title: "Fetch Current GPS Location",
                desc: "Tap the satellite button. Built-in device hardware GPS locks coordinates (Latitude & Longitude) even without mobile internet.",
              ),
              ManualStepItem(
                number: 4,
                title: "Photo Evidence Camera Uploader",
                desc: "Tap 'Add Photo' to take a clear photo of the specimen leaf, bark, or canopy using your smartphone camera.",
              ),
              ManualStepItem(
                number: 5,
                title: "Save Draft vs Submit Buttons",
                desc: "Tap 'Save Draft' if in remote deep-forest areas with zero signal; tap 'Submit' when ready to upload to the admin verification queue.",
              ),
            ],
            pins: const [
              HotspotPinData(
                number: 1,
                label: "+ New Entry Action",
                topPercent: 0.12,
                leftPercent: 0.86,
                tooltipPosition: 'left',
              ),
              HotspotPinData(
                number: 2,
                label: "Species Name Input",
                topPercent: 0.28,
                leftPercent: 0.50,
                tooltipPosition: 'bottom',
              ),
              HotspotPinData(
                number: 3,
                label: "Fetch GPS Location Button",
                topPercent: 0.44,
                leftPercent: 0.50,
                tooltipPosition: 'bottom',
              ),
              HotspotPinData(
                number: 4,
                label: "Photo Evidence Uploader",
                topPercent: 0.62,
                leftPercent: 0.50,
                tooltipPosition: 'bottom',
              ),
              HotspotPinData(
                number: 5,
                label: "Draft & Submit Buttons",
                topPercent: 0.86,
                leftPercent: 0.50,
                tooltipPosition: 'top',
              ),
            ],
            buildMockupScreen: (ctx, activeHotspot) =>
                _buildFieldDiaryMockup(isDark, activeHotspot),
          ),

        if (showAll || _selectedCategory == 'DIARY') const SizedBox(height: 18),

        // SECTION 3: EMPLOYEE MEETINGS & ATTENDANCE
        if (showAll || _selectedCategory == 'MEETINGS')
          InteractiveManualStepCard(
            isDark: isDark,
            stepNumber: "2.3",
            title: "Meeting Schedules & Attendance Verification",
            category: "Operations Coordination",
            icon: Icons.event_available_outlined,
            introText:
                "Confirm attendance for operational briefings, scan event QR codes, or submit official excusal requests:",
            items: const [
              ManualStepItem(
                number: 1,
                title: "Scheduled Meeting Agenda Card",
                desc: "Review meeting time, required briefing topic, venue location (or Google Meet virtual link), and presiding supervisors.",
              ),
              ManualStepItem(
                number: 2,
                title: "Confirm Attendance / QR Scan Button",
                desc: "Tap the green button or scan the briefing QR code on site to record your presence and timestamp your attendance.",
              ),
              ManualStepItem(
                number: 3,
                title: "Cannot Attend Excusal Request Button",
                desc: "If deployed on emergency field duty or medical leave, tap to submit an absence justification form directly to supervisors.",
              ),
            ],
            pins: const [
              HotspotPinData(
                number: 1,
                label: "Meeting Agenda Details",
                topPercent: 0.32,
                leftPercent: 0.50,
                tooltipPosition: 'bottom',
              ),
              HotspotPinData(
                number: 2,
                label: "Confirm Attendance / QR",
                topPercent: 0.62,
                leftPercent: 0.32,
                tooltipPosition: 'top',
              ),
              HotspotPinData(
                number: 3,
                label: "Cannot Attend Excusal",
                topPercent: 0.62,
                leftPercent: 0.72,
                tooltipPosition: 'top',
              ),
            ],
            buildMockupScreen: (ctx, activeHotspot) =>
                _buildEmployeeMeetingsMockup(isDark, activeHotspot),
          ),

        if (showAll || _selectedCategory == 'MEETINGS') const SizedBox(height: 18),

        // SECTION 4: OFFLINE CACHING & DATA SYNC
        if (showAll || _selectedCategory == 'SYNC')
          InteractiveManualStepCard(
            isDark: isDark,
            stepNumber: "2.4",
            title: "Offline Storage & Automatic Cloud Sync",
            category: "Field Network Resilience",
            icon: Icons.cloud_sync_outlined,
            introText:
                "GreenAtlas automatically persists your field observations offline. When connection is restored, upload queued entries with one tap:",
            items: const [
              ManualStepItem(
                number: 1,
                title: "Offline Connection Status Banner",
                desc: "A discrete badge notifies you when offline mode is active. All field diary records continue saving locally to secure device storage.",
              ),
              ManualStepItem(
                number: 2,
                title: "Pending Offline Drafts Queue",
                desc: "Review cached observation entries waiting for cellular data or Wi-Fi connectivity before transmission.",
              ),
              ManualStepItem(
                number: 3,
                title: "One-Tap Cloud Sync Button",
                desc: "Tap 'Sync All Entries' once back in range. The system securely transmits records, coordinates, and images to the main database.",
              ),
            ],
            pins: const [
              HotspotPinData(
                number: 1,
                label: "Offline Mode Indicator",
                topPercent: 0.16,
                leftPercent: 0.50,
                tooltipPosition: 'bottom',
              ),
              HotspotPinData(
                number: 2,
                label: "Pending Drafts Queue",
                topPercent: 0.44,
                leftPercent: 0.50,
                tooltipPosition: 'bottom',
              ),
              HotspotPinData(
                number: 3,
                label: "One-Tap Cloud Sync Action",
                topPercent: 0.78,
                leftPercent: 0.50,
                tooltipPosition: 'top',
              ),
            ],
            buildMockupScreen: (ctx, activeHotspot) =>
                _buildOfflineSyncMockup(isDark, activeHotspot),
          ),

        if (showAll || _selectedCategory == 'SYNC') const SizedBox(height: 18),

        // SECTION 5: EMPLOYEE FAQ
        if (showAll || _selectedCategory == 'FAQ') _buildEmployeeFaq(isDark),
      ],
    );
  }

  // --------------------------------------------------------------------------
  // SCOPE BANNER
  // --------------------------------------------------------------------------

  Widget _buildScopeBanner({
    required bool isDark,
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E2820) : const Color(0xFFE4EFE4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? leafAccent.withValues(alpha: 0.3)
              : const Color(0xFF5D7A5D).withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF2B3A2E) : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark ? Colors.white10 : const Color(0xFFD0E0D0),
              ),
            ),
            child: Icon(
              icon,
              color: isDark ? leafAccent : primaryForest,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: isDark ? leafAccent.withValues(alpha: 0.2) : primaryForest,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        "VISUAL HOTSPOTS",
                        style: TextStyle(
                          fontSize: 8.5,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.8,
                          color: isDark ? leafAccent : Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      "Interactive Guide",
                      style: TextStyle(
                        fontSize: 10,
                        color: isDark ? Colors.white54 : Colors.black45,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  title,
                  style: TextStyle(
                    fontFamily: 'Poppins-Bold',
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFF233525),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 11.5,
                    height: 1.35,
                    color: isDark ? Colors.white70 : const Color(0xFF425545),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --------------------------------------------------------------------------
  // VISITOR FAQ ACCORDION
  // --------------------------------------------------------------------------

  Widget _buildVisitorFaq(bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1B231C) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white10 : const Color(0xFFE0E8E0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.help_outline_rounded,
                      color: isDark ? leafAccent : primaryForest, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    "Visitor Frequently Asked Questions",
                    style: TextStyle(
                      fontFamily: 'Poppins-Bold',
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : const Color(0xFF2D3E2D),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          _buildFaqItem(
            isDark: isDark,
            id: 'vis_q1',
            question: "Q1: The AR model is not appearing on my phone. What should I do?",
            answer:
                "Ensure you are in a well-lit environment and slowly move your smartphone camera side-to-side pointed at a flat, textured surface (like grass or textured flooring). Make sure camera permissions are enabled for GreenAtlas in your device OS settings.",
          ),
          const SizedBox(height: 8),
          _buildFaqItem(
            isDark: isDark,
            id: 'vis_q2',
            question: "Q2: How do I save AR plant snapshots to my camera roll?",
            answer:
                "Tap the circular AR Shutter Button at the bottom center of the AR screen. A high-resolution picture will be saved directly to your device photo gallery with a confirmation prompt.",
          ),
          const SizedBox(height: 8),
          _buildFaqItem(
            isDark: isDark,
            id: 'vis_q3',
            question: "Q3: How do I reset my password if I forget my credentials?",
            answer:
                "On the mobile sign-in screen, tap 'Forgot Password?', enter your registered email address, and check your inbox for an instant secure reset link.",
          ),
        ],
      ),
    );
  }

  // --------------------------------------------------------------------------
  // EMPLOYEE FAQ ACCORDION
  // --------------------------------------------------------------------------

  Widget _buildEmployeeFaq(bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1B231C) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white10 : const Color(0xFFE0E8E0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.help_outline_rounded,
                  color: isDark ? leafAccent : primaryForest, size: 20),
              const SizedBox(width: 8),
              Text(
                "Field Operations Frequently Asked Questions",
                style: TextStyle(
                  fontFamily: 'Poppins-Bold',
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF2D3E2D),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _buildFaqItem(
            isDark: isDark,
            id: 'emp_q1',
            question: "Q1: How do I capture GPS coordinates when deep in the field without cell signal?",
            answer:
                "Your smartphone's built-in GPS antenna communicates directly with positioning satellites and does not require active mobile internet data. Simply tap 'Fetch Current Location' outdoors under an open sky.",
          ),
          const SizedBox(height: 8),
          _buildFaqItem(
            isDark: isDark,
            id: 'emp_q2',
            question: "Q2: What happens if an observation I submitted is rejected by Admin QC?",
            answer:
                "The observation will appear in your Field Diary feedback log with specific notes from the admin (e.g. 'Photo too blurry' or 'Location mismatch'). You can re-photograph the specimen and re-submit the updated entry.",
          ),
          const SizedBox(height: 8),
          _buildFaqItem(
            isDark: isDark,
            id: 'emp_q3',
            question: "Q3: How does the 'Cannot Attend' meeting excuse system work?",
            answer:
                "Select the scheduled meeting card, tap 'Cannot Attend', select an authorized category (e.g. Active Patrol, Medical Leave, Field Emergency), and submit. The presiding supervisor receives an immediate notification.",
          ),
        ],
      ),
    );
  }

  Widget _buildFaqItem({
    required bool isDark,
    required String id,
    required String question,
    required String answer,
  }) {
    final isOpen = _isFaqOpen(id);

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF222C23) : const Color(0xFFF7FAF7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.white12 : const Color(0xFFE2EBE2),
        ),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () => _toggleFaq(id),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      question,
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : const Color(0xFF2D3E2D),
                      ),
                    ),
                  ),
                  Icon(
                    isOpen ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                    color: isDark ? leafAccent : primaryForest,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
          if (isOpen)
            Container(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
              child: Text(
                answer,
                style: TextStyle(
                  fontSize: 11.5,
                  height: 1.4,
                  color: isDark ? Colors.white70 : Colors.black87,
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ==========================================================================
  // MOBILE SCREEN VISUAL MOCKUPS
  // ==========================================================================

  // --- MOCKUP 1: VISITOR DASHBOARD ---
  Widget _buildVisitorDashboardMockup(bool isDark, int? activeHotspot) {
    return Container(
      color: isDark ? const Color(0xFF141A15) : const Color(0xFFF5FAF5),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // App header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: primaryForest,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Icon(Icons.eco_rounded, color: Colors.white, size: 16),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    "GreenAtlas",
                    style: TextStyle(
                      fontFamily: 'Poppins-Bold',
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : const Color(0xFF2D3E2D),
                    ),
                  ),
                ],
              ),
              // Bell icon (Pin 1)
              Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF263327) : Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: activeHotspot == 1 ? Colors.amber : Colors.black12,
                    width: activeHotspot == 1 ? 2 : 1,
                  ),
                ),
                child: Stack(
                  children: [
                    Icon(
                      Icons.notifications_none_rounded,
                      size: 16,
                      color: isDark ? Colors.white70 : const Color(0xFF334B36),
                    ),
                    Positioned(
                      top: 0,
                      right: 0,
                      child: Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: Colors.redAccent,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Weather Sensor Widget (Pin 2)
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? [const Color(0xFF233526), const Color(0xFF1C271E)]
                    : [const Color(0xFF517156), const Color(0xFF3D5641)],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: activeHotspot == 2 ? Colors.amberAccent : Colors.white10,
                width: activeHotspot == 2 ? 2 : 1,
              ),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Cavite Plant Sanctuary",
                      style: TextStyle(fontSize: 9.5, color: Colors.white70, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 2),
                    Text(
                      "29°C  Sunny",
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Icon(Icons.wb_sunny_rounded, color: Colors.amberAccent, size: 20),
                    SizedBox(width: 4),
                    Text(
                      "Optimal",
                      style: TextStyle(fontSize: 9, color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // Featured Species Card (Pin 3)
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E2720) : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: activeHotspot == 3 ? Colors.amberAccent : (isDark ? Colors.white10 : Colors.black12),
                width: activeHotspot == 3 ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFF81C784).withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.forest_rounded, color: primaryForest, size: 26),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                            decoration: BoxDecoration(
                              color: Colors.redAccent.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              "VULNERABLE",
                              style: TextStyle(fontSize: 7.5, fontWeight: FontWeight.bold, color: Colors.redAccent),
                            ),
                          ),
                          const Spacer(),
                          const Text("Featured Flora", style: TextStyle(fontSize: 8, color: Colors.grey)),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        "Narra Tree",
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      const Text(
                        "Pterocarpus indicus",
                        style: TextStyle(fontSize: 9, fontStyle: FontStyle.italic, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // Quick Action Launchpad (Pin 4)
          Row(
            children: [
              Expanded(
                child: _buildActionTile(
                  isDark: isDark,
                  icon: Icons.local_florist_rounded,
                  label: "Gallery",
                  isActive: activeHotspot == 4,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _buildActionTile(
                  isDark: isDark,
                  icon: Icons.view_in_ar_rounded,
                  label: "AR View",
                  isActive: activeHotspot == 4,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _buildActionTile(
                  isDark: isDark,
                  icon: Icons.map_rounded,
                  label: "Eco Map",
                  isActive: activeHotspot == 4,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionTile({
    required bool isDark,
    required IconData icon,
    required String label,
    required bool isActive,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF222C24) : Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isActive ? Colors.amberAccent : (isDark ? Colors.white10 : Colors.black12),
          width: isActive ? 2 : 1,
        ),
      ),
      child: Column(
        children: [
          Icon(icon, size: 18, color: isDark ? leafAccent : primaryForest),
          const SizedBox(height: 3),
          Text(
            label,
            style: TextStyle(
              fontSize: 9.5,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white70 : const Color(0xFF2D3E2D),
            ),
          ),
        ],
      ),
    );
  }

  // --- MOCKUP 2: BOTANICAL GALLERY ---
  Widget _buildBotanicalGalleryMockup(bool isDark, int? activeHotspot) {
    return Container(
      color: isDark ? const Color(0xFF141A15) : const Color(0xFFF5FAF5),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search Bar (Pin 1)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF202A22) : Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: activeHotspot == 1 ? Colors.amberAccent : Colors.black12,
                width: activeHotspot == 1 ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.search_rounded, size: 16, color: isDark ? leafAccent : primaryForest),
                const SizedBox(width: 6),
                Text(
                  "Search Narra, Red Rose, Paho...",
                  style: TextStyle(fontSize: 10, color: isDark ? Colors.white54 : Colors.grey[600]),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Filter Chips (Pin 2)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildMockupChip("All (24)", true, isDark, activeHotspot == 2),
                const SizedBox(width: 5),
                _buildMockupChip("Trees", false, isDark, activeHotspot == 2),
                const SizedBox(width: 5),
                _buildMockupChip("Endangered", false, isDark, activeHotspot == 2),
                const SizedBox(width: 5),
                _buildMockupChip("Native", false, isDark, activeHotspot == 2),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // Botanical Card (Pin 3)
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E2720) : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: activeHotspot == 3 ? Colors.amberAccent : Colors.black12,
                width: activeHotspot == 3 ? 2 : 1,
              ),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.park_rounded, color: primaryForest, size: 24),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Narra (Pterocarpus indicus)",
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            "National Tree of the Philippines • Fabaceae",
                            style: TextStyle(fontSize: 8.5, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Native • Lowland Sanctuary",
                      style: TextStyle(fontSize: 8, color: Colors.grey),
                    ),
                    // AR View Button (Pin 4)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: primaryForest,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: activeHotspot == 4 ? Colors.amberAccent : Colors.transparent,
                          width: activeHotspot == 4 ? 2 : 1,
                        ),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.view_in_ar_rounded, size: 11, color: Colors.white),
                          SizedBox(width: 4),
                          Text(
                            "View in 3D AR",
                            style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMockupChip(String text, bool selected, bool isDark, bool highlighted) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: selected
            ? primaryForest
            : (isDark ? const Color(0xFF222C24) : const Color(0xFFE8EFE8)),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: highlighted ? Colors.amberAccent : Colors.transparent,
          width: highlighted ? 2 : 1,
        ),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.bold,
          color: selected ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
        ),
      ),
    );
  }

  // --- MOCKUP 3: AR PLANT VIEWER ---
  Widget _buildArCameraMockup(bool isDark, int? activeHotspot) {
    return Container(
      color: const Color(0xFF0F1510),
      child: Stack(
        children: [
          // Background Camera Feed Simulation with Grid
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF1B2A1E),
                  Color(0xFF2E3D30),
                  Color(0xFF141D15),
                ],
              ),
            ),
          ),

          // Camera Frame Corners
          Positioned.fill(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildCornerMark(Alignment.topLeft),
                      _buildCornerMark(Alignment.topRight),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildCornerMark(Alignment.bottomLeft),
                      _buildCornerMark(Alignment.bottomRight),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Gesture Controls Banner (Pin 3)
          Positioned(
            top: 14,
            left: 20,
            right: 20,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.65),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: activeHotspot == 3 ? Colors.amberAccent : Colors.white24,
                    width: activeHotspot == 3 ? 2 : 1,
                  ),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.pinch_rounded, size: 12, color: Colors.white),
                    SizedBox(width: 4),
                    Text(
                      "Pinch to Scale  •  Drag to Rotate Model",
                      style: TextStyle(fontSize: 8.5, color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Center 3D Plant Model (Pin 2) & Reticle (Pin 1)
          Positioned.fill(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 3D Plant Projection
                  Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      color: Colors.greenAccent.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: activeHotspot == 2 ? Colors.amberAccent : Colors.transparent,
                        width: activeHotspot == 2 ? 2 : 1,
                      ),
                    ),
                    child: const Icon(
                      Icons.park_rounded,
                      color: Color(0xFF66BB6A),
                      size: 46,
                    ),
                  ),

                  // Surface Plane Detection Reticle (Pin 1)
                  Container(
                    width: 90,
                    height: 24,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: activeHotspot == 1 ? Colors.amberAccent : const Color(0xFF81C784),
                        width: activeHotspot == 1 ? 2.5 : 1.5,
                      ),
                      borderRadius: const BorderRadius.all(Radius.elliptical(90, 24)),
                    ),
                    child: const Center(
                      child: Text(
                        "Surface Detected",
                        style: TextStyle(fontSize: 7.5, color: Color(0xFF81C784), fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Camera Shutter Button (Pin 4)
          Positioned(
            bottom: 12,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  border: Border.all(
                    color: activeHotspot == 4 ? Colors.amberAccent : const Color(0xFF43A047),
                    width: activeHotspot == 4 ? 3 : 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.4),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: const Center(
                  child: Icon(Icons.camera_alt_rounded, color: Color(0xFF2E7D32), size: 22),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCornerMark(Alignment alignment) {
    return Container(
      width: 14,
      height: 14,
      decoration: BoxDecoration(
        border: Border(
          top: alignment == Alignment.topLeft || alignment == Alignment.topRight
              ? const BorderSide(color: Colors.white70, width: 2)
              : BorderSide.none,
          bottom: alignment == Alignment.bottomLeft || alignment == Alignment.bottomRight
              ? const BorderSide(color: Colors.white70, width: 2)
              : BorderSide.none,
          left: alignment == Alignment.topLeft || alignment == Alignment.bottomLeft
              ? const BorderSide(color: Colors.white70, width: 2)
              : BorderSide.none,
          right: alignment == Alignment.topRight || alignment == Alignment.bottomRight
              ? const BorderSide(color: Colors.white70, width: 2)
              : BorderSide.none,
        ),
      ),
    );
  }

  // --- MOCKUP 4: VISITOR NOTIFICATIONS ---
  Widget _buildVisitorNotificationsMockup(bool isDark, int? activeHotspot) {
    return Container(
      color: isDark ? const Color(0xFF141A15) : const Color(0xFFF5FAF5),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Notifications",
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              // Mark all read button (Pin 1)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF233025) : const Color(0xFFE5EFE5),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: activeHotspot == 1 ? Colors.amberAccent : Colors.transparent,
                    width: activeHotspot == 1 ? 2 : 1,
                  ),
                ),
                child: Text(
                  "Mark all read",
                  style: TextStyle(
                    fontSize: 8.5,
                    fontWeight: FontWeight.bold,
                    color: isDark ? leafAccent : primaryForest,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Flora alert card (Pin 2)
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E2720) : Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: activeHotspot == 2 ? Colors.amberAccent : Colors.black12,
                width: activeHotspot == 2 ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: primaryForest.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.eco_rounded, size: 14, color: primaryForest),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "New Flora Added: Narra Tree",
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      const Text(
                        "3D AR model and profile now accessible.",
                        style: TextStyle(fontSize: 8, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Climate alert card (Pin 3)
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E2720) : Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: activeHotspot == 3 ? Colors.amberAccent : Colors.black12,
                width: activeHotspot == 3 ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.amber.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.wb_sunny_rounded, size: 14, color: Colors.amber),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Climate Warning: 34°C Ambient",
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      const Text(
                        "Extreme heat alert in Cavite Sanctuary zone.",
                        style: TextStyle(fontSize: 8, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- MOCKUP 5: EMPLOYEE DASHBOARD ---
  Widget _buildEmployeeDashboardMockup(bool isDark, int? activeHotspot) {
    return Container(
      color: isDark ? const Color(0xFF141A15) : const Color(0xFFF5FAF5),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Officer badge banner (Pin 1)
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF222E24) : Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: activeHotspot == 1 ? Colors.amberAccent : Colors.black12,
                width: activeHotspot == 1 ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: primaryForest,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.badge_rounded, color: Colors.white, size: 18),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Field Officer Ramos",
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    Text(
                      "ID: FO-104 • Cavite Sanctuary Patrol",
                      style: TextStyle(fontSize: 8.5, color: isDark ? leafAccent : primaryForest),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Field Diary quick card (Pin 2)
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? [const Color(0xFF253729), const Color(0xFF1C271E)]
                    : [const Color(0xFF517156), const Color(0xFF3B543F)],
              ),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: activeHotspot == 2 ? Colors.amberAccent : Colors.transparent,
                width: activeHotspot == 2 ? 2 : 1,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.menu_book_rounded, color: Colors.white, size: 20),
                    SizedBox(width: 8),
                    Text(
                      "Field Diary Observation Logs",
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    "3 Drafts",
                    style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Upcoming meeting card (Pin 3)
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E2720) : Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: activeHotspot == 3 ? Colors.amberAccent : Colors.black12,
                width: activeHotspot == 3 ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.event_note_rounded, size: 16, color: primaryForest),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Sanctuary Patrol Briefing",
                        style: TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      const Text(
                        "Today, 2:00 PM • Base Station",
                        style: TextStyle(fontSize: 8, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Personal validation metrics (Pin 4)
          Row(
            children: [
              Expanded(
                child: _buildMetricTile("28 Collected", Icons.upload_file_rounded, isDark, activeHotspot == 4),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _buildMetricTile("24 Validated", Icons.verified_rounded, isDark, activeHotspot == 4),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricTile(String label, IconData icon, bool isDark, bool isActive) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF222C24) : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isActive ? Colors.amberAccent : Colors.black12,
          width: isActive ? 2 : 1,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 14, color: primaryForest),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  // --- MOCKUP 6: FIELD DIARY OBSERVATION LOGGING ---
  Widget _buildFieldDiaryMockup(bool isDark, int? activeHotspot) {
    return Container(
      color: isDark ? const Color(0xFF141A15) : const Color(0xFFF5FAF5),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with + Action (Pin 1)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "New Field Observation",
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
                decoration: BoxDecoration(
                  color: primaryForest,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: activeHotspot == 1 ? Colors.amberAccent : Colors.transparent,
                    width: activeHotspot == 1 ? 2 : 1,
                  ),
                ),
                child: const Text(
                  "+ New Entry",
                  style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Species Name input (Pin 2)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF202A22) : Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: activeHotspot == 2 ? Colors.amberAccent : Colors.black12,
                width: activeHotspot == 2 ? 2 : 1,
              ),
            ),
            child: const Row(
              children: [
                Icon(Icons.edit_note_rounded, size: 14, color: primaryForest),
                SizedBox(width: 6),
                Text(
                  "Narra Sapling #14 (Healthy)",
                  style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),

          // Fetch GPS button (Pin 3)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF202A22) : Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: activeHotspot == 3 ? Colors.amberAccent : Colors.black12,
                width: activeHotspot == 3 ? 2 : 1,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.gps_fixed_rounded, size: 14, color: Colors.green),
                    SizedBox(width: 6),
                    Text(
                      "Lat 14.281° N, Long 120.912° E",
                      style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1.5),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text("Locked", style: TextStyle(fontSize: 7.5, color: Colors.green)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),

          // Photo evidence uploader (Pin 4)
          Container(
            height: 48,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF202A22) : Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: activeHotspot == 4 ? Colors.amberAccent : Colors.black12,
                width: activeHotspot == 4 ? 2 : 1,
              ),
            ),
            child: const Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.camera_alt_outlined, size: 16, color: primaryForest),
                  SizedBox(width: 6),
                  Text("Specimen Photo Attached (1)", style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),

          // Draft & Submit buttons (Pin 5)
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 5),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF28342A) : const Color(0xFFE2ECE2),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: activeHotspot == 5 ? Colors.amberAccent : Colors.transparent,
                      width: activeHotspot == 5 ? 2 : 1,
                    ),
                  ),
                  child: const Center(
                    child: Text("Save Local Draft", style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.bold)),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 5),
                  decoration: BoxDecoration(
                    color: primaryForest,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: activeHotspot == 5 ? Colors.amberAccent : Colors.transparent,
                      width: activeHotspot == 5 ? 2 : 1,
                    ),
                  ),
                  child: const Center(
                    child: Text("Submit / Upload", style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.bold, color: Colors.white)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- MOCKUP 7: EMPLOYEE MEETINGS & ATTENDANCE ---
  Widget _buildEmployeeMeetingsMockup(bool isDark, int? activeHotspot) {
    return Container(
      color: isDark ? const Color(0xFF141A15) : const Color(0xFFF5FAF5),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Scheduled Operations Meeting",
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 8),

          // Meeting Card (Pin 1)
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E2720) : Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: activeHotspot == 1 ? Colors.amberAccent : Colors.black12,
                width: activeHotspot == 1 ? 2 : 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.blue.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text("MANDATORY BRIEFING", style: TextStyle(fontSize: 7.5, fontWeight: FontWeight.bold, color: Colors.blue)),
                    ),
                    const Spacer(),
                    const Text("Oct 16 • 9:00 AM", style: TextStyle(fontSize: 8, color: Colors.grey)),
                  ],
                ),
                const SizedBox(height: 4),
                const Text(
                  "Sanctuary Perimeter & Reforestation",
                  style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 2),
                const Text(
                  "Venue: Cavite Operations Base • Presiding: Supervisor Santos",
                  style: TextStyle(fontSize: 8, color: Colors.grey),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // Attendance Action Buttons (Pin 2 & 3)
          Row(
            children: [
              // Confirm Attendance (Pin 2)
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  decoration: BoxDecoration(
                    color: primaryForest,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: activeHotspot == 2 ? Colors.amberAccent : Colors.transparent,
                      width: activeHotspot == 2 ? 2 : 1,
                    ),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.qr_code_scanner_rounded, size: 12, color: Colors.white),
                      SizedBox(width: 4),
                      Text("Confirm Attendance", style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.bold, color: Colors.white)),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // Cannot Attend (Pin 3)
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.redAccent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: activeHotspot == 3 ? Colors.amberAccent : Colors.redAccent.withValues(alpha: 0.3),
                      width: activeHotspot == 3 ? 2 : 1,
                    ),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.event_busy_rounded, size: 12, color: Colors.redAccent),
                      SizedBox(width: 4),
                      Text("Cannot Attend", style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.bold, color: Colors.redAccent)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- MOCKUP 8: OFFLINE CACHING & CLOUD SYNC ---
  Widget _buildOfflineSyncMockup(bool isDark, int? activeHotspot) {
    return Container(
      color: isDark ? const Color(0xFF141A15) : const Color(0xFFF5FAF5),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Offline Status Indicator (Pin 1)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.orange.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: activeHotspot == 1 ? Colors.amberAccent : Colors.orange.withValues(alpha: 0.3),
                width: activeHotspot == 1 ? 2 : 1,
              ),
            ),
            child: const Row(
              children: [
                Icon(Icons.cloud_off_rounded, size: 14, color: Colors.orange),
                SizedBox(width: 6),
                Text(
                  "Offline Mode Active (Data Stored Locally)",
                  style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.bold, color: Colors.orange),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Pending drafts queue (Pin 2)
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E2720) : Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: activeHotspot == 2 ? Colors.amberAccent : Colors.black12,
                width: activeHotspot == 2 ? 2 : 1,
              ),
            ),
            child: const Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Draft #1 • Narra Sapling", style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.bold)),
                    Text("Ready to Sync", style: TextStyle(fontSize: 7.5, color: Colors.green)),
                  ],
                ),
                SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Draft #2 • Red Rose Cluster", style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.bold)),
                    Text("Ready to Sync", style: TextStyle(fontSize: 7.5, color: Colors.green)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // One-tap sync button (Pin 3)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 6),
            decoration: BoxDecoration(
              color: primaryForest,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: activeHotspot == 3 ? Colors.amberAccent : Colors.transparent,
                width: activeHotspot == 3 ? 2 : 1,
              ),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.cloud_upload_rounded, size: 14, color: Colors.white),
                SizedBox(width: 6),
                Text(
                  "Sync All 2 Queued Observations",
                  style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// INTERACTIVE MANUAL STEP CARD WIDGET
// ============================================================================

class InteractiveManualStepCard extends StatefulWidget {
  final bool isDark;
  final String stepNumber;
  final String title;
  final String category;
  final IconData icon;
  final String introText;
  final List<ManualStepItem> items;
  final List<HotspotPinData> pins;
  final Widget Function(BuildContext, int? activeHotspot) buildMockupScreen;

  const InteractiveManualStepCard({
    super.key,
    required this.isDark,
    required this.stepNumber,
    required this.title,
    required this.category,
    required this.icon,
    required this.introText,
    required this.items,
    required this.pins,
    required this.buildMockupScreen,
  });

  @override
  State<InteractiveManualStepCard> createState() => _InteractiveManualStepCardState();
}

class _InteractiveManualStepCardState extends State<InteractiveManualStepCard> {
  int? _activeHotspot;

  void _selectHotspot(int number) {
    setState(() {
      _activeHotspot = _activeHotspot == number ? null : number;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1B231C) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark
              ? (_activeHotspot != null ? leafAccent.withValues(alpha: 0.4) : Colors.white12)
              : (_activeHotspot != null ? primaryForest.withValues(alpha: 0.4) : const Color(0xFFE2EBE2)),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Card Header
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF263327) : const Color(0xFFE9F3E9),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isDark ? Colors.white12 : const Color(0xFFD4E4D4),
                  ),
                ),
                child: Icon(
                  widget.icon,
                  color: isDark ? leafAccent : primaryForest,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF243126) : const Color(0xFFE2EFE2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            "SECTION ${widget.stepNumber}",
                            style: TextStyle(
                              fontSize: 8.5,
                              fontWeight: FontWeight.bold,
                              color: isDark ? leafAccent : primaryForest,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          widget.category,
                          style: TextStyle(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white54 : Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.title,
                      style: TextStyle(
                        fontFamily: 'Poppins-Bold',
                        fontSize: 13.5,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : const Color(0xFF243525),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Tip pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF233025) : const Color(0xFFEAF5EA),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.touch_app_rounded,
                  size: 14,
                  color: isDark ? leafAccent : primaryForest,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    "Tap numbered badges (①, ②, ③) or steps to pinpoint exact UI controls",
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: isDark ? leafAccent : primaryForest,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // Intro text
          Text(
            widget.introText,
            style: TextStyle(
              fontSize: 11.5,
              height: 1.4,
              color: isDark ? Colors.white70 : const Color(0xFF455847),
            ),
          ),
          const SizedBox(height: 14),

          // PHONE MOCKUP WITH HOTSPOT CIRCLES
          Center(
            child: MobileDeviceFrame(
              isDark: isDark,
              activeHotspot: _activeHotspot,
              onSelectHotspot: _selectHotspot,
              pins: widget.pins,
              screenContent: widget.buildMockupScreen(context, _activeHotspot),
            ),
          ),
          const SizedBox(height: 14),

          // STEP INSTRUCTIONS LIST
          Column(
            children: widget.items.map((item) {
              final isHovered = _activeHotspot == item.number;

              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: InkWell(
                  onTap: () => _selectHotspot(item.number),
                  borderRadius: BorderRadius.circular(12),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isHovered
                          ? (isDark ? const Color(0xFF27382A) : const Color(0xFFE6F3E6))
                          : (isDark ? const Color(0xFF202A21) : const Color(0xFFF7FAF7)),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isHovered
                            ? (isDark ? leafAccent : primaryForest)
                            : (isDark ? Colors.white12 : const Color(0xFFE5EDE5)),
                        width: isHovered ? 1.5 : 1,
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Number Circle Badge
                        Container(
                          width: 22,
                          height: 22,
                          decoration: BoxDecoration(
                            color: isHovered
                                ? (isDark ? leafAccent : primaryForest)
                                : (isDark ? const Color(0xFF334335) : const Color(0xFF384F3B)),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isHovered ? Colors.white : Colors.transparent,
                              width: 1.5,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              "${item.number}",
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.bold,
                                color: isHovered && isDark ? Colors.black : Colors.white,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.title,
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.bold,
                                  color: isHovered
                                      ? (isDark ? leafAccent : primaryForest)
                                      : (isDark ? Colors.white : const Color(0xFF243525)),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                item.desc,
                                style: TextStyle(
                                  fontSize: 10.5,
                                  height: 1.35,
                                  color: isDark ? Colors.white70 : Colors.black87,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// MOBILE DEVICE FRAME MOCKUP CONTAINER
// ============================================================================

class MobileDeviceFrame extends StatelessWidget {
  final bool isDark;
  final int? activeHotspot;
  final ValueChanged<int> onSelectHotspot;
  final List<HotspotPinData> pins;
  final Widget screenContent;

  const MobileDeviceFrame({
    super.key,
    required this.isDark,
    required this.activeHotspot,
    required this.onSelectHotspot,
    required this.pins,
    required this.screenContent,
  });

  @override
  Widget build(BuildContext context) {
    // Phone shell dimensions
    const frameWidth = 280.0;
    const frameHeight = 270.0;

    return Container(
      width: frameWidth,
      height: frameHeight,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E281F) : const Color(0xFF2D3C2E),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? const Color(0xFF384B3B) : const Color(0xFF455847),
          width: 4,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.5 : 0.25),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            // Internal Screen
            Positioned.fill(
              child: Column(
                children: [
                  // Phone Status Bar
                  Container(
                    height: 18,
                    color: isDark ? const Color(0xFF141A15) : const Color(0xFFE8F1E8),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "9:41",
                          style: TextStyle(
                            fontSize: 8.5,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white70 : Colors.black87,
                          ),
                        ),
                        // Mini speaker / notch notch
                        Container(
                          width: 38,
                          height: 4,
                          decoration: BoxDecoration(
                            color: isDark ? Colors.white24 : Colors.black26,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        Row(
                          children: [
                            Icon(Icons.wifi_rounded, size: 9, color: isDark ? Colors.white70 : Colors.black87),
                            const SizedBox(width: 3),
                            Icon(Icons.battery_full_rounded, size: 9, color: isDark ? Colors.white70 : Colors.black87),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Child Screen Content
                  Expanded(
                    child: screenContent,
                  ),
                ],
              ),
            ),

            // HOTSPOT CIRCLE PINS OVERLAY
            ...pins.map((pin) {
              final isSelected = activeHotspot == pin.number;

              return Positioned(
                top: (frameHeight - 18) * pin.topPercent + 18 - 12,
                left: frameWidth * pin.leftPercent - 12,
                child: HotspotCircleBadge(
                  number: pin.number,
                  label: pin.label,
                  isSelected: isSelected,
                  tooltipPosition: pin.tooltipPosition,
                  onTap: () => onSelectHotspot(pin.number),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// HOTSPOT CIRCLE BADGE (NUMBERED PULSING PIN)
// ============================================================================

class HotspotCircleBadge extends StatelessWidget {
  final int number;
  final String label;
  final bool isSelected;
  final String tooltipPosition;
  final VoidCallback onTap;

  const HotspotCircleBadge({
    super.key,
    required this.number,
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.tooltipPosition = 'top',
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          // Outer Ping Ring when active
          if (isSelected)
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF2E7D32).withValues(alpha: 0.35),
                border: Border.all(color: Colors.greenAccent, width: 1.5),
              ),
            ),

          // Inner Circle Pin
          Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isSelected ? const Color(0xFF2E7D32) : const Color(0xFF1E281F),
              border: Border.all(
                color: isSelected ? Colors.amberAccent : Colors.white,
                width: isSelected ? 2 : 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: isSelected ? Colors.greenAccent.withValues(alpha: 0.6) : Colors.black45,
                  blurRadius: isSelected ? 8 : 4,
                  spreadRadius: isSelected ? 1 : 0,
                ),
              ],
            ),
            child: Center(
              child: Text(
                "$number",
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
            ),
          ),

          // Tooltip floating bubble when active
          if (isSelected)
            Positioned(
              top: tooltipPosition == 'bottom' ? 24 : null,
              bottom: tooltipPosition == 'top' ? 24 : null,
              left: tooltipPosition == 'right' ? 24 : null,
              right: tooltipPosition == 'left' ? 24 : null,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF152217),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.amberAccent, width: 1),
                  boxShadow: const [
                    BoxShadow(color: Colors.black54, blurRadius: 6),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: const BoxDecoration(
                        color: Colors.amberAccent,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          "$number",
                          style: const TextStyle(fontSize: 7.5, fontWeight: FontWeight.bold, color: Colors.black),
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      label,
                      style: const TextStyle(
                        fontSize: 8.5,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
