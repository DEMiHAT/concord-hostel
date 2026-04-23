import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../services/app_service.dart';
import '../../widgets/glass_widgets.dart';

class AdminHomeScreen extends StatefulWidget {
  final AppService service;
  const AdminHomeScreen({super.key, required this.service});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  int _currentIndex = 0;
  bool _isLoading = true;
  Map<String, int> _stats = {};
  Map<String, dynamic> _attendance = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      // Try async first (Firebase)
      final dynamic svc = widget.service;
      try {
        _stats = await svc.getStatsAsync() as Map<String, int>;
      } catch (_) {
        _stats = widget.service.getStats();
      }
    } catch (_) {
      _stats = widget.service.getStats();
    }
    _attendance = widget.service.getTodayAttendance();

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return GlassScaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: AppColors.primaryStart),
              const SizedBox(height: 16),
              Text('Loading...', style: TextStyle(color: AppColors.textMuted)),
            ],
          ),
        ),
      );
    }

    return GlassScaffold(
      bottomNavigationBar: _buildBottomNav(),
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _buildDashboard(),
          _buildBusMode(),
          _buildAuditLogs(),
          _buildSettings(),
        ],
      ),
    );
  }

  Widget _buildBottomNav() {
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
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.dashboard_rounded),
                label: 'Dashboard',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.directions_bus_rounded),
                label: 'Bus Mode',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.history_rounded),
                label: 'Audit',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.settings_rounded),
                label: 'Settings',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDashboard() {
    final stats = _stats;
    final attendance = _attendance;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Admin Panel',
                      style: Theme.of(context).textTheme.headlineLarge,
                    ),
                    Text(
                      'System overview & management',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () {
                  widget.service.logout();
                  Navigator.of(context).pushReplacementNamed('/');
                },
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.admin_panel_settings_rounded,
                      color: Colors.white, size: 22),
                ),
              ),
            ],
          ).animate().fadeIn(duration: 400.ms),
          const SizedBox(height: 24),

          // Stats Grid
          Row(
            children: [
              Expanded(
                child: StatCard(
                  title: 'Total Requests',
                  value: '${stats['total']}',
                  icon: Icons.receipt_long_rounded,
                  color: AppColors.primaryStart,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: StatCard(
                  title: 'Pending',
                  value: '${stats['pending']}',
                  icon: Icons.hourglass_top_rounded,
                  color: AppColors.accentAmber,
                ),
              ),
            ],
          ).animate().fadeIn(delay: 200.ms, duration: 400.ms),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: StatCard(
                  title: 'Approved',
                  value: '${stats['approved']}',
                  icon: Icons.check_circle_rounded,
                  color: AppColors.accentGreen,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: StatCard(
                  title: 'Rejected',
                  value: '${stats['rejected']}',
                  icon: Icons.cancel_rounded,
                  color: AppColors.accentRed,
                ),
              ),
            ],
          ).animate().fadeIn(delay: 300.ms, duration: 400.ms),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: StatCard(
                  title: 'Active QR',
                  value: '${stats['activeQr']}',
                  icon: Icons.qr_code_rounded,
                  color: AppColors.accentCyan,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: StatCard(
                  title: 'Students',
                  value: '${stats['totalStudents']}',
                  icon: Icons.people_rounded,
                  color: AppColors.accentPink,
                ),
              ),
            ],
          ).animate().fadeIn(delay: 400.ms, duration: 400.ms),
          const SizedBox(height: 24),

          // Today's Attendance
          Text(
            "Today's Attendance",
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          GlassCard(
            child: Column(
              children: [
                _attendanceRow(
                  Icons.logout_rounded,
                  'Exited Hostel',
                  '${attendance['exitedHostel']}',
                  AppColors.accentAmber,
                ),
                const Divider(color: AppColors.glassBorder, height: 16),
                _attendanceRow(
                  Icons.door_front_door_rounded,
                  'Exited Campus',
                  '${attendance['exitedCampus']}',
                  AppColors.accentPink,
                ),
                const Divider(color: AppColors.glassBorder, height: 16),
                _attendanceRow(
                  Icons.login_rounded,
                  'Returned',
                  '${attendance['returned']}',
                  AppColors.accentGreen,
                ),
                const Divider(color: AppColors.glassBorder, height: 16),
                _attendanceRow(
                  Icons.person_off_rounded,
                  'Still Outside',
                  '${attendance['stillOut']}',
                  AppColors.accentRed,
                ),
              ],
            ),
          ).animate().fadeIn(delay: 500.ms, duration: 400.ms),
          const SizedBox(height: 24),

          // Quick Actions
          Text(
            'Quick Actions',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          _actionTile(
            Icons.directions_bus_rounded,
            'Bus Mode',
            widget.service.busMode ? 'Active' : 'Inactive',
            widget.service.busMode ? AppColors.accentGreen : AppColors.textMuted,
            () => setState(() {
              _currentIndex = 1;
            }),
          ),
          _actionTile(
            Icons.people_rounded,
            'Block Management',
            'Manage hostels',
            AppColors.primaryStart,
            () => _showBlockManagement(),
          ),
          _actionTile(
            Icons.schedule_rounded,
            'Peak Hours',
            'Configure time windows',
            AppColors.accentAmber,
            () => _showPeakHoursConfig(),
          ),
          _actionTile(
            Icons.bar_chart_rounded,
            'Attendance Report',
            'View attendance data',
            AppColors.accentCyan,
            () => _showAttendanceReport(),
          ),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _attendanceRow(IconData icon, String label, String value, Color color) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(label, style: Theme.of(context).textTheme.bodyMedium),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: color,
                fontWeight: FontWeight.w700,
              ),
        ),
      ],
    );
  }

  Widget _actionTile(
    IconData icon,
    String title,
    String subtitle,
    Color color,
    VoidCallback onTap,
  ) {
    return GlassCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleMedium),
                Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded,
              color: AppColors.textMuted, size: 20),
        ],
      ),
    );
  }

  Widget _buildBusMode() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          Text(
            'Bus Mode',
            style: Theme.of(context).textTheme.headlineLarge,
          ),
          Text(
            'Enable bulk departure management',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 24),

          // Bus Mode Toggle
          GlassCard(
            borderColor: widget.service.busMode
                ? AppColors.accentGreen.withValues(alpha: 0.4)
                : AppColors.glassBorder,
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: (widget.service.busMode
                            ? AppColors.accentGreen
                            : AppColors.textMuted)
                        .withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    Icons.directions_bus_rounded,
                    color: widget.service.busMode
                        ? AppColors.accentGreen
                        : AppColors.textMuted,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Bus Departure Mode',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Text(
                        widget.service.busMode
                            ? 'Active — bus lane enabled for security'
                            : 'Inactive — standard gate mode',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                Switch.adaptive(
                  value: widget.service.busMode,
                  onChanged: (v) {
                    widget.service.setBusMode(v);
                    setState(() {});
                  },
                  activeColor: AppColors.accentGreen,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          if (widget.service.busMode) ...[
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.info_outline_rounded,
                          color: AppColors.accentCyan, size: 18),
                      const SizedBox(width: 8),
                      Text('Bus Mode Info',
                          style: Theme.of(context).textTheme.titleMedium),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _infoRow('Mode', 'Special bus departure queue'),
                  _infoRow('Validation', 'Bus manifest check'),
                  _infoRow('Lane', 'Dedicated bus lane at hostel gate'),
                  _infoRow('Security', 'Bus lane visible to gate security'),
                  _infoRow('Status', 'All passes bulk-processed'),
                ],
              ),
            ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.05),
          ],
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    )),
          ),
          Expanded(
            child: Text(value,
                style: Theme.of(context).textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }

  Widget _buildAuditLogs() {
    final approvalLogs = widget.service.getAllApprovalHistory();
    final gateLogs = widget.service.getAllGateLogs();
    final dateFormat = DateFormat('dd MMM, hh:mm a');

    return DefaultTabController(
      length: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              'Audit Logs',
              style: Theme.of(context).textTheme.headlineLarge,
            ),
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              '${approvalLogs.length + gateLogs.length} total log entries',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          const SizedBox(height: 16),

          // Tab bar
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              color: AppColors.glassWhite,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.glassBorder, width: 0.5),
            ),
            child: TabBar(
              indicator: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(12),
              ),
              labelColor: Colors.white,
              unselectedLabelColor: AppColors.textMuted,
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              tabs: [
                Tab(text: 'Approvals (${approvalLogs.length})'),
                Tab(text: 'Gate Logs (${gateLogs.length})'),
              ],
            ),
          ),
          const SizedBox(height: 12),

          Expanded(
            child: TabBarView(
              children: [
                // Approval logs
                ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  physics: const BouncingScrollPhysics(),
                  itemCount: approvalLogs.length,
                  itemBuilder: (context, index) {
                    final log = approvalLogs[index];
                    Color actionColor;
                    IconData actionIcon;
                    switch (log['action']) {
                      case 'approved':
                        actionColor = AppColors.accentGreen;
                        actionIcon = Icons.check_circle_rounded;
                        break;
                      case 'rejected':
                        actionColor = AppColors.accentRed;
                        actionIcon = Icons.cancel_rounded;
                        break;
                      case 'documents_requested':
                        actionColor = AppColors.accentCyan;
                        actionIcon = Icons.upload_file_rounded;
                        break;
                      case 'documents_submitted':
                        actionColor = AppColors.accentAmber;
                        actionIcon = Icons.description_rounded;
                        break;
                      default:
                        actionColor = AppColors.primaryStart;
                        actionIcon = Icons.arrow_forward_rounded;
                    }

                    return GlassCard(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: actionColor.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(actionIcon,
                                color: actionColor, size: 18),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${log['approverName']} (${log['approverRole']})',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(fontSize: 13),
                                ),
                                Text(
                                  '${(log['action'] as String).toUpperCase()} • ${log['studentName']} • ${log['leaveType']}',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                                if (log['comment'] != null)
                                  Text(
                                    log['comment'],
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(
                                            fontStyle: FontStyle.italic),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                Text(
                                  dateFormat.format(log['timestamp']),
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(fontSize: 10),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),

                // Gate logs
                ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  physics: const BouncingScrollPhysics(),
                  itemCount: gateLogs.length,
                  itemBuilder: (context, index) {
                    final log = gateLogs[index];
                    final isExit = log['action'] == 'exit';

                    return GlassCard(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: (isExit
                                      ? AppColors.accentAmber
                                      : AppColors.accentGreen)
                                  .withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              isExit
                                  ? Icons.logout_rounded
                                  : Icons.login_rounded,
                              color: isExit
                                  ? AppColors.accentAmber
                                  : AppColors.accentGreen,
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${log['studentName']} (${log['rollNumber']})',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(fontSize: 13),
                                ),
                                Text(
                                  '${(log['action'] as String).toUpperCase()} at ${(log['gateType'] as String).toUpperCase()} gate${log['laneType'] != null ? ' [${log['laneType']}]' : ''}',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                                Text(
                                  dateFormat.format(log['timestamp']),
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(fontSize: 10),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettings() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          Text(
            'Settings',
            style: Theme.of(context).textTheme.headlineLarge,
          ),
          Text(
            'System configuration',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 24),
          _settingTile(
              Icons.notifications_rounded, 'Notifications', 'Push notification settings', AppColors.accentAmber),
          _settingTile(
              Icons.security_rounded, 'Security Rules', 'Configure gate rules', AppColors.accentRed),
          _settingTile(
              Icons.schedule_rounded, 'Peak Hours', 'Set peak hour windows', AppColors.primaryStart),
          _settingTile(
              Icons.apartment_rounded, 'Hostel Blocks', 'Manage hostel blocks', AppColors.accentCyan),
          _settingTile(
              Icons.people_rounded, 'User Management', 'Manage user roles', AppColors.accentGreen),
          _settingTile(
              Icons.backup_rounded, 'Data Backup', 'Export system data', AppColors.accentPink),
          const SizedBox(height: 32),
          GlassButton(
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
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _settingTile(
      IconData icon, String title, String subtitle, Color color) {
    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleMedium),
                Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded,
              color: AppColors.textMuted, size: 20),
        ],
      ),
    );
  }

  void _showBlockManagement() {
    final blocks = widget.service.getStudentsByBlock();
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.bgCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.glassBorder,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text('Block Management',
                style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 16),
            ...blocks.entries.map((entry) => GlassCard(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: AppColors.primaryStart.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(Icons.apartment_rounded,
                            color: AppColors.primaryStart, size: 22),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(entry.key,
                                style:
                                    Theme.of(context).textTheme.titleMedium),
                            Text(
                              '${entry.value.length} student(s)',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      ...entry.value.take(3).map((s) => Container(
                            width: 28,
                            height: 28,
                            margin: const EdgeInsets.only(left: 4),
                            decoration: BoxDecoration(
                              gradient: AppColors.primaryGradient,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Center(
                              child: Text(
                                s.name[0],
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700),
                              ),
                            ),
                          )),
                    ],
                  ),
                )),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _showPeakHoursConfig() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.bgCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.glassBorder,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text('Peak Hours Configuration',
                style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 16),
            _peakHourRow('Morning Rush', '07:00 AM - 09:00 AM', true),
            _peakHourRow('Lunch Break', '12:00 PM - 02:00 PM', false),
            _peakHourRow('Evening Return', '05:00 PM - 08:00 PM', true),
            _peakHourRow('Night Curfew', '10:00 PM - 06:00 AM', true),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _peakHourRow(String label, String time, bool enabled) {
    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(Icons.schedule_rounded,
              color: enabled ? AppColors.accentAmber : AppColors.textMuted,
              size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontSize: 14)),
                Text(time, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
          StatusBadge(
            label: enabled ? 'Active' : 'Inactive',
            color: enabled ? AppColors.accentGreen : AppColors.textMuted,
          ),
        ],
      ),
    );
  }

  void _showAttendanceReport() {
    final attendance = widget.service.getTodayAttendance();
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.bgCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.glassBorder,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text("Today's Attendance Report",
                style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 8),
            Text(
              DateFormat('EEEE, dd MMMM yyyy').format(DateTime.now()),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _miniStatCard(
                    'Total Movement',
                    '${attendance['total']}',
                    AppColors.primaryStart,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _miniStatCard(
                    'Still Outside',
                    '${attendance['stillOut']}',
                    AppColors.accentRed,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _miniStatCard(
                    'Returned',
                    '${attendance['returned']}',
                    AppColors.accentGreen,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _miniStatCard(
                    'Exited Campus',
                    '${attendance['exitedCampus']}',
                    AppColors.accentAmber,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _miniStatCard(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 0.5),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              color: color.withValues(alpha: 0.8),
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
