import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../models/enums.dart';
import '../../models/leave_request.dart';
import '../../models/user_model.dart';
import '../../services/mock_service.dart';
import '../../widgets/glass_widgets.dart';
import '../shared/attendance_screen.dart';
import '../shared/medical_screen.dart';
import '../shared/grievance_screen.dart';
import '../shared/geofence_attendance_screen.dart';

class ApproverHomeScreen extends StatefulWidget {
  final MockService service;
  const ApproverHomeScreen({super.key, required this.service});

  @override
  State<ApproverHomeScreen> createState() => _ApproverHomeScreenState();
}

class _ApproverHomeScreenState extends State<ApproverHomeScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final user = widget.service.currentUser!;
    final pendingRequests =
        widget.service.getPendingApprovalsForRole(user.role);
    final allRequests = widget.service.leaveRequests;

    return GlassScaffold(
      bottomNavigationBar: _buildBottomNav(),
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _buildDashboard(user, pendingRequests),
          _buildPendingList(pendingRequests),
          _buildAllRequests(allRequests),
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
    final stats = widget.service.getStats();

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
    final user = widget.service.currentUser!;
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
      final user = widget.service.currentUser!;
      await widget.service.rejectRequest(
        req.id,
        user.uid,
        user.name,
        user.role.label,
        reasonController.text.trim().isEmpty
            ? 'Rejected'
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
      final user = widget.service.currentUser!;
      await widget.service.requestDocuments(
        req.id,
        user.uid,
        user.name,
        commentController.text.trim().isEmpty
            ? 'Please upload supporting documents'
            : commentController.text.trim(),
      );
      setState(() {});
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
