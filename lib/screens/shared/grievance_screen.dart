import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../models/enums.dart';
import '../../models/grievance.dart';
import '../../services/mock_service.dart';
import '../../widgets/glass_widgets.dart';

class GrievanceScreen extends StatefulWidget {
  final MockService service;
  final bool isManagementView; // RT/Warden/Admin
  const GrievanceScreen({super.key, required this.service, this.isManagementView = false});

  @override
  State<GrievanceScreen> createState() => _GrievanceScreenState();
}

class _GrievanceScreenState extends State<GrievanceScreen> {
  Color _statusColor(GrievanceStatus status) {
    switch (status) {
      case GrievanceStatus.open:
        return AppColors.accentAmber;
      case GrievanceStatus.underReview:
        return AppColors.accentCyan;
      case GrievanceStatus.actionTaken:
        return const Color(0xFF8B5CF6);
      case GrievanceStatus.escalated:
        return AppColors.accentRed;
      case GrievanceStatus.resolved:
        return AppColors.accentGreen;
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.service.currentUser!;
    final grievances = widget.isManagementView
        ? widget.service.getGrievancesForRole(user.role)
        : widget.service.getStudentGrievances(user.uid);
    final allGrievances = widget.isManagementView
        ? widget.service.getAllGrievances()
        : grievances;

    final openCount =
        allGrievances.where((g) => g.status == GrievanceStatus.open).length;
    final escalatedCount =
        allGrievances.where((g) => g.status == GrievanceStatus.escalated).length;

    return GlassScaffold(
      appBar: AppBar(
        title: Text(widget.isManagementView ? 'Grievance Management' : 'Grievances'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      floatingActionButton: !widget.isManagementView
          ? FloatingActionButton(
              backgroundColor: AppColors.primaryStart,
              onPressed: () => _showSubmitDialog(),
              child: const Icon(Icons.add_rounded, color: Colors.white),
            )
          : null,
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),

            // Management stats
            if (widget.isManagementView) ...[
              Row(
                children: [
                  Expanded(
                    child: StatCard(
                      title: 'Open',
                      value: '$openCount',
                      icon: Icons.inbox_rounded,
                      color: AppColors.accentAmber,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: StatCard(
                      title: 'Escalated',
                      value: '$escalatedCount',
                      icon: Icons.arrow_upward_rounded,
                      color: AppColors.accentRed,
                    ),
                  ),
                ],
              ).animate().fadeIn(duration: 400.ms),
              const SizedBox(height: 16),
            ],

            Text(widget.isManagementView ? 'Assigned to You' : 'Your Complaints',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),

            if (grievances.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(40),
                  child: Column(
                    children: [
                      Icon(Icons.feedback_rounded,
                          size: 48, color: AppColors.textMuted),
                      const SizedBox(height: 12),
                      Text(
                        widget.isManagementView
                            ? 'No pending grievances'
                            : 'No complaints submitted',
                        style: TextStyle(color: AppColors.textMuted),
                      ),
                    ],
                  ),
                ),
              )
            else
              ...grievances.map((Grievance grv) {
                final color = _statusColor(grv.status);
                return GlassCard(
                  onTap: () => _showGrievanceDetail(grv),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(grv.category.icon, style: const TextStyle(fontSize: 24)),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(grv.category.label,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textPrimary)),
                                if (widget.isManagementView)
                                  Text(
                                      '${grv.studentName} • ${grv.hostelBlock} ${grv.roomNumber}',
                                      style: Theme.of(context).textTheme.bodySmall),
                                Text(
                                  DateFormat('dd MMM yyyy').format(grv.createdAt),
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                          StatusBadge(label: grv.status.label, color: color),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(grv.description,
                          style: Theme.of(context).textTheme.bodyMedium,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis),
                      if (grv.escalationLevel > 0) ...[
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(Icons.arrow_upward_rounded,
                                size: 14, color: AppColors.accentRed),
                            const SizedBox(width: 4),
                            Text(
                              'Escalation level: ${grv.escalationLevel}',
                              style: TextStyle(
                                  fontSize: 11,
                                  color: AppColors.accentRed,
                                  fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ],
                      if (grv.actions.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          'Last action: ${grv.actions.last.action} by ${grv.actions.last.actorName}',
                          style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                        ),
                      ],
                    ],
                  ),
                ).animate().fadeIn(duration: 300.ms);
              }),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  void _showSubmitDialog() {
    GrievanceCategory selectedCategory = GrievanceCategory.other;
    final descController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: AppColors.bgCard,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Submit Complaint',
              style: TextStyle(color: AppColors.textPrimary)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Category', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: GrievanceCategory.values.map((cat) {
                    final isSelected = cat == selectedCategory;
                    return GestureDetector(
                      onTap: () => setDialogState(() => selectedCategory = cat),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.primaryStart.withValues(alpha: 0.1)
                              : AppColors.bgSurface,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isSelected
                                ? AppColors.primaryStart
                                : AppColors.glassBorder,
                          ),
                        ),
                        child: Text(
                          '${cat.icon} ${cat.label}',
                          style: TextStyle(
                            fontSize: 12,
                            color: isSelected
                                ? AppColors.primaryStart
                                : AppColors.textSecondary,
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.w400,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: descController,
                  maxLines: 4,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: const InputDecoration(
                      hintText: 'Describe your issue in detail...'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel',
                  style: TextStyle(color: AppColors.textMuted)),
            ),
            ElevatedButton(
              onPressed: () async {
                if (descController.text.trim().isNotEmpty) {
                  await widget.service.submitGrievance(
                    category: selectedCategory,
                    description: descController.text.trim(),
                  );
                  if (mounted) Navigator.pop(ctx);
                  setState(() {});
                }
              },
              child: const Text('Submit'),
            ),
          ],
        ),
      ),
    );
  }

  void _showGrievanceDetail(Grievance grv) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.bgCard,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        expand: false,
        builder: (ctx, scrollController) => SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(24),
          child: Column(
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
              Row(
                children: [
                  Text(grv.category.icon, style: const TextStyle(fontSize: 32)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(grv.category.label,
                            style: Theme.of(context).textTheme.headlineMedium),
                        Text(
                          'by ${grv.studentName} • ${grv.hostelBlock} ${grv.roomNumber}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  StatusBadge(
                      label: grv.status.label,
                      color: _statusColor(grv.status)),
                ],
              ),
              const SizedBox(height: 16),
              Text(grv.description,
                  style: Theme.of(context).textTheme.bodyLarge),
              const SizedBox(height: 20),

              // Action history
              if (grv.actions.isNotEmpty) ...[
                Text('Action History',
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                ...grv.actions.map((GrievanceAction action) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            margin: const EdgeInsets.only(top: 6),
                            decoration: BoxDecoration(
                              color: AppColors.primaryStart,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${action.actorName} (${action.actorRole}) — ${action.action}',
                                  style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textPrimary),
                                ),
                                if (action.comment != null)
                                  Text(action.comment!,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall),
                                Text(
                                  DateFormat('dd MMM, HH:mm')
                                      .format(action.timestamp),
                                  style: TextStyle(
                                      fontSize: 11,
                                      color: AppColors.textMuted),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    )),
                const SizedBox(height: 12),
              ],

              // Management actions
              if (widget.isManagementView &&
                  grv.status != GrievanceStatus.resolved) ...[
                const Divider(),
                const SizedBox(height: 8),
                Text('Actions',
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: GlassButton(
                        label: 'Respond',
                        icon: Icons.reply_rounded,
                        isSmall: true,
                        gradient: LinearGradient(
                            colors: [AppColors.accentCyan, const Color(0xFF0284C7)]),
                        onPressed: () {
                          Navigator.pop(ctx);
                          _showRespondDialog(grv);
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: GlassButton(
                        label: 'Escalate',
                        icon: Icons.arrow_upward_rounded,
                        isSmall: true,
                        gradient: LinearGradient(
                            colors: [AppColors.accentRed, const Color(0xFFB91C1C)]),
                        onPressed: () async {
                          await widget.service.escalateGrievance(
                            grievanceId: grv.id,
                            reason: 'Escalated by ${widget.service.currentUser!.role.label}',
                          );
                          if (mounted) Navigator.pop(ctx);
                          setState(() {});
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: GlassButton(
                    label: 'Resolve',
                    icon: Icons.check_circle_rounded,
                    isSmall: true,
                    gradient: LinearGradient(
                        colors: [AppColors.accentGreen, const Color(0xFF047857)]),
                    onPressed: () {
                      Navigator.pop(ctx);
                      _showResolveDialog(grv);
                    },
                  ),
                ),
              ],
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  void _showRespondDialog(Grievance grv) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.bgCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Respond', style: TextStyle(color: AppColors.textPrimary)),
        content: TextField(
          controller: controller,
          maxLines: 3,
          style: const TextStyle(color: AppColors.textPrimary),
          decoration: const InputDecoration(hintText: 'Your response...'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel', style: TextStyle(color: AppColors.textMuted))),
          ElevatedButton(
            onPressed: () async {
              if (controller.text.trim().isNotEmpty) {
                await widget.service.respondToGrievance(
                  grievanceId: grv.id,
                  comment: controller.text.trim(),
                );
                if (mounted) Navigator.pop(ctx);
                setState(() {});
              }
            },
            child: const Text('Send'),
          ),
        ],
      ),
    );
  }

  void _showResolveDialog(Grievance grv) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.bgCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Resolve Grievance',
            style: TextStyle(color: AppColors.textPrimary)),
        content: TextField(
          controller: controller,
          maxLines: 3,
          style: const TextStyle(color: AppColors.textPrimary),
          decoration: const InputDecoration(hintText: 'Resolution note...'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel', style: TextStyle(color: AppColors.textMuted))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.accentGreen),
            onPressed: () async {
              await widget.service.resolveGrievance(
                grievanceId: grv.id,
                comment: controller.text.trim().isEmpty
                    ? 'Resolved'
                    : controller.text.trim(),
              );
              if (mounted) Navigator.pop(ctx);
              setState(() {});
            },
            child: const Text('Resolve'),
          ),
        ],
      ),
    );
  }
}
