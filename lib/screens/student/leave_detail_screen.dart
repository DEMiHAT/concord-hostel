import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../models/enums.dart';
import '../../models/leave_request.dart';
import '../../services/app_service.dart';
import '../../widgets/glass_widgets.dart';
import 'qr_pass_screen.dart';

class LeaveDetailScreen extends StatefulWidget {
  final AppService service;
  final LeaveRequest leave;

  const LeaveDetailScreen({
    super.key,
    required this.service,
    required this.leave,
  });

  @override
  State<LeaveDetailScreen> createState() => _LeaveDetailScreenState();
}

class _LeaveDetailScreenState extends State<LeaveDetailScreen> {
  late LeaveRequest _leave;

  @override
  void initState() {
    super.initState();
    _leave = widget.leave;
  }

  Color _getStatusColor(LeaveStatus status) {
    switch (status) {
      case LeaveStatus.approved:
        return AppColors.statusApproved;
      case LeaveStatus.rejected:
        return AppColors.statusRejected;
      case LeaveStatus.pending:
        return AppColors.statusPending;
      case LeaveStatus.documentsRequested:
        return AppColors.accentAmber;
      default:
        return AppColors.statusForwarded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd MMM yyyy, hh:mm a');
    final leave = _leave;
    final statusColor = _getStatusColor(leave.status);

    return GlassScaffold(
      appBar: AppBar(
        title: Text(leave.leaveType.label),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),

            // Status Banner
            GlassCard(
              borderColor: statusColor.withValues(alpha: 0.4),
              backgroundColor: statusColor.withValues(alpha: 0.05),
              child: Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Center(
                      child: Text(
                        leave.leaveType.icon,
                        style: const TextStyle(fontSize: 28),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          leave.leaveType.label,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 4),
                        StatusBadge(
                          label: leave.status.label,
                          color: statusColor,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Details
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _detailRow(context, Icons.calendar_today_rounded, 'From',
                      dateFormat.format(leave.fromDate)),
                  const Divider(color: AppColors.glassBorder, height: 20),
                  _detailRow(context, Icons.event_rounded, 'To',
                      dateFormat.format(leave.toDate)),
                  const Divider(color: AppColors.glassBorder, height: 20),
                  _detailRow(context, Icons.access_time_rounded, 'Created',
                      dateFormat.format(leave.createdAt)),
                ],
              ),
            ),

            // Reason
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.notes_rounded,
                          color: AppColors.primaryStart, size: 18),
                      const SizedBox(width: 8),
                      Text('Reason',
                          style: Theme.of(context).textTheme.titleMedium),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    leave.reason,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ],
              ),
            ),

            // Rejection reason
            if (leave.rejectionReason != null &&
                leave.rejectionReason!.isNotEmpty) ...[
              GlassCard(
                borderColor: AppColors.accentRed.withValues(alpha: 0.3),
                backgroundColor: AppColors.accentRed.withValues(alpha: 0.05),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.cancel_rounded,
                            color: AppColors.accentRed, size: 18),
                        const SizedBox(width: 8),
                        Text('Rejection Reason',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(color: AppColors.accentRed)),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      leave.rejectionReason!,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ],
                ),
              ),
            ],

            // Approval Chain
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Approval Progress',
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 16),
                  ApprovalChainWidget(
                    steps: leave.leaveType.approvalChain,
                    currentStep: leave.approvalHistory.length,
                    isRejected: leave.status == LeaveStatus.rejected,
                  ),
                  const SizedBox(height: 16),
                  // Approval history timeline
                  ...leave.approvalHistory.map((step) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: step.action == 'approved'
                                    ? AppColors.accentGreen.withValues(alpha: 0.15)
                                    : step.action == 'rejected'
                                        ? AppColors.accentRed.withValues(alpha: 0.15)
                                        : AppColors.accentAmber.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                step.action == 'approved'
                                    ? Icons.check_rounded
                                    : step.action == 'rejected'
                                        ? Icons.close_rounded
                                        : Icons.arrow_forward_rounded,
                                color: step.action == 'approved'
                                    ? AppColors.accentGreen
                                    : step.action == 'rejected'
                                        ? AppColors.accentRed
                                        : AppColors.accentAmber,
                                size: 16,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${step.approverName} (${step.approverRole})',
                                    style:
                                        Theme.of(context).textTheme.titleMedium?.copyWith(fontSize: 14),
                                  ),
                                  Text(
                                    '${step.action.toUpperCase()} • ${DateFormat('dd MMM, hh:mm a').format(step.timestamp)}',
                                    style:
                                        Theme.of(context).textTheme.bodySmall,
                                  ),
                                  if (step.comment != null) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      step.comment!,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.copyWith(fontStyle: FontStyle.italic),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      )),
                ],
              ),
            ),

            // Documents Requested banner
            if (leave.status == LeaveStatus.documentsRequested) ...[
              GlassCard(
                borderColor: AppColors.accentAmber.withValues(alpha: 0.4),
                backgroundColor: AppColors.accentAmber.withValues(alpha: 0.05),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.upload_file_rounded,
                            color: AppColors.accentAmber, size: 20),
                        const SizedBox(width: 8),
                        Text('Documents Requested',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(color: AppColors.accentAmber)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Show latest faculty comment
                    if (leave.approvalHistory.isNotEmpty &&
                        leave.approvalHistory.last.action == 'documents_requested' &&
                        leave.approvalHistory.last.comment != null)
                      Text(
                        leave.approvalHistory.last.comment!,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: GlassButton(
                        label: 'Upload Documents',
                        icon: Icons.cloud_upload_rounded,
                        isSmall: true,
                        gradient: const LinearGradient(
                          colors: [AppColors.accentAmber, Color(0xFFD97706)],
                        ),
                        onPressed: () => _uploadDocuments(),
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn(duration: 300.ms).shake(hz: 1, delay: 200.ms),
            ],

            // Proof Documents list
            if (leave.proofDocumentUrls.isNotEmpty) ...[
              GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.attach_file_rounded,
                            color: AppColors.accentCyan, size: 18),
                        const SizedBox(width: 8),
                        Text('Uploaded Documents',
                            style: Theme.of(context).textTheme.titleMedium),
                      ],
                    ),
                    const SizedBox(height: 10),
                    ...leave.proofDocumentUrls.asMap().entries.map(
                          (entry) => Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Row(
                              children: [
                                const Icon(Icons.description_rounded,
                                    color: AppColors.accentCyan, size: 16),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    entry.value,
                                    style: Theme.of(context).textTheme.bodyMedium
                                        ?.copyWith(color: AppColors.accentCyan),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                  ],
                ),
              ),
            ],

            // QR Pass button
            if (leave.qrPassId != null) ...[
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: GlassButton(
                  label: 'View QR Pass',
                  icon: Icons.qr_code_2_rounded,
                  gradient: const LinearGradient(
                    colors: [AppColors.accentGreen, Color(0xFF059669)],
                  ),
                  onPressed: () {
                    final pass = widget.service.getQrPass(leave.qrPassId!);
                    if (pass != null) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              QrPassScreen(service: widget.service, pass: pass),
                        ),
                      );
                    }
                  },
                ),
              ),
            ],
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(
      BuildContext context, IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primaryStart, size: 18),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: Theme.of(context).textTheme.bodySmall),
            Text(value, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontSize: 14)),
          ],
        ),
      ],
    );
  }

  Future<void> _uploadDocuments() async {
    // Simulate document upload with mock file names
    final mockDocNames = [
      'event_invitation.pdf',
      'travel_ticket.pdf',
      'medical_certificate.pdf',
      'permission_letter.pdf',
    ];

    final selected = await showDialog<List<String>>(
      context: context,
      builder: (ctx) {
        final chosen = <String>{};
        return StatefulBuilder(
          builder: (ctx, setDialogState) => AlertDialog(
            backgroundColor: AppColors.bgCard,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Text('Select Documents',
                style: TextStyle(color: AppColors.textPrimary)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Select documents to upload (demo mode):',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 12),
                ...mockDocNames.map((doc) => CheckboxListTile(
                      title: Text(doc,
                          style: const TextStyle(color: AppColors.textPrimary, fontSize: 14)),
                      value: chosen.contains(doc),
                      activeColor: AppColors.accentCyan,
                      onChanged: (v) {
                        setDialogState(() {
                          if (v == true) {
                            chosen.add(doc);
                          } else {
                            chosen.remove(doc);
                          }
                        });
                      },
                    )),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, null),
                child: const Text('Cancel',
                    style: TextStyle(color: AppColors.textMuted)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accentCyan,
                ),
                onPressed: chosen.isEmpty ? null : () => Navigator.pop(ctx, chosen.toList()),
                child: const Text('Upload'),
              ),
            ],
          ),
        );
      },
    );

    if (selected != null && selected.isNotEmpty && mounted) {
      await widget.service.submitDocuments(_leave.id, selected);
      // Refresh the leave request
      final updated = widget.service.leaveRequests.firstWhere(
        (l) => l.id == _leave.id,
        orElse: () => _leave,
      );
      setState(() => _leave = updated);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${selected.length} document(s) uploaded ✅'),
          backgroundColor: AppColors.accentGreen,
        ),
      );
    }
  }
}
