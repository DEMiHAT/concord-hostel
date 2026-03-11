import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../models/enums.dart';
import '../../models/leave_request.dart';
import '../../models/user_model.dart';
import '../../services/app_service.dart';
import '../../widgets/glass_widgets.dart';
import '../shared/geofence_attendance_screen.dart';

class ParentHomeScreen extends StatefulWidget {
  final AppService service;
  const ParentHomeScreen({super.key, required this.service});

  @override
  State<ParentHomeScreen> createState() => _ParentHomeScreenState();
}

class _ParentHomeScreenState extends State<ParentHomeScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final user = widget.service.currentUser;
    if (user == null) return const SizedBox.shrink();
    final pendingRequests =
        widget.service.getPendingApprovalsForRole(UserRole.parent);
    final allRequests = widget.service.leaveRequests;

    return GlassScaffold(
      bottomNavigationBar: _buildBottomNav(pendingRequests.length),
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _buildDashboard(user, pendingRequests, allRequests),
          _buildPendingList(pendingRequests),
          _buildChildInfo(user, allRequests),
          _buildProfile(user),
        ],
      ),
    );
  }

  Widget _buildBottomNav(int pendingCount) {
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
            selectedItemColor: AppColors.accentAmber,
            unselectedItemColor: AppColors.textMuted,
            selectedFontSize: 11,
            unselectedFontSize: 10,
            items: [
              const BottomNavigationBarItem(
                icon: Icon(Icons.dashboard_rounded),
                label: 'Home',
              ),
              BottomNavigationBarItem(
                icon: Badge(
                  isLabelVisible: pendingCount > 0,
                  label: Text('$pendingCount',
                      style: const TextStyle(fontSize: 9)),
                  child: const Icon(Icons.pending_actions_rounded),
                ),
                label: 'Approvals',
              ),
              const BottomNavigationBarItem(
                icon: Icon(Icons.child_care_rounded),
                label: 'My Child',
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

  // ─── Dashboard ───────────────────────────────────────

  Widget _buildDashboard(
      AppUser user, List<LeaveRequest> pending, List<LeaveRequest> all) {
    // Get child info
    final childRequests = all;
    final approvedCount =
        childRequests.where((r) => r.status == LeaveStatus.approved).length;
    final activeQrCount = widget.service.qrPasses.where((p) => p.isActive).length;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          // Greeting
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hello, ${user.name.split(' ').first} 👋',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    Text(
                      'Parent Dashboard',
                      style: Theme.of(context).textTheme.headlineLarge,
                    ),
                    StatusBadge(
                      label: 'Parent',
                      color: AppColors.accentAmber,
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
                    gradient: const LinearGradient(
                      colors: [AppColors.accentAmber, Color(0xFFD97706)],
                    ),
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

          // Stats
          Row(
            children: [
              Expanded(
                child: StatCard(
                  title: 'Needs Approval',
                  value: '${pending.length}',
                  icon: Icons.hourglass_top_rounded,
                  color: AppColors.accentAmber,
                  subtitle: 'From your child',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: StatCard(
                  title: 'Approved',
                  value: '$approvedCount',
                  icon: Icons.check_circle_rounded,
                  color: AppColors.accentGreen,
                ),
              ),
            ],
          ).animate().fadeIn(delay: 200.ms, duration: 400.ms),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: StatCard(
                  title: 'Total Requests',
                  value: '${childRequests.length}',
                  icon: Icons.receipt_long_rounded,
                  color: AppColors.primaryStart,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: StatCard(
                  title: 'Active Passes',
                  value: '$activeQrCount',
                  icon: Icons.qr_code_rounded,
                  color: AppColors.accentCyan,
                ),
              ),
            ],
          ).animate().fadeIn(delay: 300.ms, duration: 400.ms),
          const SizedBox(height: 24),

          // Pending approvals preview
          if (pending.isNotEmpty) ...[
            Row(
              children: [
                const Icon(Icons.notification_important_rounded,
                    color: AppColors.accentAmber, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Requires Your Approval',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 8),
            ...pending.take(3).map((req) => _buildRequestCard(req)),
            if (pending.length > 3) ...[
              const SizedBox(height: 8),
              Center(
                child: TextButton(
                  onPressed: () => setState(() => _currentIndex = 1),
                  child: Text(
                    'View all ${pending.length} pending →',
                    style: TextStyle(
                      color: AppColors.accentAmber,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
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
                        'No pending approvals from your child',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
          const SizedBox(height: 24),

          // Quick access
          Text('Quick Access', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          GlassCard(
            onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      GeofenceAttendanceScreen(service: widget.service),
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
                  child: const Icon(Icons.location_on_rounded,
                      color: Color(0xFF8B5CF6), size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Attendance & Alerts',
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary)),
                      Text('View child\'s attendance & anomaly alerts',
                          style:
                              TextStyle(fontSize: 11, color: AppColors.textMuted)),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded,
                    color: AppColors.textMuted, size: 22),
              ],
            ),
          ).animate().fadeIn(delay: 500.ms, duration: 400.ms),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  // ─── Pending List ───────────────────────────────────

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
            '${pendingRequests.length} requests from your child',
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
                    Text('No pending approvals',
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

  // ─── Child Info ──────────────────────────────────────

  Widget _buildChildInfo(AppUser user, List<LeaveRequest> allRequests) {
    // Find the linked student (from leave requests)
    final studentNames = allRequests
        .map((r) => r.studentName)
        .toSet()
        .toList();

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          Text(
            'My Child',
            style: Theme.of(context).textTheme.headlineLarge,
          ),
          const SizedBox(height: 4),
          Text(
            'Leave request history & status',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),

          // Child summary cards
          if (studentNames.isNotEmpty)
            ...studentNames.map((name) {
              final childReqs =
                  allRequests.where((r) => r.studentName == name).toList();
              final approved = childReqs
                  .where((r) => r.status == LeaveStatus.approved)
                  .length;
              final pending = childReqs
                  .where((r) =>
                      r.status != LeaveStatus.approved &&
                      r.status != LeaveStatus.rejected)
                  .length;
              final rejected = childReqs
                  .where((r) => r.status == LeaveStatus.rejected)
                  .length;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GlassCard(
                    borderColor: AppColors.accentAmber.withValues(alpha: 0.3),
                    child: Row(
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [
                                AppColors.accentAmber,
                                Color(0xFFD97706)
                              ],
                            ),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Center(
                            child: Text(
                              name[0],
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(name,
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium),
                              if (childReqs.isNotEmpty)
                                Text(
                                  '${childReqs.first.studentRollNumber} • ${childReqs.first.hostelBlock}',
                                  style:
                                      Theme.of(context).textTheme.bodySmall,
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Mini stats
                  Row(
                    children: [
                      _miniStat('Approved', '$approved',
                          AppColors.accentGreen),
                      const SizedBox(width: 8),
                      _miniStat('Pending', '$pending',
                          AppColors.accentAmber),
                      const SizedBox(width: 8),
                      _miniStat('Rejected', '$rejected',
                          AppColors.accentRed),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // All requests
                  Text('All Requests',
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  ...childReqs.map((req) => _buildRequestCard(req,
                      showActions: false)),
                ],
              );
            }),

          if (studentNames.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(40),
                child: Column(
                  children: [
                    Icon(Icons.child_care_rounded,
                        size: 64, color: AppColors.textMuted),
                    const SizedBox(height: 16),
                    Text('No child activity yet',
                        style: TextStyle(
                            color: AppColors.textMuted, fontSize: 16)),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _miniStat(String label, String value, Color color) {
    return Expanded(
      child: GlassCard(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Profile ─────────────────────────────────────────

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
              gradient: const LinearGradient(
                colors: [AppColors.accentAmber, Color(0xFFD97706)],
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: AppColors.accentAmber.withValues(alpha: 0.3),
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
          StatusBadge(label: 'Parent', color: AppColors.accentAmber),
          const SizedBox(height: 24),

          if (user.phone != null)
            _profileItem(Icons.phone_rounded, 'Phone', user.phone!),
          _profileItem(Icons.email_rounded, 'Email', user.email),
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
          Icon(icon, color: AppColors.accentAmber, size: 20),
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

  // ─── Request Card ────────────────────────────────────

  Widget _buildRequestCard(LeaveRequest req, {bool showActions = true}) {
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
      case LeaveStatus.forwardedToParent:
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

          // Approval chain
          if (req.leaveType.approvalChain.isNotEmpty) ...[
            const SizedBox(height: 12),
            ApprovalChainWidget(
              steps: req.leaveType.approvalChain,
              currentStep: req.approvalHistory.length,
              isRejected: req.status == LeaveStatus.rejected,
            ),
          ],

          // Action buttons for pending parent approval
          if (showActions &&
              req.status == LeaveStatus.forwardedToParent) ...[
            const SizedBox(height: 12),
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
          ],
        ],
      ),
    ).animate().fadeIn(duration: 300.ms).slideX(begin: 0.02);
  }

  // ─── Actions ─────────────────────────────────────────

  Future<void> _approve(LeaveRequest req) async {
    final user = widget.service.currentUser;
    if (user == null) return;
    await widget.service.approveRequest(
      req.id,
      user.uid,
      user.name,
      user.role.label,
    );
    setState(() {});
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Leave approved ✓'),
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
            ? 'Rejected by parent'
            : reasonController.text.trim(),
      );
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Request rejected'),
          backgroundColor: AppColors.accentRed,
        ),
      );
    }
    reasonController.dispose();
  }
}
