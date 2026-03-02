import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../models/enums.dart';
import '../../models/leave_request.dart';
import '../../models/qr_pass.dart';
import '../../models/user_model.dart';
import '../../services/mock_service.dart';
import '../../widgets/glass_widgets.dart';
import 'create_leave_screen.dart';
import 'leave_detail_screen.dart';
import 'qr_pass_screen.dart';

class StudentHomeScreen extends StatefulWidget {
  final MockService service;
  const StudentHomeScreen({super.key, required this.service});

  @override
  State<StudentHomeScreen> createState() => _StudentHomeScreenState();
}

class _StudentHomeScreenState extends State<StudentHomeScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final user = widget.service.currentUser!;
    final leaves = widget.service.getStudentLeaves(user.uid);
    final activePasses = widget.service.getStudentPasses(user.uid)
        .where((p) => p.isActive)
        .toList();

    return GlassScaffold(
      bottomNavigationBar: _buildBottomNav(),
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _buildDashboard(user, leaves, activePasses),
          _buildLeaveHistory(leaves),
          _buildPassesView(activePasses),
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
                      style: Theme.of(context).textTheme.headlineLarge,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${user.rollNumber} • ${user.hostelBlock}',
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

          // Quick Stats
          Row(
            children: [
              Expanded(
                child: StatCard(
                  title: 'Pending',
                  value: '$pendingCount',
                  icon: Icons.hourglass_top_rounded,
                  color: AppColors.accentAmber,
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
          ).animate().fadeIn(delay: 200.ms, duration: 400.ms).slideY(begin: 0.05),
          const SizedBox(height: 16),

          // Active QR Pass
          if (activePasses.isNotEmpty) ...[
            Text(
              'Active Pass',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            GlassCard(
              borderColor: AppColors.accentGreen.withValues(alpha: 0.4),
              backgroundColor: AppColors.accentGreen.withValues(alpha: 0.05),
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
              child: Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.accentGreen, Color(0xFF059669)],
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.qr_code_2_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'QR Pass Ready',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        Text(
                          'Tap to view your gate pass',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  StatusBadge(
                    label: activePasses.first.state.label,
                    color: AppColors.accentGreen,
                  ),
                ],
              ),
            ).animate().fadeIn(delay: 300.ms, duration: 400.ms),
            const SizedBox(height: 16),
          ],

          // New Request Button
          GlassButton(
            label: 'Create Leave Request',
            icon: Icons.add_rounded,
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => CreateLeaveScreen(service: widget.service),
                ),
              );
              setState(() {});
            },
          ).animate().fadeIn(delay: 400.ms, duration: 400.ms),
          const SizedBox(height: 24),

          // Recent Requests
          Text(
            'Recent Requests',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          ...leaves.take(3).map((leave) => _buildLeaveCard(leave)),
          const SizedBox(height: 100),
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
          const SizedBox(height: 16),
          if (leaves.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(40),
                child: Column(
                  children: [
                    Icon(Icons.inbox_rounded, size: 64, color: AppColors.textMuted),
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
            ...leaves.map((leave) => _buildLeaveCard(leave)),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildPassesView(List<QrPass> activePasses) {
    final allPasses = widget.service.getStudentPasses(widget.service.currentUser!.uid);
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          Text(
            'Gate Passes',
            style: Theme.of(context).textTheme.headlineLarge,
          ),
          const SizedBox(height: 16),
          if (allPasses.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(40),
                child: Column(
                  children: [
                    Icon(Icons.qr_code_rounded, size: 64, color: AppColors.textMuted),
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
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          const SizedBox(height: 16),
          // Profile avatar
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
          const SizedBox(height: 24),

          _profileItem(Icons.badge_rounded, 'Roll Number', user.rollNumber ?? '-'),
          _profileItem(Icons.apartment_rounded, 'Hostel Block', user.hostelBlock ?? '-'),
          _profileItem(Icons.door_front_door_rounded, 'Room', user.roomNumber ?? '-'),
          _profileItem(Icons.school_rounded, 'Department', user.department ?? '-'),
          _profileItem(Icons.phone_rounded, 'Phone', user.phone ?? '-'),
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
