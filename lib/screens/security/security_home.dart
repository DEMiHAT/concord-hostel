import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../models/enums.dart';
import '../../models/qr_pass.dart';
import '../../models/user_model.dart';
import '../../services/app_service.dart';
import '../../widgets/glass_widgets.dart';

class SecurityHomeScreen extends StatefulWidget {
  final AppService service;
  const SecurityHomeScreen({super.key, required this.service});

  @override
  State<SecurityHomeScreen> createState() => _SecurityHomeScreenState();
}

class _SecurityHomeScreenState extends State<SecurityHomeScreen> {
  int _currentIndex = 0;
  GateType _selectedGate = GateType.hostel;
  LaneType _selectedLane = LaneType.scanLane;
  String _scanResult = '';
  bool _isScanning = false;
  final TextEditingController _exceptionController = TextEditingController();
  final TextEditingController _exceptionReasonController =
      TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _exceptionController.dispose();
    _exceptionReasonController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.service.currentUser;
    if (user == null) return const SizedBox.shrink();

    final activePasses =
        widget.service.qrPasses.where((p) => p.isActive).toList();

    return GlassScaffold(
      bottomNavigationBar: _buildBottomNav(activePasses.length),
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _buildDashboard(user, activePasses),
          _buildScanView(),
          _buildActivePasses(activePasses),
          _buildProfile(user),
        ],
      ),
    );
  }

  // ─── Bottom Navigation ───────────────────────────────

  Widget _buildBottomNav(int activeCount) {
    return Container(
      margin: const EdgeInsets.all(16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.bgCard.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.glassBorder, width: 0.5),
          ),
          child: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: (i) => setState(() => _currentIndex = i),
            backgroundColor: Colors.transparent,
            elevation: 0,
            type: BottomNavigationBarType.fixed,
            selectedItemColor: AppColors.primaryStart,
            unselectedItemColor: AppColors.textMuted,
            selectedFontSize: 11,
            unselectedFontSize: 10,
            items: [
              const BottomNavigationBarItem(
                icon: Icon(Icons.dashboard_rounded),
                label: 'Home',
              ),
              const BottomNavigationBarItem(
                icon: Icon(Icons.qr_code_scanner_rounded),
                label: 'Scan QR',
              ),
              BottomNavigationBarItem(
                icon: Badge(
                  isLabelVisible: activeCount > 0,
                  label:
                      Text('$activeCount', style: const TextStyle(fontSize: 9)),
                  child: const Icon(Icons.badge_rounded),
                ),
                label: 'Passes',
              ),
              const BottomNavigationBarItem(
                icon: Icon(Icons.person_rounded),
                label: 'Profile',
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Dashboard (Home) ────────────────────────────────

  Widget _buildDashboard(AppUser user, List<QrPass> activePasses) {
    final todayAttendance = widget.service.getTodayAttendance();
    final totalPasses = widget.service.qrPasses.length;
    final now = DateTime.now();
    final greeting = now.hour < 12
        ? 'Good Morning'
        : now.hour < 17
            ? 'Good Afternoon'
            : 'Good Evening';

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),

          // Greeting row
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$greeting 👋',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    Text(
                      user.name,
                      style: Theme.of(context).textTheme.headlineLarge,
                    ),
                    const SizedBox(height: 4),
                    StatusBadge(
                      label: 'Security Personnel',
                      color: AppColors.primaryStart,
                    ),
                  ],
                ),
              ),
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryStart.withValues(alpha: 0.2),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(Icons.shield_rounded,
                    color: Colors.white, size: 26),
              ),
            ],
          ).animate().fadeIn(duration: 400.ms),
          const SizedBox(height: 20),

          // Date & time card
          GlassCard(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            borderColor: AppColors.accentCyan.withValues(alpha: 0.2),
            child: Row(
              children: [
                Icon(Icons.calendar_today_rounded,
                    color: AppColors.accentCyan, size: 18),
                const SizedBox(width: 10),
                Text(
                  DateFormat('EEEE, dd MMMM yyyy').format(now),
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.accentGreen.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'On Duty',
                    style: TextStyle(
                      color: AppColors.accentGreen,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(delay: 100.ms, duration: 400.ms),

          // Bus Mode banner
          if (widget.service.busMode) ...[
            const SizedBox(height: 8),
            GlassCard(
              borderColor: AppColors.accentGreen.withValues(alpha: 0.4),
              backgroundColor: AppColors.accentGreen.withValues(alpha: 0.05),
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  const Icon(Icons.directions_bus_rounded,
                      color: AppColors.accentGreen, size: 20),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      '🚌 Bus Mode is ON — Bus lane is enabled at hostel gate',
                      style: TextStyle(
                        color: AppColors.accentGreen,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 300.ms),
          ],
          const SizedBox(height: 16),

          // Quick stats
          Text('Today\'s Overview',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _quickStat(
                  'Students Out',
                  '${todayAttendance['stillOut'] ?? 0}',
                  Icons.directions_walk_rounded,
                  AppColors.accentAmber,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _quickStat(
                  'Returned',
                  '${todayAttendance['returned'] ?? 0}',
                  Icons.home_rounded,
                  AppColors.accentGreen,
                ),
              ),
            ],
          ).animate().fadeIn(delay: 200.ms, duration: 400.ms),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _quickStat(
                  'Active Passes',
                  '${activePasses.length}',
                  Icons.qr_code_rounded,
                  AppColors.accentCyan,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _quickStat(
                  'Total Passes',
                  '$totalPasses',
                  Icons.receipt_long_rounded,
                  AppColors.primaryStart,
                ),
              ),
            ],
          ).animate().fadeIn(delay: 300.ms, duration: 400.ms),
          const SizedBox(height: 24),

          // Quick actions
          Text('Quick Actions', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 10),
          _actionTile(
            icon: Icons.qr_code_scanner_rounded,
            title: 'Scan QR Pass',
            subtitle: 'Scan a student\'s gate pass to record entry or exit',
            color: AppColors.accentCyan,
            onTap: () => setState(() => _currentIndex = 1),
          ).animate().fadeIn(delay: 400.ms, duration: 400.ms),
          _actionTile(
            icon: Icons.badge_rounded,
            title: 'View Active Passes',
            subtitle: 'See all students who currently have active gate passes',
            color: AppColors.accentAmber,
            onTap: () => setState(() => _currentIndex = 2),
          ).animate().fadeIn(delay: 500.ms, duration: 400.ms),
          const SizedBox(height: 24),

          // Recent activity (from gate logs)
          Text('Recent Gate Activity',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 10),
          ..._buildRecentActivity(),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _quickStat(String label, String value, IconData icon, Color color) {
    return GlassCard(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GlassCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      borderColor: color.withValues(alpha: 0.15),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary)),
                const SizedBox(height: 2),
                Text(subtitle,
                    style: TextStyle(
                        fontSize: 12, color: AppColors.textSecondary)),
              ],
            ),
          ),
          Icon(Icons.chevron_right_rounded,
              color: AppColors.textMuted, size: 22),
        ],
      ),
    );
  }

  List<Widget> _buildRecentActivity() {
    final allLogs = widget.service.getAllGateLogs();
    final recentLogs = allLogs.take(5).toList();

    if (recentLogs.isEmpty) {
      return [
        GlassCard(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Icon(Icons.history_rounded,
                      size: 40, color: AppColors.textMuted),
                  const SizedBox(height: 8),
                  Text('No gate activity yet',
                      style: TextStyle(
                          color: AppColors.textMuted, fontSize: 14)),
                ],
              ),
            ),
          ),
        ),
      ];
    }

    return recentLogs.map<Widget>((log) {
      final isEntry = log['action'] == 'entry';
      final timeFormat = DateFormat('hh:mm a');
      final gateLabel = log['gateType'] == 'hostel' ? 'Hostel Gate' : 'Main Gate';

      return GlassCard(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: (isEntry ? AppColors.accentGreen : AppColors.accentAmber)
                    .withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                isEntry ? Icons.login_rounded : Icons.logout_rounded,
                color:
                    isEntry ? AppColors.accentGreen : AppColors.accentAmber,
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${log['studentName']}',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    '${log['rollNumber']} • $gateLabel',
                    style: TextStyle(
                        fontSize: 11, color: AppColors.textMuted),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color:
                        (isEntry ? AppColors.accentGreen : AppColors.accentAmber)
                            .withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    isEntry ? 'ENTRY' : 'EXIT',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: isEntry
                          ? AppColors.accentGreen
                          : AppColors.accentAmber,
                    ),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  timeFormat.format(log['timestamp'] as DateTime),
                  style: TextStyle(
                      fontSize: 10, color: AppColors.textMuted),
                ),
              ],
            ),
          ],
        ),
      );
    }).toList();
  }

  // ─── Scan View ───────────────────────────────────────

  Widget _buildScanView() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          Text(
            'Scan QR Pass',
            style: Theme.of(context).textTheme.headlineLarge,
          ),
          Text(
            'Choose a gate and scan a student\'s pass',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 20),

          // Step 1: Select Gate
          _stepLabel('1', 'Which gate are you at?'),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: _gateOption(GateType.hostel, 'Hostel Gate',
                  Icons.apartment_rounded, AppColors.accentCyan)),
              const SizedBox(width: 12),
              Expanded(child: _gateOption(GateType.main, 'Main Gate',
                  Icons.door_front_door_rounded, AppColors.accentAmber)),
            ],
          ).animate().fadeIn(delay: 100.ms, duration: 400.ms),

          // Step 2: Select Lane (hostel gate only)
          if (_selectedGate == GateType.hostel) ...[
            const SizedBox(height: 20),
            _stepLabel('2', 'Which lane?'),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: LaneType.values.where((lane) {
                if (lane == LaneType.busMode && !widget.service.busMode) {
                  return false;
                }
                return true;
              }).map((lane) => _laneChip(lane)).toList(),
            ).animate().fadeIn(delay: 150.ms, duration: 400.ms),
          ],

          const SizedBox(height: 20),

          // Step 3: Scanner
          _stepLabel(
            _selectedGate == GateType.hostel ? '3' : '2',
            _selectedGate == GateType.hostel &&
                    _selectedLane == LaneType.exception
                ? 'Enter student details for override'
                : 'Scan the QR code',
          ),
          const SizedBox(height: 10),

          // Exception Lane or Standard Scanner
          if (_selectedGate == GateType.hostel &&
              _selectedLane == LaneType.exception)
            _buildExceptionLane()
          else
            _buildStandardScanner(),

          // Scan Result
          if (_scanResult.isNotEmpty) ...[
            const SizedBox(height: 12),
            _buildScanResultCard(),
          ],
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _stepLabel(String number, String text) {
    return Row(
      children: [
        Container(
          width: 26,
          height: 26,
          decoration: BoxDecoration(
            color: AppColors.primaryStart,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Text(
              number,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          text,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _gateOption(
      GateType gate, String label, IconData icon, Color color) {
    final isSelected = _selectedGate == gate;
    return GlassCard(
      onTap: () => setState(() => _selectedGate = gate),
      padding: const EdgeInsets.all(16),
      borderColor: isSelected ? color : null,
      backgroundColor: isSelected ? color.withValues(alpha: 0.08) : null,
      child: Column(
        children: [
          Icon(icon,
              color: isSelected ? color : AppColors.textMuted, size: 36),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              color: isSelected ? color : AppColors.textSecondary,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _laneChip(LaneType lane) {
    final isSelected = _selectedLane == lane;
    return GestureDetector(
      onTap: () => setState(() => _selectedLane = lane),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? lane.color.withValues(alpha: 0.15)
              : AppColors.glassWhite,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? lane.color : AppColors.glassBorder,
            width: isSelected ? 1.5 : 0.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(lane.icon,
                color: isSelected ? lane.color : AppColors.textMuted,
                size: 18),
            const SizedBox(width: 6),
            Text(
              lane.label,
              style: TextStyle(
                color:
                    isSelected ? lane.color : AppColors.textSecondary,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStandardScanner() {
    return GlassCard(
      borderColor: AppColors.primaryStart.withValues(alpha: 0.2),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            height: 180,
            decoration: BoxDecoration(
              color: AppColors.bgDark,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _isScanning
                    ? AppColors.accentGreen
                    : AppColors.glassBorder,
                width: _isScanning ? 2 : 0.5,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _isScanning
                      ? Icons.qr_code_scanner_rounded
                      : Icons.qr_code_2_rounded,
                  color: _isScanning
                      ? AppColors.accentGreen
                      : AppColors.textMuted,
                  size: 56,
                ),
                const SizedBox(height: 10),
                Text(
                  _isScanning ? 'Scanning...' : 'Camera preview area',
                  style: TextStyle(
                    color: _isScanning
                        ? AppColors.accentGreen
                        : AppColors.textMuted,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (_selectedGate == GateType.hostel) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Lane: ${_selectedLane.label}',
                    style: TextStyle(
                      color: _selectedLane.color.withValues(alpha: 0.7),
                      fontSize: 11,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Demo buttons — clearly labeled
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.bgSurface,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline_rounded,
                    color: AppColors.textMuted, size: 14),
                const SizedBox(width: 6),
                Text(
                  'Demo mode: tap a button to simulate a scan',
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: GlassButton(
                  label: 'Student Leaving',
                  icon: Icons.logout_rounded,
                  isSmall: true,
                  gradient: const LinearGradient(
                    colors: [AppColors.accentAmber, Color(0xFFD97706)],
                  ),
                  onPressed: () => _simulateScan('exit'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: GlassButton(
                  label: 'Student Entering',
                  icon: Icons.login_rounded,
                  isSmall: true,
                  gradient: const LinearGradient(
                    colors: [AppColors.accentGreen, Color(0xFF059669)],
                  ),
                  onPressed: () => _simulateScan('entry'),
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(delay: 200.ms, duration: 400.ms);
  }

  Widget _buildExceptionLane() {
    return GlassCard(
      borderColor: AppColors.accentRed.withValues(alpha: 0.3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.warning_amber_rounded,
                  color: AppColors.accentRed, size: 20),
              const SizedBox(width: 8),
              Text('Manual Override',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(color: AppColors.accentRed)),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Use this only when the student cannot scan their QR code',
            style: TextStyle(fontSize: 12, color: AppColors.textMuted),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _exceptionController,
            style: const TextStyle(color: AppColors.textPrimary),
            decoration: InputDecoration(
              labelText: 'Student Roll Number',
              hintText: 'e.g., CS21B1045',
              prefixIcon: const Icon(Icons.badge_rounded),
              filled: true,
              fillColor: AppColors.glassWhite,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.glassBorder),
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _exceptionReasonController,
            maxLines: 2,
            style: const TextStyle(color: AppColors.textPrimary),
            decoration: InputDecoration(
              labelText: 'Reason for Override',
              hintText: 'Why is a manual override needed?',
              prefixIcon: const Padding(
                padding: EdgeInsets.only(bottom: 24),
                child: Icon(Icons.edit_note_rounded),
              ),
              filled: true,
              fillColor: AppColors.glassWhite,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.glassBorder),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: GlassButton(
                  label: 'Override Exit',
                  icon: Icons.logout_rounded,
                  isSmall: true,
                  gradient: const LinearGradient(
                    colors: [AppColors.accentAmber, Color(0xFFD97706)],
                  ),
                  onPressed: () => _handleException('exit'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: GlassButton(
                  label: 'Override Entry',
                  icon: Icons.login_rounded,
                  isSmall: true,
                  gradient: const LinearGradient(
                    colors: [AppColors.accentGreen, Color(0xFF059669)],
                  ),
                  onPressed: () => _handleException('entry'),
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(delay: 200.ms, duration: 400.ms);
  }

  Widget _buildScanResultCard() {
    final isSuccess = _scanResult.startsWith('✓');
    final isWarning = _scanResult.startsWith('⚠');
    final color = isSuccess
        ? AppColors.accentGreen
        : isWarning
            ? AppColors.accentAmber
            : AppColors.accentRed;
    final icon = isSuccess
        ? Icons.check_circle_rounded
        : isWarning
            ? Icons.warning_rounded
            : Icons.error_rounded;

    return GlassCard(
      borderColor: color.withValues(alpha: 0.4),
      backgroundColor: color.withValues(alpha: 0.05),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _scanResult,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(duration: 300.ms)
        .shake(hz: 2, delay: 100.ms);
  }

  Future<void> _simulateScan(String action) async {
    setState(() => _isScanning = true);
    await Future.delayed(const Duration(milliseconds: 800));

    final passes = widget.service.qrPasses.where((p) => p.isActive).toList();
    if (passes.isEmpty) {
      setState(() {
        _isScanning = false;
        _scanResult = '✗ No active passes found';
      });
      return;
    }

    final error = await widget.service.scanQr(
      passes.first.id,
      _selectedGate,
      action,
      laneType: _selectedGate == GateType.hostel ? _selectedLane : null,
    );

    setState(() {
      _isScanning = false;
      if (error != null) {
        _scanResult = '✗ $error';
      } else {
        final gateName =
            _selectedGate == GateType.hostel ? 'Hostel Gate' : 'Main Gate';
        final laneInfo = _selectedGate == GateType.hostel
            ? ' (${_selectedLane.label})'
            : '';
        _scanResult =
            '✓ ${action == 'exit' ? 'EXIT' : 'ENTRY'} recorded at $gateName$laneInfo';
      }
    });
  }

  Future<void> _handleException(String action) async {
    final rollNumber = _exceptionController.text.trim();
    final reason = _exceptionReasonController.text.trim();

    if (rollNumber.isEmpty) {
      setState(
          () => _scanResult = '⚠ Please enter the student\'s roll number');
      return;
    }
    if (reason.isEmpty) {
      setState(() => _scanResult = '⚠ Please provide a reason for override');
      return;
    }

    setState(() => _isScanning = true);
    await Future.delayed(const Duration(milliseconds: 500));

    setState(() {
      _isScanning = false;
      _scanResult =
          '✓ OVERRIDE: ${action == 'exit' ? 'EXIT' : 'ENTRY'} recorded for $rollNumber';
      _exceptionController.clear();
      _exceptionReasonController.clear();
    });
  }

  // ─── Active Passes ──────────────────────────────────

  Widget _buildActivePasses(List<QrPass> activePasses) {
    final allPasses = widget.service.qrPasses;

    // Filter passes by search query
    final filteredPasses = _searchQuery.isEmpty
        ? activePasses
        : activePasses.where((p) {
            final query = _searchQuery.toLowerCase();
            return p.studentName.toLowerCase().contains(query) ||
                p.studentRollNumber.toLowerCase().contains(query);
          }).toList();

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          Text(
            'Active Passes',
            style: Theme.of(context).textTheme.headlineLarge,
          ),
          const SizedBox(height: 4),
          Text(
            '${activePasses.length} students with active passes • ${allPasses.length} total issued',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 12),

          // Search bar
          TextField(
            controller: _searchController,
            onChanged: (value) => setState(() => _searchQuery = value),
            style: const TextStyle(
                color: AppColors.textPrimary, fontSize: 14),
            decoration: InputDecoration(
              hintText: 'Search by name or roll number...',
              hintStyle: TextStyle(
                  color: AppColors.textMuted, fontSize: 13),
              prefixIcon: const Icon(Icons.search_rounded,
                  color: AppColors.textMuted, size: 20),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear_rounded,
                          color: AppColors.textMuted, size: 18),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _searchQuery = '');
                      },
                    )
                  : null,
              filled: true,
              fillColor: AppColors.glassWhite,
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide:
                    const BorderSide(color: AppColors.glassBorder),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide:
                    const BorderSide(color: AppColors.glassBorder),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(
                    color: AppColors.primaryStart, width: 1.5),
              ),
            ),
          ),
          const SizedBox(height: 12),

          if (filteredPasses.isEmpty && _searchQuery.isNotEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(30),
                child: Column(
                  children: [
                    Icon(Icons.search_off_rounded,
                        size: 48, color: AppColors.textMuted),
                    const SizedBox(height: 12),
                    Text('No passes match "$_searchQuery"',
                        style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 14)),
                  ],
                ),
              ),
            )
          else if (filteredPasses.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(40),
                child: Column(
                  children: [
                    Icon(Icons.badge_rounded,
                        size: 64, color: AppColors.textMuted),
                    const SizedBox(height: 16),
                    Text('No active passes right now',
                        style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 15,
                            fontWeight: FontWeight.w500)),
                    const SizedBox(height: 4),
                    Text(
                        'Students with approved leave will appear here',
                        style: TextStyle(
                            color: AppColors.textMuted, fontSize: 12)),
                  ],
                ),
              ),
            )
          else
            ...filteredPasses.map((pass) {
              Color stateColor;
              String stateDescription;
              IconData stateIcon;
              switch (pass.state) {
                case QrState.unused:
                  stateColor = AppColors.accentCyan;
                  stateDescription = 'Not yet used';
                  stateIcon = Icons.qr_code_rounded;
                  break;
                case QrState.hostelExited:
                  stateColor = AppColors.accentAmber;
                  stateDescription = 'Left hostel, heading to main gate';
                  stateIcon = Icons.directions_walk_rounded;
                  break;
                case QrState.campusExited:
                  stateColor = AppColors.accentPink;
                  stateDescription = 'Left campus';
                  stateIcon = Icons.flight_takeoff_rounded;
                  break;
                case QrState.campusEntered:
                  stateColor = AppColors.accentGreen;
                  stateDescription = 'Back on campus, heading to hostel';
                  stateIcon = Icons.flight_land_rounded;
                  break;
                default:
                  stateColor = AppColors.textMuted;
                  stateDescription = pass.state.label;
                  stateIcon = Icons.check_circle_rounded;
              }

              return GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: stateColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(stateIcon,
                              color: stateColor, size: 24),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(pass.studentName,
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium),
                              Text(pass.studentRollNumber,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall),
                            ],
                          ),
                        ),
                        StatusBadge(
                          label: pass.state.label,
                          color: stateColor,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: stateColor.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.info_outline_rounded,
                              color: stateColor, size: 14),
                          const SizedBox(width: 6),
                          Text(
                            stateDescription,
                            style: TextStyle(
                              fontSize: 12,
                              color: stateColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  // ─── Profile ─────────────────────────────────────────

  Widget _buildProfile(AppUser user) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 24),

          // Avatar
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(26),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryStart.withValues(alpha: 0.25),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const Icon(Icons.shield_rounded,
                color: Colors.white, size: 40),
          ).animate().fadeIn(duration: 400.ms).scale(
                begin: const Offset(0.8, 0.8),
                duration: 500.ms,
                curve: Curves.elasticOut,
              ),
          const SizedBox(height: 16),

          // Name & email
          Text(user.name,
              style: Theme.of(context).textTheme.headlineMedium,
              textAlign: TextAlign.center),
          const SizedBox(height: 4),
          Text(user.email,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center),
          const SizedBox(height: 10),
          StatusBadge(
            label: 'Security Personnel',
            color: AppColors.primaryStart,
          ),
          const SizedBox(height: 28),

          // Profile info cards
          _profileInfoCard(
            Icons.shield_rounded,
            'Role',
            'Gate Security',
            AppColors.primaryStart,
          ).animate().fadeIn(delay: 100.ms, duration: 400.ms),
          _profileInfoCard(
            Icons.email_rounded,
            'Email',
            user.email,
            AppColors.accentCyan,
          ).animate().fadeIn(delay: 200.ms, duration: 400.ms),
          if (user.phone != null)
            _profileInfoCard(
              Icons.phone_rounded,
              'Phone',
              user.phone!,
              AppColors.accentGreen,
            ).animate().fadeIn(delay: 300.ms, duration: 400.ms),
          _profileInfoCard(
            Icons.access_time_rounded,
            'Shift Status',
            'On Duty',
            AppColors.accentGreen,
          ).animate().fadeIn(delay: 400.ms, duration: 400.ms),
          const SizedBox(height: 24),

          // Logout button
          SizedBox(
            width: double.infinity,
            child: GlassButton(
              label: 'Logout',
              icon: Icons.logout_rounded,
              gradient: const LinearGradient(
                colors: [AppColors.accentRed, Color(0xFFDC2626)],
              ),
              onPressed: () {
                widget.service.logout();
                Navigator.of(context).pushReplacementNamed('/');
              },
            ),
          ).animate().fadeIn(delay: 500.ms, duration: 400.ms),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _profileInfoCard(
      IconData icon, String label, String value, Color color) {
    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textMuted,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
