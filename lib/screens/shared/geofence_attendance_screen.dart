import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../models/enums.dart';
import '../../models/geofence_attendance.dart';
import '../../services/mock_service.dart';
import '../../widgets/glass_widgets.dart';

/// Unified geofence attendance screen with role-driven views:
/// - RT: open/close window, block analytics, raise anomaly
/// - Student: mark attendance, see percentage
/// - Warden: full logs, overall analytics
/// - Faculty: department students patterns
/// - Parent: child percentage + anomaly alerts
class GeofenceAttendanceScreen extends StatefulWidget {
  final MockService service;
  const GeofenceAttendanceScreen({super.key, required this.service});

  @override
  State<GeofenceAttendanceScreen> createState() => _GeofenceAttendanceScreenState();
}

class _GeofenceAttendanceScreenState extends State<GeofenceAttendanceScreen>
    with SingleTickerProviderStateMixin {
  bool _loading = false;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    final role = widget.service.currentUser!.role;
    final tabCount = _getTabCount(role);
    _tabController = TabController(length: tabCount, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  int _getTabCount(UserRole role) {
    switch (role) {
      case UserRole.rt:
        return 3; // Session, Analytics, Anomalies
      case UserRole.student:
        return 2; // Mark, History
      case UserRole.warden:
      case UserRole.admin:
        return 3; // Overview, Logs, Anomalies
      case UserRole.faculty:
        return 2; // Students, Patterns
      case UserRole.parent:
        return 2; // Summary, Alerts
      default:
        return 1;
    }
  }

  List<Tab> _getTabs(UserRole role) {
    switch (role) {
      case UserRole.rt:
        return const [
          Tab(text: 'Session'),
          Tab(text: 'Analytics'),
          Tab(text: 'Anomalies'),
        ];
      case UserRole.student:
        return const [
          Tab(text: 'Attendance'),
          Tab(text: 'History'),
        ];
      case UserRole.warden:
      case UserRole.admin:
        return const [
          Tab(text: 'Overview'),
          Tab(text: 'Logs'),
          Tab(text: 'Anomalies'),
        ];
      case UserRole.faculty:
        return const [
          Tab(text: 'Students'),
          Tab(text: 'Patterns'),
        ];
      case UserRole.parent:
        return const [
          Tab(text: 'Summary'),
          Tab(text: 'Alerts'),
        ];
      default:
        return const [Tab(text: 'Attendance')];
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.service.currentUser!;

    return GlassScaffold(
      appBar: AppBar(
        title: const Text('Geofence Attendance'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              color: AppColors.bgSurface,
              borderRadius: BorderRadius.circular(14),
            ),
            child: TabBar(
              controller: _tabController,
              labelColor: Colors.white,
              unselectedLabelColor: AppColors.textMuted,
              labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              unselectedLabelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
              indicator: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: AppColors.primaryGradient,
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              tabs: _getTabs(user.role),
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: _getTabViews(user.role),
      ),
    );
  }

  List<Widget> _getTabViews(UserRole role) {
    switch (role) {
      case UserRole.rt:
        return [_buildRtSessionView(), _buildRtAnalyticsView(), _buildRtAnomaliesView()];
      case UserRole.student:
        return [_buildStudentAttendanceView(), _buildStudentHistoryView()];
      case UserRole.warden:
      case UserRole.admin:
        return [_buildWardenOverview(), _buildWardenLogsView(), _buildWardenAnomaliesView()];
      case UserRole.faculty:
        return [_buildFacultyStudentsView(), _buildFacultyPatternsView()];
      case UserRole.parent:
        return [_buildParentSummaryView(), _buildParentAlertsView()];
      default:
        return [_buildStudentAttendanceView()];
    }
  }

  // ═══════════════════════════════════════════
  // RT VIEWS
  // ═══════════════════════════════════════════

  Widget _buildRtSessionView() {
    final user = widget.service.currentUser!;
    final block = user.hostelBlock ?? 'Block A';
    final activeSession = widget.service.getActiveSession(block);
    final recentSessions = widget.service.getBlockSessions(block).take(5).toList();

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),

          // Active session card or open button
          if (activeSession != null) ...[
            _buildActiveSessionCard(activeSession),
          ] else ...[
            _buildOpenWindowCard(block),
          ],
          const SizedBox(height: 24),

          // Live check-ins for active session
          if (activeSession != null) ...[
            Text('Live Check-ins', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            ..._buildCheckInList(activeSession.id),
            const SizedBox(height: 24),
          ],

          // Recent sessions
          Text('Recent Sessions', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          if (recentSessions.isEmpty)
            _buildEmptyState(Icons.history_rounded, 'No sessions yet')
          else
            ...recentSessions.map((s) => _buildSessionCard(s)),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildOpenWindowCard(String block) {
    return GlassCard(
      padding: const EdgeInsets.all(24),
      borderColor: AppColors.accentGreen.withValues(alpha: 0.3),
      backgroundColor: AppColors.accentGreen.withValues(alpha: 0.03),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF059669), Color(0xFF10B981)],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: AppColors.accentGreen.withValues(alpha: 0.3),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: const Icon(Icons.location_on_rounded, color: Colors.white, size: 32),
          ),
          const SizedBox(height: 16),
          Text(
            'Open Attendance Window',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 4),
          Text(
            'Start collecting geofence attendance for $block',
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: GlassButton(
              label: 'Open Window',
              icon: Icons.play_arrow_rounded,
              isLoading: _loading,
              gradient: const LinearGradient(
                colors: [Color(0xFF059669), Color(0xFF10B981)],
              ),
              onPressed: _loading
                  ? null
                  : () async {
                      setState(() => _loading = true);
                      await widget.service.openAttendanceWindow(hostelBlock: block);
                      setState(() => _loading = false);
                    },
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).scale(begin: const Offset(0.95, 0.95));
  }

  Widget _buildActiveSessionCard(GeofenceSession session) {
    final elapsed = session.duration;
    final minutes = elapsed.inMinutes;
    final seconds = elapsed.inSeconds % 60;

    return GlassCard(
      padding: const EdgeInsets.all(20),
      borderColor: AppColors.accentGreen.withValues(alpha: 0.5),
      backgroundColor: AppColors.accentGreen.withValues(alpha: 0.05),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: AppColors.accentGreen,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.accentGreen.withValues(alpha: 0.5),
                      blurRadius: 8,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Text('LIVE SESSION',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.accentGreen,
                      letterSpacing: 1.2)),
              const Spacer(),
              Text('${minutes}m ${seconds}s',
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary)),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildSessionStat(
                '${session.markedCount}',
                'Checked In',
                AppColors.accentGreen,
              ),
              const SizedBox(width: 16),
              _buildSessionStat(
                '${session.totalStudents - session.markedCount}',
                'Pending',
                AppColors.accentAmber,
              ),
              const SizedBox(width: 16),
              _buildSessionStat(
                '${(session.completionRate * 100).toInt()}%',
                'Rate',
                AppColors.accentCyan,
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Completion progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: session.completionRate,
              minHeight: 8,
              backgroundColor: AppColors.bgSurface,
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.accentGreen),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: GlassButton(
              label: 'Close Window',
              icon: Icons.stop_rounded,
              isLoading: _loading,
              gradient: const LinearGradient(
                colors: [AppColors.accentRed, Color(0xFFDC2626)],
              ),
              onPressed: _loading
                  ? null
                  : () async {
                      setState(() => _loading = true);
                      await widget.service.closeAttendanceWindow(session.id);
                      setState(() => _loading = false);
                    },
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms);
  }

  Widget _buildSessionStat(String value, String label, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(value,
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: color)),
            const SizedBox(height: 2),
            Text(label,
                style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textMuted)),
          ],
        ),
      ),
    );
  }

  Widget _buildSessionCard(GeofenceSession session) {
    final dateFormat = DateFormat('dd MMM, HH:mm');
    return GlassCard(
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: (session.isActive ? AppColors.accentGreen : AppColors.textMuted)
                  .withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              session.isActive ? Icons.wifi_tethering_rounded : Icons.check_circle_rounded,
              color: session.isActive ? AppColors.accentGreen : AppColors.textMuted,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(dateFormat.format(session.startTime),
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                Text(
                    '${session.markedCount}/${session.totalStudents} students • ${(session.completionRate * 100).toInt()}%',
                    style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
          StatusBadge(
            label: session.status.label,
            color: session.isActive ? AppColors.accentGreen : AppColors.textMuted,
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms);
  }

  List<Widget> _buildCheckInList(String sessionId) {
    final checkIns = widget.service.getSessionCheckIns(sessionId);
    if (checkIns.isEmpty) {
      return [
        _buildEmptyState(Icons.people_outline_rounded, 'No check-ins yet. Waiting for students...'),
      ];
    }

    return checkIns.map((c) {
      return GlassCard(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text(c.studentName[0],
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(c.studentName,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                          fontSize: 13)),
                  Text('${c.rollNumber} • ${DateFormat('HH:mm').format(c.timestamp)}',
                      style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
            Icon(Icons.check_circle_rounded, color: AppColors.accentGreen, size: 20),
          ],
        ),
      );
    }).toList();
  }

  Widget _buildRtAnalyticsView() {
    final user = widget.service.currentUser!;
    final block = user.hostelBlock ?? 'Block A';
    final summaries = widget.service.getBlockAttendanceSummary(block);
    final stats = widget.service.getGeofenceAttendanceStats();
    final anomalyCount = widget.service.getUnresolvedAnomalyCount(block);

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),

          // Stats overview
          Row(
            children: [
              Expanded(
                child: StatCard(
                  title: 'Sessions',
                  value: '${stats['totalSessions']}',
                  icon: Icons.calendar_today_rounded,
                  color: AppColors.accentCyan,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: StatCard(
                  title: 'Avg Rate',
                  value: '${(stats['avgAttendance'] as double).toInt()}%',
                  icon: Icons.trending_up_rounded,
                  color: AppColors.accentGreen,
                ),
              ),
            ],
          ).animate().fadeIn(duration: 400.ms),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: StatCard(
                  title: 'Check-ins',
                  value: '${stats['totalCheckIns']}',
                  icon: Icons.how_to_reg_rounded,
                  color: AppColors.primaryStart,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: StatCard(
                  title: 'Anomalies',
                  value: '$anomalyCount',
                  icon: Icons.warning_rounded,
                  color: anomalyCount > 0 ? AppColors.accentRed : AppColors.accentGreen,
                ),
              ),
            ],
          ).animate().fadeIn(delay: 200.ms, duration: 400.ms),
          const SizedBox(height: 24),

          // Student-wise breakdown
          Text('Student Breakdown — $block',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          ...summaries.map((s) => _buildStudentSummaryCard(s)),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildStudentSummaryCard(StudentAttendanceSummary summary) {
    final Color percentColor;
    if (summary.percentage >= 85) {
      percentColor = AppColors.accentGreen;
    } else if (summary.percentage >= 70) {
      percentColor = AppColors.accentAmber;
    } else {
      percentColor = AppColors.accentRed;
    }

    return GlassCard(
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(summary.studentName[0],
                      style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16)),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(summary.studentName,
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                    Text('${summary.rollNumber} • ${summary.attended}/${summary.totalSessions} sessions',
                        style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('${summary.percentage.toInt()}%',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: percentColor)),
                  if (summary.anomalyCount > 0)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.warning_rounded, size: 12, color: AppColors.accentRed),
                        const SizedBox(width: 2),
                        Text('${summary.anomalyCount}',
                            style: TextStyle(fontSize: 11, color: AppColors.accentRed)),
                      ],
                    ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: summary.percentage / 100,
              minHeight: 6,
              backgroundColor: AppColors.bgSurface,
              valueColor: AlwaysStoppedAnimation<Color>(percentColor),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms);
  }

  Widget _buildRtAnomaliesView() {
    final user = widget.service.currentUser!;
    final block = user.hostelBlock ?? 'Block A';
    final summaries = widget.service.getBlockAttendanceSummary(block);
    final anomalies = widget.service.getAllAnomalies()
        .where((a) => a.hostelBlock == block)
        .toList();

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),

          // Raise new anomaly button
          GlassButton(
            label: 'Raise Anomaly',
            icon: Icons.add_alert_rounded,
            gradient: const LinearGradient(
              colors: [AppColors.accentAmber, Color(0xFFD97706)],
            ),
            onPressed: () => _showRaiseAnomalyDialog(summaries),
          ).animate().fadeIn(duration: 400.ms),
          const SizedBox(height: 24),

          // Existing anomalies
          Text('Active Anomalies', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          ...anomalies.where((a) => !a.resolved).map((a) => _buildAnomalyCard(a)),

          if (anomalies.where((a) => !a.resolved).isEmpty)
            _buildEmptyState(Icons.check_circle_outline_rounded, 'No active anomalies'),

          const SizedBox(height: 24),

          // Resolved
          if (anomalies.where((a) => a.resolved).isNotEmpty) ...[
            Text('Resolved', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            ...anomalies.where((a) => a.resolved).map((a) => _buildAnomalyCard(a)),
          ],
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  void _showRaiseAnomalyDialog(List<StudentAttendanceSummary> summaries) {
    String? selectedStudentId;
    AnomalyType selectedType = AnomalyType.frequentAbsence;
    final descController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: AppColors.bgCard,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Raise Anomaly', style: TextStyle(color: AppColors.textPrimary)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Student', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: AppColors.bgSurface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.glassBorder),
                  ),
                  child: DropdownButton<String>(
                    isExpanded: true,
                    value: selectedStudentId,
                    hint: const Text('Select student'),
                    underline: const SizedBox(),
                    dropdownColor: AppColors.bgCard,
                    items: summaries.map((s) => DropdownMenuItem(
                      value: s.studentId,
                      child: Text('${s.studentName} (${s.percentage.toInt()}%)',
                          style: const TextStyle(color: AppColors.textPrimary)),
                    )).toList(),
                    onChanged: (v) => setDialogState(() => selectedStudentId = v),
                  ),
                ),
                const SizedBox(height: 16),
                const Text('Type', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: AppColors.bgSurface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.glassBorder),
                  ),
                  child: DropdownButton<AnomalyType>(
                    isExpanded: true,
                    value: selectedType,
                    underline: const SizedBox(),
                    dropdownColor: AppColors.bgCard,
                    items: AnomalyType.values.map((t) => DropdownMenuItem(
                      value: t,
                      child: Text('${t.icon} ${t.label}',
                          style: const TextStyle(color: AppColors.textPrimary)),
                    )).toList(),
                    onChanged: (v) => setDialogState(() => selectedType = v!),
                  ),
                ),
                const SizedBox(height: 16),
                const Text('Description', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                const SizedBox(height: 6),
                TextField(
                  controller: descController,
                  maxLines: 3,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: InputDecoration(
                    hintText: 'Describe the anomaly...',
                    filled: true,
                    fillColor: AppColors.bgSurface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.glassBorder),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel', style: TextStyle(color: AppColors.textMuted)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.accentAmber),
              onPressed: () async {
                if (selectedStudentId != null && descController.text.trim().isNotEmpty) {
                  await widget.service.raiseAttendanceAnomaly(
                    studentId: selectedStudentId!,
                    type: selectedType,
                    description: descController.text.trim(),
                  );
                  if (ctx.mounted) Navigator.pop(ctx);
                  setState(() {});
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Anomaly raised & parent notified ⚠'),
                        backgroundColor: AppColors.accentAmber,
                      ),
                    );
                  }
                }
              },
              child: const Text('Raise'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnomalyCard(AttendanceAnomaly anomaly) {
    final color = anomaly.resolved ? AppColors.accentGreen : AppColors.accentRed;

    return GlassCard(
      borderColor: color.withValues(alpha: 0.2),
      backgroundColor: color.withValues(alpha: 0.03),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(anomaly.type.icon, style: const TextStyle(fontSize: 20)),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(anomaly.studentName,
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                    Text('${anomaly.rollNumber} • ${anomaly.type.label}',
                        style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              ),
              StatusBadge(
                label: anomaly.resolved ? 'Resolved' : 'Active',
                color: color,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(anomaly.description,
              style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 4),
          Text('Raised by ${anomaly.raisedByName} • ${DateFormat('dd MMM').format(anomaly.raisedAt)}',
              style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
          if (anomaly.parentResponse != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.bgSurface,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.family_restroom_rounded, size: 16, color: AppColors.accentAmber),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text('Parent: ${anomaly.parentResponse}',
                        style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    ).animate().fadeIn(duration: 300.ms);
  }

  // ═══════════════════════════════════════════
  // STUDENT VIEWS
  // ═══════════════════════════════════════════

  Widget _buildStudentAttendanceView() {
    final user = widget.service.currentUser!;
    final block = user.hostelBlock ?? '';
    final activeSession = widget.service.getActiveSession(block);
    final percentage = widget.service.getStudentGeofencePercentage(user.uid);
    final hasMarked = activeSession != null
        ? widget.service.hasStudentMarkedAttendance(activeSession.id, user.uid)
        : false;

    final Color percentColor;
    if (percentage >= 85) {
      percentColor = AppColors.accentGreen;
    } else if (percentage >= 70) {
      percentColor = AppColors.accentAmber;
    } else {
      percentColor = AppColors.accentRed;
    }

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const SizedBox(height: 8),

          // Percentage circle
          Container(
            width: 160,
            height: 160,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: percentColor.withValues(alpha: 0.3), width: 3),
              color: percentColor.withValues(alpha: 0.05),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('${percentage.toInt()}%',
                    style: TextStyle(
                        fontSize: 42,
                        fontWeight: FontWeight.w900,
                        color: percentColor)),
                Text('Attendance', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
              ],
            ),
          ).animate().fadeIn(duration: 600.ms).scale(begin: const Offset(0.8, 0.8)),
          const SizedBox(height: 32),

          // Active session action
          if (activeSession != null) ...[
            GlassCard(
              borderColor: hasMarked
                  ? AppColors.accentGreen.withValues(alpha: 0.4)
                  : AppColors.accentCyan.withValues(alpha: 0.4),
              backgroundColor: hasMarked
                  ? AppColors.accentGreen.withValues(alpha: 0.05)
                  : AppColors.accentCyan.withValues(alpha: 0.05),
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: AppColors.accentGreen,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.accentGreen.withValues(alpha: 0.5),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text('Attendance Window Open',
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.accentGreen)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    hasMarked
                        ? '✅ Attendance Marked!'
                        : 'You are inside the geofence. Mark your attendance now.',
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                  if (!hasMarked) ...[
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: GlassButton(
                        label: 'Mark Attendance',
                        icon: Icons.fingerprint_rounded,
                        isLoading: _loading,
                        gradient: const LinearGradient(
                          colors: [AppColors.accentCyan, Color(0xFF0891B2)],
                        ),
                        onPressed: _loading
                            ? null
                            : () async {
                                setState(() => _loading = true);
                                final error = await widget.service
                                    .markGeofenceAttendance(activeSession.id);
                                setState(() => _loading = false);
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(error ?? 'Attendance marked ✓'),
                                      backgroundColor: error != null
                                          ? AppColors.accentRed
                                          : AppColors.accentGreen,
                                    ),
                                  );
                                }
                              },
                      ),
                    ),
                  ],
                ],
              ),
            ).animate().fadeIn(delay: 300.ms, duration: 400.ms),
          ] else ...[
            GlassCard(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Icon(Icons.location_off_rounded, size: 48, color: AppColors.textMuted),
                  const SizedBox(height: 12),
                  Text('No Active Window', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 4),
                  Text('Your RT hasn\'t opened an attendance window yet.',
                      style: Theme.of(context).textTheme.bodySmall,
                      textAlign: TextAlign.center),
                ],
              ),
            ).animate().fadeIn(delay: 300.ms, duration: 400.ms),
          ],
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildStudentHistoryView() {
    final user = widget.service.currentUser!;
    final block = user.hostelBlock ?? '';
    final sessions = widget.service.getBlockSessions(block);

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          Text('Attendance History', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          if (sessions.isEmpty)
            _buildEmptyState(Icons.history_rounded, 'No attendance history')
          else
            ...sessions.take(20).map((session) {
              final attended = widget.service.hasStudentMarkedAttendance(session.id, user.uid);
              return GlassCard(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: (attended ? AppColors.accentGreen : AppColors.accentRed)
                            .withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        attended ? Icons.check_rounded : Icons.close_rounded,
                        color: attended ? AppColors.accentGreen : AppColors.accentRed,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(DateFormat('EEEE, dd MMM yyyy').format(session.startTime),
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                  fontSize: 13)),
                          Text('${DateFormat('HH:mm').format(session.startTime)} session',
                              style: Theme.of(context).textTheme.bodySmall),
                        ],
                      ),
                    ),
                    StatusBadge(
                      label: attended ? 'Present' : 'Absent',
                      color: attended ? AppColors.accentGreen : AppColors.accentRed,
                    ),
                  ],
                ),
              ).animate().fadeIn(duration: 300.ms);
            }),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════
  // WARDEN VIEWS
  // ═══════════════════════════════════════════

  Widget _buildWardenOverview() {
    final stats = widget.service.getGeofenceAttendanceStats();
    final sessions = widget.service.getAllGeofenceSessions().take(10).toList();
    final summaries = widget.service.getBlockAttendanceSummary('Block A');

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),

          // Overall stats
          Row(
            children: [
              Expanded(
                child: StatCard(
                  title: 'Total Sessions',
                  value: '${stats['totalSessions']}',
                  icon: Icons.calendar_today_rounded,
                  color: AppColors.accentCyan,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: StatCard(
                  title: 'Avg Attendance',
                  value: '${(stats['avgAttendance'] as double).toInt()}%',
                  icon: Icons.trending_up_rounded,
                  color: AppColors.accentGreen,
                ),
              ),
            ],
          ).animate().fadeIn(duration: 400.ms),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: StatCard(
                  title: 'Total Check-ins',
                  value: '${stats['totalCheckIns']}',
                  icon: Icons.how_to_reg_rounded,
                  color: AppColors.primaryStart,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: StatCard(
                  title: 'Open Issues',
                  value: '${stats['unresolvedAnomalies']}',
                  icon: Icons.warning_rounded,
                  color: (stats['unresolvedAnomalies'] as int) > 0
                      ? AppColors.accentRed
                      : AppColors.accentGreen,
                ),
              ),
            ],
          ).animate().fadeIn(delay: 200.ms, duration: 400.ms),
          const SizedBox(height: 24),

          // Student summary
          Text('Student Attendance — Block A',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          ...summaries.map((s) => _buildStudentSummaryCard(s)),
          const SizedBox(height: 24),

          // Recent sessions
          Text('Recent Sessions', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          ...sessions.map((s) => _buildSessionCard(s)),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildWardenLogsView() {
    final sessions = widget.service.getAllGeofenceSessions();

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          Text('All Attendance Logs', style: Theme.of(context).textTheme.titleMedium),
          Text('${sessions.length} sessions recorded',
              style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 16),
          ...sessions.map((session) {
            final checkIns = widget.service.getSessionCheckIns(session.id);
            return ExpansionTile(
              title: Text(DateFormat('dd MMM yyyy, HH:mm').format(session.startTime),
                  style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                      fontSize: 14)),
              subtitle: Text(
                  '${session.hostelBlock} • ${session.markedCount}/${session.totalStudents} (${(session.completionRate * 100).toInt()}%)',
                  style: Theme.of(context).textTheme.bodySmall),
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.accentCyan.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.list_alt_rounded, color: AppColors.accentCyan, size: 20),
              ),
              children: checkIns.map((c) => ListTile(
                dense: true,
                leading: Icon(Icons.check_circle_rounded, color: AppColors.accentGreen, size: 18),
                title: Text(c.studentName,
                    style: const TextStyle(fontSize: 13, color: AppColors.textPrimary)),
                subtitle: Text('${c.rollNumber} • ${DateFormat('HH:mm:ss').format(c.timestamp)}'),
                trailing: Text('${c.distanceFromCenter?.toInt() ?? '-'}m',
                    style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
              )).toList(),
            );
          }),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildWardenAnomaliesView() {
    final anomalies = widget.service.getAllAnomalies();

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          Text('All Anomalies', style: Theme.of(context).textTheme.titleMedium),
          Text('${anomalies.length} total',
              style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 16),
          if (anomalies.isEmpty)
            _buildEmptyState(Icons.check_circle_outline_rounded, 'No anomalies raised')
          else
            ...anomalies.map((a) => _buildAnomalyCard(a)),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════
  // FACULTY VIEWS
  // ═══════════════════════════════════════════

  Widget _buildFacultyStudentsView() {
    final user = widget.service.currentUser!;
    final dept = user.department ?? 'Computer Science';
    final summaries = widget.service.getDepartmentAttendancePatterns(dept);

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          Text('My Students — $dept', style: Theme.of(context).textTheme.titleMedium),
          Text('${summaries.length} students', style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 16),
          if (summaries.isEmpty)
            _buildEmptyState(Icons.people_outline_rounded, 'No students in your department')
          else
            ...summaries.map((s) => _buildStudentSummaryCard(s)),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildFacultyPatternsView() {
    final user = widget.service.currentUser!;
    final dept = user.department ?? 'Computer Science';
    final summaries = widget.service.getDepartmentAttendancePatterns(dept);

    final avgAttendance = summaries.isEmpty
        ? 0.0
        : summaries.fold<double>(0, (s, v) => s + v.percentage) / summaries.length;
    final lowAttendance = summaries.where((s) => s.percentage < 75).toList();
    final totalAnomalies = summaries.fold<int>(0, (s, v) => s + v.anomalyCount);

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),

          // Department overview
          Row(
            children: [
              Expanded(
                child: StatCard(
                  title: 'Avg Attendance',
                  value: '${avgAttendance.toInt()}%',
                  icon: Icons.trending_up_rounded,
                  color: avgAttendance >= 80 ? AppColors.accentGreen : AppColors.accentAmber,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: StatCard(
                  title: 'Low Attendance',
                  value: '${lowAttendance.length}',
                  icon: Icons.trending_down_rounded,
                  color: lowAttendance.isNotEmpty ? AppColors.accentRed : AppColors.accentGreen,
                  subtitle: '< 75%',
                ),
              ),
            ],
          ).animate().fadeIn(duration: 400.ms),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: StatCard(
                  title: 'Students',
                  value: '${summaries.length}',
                  icon: Icons.people_rounded,
                  color: AppColors.primaryStart,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: StatCard(
                  title: 'Anomalies',
                  value: '$totalAnomalies',
                  icon: Icons.warning_rounded,
                  color: totalAnomalies > 0 ? AppColors.accentAmber : AppColors.accentGreen,
                ),
              ),
            ],
          ).animate().fadeIn(delay: 200.ms, duration: 400.ms),
          const SizedBox(height: 24),

          // At-risk students
          if (lowAttendance.isNotEmpty) ...[
            Text('⚠ At-Risk Students', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            ...lowAttendance.map((s) => _buildStudentSummaryCard(s)),
            const SizedBox(height: 16),
          ],
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════
  // PARENT VIEWS
  // ═══════════════════════════════════════════

  Widget _buildParentSummaryView() {
    // Parent sees their child's attendance percentage
    // For demo, we link parent to student1
    const childId = 'student1';
    final percentage = widget.service.getStudentGeofencePercentage(childId);
    final anomalies = widget.service.getAnomaliesForStudent(childId);
    final unresolvedCount = anomalies.where((a) => !a.resolved).length;

    final Color percentColor;
    if (percentage >= 85) {
      percentColor = AppColors.accentGreen;
    } else if (percentage >= 70) {
      percentColor = AppColors.accentAmber;
    } else {
      percentColor = AppColors.accentRed;
    }

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const SizedBox(height: 16),

          // Child info
          GlassCard(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: const Center(
                    child: Text('A',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.w800)),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Arjun Mehta',
                          style: Theme.of(context).textTheme.titleLarge),
                      Text('CS21B1045 • Block A',
                          style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(duration: 400.ms),
          const SizedBox(height: 24),

          // Percentage display
          Container(
            width: 180,
            height: 180,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: percentColor.withValues(alpha: 0.3), width: 4),
              color: percentColor.withValues(alpha: 0.05),
              boxShadow: [
                BoxShadow(
                  color: percentColor.withValues(alpha: 0.15),
                  blurRadius: 32,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('${percentage.toInt()}%',
                    style: TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.w900,
                        color: percentColor)),
                Text('Hostel Attendance',
                    style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
              ],
            ),
          ).animate().fadeIn(delay: 200.ms, duration: 600.ms).scale(begin: const Offset(0.8, 0.8)),
          const SizedBox(height: 24),

          // Quick stats
          Row(
            children: [
              Expanded(
                child: StatCard(
                  title: 'Anomalies',
                  value: '$unresolvedCount',
                  icon: Icons.warning_rounded,
                  color: unresolvedCount > 0 ? AppColors.accentRed : AppColors.accentGreen,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: StatCard(
                  title: 'Status',
                  value: percentage >= 75 ? 'Good' : 'Low',
                  icon: percentage >= 75
                      ? Icons.check_circle_rounded
                      : Icons.error_rounded,
                  color: percentage >= 75 ? AppColors.accentGreen : AppColors.accentRed,
                ),
              ),
            ],
          ).animate().fadeIn(delay: 400.ms, duration: 400.ms),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildParentAlertsView() {
    const childId = 'student1';
    final anomalies = widget.service.getAnomaliesForStudent(childId);

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          Text('Attendance Alerts', style: Theme.of(context).textTheme.titleMedium),
          Text('Anomalies raised by Resident Tutor',
              style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 16),
          if (anomalies.isEmpty)
            _buildEmptyState(Icons.check_circle_outline_rounded, 'No alerts. All good!'),
          ...anomalies.map((a) => _buildParentAnomalyCard(a)),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildParentAnomalyCard(AttendanceAnomaly anomaly) {
    final color = anomaly.resolved ? AppColors.accentGreen : AppColors.accentAmber;

    return GlassCard(
      borderColor: color.withValues(alpha: 0.3),
      backgroundColor: color.withValues(alpha: 0.03),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(anomaly.type.icon, style: const TextStyle(fontSize: 22)),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(anomaly.type.label,
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                    Text(DateFormat('dd MMM yyyy').format(anomaly.raisedAt),
                        style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              ),
              StatusBadge(
                label: anomaly.resolved ? 'Resolved' : 'Pending',
                color: color,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(anomaly.description, style: Theme.of(context).textTheme.bodyMedium),
          if (!anomaly.resolved) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: GlassButton(
                label: 'Acknowledge',
                icon: Icons.check_rounded,
                isSmall: true,
                gradient: const LinearGradient(
                  colors: [AppColors.accentGreen, Color(0xFF059669)],
                ),
                onPressed: () async {
                  await widget.service.resolveAnomaly(
                    anomalyId: anomaly.id,
                    response: 'Acknowledged by parent. Will take necessary action.',
                  );
                  setState(() {});
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Anomaly acknowledged ✓'),
                        backgroundColor: AppColors.accentGreen,
                      ),
                    );
                  }
                },
              ),
            ),
          ],
          if (anomaly.parentResponse != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.bgSurface,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.check_circle_rounded, size: 16, color: AppColors.accentGreen),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text('Your response: ${anomaly.parentResponse}',
                        style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    ).animate().fadeIn(duration: 300.ms);
  }

  // ═══════════════════════════════════════════
  // SHARED HELPERS
  // ═══════════════════════════════════════════

  Widget _buildEmptyState(IconData icon, String label) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          children: [
            Icon(icon, size: 48, color: AppColors.textMuted),
            const SizedBox(height: 12),
            Text(label,
                style: TextStyle(color: AppColors.textMuted),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
