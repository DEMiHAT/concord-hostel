import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../models/enums.dart';
import '../../models/leave_request.dart';
import '../../models/user_model.dart';
import '../../services/app_service.dart';
import '../../widgets/glass_widgets.dart';
import '../shared/attendance_screen.dart';
import '../shared/medical_screen.dart';
import '../shared/grievance_screen.dart';
import '../shared/geofence_attendance_screen.dart';

class ApproverHomeScreen extends StatefulWidget {
  final AppService service;
  const ApproverHomeScreen({super.key, required this.service});

  @override
  State<ApproverHomeScreen> createState() => _ApproverHomeScreenState();
}

class _ApproverHomeScreenState extends State<ApproverHomeScreen> {
  int _currentIndex = 0;
  bool _isLoading = true;
  List<LeaveRequest> _pendingRequests = [];
  List<LeaveRequest> _allRequests = [];
  Map<String, int> _stats = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final user = widget.service.currentUser;
    if (user == null) return;

    List<LeaveRequest> pending;
    List<LeaveRequest> all;
    Map<String, int> stats;

    try {
      // Try async methods (FirebaseService)
      pending = await _tryGetPendingAsync(user.role);
      all = await _tryGetAllRequestsAsync();
      stats = await _tryGetStatsAsync();
    } catch (_) {
      pending = widget.service.getPendingApprovalsForRole(user.role);
      all = widget.service.leaveRequests;
      stats = widget.service.getStats();
    }

    if (mounted) {
      setState(() {
        _pendingRequests = pending;
        _allRequests = all;
        _stats = stats;
        _isLoading = false;
      });
    }
  }

  Future<List<LeaveRequest>> _tryGetPendingAsync(UserRole role) async {
    final syncResult = widget.service.getPendingApprovalsForRole(role);
    if (syncResult.isNotEmpty) return syncResult;
    try {
      final dynamic svc = widget.service;
      return await svc.getPendingApprovalsForRoleAsync(role) as List<LeaveRequest>;
    } catch (_) {
      return syncResult;
    }
  }

  Future<List<LeaveRequest>> _tryGetAllRequestsAsync() async {
    final syncResult = widget.service.leaveRequests;
    if (syncResult.isNotEmpty) return syncResult;
    try {
      final dynamic svc = widget.service;
      return await svc.getAllLeaveRequestsAsync() as List<LeaveRequest>;
    } catch (_) {
      return syncResult;
    }
  }

  Future<Map<String, int>> _tryGetStatsAsync() async {
    final syncResult = widget.service.getStats();
    if (syncResult.values.any((v) => v > 0)) return syncResult;
    try {
      final dynamic svc = widget.service;
      return await svc.getStatsAsync() as Map<String, int>;
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
          _buildDashboard(user, _pendingRequests),
          _buildPendingList(_pendingRequests),
          _buildAllRequests(_allRequests),
          _buildProfile(user),
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
                icon: Icon(Icons.pending_actions_rounded),
                label: 'Pending',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.list_alt_rounded),
                label: 'All',
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

  Widget _buildDashboard(AppUser user, List<LeaveRequest> pendingRequests) {
    final stats = _stats;

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
                      'Welcome back 👋',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    Text(
                      user.name,
                      style: Theme.of(context).textTheme.headlineLarge,
                    ),
                    StatusBadge(
                      label: user.role.label,
                      color: AppColors.primaryStart,
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
                  child: Center(
                    child: Text(
                      user.name[0],
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
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
                  title: 'Pending',
                  value: '${pendingRequests.length}',
                  icon: Icons.hourglass_top_rounded,
                  color: AppColors.accentAmber,
                  subtitle: 'Awaiting your action',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: StatCard(
                  title: 'Total',
                  value: '${stats['total']}',
                  icon: Icons.receipt_long_rounded,
                  color: AppColors.primaryStart,
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
                  title: 'Active QR',
                  value: '${stats['activeQr']}',
                  icon: Icons.qr_code_rounded,
                  color: AppColors.accentCyan,
                ),
              ),
            ],
          ).animate().fadeIn(delay: 300.ms, duration: 400.ms),
          const SizedBox(height: 24),

          // Pending preview
          if (pendingRequests.isNotEmpty) ...[
            Text(
              'Requires Your Action',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            ...pendingRequests.take(3).map(
                  (req) => _buildRequestCard(req),
                ),
          ] else ...[
            GlassCard(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Icon(Icons.check_circle_outline_rounded,
                          size: 48, color: AppColors.accentGreen),
                      const SizedBox(height: 12),
                      Text(
                        'All caught up!',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Text(
                        'No pending approvals',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
          const SizedBox(height: 24),

          // Modules Quick Access
          Text('Modules', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildModuleTile(
                  icon: Icons.event_available_rounded,
                  label: 'Attendance',
                  color: AppColors.accentGreen,
                  onTap: () => Navigator.push(context, MaterialPageRoute(
                    builder: (_) => AttendanceScreen(
                      service: widget.service,
                      isWardenView: user.role == UserRole.warden || user.role == UserRole.admin,
                    ),
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
                    builder: (_) => MedicalScreen(
                      service: widget.service,
                      isApproverView: true,
                    ),
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
                    builder: (_) => GrievanceScreen(
                      service: widget.service,
                      isManagementView: true,
                    ),
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
            borderColor: const Color(0xFF8B5CF6).withValues(alpha: 0.2),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFF8B5CF6).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.location_on_rounded, color: Color(0xFF8B5CF6), size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Geofence Attendance',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                      Text('Location-based hostel attendance',
                          style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded, color: AppColors.textMuted, size: 22),
              ],
            ),
          ).animate().fadeIn(delay: 600.ms, duration: 400.ms),
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

  /// Look up the full AppUser from the users cache for extra student info
  AppUser? _findStudentUser(String studentId) {
    try {
      final users = widget.service.getStudentUsers();
      return users.firstWhere((u) => u.uid == studentId);
    } catch (_) {
      return null;
    }
  }

  void _showStudentDetails(LeaveRequest req) {
    final student = _findStudentUser(req.studentId);
    final dateFormat = DateFormat('dd MMM yyyy, hh:mm a');
    final shortDateFormat = DateFormat('dd MMM');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (_, scrollController) => Container(
          decoration: const BoxDecoration(
            color: AppColors.bgCard,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: AppColors.textMuted.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Student header
              Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primaryStart.withValues(alpha: 0.25),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        req.studentName.isNotEmpty ? req.studentName[0] : '?',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          req.studentName,
                          style: Theme.of(ctx).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          req.studentRollNumber,
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.primaryStart,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  StatusBadge(
                    label: req.status.label,
                    color: req.status == LeaveStatus.approved
                        ? AppColors.statusApproved
                        : req.status == LeaveStatus.rejected
                            ? AppColors.statusRejected
                            : req.status == LeaveStatus.pending
                                ? AppColors.statusPending
                                : AppColors.statusForwarded,
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // ─── Student Details Grid ───
              Text(
                'Student Details',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textMuted,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 10),
              GlassCard(
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _detailRow(Icons.apartment_rounded, 'Hostel Block', req.hostelBlock),
                    _detailDivider(),
                    _detailRow(Icons.door_front_door_rounded, 'Room Number', req.roomNumber),
                    if (student?.department != null) ...[
                      _detailDivider(),
                      _detailRow(Icons.school_rounded, 'Department', student!.department!),
                    ],
                    if (student?.phone != null) ...[
                      _detailDivider(),
                      _detailRow(Icons.phone_rounded, 'Phone', student!.phone!),
                    ],
                    if (student?.parentPhone != null) ...[
                      _detailDivider(),
                      _detailRow(Icons.family_restroom_rounded, 'Parent Phone', student!.parentPhone!),
                    ],
                    if (student?.email != null) ...[
                      _detailDivider(),
                      _detailRow(Icons.email_rounded, 'Email', student!.email),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // ─── Leave Details ───
              Text(
                'Leave Details',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textMuted,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 10),
              GlassCard(
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _detailRow(Icons.category_rounded, 'Leave Type', '${req.leaveType.icon} ${req.leaveType.label}'),
                    _detailDivider(),
                    _detailRow(Icons.calendar_today_rounded, 'From', shortDateFormat.format(req.fromDate)),
                    _detailDivider(),
                    _detailRow(Icons.event_rounded, 'To', shortDateFormat.format(req.toDate)),
                    _detailDivider(),
                    _detailRow(Icons.timelapse_rounded, 'Duration', '${req.toDate.difference(req.fromDate).inDays + 1} day(s)'),
                    _detailDivider(),
                    _detailRow(Icons.access_time_rounded, 'Submitted', dateFormat.format(req.createdAt)),
                  ],
                ),
              ),
              const SizedBox(height: 8),

              // Reason
              GlassCard(
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.all(16),
                borderColor: AppColors.primaryStart.withValues(alpha: 0.15),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.notes_rounded, color: AppColors.primaryStart, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          'Reason',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primaryStart,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      req.reason,
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textPrimary,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // ─── Approval Chain ───
              Text(
                'Approval Chain',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textMuted,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 10),
              GlassCard(
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.all(16),
                child: ApprovalChainWidget(
                  steps: req.leaveType.approvalChain,
                  currentStep: req.approvalHistory.length,
                  isRejected: req.status == LeaveStatus.rejected,
                ),
              ),

              // ─── Approval History Timeline ───
              if (req.approvalHistory.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(
                  'Approval History',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textMuted,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 10),
                ...req.approvalHistory.map((step) {
                  final isApproved = step.action == 'approved' || step.action == 'forwarded';
                  final isRejected = step.action == 'rejected';
                  final color = isRejected
                      ? AppColors.accentRed
                      : isApproved
                          ? AppColors.accentGreen
                          : AppColors.accentAmber;
                  return GlassCard(
                    margin: const EdgeInsets.only(bottom: 4),
                    padding: const EdgeInsets.all(14),
                    borderColor: color.withValues(alpha: 0.15),
                    child: Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            isRejected
                                ? Icons.close_rounded
                                : isApproved
                                    ? Icons.check_rounded
                                    : Icons.hourglass_top_rounded,
                            color: color,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${step.approverName} (${step.approverRole})',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                step.comment ?? step.action.toUpperCase(),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          DateFormat('dd MMM\nhh:mm a').format(step.timestamp),
                          style: TextStyle(
                            fontSize: 10,
                            color: AppColors.textMuted,
                            height: 1.3,
                          ),
                          textAlign: TextAlign.right,
                        ),
                      ],
                    ),
                  );
                }),
              ],

              // Rejection reason
              if (req.rejectionReason != null && req.rejectionReason!.isNotEmpty) ...[
                const SizedBox(height: 12),
                GlassCard(
                  margin: EdgeInsets.zero,
                  padding: const EdgeInsets.all(14),
                  borderColor: AppColors.accentRed.withValues(alpha: 0.2),
                  backgroundColor: AppColors.accentRed.withValues(alpha: 0.04),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline_rounded, color: AppColors.accentRed, size: 18),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Rejected: ${req.rejectionReason}',
                          style: TextStyle(fontSize: 13, color: AppColors.accentRed),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 24),

              // ─── Action Buttons inside bottom sheet ───
              if (req.status == LeaveStatus.pending ||
                  req.status == LeaveStatus.forwardedToParent ||
                  req.status == LeaveStatus.forwardedToHod ||
                  req.status == LeaveStatus.forwardedToWarden ||
                  req.status == LeaveStatus.forwardedToFaculty ||
                  req.status == LeaveStatus.awaitingHodAfterFaculty ||
                  req.status == LeaveStatus.returnedToRt) ...[
                Row(
                  children: [
                    Expanded(
                      child: GlassButton(
                        label: 'Approve',
                        icon: Icons.check_rounded,
                        gradient: const LinearGradient(
                          colors: [AppColors.accentGreen, Color(0xFF059669)],
                        ),
                        onPressed: () {
                          Navigator.pop(ctx);
                          _approve(req);
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: GlassButton(
                        label: 'Reject',
                        icon: Icons.close_rounded,
                        gradient: const LinearGradient(
                          colors: [AppColors.accentRed, Color(0xFFDC2626)],
                        ),
                        onPressed: () {
                          Navigator.pop(ctx);
                          _reject(req);
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primaryStart, size: 18),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textMuted,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _detailDivider() {
    return Divider(
      height: 1,
      thickness: 0.5,
      color: AppColors.glassBorder.withValues(alpha: 0.5),
    );
  }

  Widget _buildRequestCard(LeaveRequest req) {
    final dateFormat = DateFormat('dd MMM');
    Color statusColor;
    switch (req.status) {
      case LeaveStatus.approved:
        statusColor = AppColors.statusApproved;
        break;
      case LeaveStatus.rejected:
        statusColor = AppColors.statusRejected;
        break;
      case LeaveStatus.pending:
        statusColor = AppColors.statusPending;
        break;
      case LeaveStatus.documentsRequested:
        statusColor = AppColors.accentAmber;
        break;
      default:
        statusColor = AppColors.statusForwarded;
    }

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(req.leaveType.icon, style: const TextStyle(fontSize: 24)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(req.studentName,
                        style: Theme.of(context).textTheme.titleMedium),
                    Text(
                      '${req.leaveType.label} • ${dateFormat.format(req.fromDate)} - ${dateFormat.format(req.toDate)}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              StatusBadge(label: req.status.label, color: statusColor),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            req.reason,
            style: Theme.of(context).textTheme.bodyMedium,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 10),

          // Brief info row (block & roll)
          Row(
            children: [
              Icon(Icons.apartment_rounded, size: 14, color: AppColors.textMuted),
              const SizedBox(width: 4),
              Text(
                req.hostelBlock,
                style: TextStyle(fontSize: 12, color: AppColors.textMuted, fontWeight: FontWeight.w500),
              ),
              const SizedBox(width: 12),
              Icon(Icons.door_front_door_rounded, size: 14, color: AppColors.textMuted),
              const SizedBox(width: 4),
              Text(
                req.roomNumber,
                style: TextStyle(fontSize: 12, color: AppColors.textMuted, fontWeight: FontWeight.w500),
              ),
              const Spacer(),
              // See More button
              GestureDetector(
                onTap: () => _showStudentDetails(req),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.primaryStart.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppColors.primaryStart.withValues(alpha: 0.2),
                      width: 0.5,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.info_outline_rounded, size: 14, color: AppColors.primaryStart),
                      const SizedBox(width: 4),
                      Text(
                        'See More',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.primaryStart,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Action buttons
          if (req.status == LeaveStatus.pending ||
              req.status == LeaveStatus.forwardedToParent ||
              req.status == LeaveStatus.forwardedToHod ||
              req.status == LeaveStatus.forwardedToWarden ||
              req.status == LeaveStatus.forwardedToFaculty ||
              req.status == LeaveStatus.awaitingHodAfterFaculty ||
              req.status == LeaveStatus.returnedToRt)
            Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: GlassButton(
                        label: 'Approve',
                        icon: Icons.check_rounded,
                        isSmall: true,
                        gradient: const LinearGradient(
                          colors: [AppColors.accentGreen, Color(0xFF059669)],
                        ),
                        onPressed: () => _approve(req),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: GlassButton(
                        label: 'Reject',
                        icon: Icons.close_rounded,
                        isSmall: true,
                        gradient: const LinearGradient(
                          colors: [AppColors.accentRed, Color(0xFFDC2626)],
                        ),
                        onPressed: () => _reject(req),
                      ),
                    ),
                  ],
                ),
                // Faculty can request documents
                if (widget.service.currentUser?.role == UserRole.faculty &&
                    req.status == LeaveStatus.forwardedToFaculty) ...[
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: GlassButton(
                      label: 'Request Documents',
                      icon: Icons.upload_file_rounded,
                      isSmall: true,
                      gradient: const LinearGradient(
                        colors: [AppColors.accentCyan, Color(0xFF0891B2)],
                      ),
                      onPressed: () => _requestDocs(req),
                    ),
                  ),
                ],
              ],
            ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms).slideX(begin: 0.02);
  }

  Future<void> _approve(LeaveRequest req) async {
    final user = widget.service.currentUser;
    if (user == null) return;

    // ─── Overlap check — warn RT of conflicting passes ─────
    final overlapping = widget.service.getOverlappingPasses(
      req.studentId,
      req.fromDate,
      req.toDate,
    );

    if (overlapping.isNotEmpty && mounted) {
      final proceed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: AppColors.bgCard,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Icon(Icons.warning_amber_rounded,
                  color: AppColors.accentAmber, size: 24),
              const SizedBox(width: 10),
              const Text('Overlapping Pass Detected',
                  style: TextStyle(
                      color: AppColors.textPrimary, fontSize: 15)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${req.studentName} already has ${overlapping.length} active pass(es) during this window:',
                style: TextStyle(
                    color: AppColors.textSecondary, fontSize: 13),
              ),
              const SizedBox(height: 12),
              ...overlapping.map((p) => Container(
                    margin: const EdgeInsets.only(bottom: 6),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color:
                          AppColors.accentAmber.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: AppColors.accentAmber
                            .withValues(alpha: 0.2),
                      ),
                    ),
                    child: Text(
                      '${DateFormat('dd MMM HH:mm').format(p.validFrom)} → ${DateFormat('dd MMM HH:mm').format(p.validUntil)} (${p.state.label})',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.accentAmber,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  )),
              const SizedBox(height: 8),
              Text(
                'Approve with overlapping pass?',
                style: TextStyle(
                    color: AppColors.textSecondary, fontSize: 13),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel',
                  style: TextStyle(color: AppColors.textMuted)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accentAmber,
              ),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Approve Anyway'),
            ),
          ],
        ),
      );
      if (proceed != true) return;
    }
    // ─────────────────────────────────────────────────────

    await widget.service.approveRequest(
      req.id,
      user.uid,
      user.name,
      user.role.label,
    );
    _loadData();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Request approved ✓'),
          backgroundColor: AppColors.accentGreen,
        ),
      );
    }
  }

  Future<void> _reject(LeaveRequest req) async {
    final reasonController = TextEditingController();
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.bgCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Reject Request',
            style: TextStyle(color: AppColors.textPrimary)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Please provide a reason for rejection:',
              style: TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: reasonController,
              maxLines: 3,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: InputDecoration(
                hintText: 'Reason...',
                filled: true,
                fillColor: AppColors.glassWhite,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.glassBorder),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel',
                style: TextStyle(color: AppColors.textMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accentRed,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Reject'),
          ),
        ],
      ),
    );

    if (result == true && mounted) {
      final user = widget.service.currentUser;
      if (user == null) return;
      await widget.service.rejectRequest(
        req.id,
        user.uid,
        user.name,
        user.role.label,
        reasonController.text.trim().isEmpty
            ? 'Rejected'
            : reasonController.text.trim(),
      );
      _loadData();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Request rejected'),
          backgroundColor: AppColors.accentRed,
        ),
      );
    }
    reasonController.dispose();
  }

  Future<void> _requestDocs(LeaveRequest req) async {
    final commentController = TextEditingController();
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.bgCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Request Documents',
            style: TextStyle(color: AppColors.textPrimary)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'What documents do you need from the student?',
              style: TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: commentController,
              maxLines: 3,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: InputDecoration(
                hintText: 'e.g., Event invitation, travel itinerary...',
                filled: true,
                fillColor: AppColors.glassWhite,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.glassBorder),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel',
                style: TextStyle(color: AppColors.textMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accentCyan,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Request'),
          ),
        ],
      ),
    );

    if (result == true && mounted) {
      final user = widget.service.currentUser;
      if (user == null) return;
      await widget.service.requestDocuments(
        req.id,
        user.uid,
        user.name,
        commentController.text.trim().isEmpty
            ? 'Please upload supporting documents'
            : commentController.text.trim(),
      );
      _loadData();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Documents requested from student 📄'),
          backgroundColor: AppColors.accentCyan,
        ),
      );
    }
    commentController.dispose();
  }

  Widget _buildPendingList(List<LeaveRequest> pendingRequests) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          Text(
            'Pending Approvals',
            style: Theme.of(context).textTheme.headlineLarge,
          ),
          const SizedBox(height: 4),
          Text(
            '${pendingRequests.length} requests require your action',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          if (pendingRequests.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(40),
                child: Column(
                  children: [
                    Icon(Icons.check_circle_outline_rounded,
                        size: 64, color: AppColors.accentGreen),
                    const SizedBox(height: 16),
                    Text('No pending requests',
                        style: TextStyle(
                            color: AppColors.textMuted, fontSize: 16)),
                  ],
                ),
              ),
            )
          else
            ...pendingRequests.map((req) => _buildRequestCard(req)),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildAllRequests(List<LeaveRequest> allRequests) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          Text(
            'All Requests',
            style: Theme.of(context).textTheme.headlineLarge,
          ),
          const SizedBox(height: 16),
          ...allRequests.map((req) => _buildRequestCard(req)),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildProfile(AppUser user) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          const SizedBox(height: 16),
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryStart.withValues(alpha: 0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Center(
              child: Text(
                user.name[0],
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(user.name, style: Theme.of(context).textTheme.headlineMedium),
          Text(user.email, style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 8),
          StatusBadge(label: user.role.label, color: AppColors.primaryStart),
          const SizedBox(height: 24),

          if (user.department != null)
            _profileItem(Icons.school_rounded, 'Department', user.department!),
          if (user.hostelBlock != null)
            _profileItem(
                Icons.apartment_rounded, 'Hostel Block', user.hostelBlock!),
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
          ),
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
}
