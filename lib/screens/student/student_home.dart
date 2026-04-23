import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../models/enums.dart';
import '../../models/leave_request.dart';
import '../../models/qr_pass.dart';
import '../../models/user_model.dart';
import '../../services/app_service.dart';
import '../../widgets/glass_widgets.dart';
import '../../widgets/flex_widgets.dart';
import '../shared/attendance_screen.dart';
import '../shared/medical_screen.dart';
import '../shared/grievance_screen.dart';
import '../shared/geofence_attendance_screen.dart';
import 'create_leave_screen.dart';
import 'leave_detail_screen.dart';
import 'qr_pass_screen.dart';

class StudentHomeScreen extends StatefulWidget {
  final AppService service;
  const StudentHomeScreen({super.key, required this.service});

  @override
  State<StudentHomeScreen> createState() => _StudentHomeScreenState();
}

class _StudentHomeScreenState extends State<StudentHomeScreen> {
  int _currentIndex = 0;
  bool _isLoading = true;
  List<LeaveRequest> _leaves = [];
  List<QrPass> _allPasses = [];
  List<QrPass> _activePasses = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final user = widget.service.currentUser;
    if (user == null) return;

    // Try async methods first (FirebaseService), fall back to sync (MockService)
    List<LeaveRequest> leaves;
    List<QrPass> passes;
    try {
      leaves = await _tryGetStudentLeavesAsync(user.uid);
      passes = await _tryGetStudentPassesAsync(user.uid);
    } catch (_) {
      leaves = widget.service.getStudentLeaves(user.uid);
      passes = widget.service.getStudentPasses(user.uid);
    }

    if (mounted) {
      setState(() {
        _leaves = leaves;
        _allPasses = passes;
        _activePasses = passes.where((p) => p.isActive).toList();
        _isLoading = false;
      });
    }
  }

  Future<List<LeaveRequest>> _tryGetStudentLeavesAsync(String uid) async {
    // Use reflection-like approach: call the async method if it exists
    final service = widget.service;
    // Check if the sync method returns empty (FirebaseService stub)
    final syncResult = service.getStudentLeaves(uid);
    if (syncResult.isNotEmpty) return syncResult;

    // Must be FirebaseService — use dynamic call
    try {
      final dynamic dynService = service;
      return await dynService.getStudentLeavesAsync(uid) as List<LeaveRequest>;
    } catch (_) {
      return syncResult;
    }
  }

  Future<List<QrPass>> _tryGetStudentPassesAsync(String uid) async {
    final service = widget.service;
    final syncResult = service.getStudentPasses(uid);
    if (syncResult.isNotEmpty) return syncResult;

    try {
      final dynamic dynService = service;
      return await dynService.getStudentPassesAsync(uid) as List<QrPass>;
    } catch (_) {
      return syncResult;
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.service.currentUser;
    if (user == null) return const SizedBox.shrink();

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
          _buildDashboard(user, _leaves, _activePasses),
          _buildLeaveHistory(_leaves),
          _buildPassesView(_activePasses),
          _buildProfileView(user),
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
                label: 'Home',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.history_rounded),
                label: 'History',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.qr_code_rounded),
                label: 'Passes',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person_rounded),
                label: 'Profile',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDashboard(AppUser user, List<LeaveRequest> leaves, List<QrPass> activePasses) {
    final pendingCount = leaves.where((l) =>
        l.status != LeaveStatus.approved &&
        l.status != LeaveStatus.rejected).length;
    final approvedCount = leaves.where((l) => l.status == LeaveStatus.approved).length;
    final rejectedCount = leaves.where((l) => l.status == LeaveStatus.rejected).length;
    final totalCount = leaves.length;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          // Premium Greeting Header
          GreetingHeader(
            name: user.name.split(' ').first,
            subtitle: '${user.rollNumber} · ${user.hostelBlock}',
            avatarLetter: user.name[0],
            onAvatarTap: () =>
                setState(() => _currentIndex = 3),
          ).animate().fadeIn(duration: 400.ms),
          const SizedBox(height: 8),

          // Insight chips row
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: [
                InsightChip(
                  label: '${activePasses.length} Active Pass${activePasses.length != 1 ? 'es' : ''}',
                  icon: Icons.qr_code_rounded,
                  color: activePasses.isNotEmpty
                      ? AppColors.accentGreen
                      : AppColors.textMuted,
                ),
                const SizedBox(width: 8),
                InsightChip(
                  label: '$totalCount Total Requests',
                  icon: Icons.receipt_long_rounded,
                  color: AppColors.accentCyan,
                ),
                if (rejectedCount > 0) ...[
                  const SizedBox(width: 8),
                  InsightChip(
                    label: '$rejectedCount Rejected',
                    icon: Icons.block_rounded,
                    color: AppColors.accentRed,
                  ),
                ],
              ],
            ),
          ).animate().fadeIn(delay: 150.ms, duration: 400.ms),
          const SizedBox(height: 20),

          // Quick Stats — MetricTiles with animated counters
          Row(
            children: [
              Expanded(
                child: MetricTile(
                  label: 'Pending',
                  value: '$pendingCount',
                  icon: Icons.hourglass_top_rounded,
                  color: AppColors.accentAmber,
                  trend: pendingCount > 0 ? '$pendingCount' : null,
                  trendUp: false,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: MetricTile(
                  label: 'Approved',
                  value: '$approvedCount',
                  icon: Icons.check_circle_rounded,
                  color: AppColors.accentGreen,
                  trend: approvedCount > 0 ? '+$approvedCount' : null,
                  trendUp: true,
                ),
              ),
            ],
          ).animate().fadeIn(delay: 200.ms, duration: 400.ms).slideY(begin: 0.05),
          const SizedBox(height: 20),

          // Active QR Pass — FloatingBanner
          if (activePasses.isNotEmpty) ...[
            FloatingBanner(
              title: 'Gate Pass Active',
              subtitle: 'Tap to view your QR pass · ${activePasses.first.state.label}',
              icon: Icons.qr_code_2_rounded,
              gradientColors: const [Color(0xFF059669), Color(0xFF047857)],
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => QrPassScreen(
                      service: widget.service,
                      pass: activePasses.first,
                    ),
                  ),
                );
              },
            ).animate().fadeIn(delay: 300.ms, duration: 400.ms),
            const SizedBox(height: 8),
          ],

          // Create leave — GradientBorderCard
          GradientBorderCard(
            borderColors: const [
              Color(0xFF1A1A1A),
              Color(0xFF444444),
              Color(0xFF1A1A1A),
              Color(0xFF444444),
            ],
            borderWidth: 1,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: GestureDetector(
              onTap: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CreateLeaveScreen(service: widget.service),
                  ),
                );
                _loadData();
              },
              child: Row(
                children: [
                  const GradientIconBadge(
                    icon: Icons.add_rounded,
                    colors: [Color(0xFF1A1A1A), Color(0xFF444444)],
                    size: 44,
                    iconSize: 22,
                    borderRadius: 14,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('New Leave Request',
                            style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary)),
                        Text('Submit a new application',
                            style: TextStyle(
                                fontSize: 12,
                                color: AppColors.textMuted)),
                      ],
                    ),
                  ),
                  Icon(Icons.arrow_forward_ios_rounded,
                      color: AppColors.textMuted, size: 14),
                ],
              ),
            ),
          ).animate().fadeIn(delay: 400.ms, duration: 400.ms),
          const SizedBox(height: 24),

          // Quick Access with LabelDivider
          const LabelDivider(label: 'Quick Access'),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildModuleTile(
                  icon: Icons.event_available_rounded,
                  label: 'Attendance',
                  color: AppColors.accentGreen,
                  onTap: () => Navigator.push(context, MaterialPageRoute(
                    builder: (_) => AttendanceScreen(service: widget.service),
                  )),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildModuleTile(
                  icon: Icons.medical_services_rounded,
                  label: 'Medical',
                  color: AppColors.accentRed,
                  onTap: () => Navigator.push(context, MaterialPageRoute(
                    builder: (_) => MedicalScreen(service: widget.service),
                  )),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildModuleTile(
                  icon: Icons.feedback_rounded,
                  label: 'Grievances',
                  color: AppColors.accentAmber,
                  onTap: () => Navigator.push(context, MaterialPageRoute(
                    builder: (_) => GrievanceScreen(service: widget.service),
                  )),
                ),
              ),
            ],
          ).animate().fadeIn(delay: 500.ms, duration: 400.ms),
          const SizedBox(height: 10),
          GlassCard(
            onTap: () => Navigator.push(context, MaterialPageRoute(
              builder: (_) => GeofenceAttendanceScreen(service: widget.service),
            )),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            borderColor: AppColors.accentCyan.withValues(alpha: 0.2),
            child: Row(
              children: [
                const GradientIconBadge(
                  icon: Icons.location_on_rounded,
                  colors: [Color(0xFF0EA5E9), Color(0xFF0284C7)],
                  size: 44,
                  iconSize: 22,
                  borderRadius: 14,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Geofence Attendance',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                      Text('Mark attendance within hostel zone',
                          style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded, color: AppColors.textMuted, size: 22),
              ],
            ),
          ).animate().fadeIn(delay: 600.ms, duration: 400.ms),
          const SizedBox(height: 24),

          // Recent Requests with LabelDivider + staggered items
          const LabelDivider(label: 'Recent Requests'),
          const SizedBox(height: 12),
          if (leaves.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  children: [
                    ProgressRing(
                      progress: 0,
                      size: 64,
                      color: AppColors.textMuted,
                      child: Icon(Icons.inbox_rounded,
                          size: 28, color: AppColors.textMuted),
                    ),
                    const SizedBox(height: 16),
                    Text('No requests yet',
                        style: TextStyle(color: AppColors.textMuted, fontSize: 14)),
                  ],
                ),
              ),
            ).animate().fadeIn(delay: 700.ms)
          else
            ...leaves.take(3).toList().asMap().entries.map((entry) {
              return StaggeredItem(
                index: entry.key,
                baseDelay: const Duration(milliseconds: 650),
                child: _buildLeaveCard(entry.value),
              );
            }),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildModuleTile({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GlassCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: 8),
          Text(label,
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary)),
        ],
      ),
    );
  }

  Widget _buildLeaveCard(LeaveRequest leave) {
    final dateFormat = DateFormat('dd MMM');
    Color statusColor;
    switch (leave.status) {
      case LeaveStatus.approved:
        statusColor = AppColors.statusApproved;
        break;
      case LeaveStatus.rejected:
        statusColor = AppColors.statusRejected;
        break;
      case LeaveStatus.pending:
        statusColor = AppColors.statusPending;
        break;
      default:
        statusColor = AppColors.statusForwarded;
    }

    return GlassCard(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => LeaveDetailScreen(
              service: widget.service,
              leave: leave,
            ),
          ),
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                leave.leaveType.icon,
                style: const TextStyle(fontSize: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      leave.leaveType.label,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Text(
                      '${dateFormat.format(leave.fromDate)} - ${dateFormat.format(leave.toDate)}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              StatusBadge(
                label: leave.status.label,
                color: statusColor,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            leave.reason,
            style: Theme.of(context).textTheme.bodyMedium,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          if (leave.leaveType.approvalChain.isNotEmpty) ...[
            const SizedBox(height: 12),
            ApprovalChainWidget(
              steps: leave.leaveType.approvalChain,
              currentStep: leave.approvalHistory.length,
              isRejected: leave.status == LeaveStatus.rejected,
            ),
          ],
        ],
      ),
    ).animate().fadeIn(duration: 300.ms).slideX(begin: 0.02);
  }

  Widget _buildLeaveHistory(List<LeaveRequest> leaves) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          Text(
            'Leave History',
            style: Theme.of(context).textTheme.headlineLarge,
          ),
          const SizedBox(height: 6),
          // Summary chips
          Row(
            children: [
              InsightChip(
                label: '${leaves.length} Total',
                icon: Icons.list_alt_rounded,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: 8),
              InsightChip(
                label: '${leaves.where((l) => l.status == LeaveStatus.approved).length} Approved',
                icon: Icons.check_rounded,
                color: AppColors.accentGreen,
              ),
            ],
          ).animate().fadeIn(delay: 100.ms),
          const SizedBox(height: 16),
          if (leaves.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(40),
                child: Column(
                  children: [
                    ProgressRing(
                      progress: 0,
                      size: 64,
                      color: AppColors.textMuted,
                      child: Icon(Icons.inbox_rounded, size: 28, color: AppColors.textMuted),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No leave requests yet',
                      style: TextStyle(color: AppColors.textMuted, fontSize: 16),
                    ),
                  ],
                ),
              ),
            )
          else
            ...leaves.toList().asMap().entries.map((entry) {
              return StaggeredItem(
                index: entry.key,
                baseDelay: const Duration(milliseconds: 200),
                child: _buildLeaveCard(entry.value),
              );
            }),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildPassesView(List<QrPass> activePasses) {
    final uid = widget.service.currentUser?.uid;
    if (uid == null) return const SizedBox.shrink();
    final allPasses = _allPasses;
    final activeCount = allPasses.where((p) => p.isActive).length;
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          Row(
            children: [
              Text(
                'Gate Passes',
                style: Theme.of(context).textTheme.headlineLarge,
              ),
              const Spacer(),
              if (activeCount > 0)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const PulsingDot(size: 7, color: AppColors.accentGreen),
                    const SizedBox(width: 6),
                    Text('$activeCount active',
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.accentGreen,
                          fontWeight: FontWeight.w600,
                        )),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 16),
          if (allPasses.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(40),
                child: Column(
                  children: [
                    ProgressRing(
                      progress: 0,
                      size: 64,
                      color: AppColors.textMuted,
                      child: Icon(Icons.qr_code_rounded, size: 28, color: AppColors.textMuted),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No passes generated yet',
                      style: TextStyle(color: AppColors.textMuted, fontSize: 16),
                    ),
                  ],
                ),
              ),
            )
          else
            ...allPasses.map((pass) {
              Color stateColor = pass.isActive
                  ? AppColors.accentGreen
                  : pass.state == QrState.hostelEntered
                      ? AppColors.accentCyan
                      : AppColors.textMuted;

              return GlassCard(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => QrPassScreen(
                        service: widget.service,
                        pass: pass,
                      ),
                    ),
                  );
                },
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: stateColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        Icons.qr_code_2_rounded,
                        color: stateColor,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            pass.studentRollNumber,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          Text(
                            'Valid: ${DateFormat('dd MMM, HH:mm').format(pass.validFrom)} - ${DateFormat('dd MMM, HH:mm').format(pass.validUntil)}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    StatusBadge(
                      label: pass.state.label,
                      color: stateColor,
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

  Widget _buildProfileView(AppUser user) {
    // Calculate profile completion
    int filled = 0;
    int total = 5;
    if (user.rollNumber != null && user.rollNumber!.isNotEmpty) filled++;
    if (user.hostelBlock != null && user.hostelBlock!.isNotEmpty) filled++;
    if (user.roomNumber != null && user.roomNumber!.isNotEmpty) filled++;
    if (user.department != null && user.department!.isNotEmpty) filled++;
    if (user.phone != null && user.phone!.isNotEmpty) filled++;
    final double completion = filled / total;
    final Color ringColor = completion >= 1.0
        ? AppColors.accentGreen
        : AppColors.accentCyan;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          const SizedBox(height: 16),
          // Profile avatar with progress ring
          _buildProfileAvatar(user, ringColor, completion),
          const SizedBox(height: 14),
          Text(user.name, style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 4),
          Text(user.email, style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 8),
          InsightChip(
            label: completion == 1.0
                ? 'Profile Complete'
                : '${(completion * 100).toInt()}% Complete',
            icon: completion == 1.0
                ? Icons.verified_rounded
                : Icons.info_outline_rounded,
            color: completion == 1.0
                ? AppColors.accentGreen
                : AppColors.accentAmber,
          ).animate().fadeIn(delay: 200.ms),
          const SizedBox(height: 20),

          const LabelDivider(label: 'Personal Info'),
          const SizedBox(height: 10),
          ...([
            _profileItem(Icons.badge_rounded, 'Roll Number', user.rollNumber ?? '-'),
            _profileItem(Icons.apartment_rounded, 'Hostel Block', user.hostelBlock ?? '-'),
            _profileItem(Icons.door_front_door_rounded, 'Room', user.roomNumber ?? '-'),
            _profileItem(Icons.school_rounded, 'Department', user.department ?? '-'),
            _profileItem(Icons.phone_rounded, 'Phone', user.phone ?? '-'),
          ].asMap().entries.map((entry) {
            return StaggeredItem(
              index: entry.key,
              baseDelay: const Duration(milliseconds: 300),
              child: entry.value,
            );
          })),
          const SizedBox(height: 24),

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
          ).animate().fadeIn(delay: 600.ms),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _profileItem(IconData icon, String label, String value) {
    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primaryStart, size: 20),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: Theme.of(context).textTheme.bodySmall),
              Text(value, style: Theme.of(context).textTheme.titleMedium),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProfileAvatar(AppUser user, Color ringColor, double completion) {
    return ProgressRing(
      progress: completion,
      size: 96,
      strokeWidth: 3,
      color: ringColor,
      child: Container(
        width: 76,
        height: 76,
        decoration: BoxDecoration(
          gradient: AppColors.primaryGradient,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryStart.withValues(alpha: 0.3),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Center(
          child: Text(
            user.name[0],
            style: const TextStyle(
              color: Colors.white,
              fontSize: 30,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }
}
