import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../models/enums.dart';
import '../../models/medical.dart';
import '../../services/app_service.dart';
import '../../widgets/glass_widgets.dart';

/// Medical Screen for Students and Approvers (RT/Faculty/Warden/HoD)
/// Students: Read-only view of their records + request review
/// Approvers: View student fitness status + acknowledge intimation
class MedicalScreen extends StatefulWidget {
  final AppService service;
  final bool isApproverView; // RT, Faculty, Warden, HoD
  const MedicalScreen({super.key, required this.service, this.isApproverView = false});

  @override
  State<MedicalScreen> createState() => _MedicalScreenState();
}

class _MedicalScreenState extends State<MedicalScreen> {
  Color _fitnessColor(FitnessStatus status) {
    switch (status) {
      case FitnessStatus.fit:
        return AppColors.accentGreen;
      case FitnessStatus.notFit:
        return AppColors.accentRed;
      case FitnessStatus.underObservation:
        return AppColors.accentAmber;
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.service.currentUser!;
    final visits = widget.isApproverView
        ? widget.service.getAllMedicalVisits()
        : widget.service.getStudentMedicalVisits(user.uid);

    return GlassScaffold(
      appBar: AppBar(
        title: Text(widget.isApproverView ? 'Student Medical Status' : 'My Medical Records'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      // Students CANNOT create — only medical officers
      // Students CAN request review of existing records
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),

            // Student restriction banner
            if (!widget.isApproverView &&
                widget.service.isStudentMedicalRestricted(user.uid)) ...[
              GlassCard(
                borderColor: AppColors.accentRed.withValues(alpha: 0.5),
                backgroundColor: AppColors.accentRed.withValues(alpha: 0.08),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.accentRed.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.block_rounded,
                          color: AppColors.accentRed, size: 22),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Movement Restricted',
                              style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.accentRed,
                                  fontSize: 14)),
                          Text('Your gate exit is currently blocked by the Medical Officer.',
                              style: Theme.of(context).textTheme.bodySmall),
                        ],
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn().shake(delay: 300.ms, hz: 2, offset: const Offset(2, 0)),
              const SizedBox(height: 16),
            ],

            // Student: info notice
            if (!widget.isApproverView) ...[
              GlassCard(
                borderColor: AppColors.accentCyan.withValues(alpha: 0.3),
                backgroundColor: AppColors.accentCyan.withValues(alpha: 0.05),
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    Icon(Icons.info_outline_rounded,
                        color: AppColors.accentCyan, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Medical records are created by the Medical Officer after examination. '
                        'You can request a review of any existing record.',
                        style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Approver: summary
            if (widget.isApproverView) ...[
              Row(
                children: [
                  Expanded(
                    child: StatCard(
                      title: 'Not Fit',
                      value: '${visits.where((v) => v.fitnessStatus == FitnessStatus.notFit).length}',
                      icon: Icons.cancel_rounded,
                      color: AppColors.accentRed,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: StatCard(
                      title: 'Under Observation',
                      value: '${visits.where((v) => v.fitnessStatus == FitnessStatus.underObservation).length}',
                      icon: Icons.visibility_rounded,
                      color: AppColors.accentAmber,
                    ),
                  ),
                ],
              ).animate().fadeIn(duration: 400.ms),
              const SizedBox(height: 16),
            ],

            Text(widget.isApproverView ? 'All Student Records' : 'Your Medical Records',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),

            if (visits.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(40),
                  child: Column(
                    children: [
                      Icon(Icons.medical_services_rounded,
                          size: 48, color: AppColors.textMuted),
                      const SizedBox(height: 12),
                      Text('No medical records',
                          style: TextStyle(color: AppColors.textMuted)),
                      if (!widget.isApproverView)
                        Text('Records will appear when the Medical Officer creates them.',
                            style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                            textAlign: TextAlign.center),
                    ],
                  ),
                ),
              )
            else
              ...visits.map((MedicalVisit visit) {
                final fitnessColor = _fitnessColor(visit.fitnessStatus);
                return GlassCard(
                  onTap: () => _showRecordDetail(visit),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: fitnessColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Icon(
                              visit.fitnessStatus == FitnessStatus.fit
                                  ? Icons.check_circle_rounded
                                  : visit.fitnessStatus == FitnessStatus.notFit
                                      ? Icons.cancel_rounded
                                      : Icons.visibility_rounded,
                              color: fitnessColor,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.isApproverView ? visit.studentName : (visit.diagnosis ?? visit.symptoms),
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textPrimary),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  widget.isApproverView
                                      ? '${visit.rollNumber ?? ''} • ${visit.hostelBlock}'
                                      : 'By ${visit.createdByOfficerName}',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              StatusBadge(label: visit.fitnessStatus.label, color: fitnessColor),
                              const SizedBox(height: 4),
                              Text(DateFormat('dd MMM').format(visit.createdAt),
                                  style: TextStyle(fontSize: 10, color: AppColors.textMuted)),
                            ],
                          ),
                        ],
                      ),
                      if (visit.restDays != null || visit.movementRestricted) ...[
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            if (visit.restDays != null) ...[
                              Icon(Icons.bed_rounded, size: 12, color: AppColors.textMuted),
                              const SizedBox(width: 3),
                              Text('${visit.restDays} days rest',
                                  style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                            ],
                            if (visit.movementRestricted) ...[
                              const SizedBox(width: 10),
                              Icon(Icons.block_rounded, size: 12, color: AppColors.accentRed),
                              const SizedBox(width: 3),
                              Text('Movement Restricted',
                                  style: TextStyle(fontSize: 11, color: AppColors.accentRed, fontWeight: FontWeight.w600)),
                            ],
                          ],
                        ),
                      ],
                      if (visit.reviewRequested && !widget.isApproverView) ...[
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(Icons.rate_review_rounded, size: 12, color: AppColors.accentAmber),
                            const SizedBox(width: 3),
                            Text('Review requested — waiting for officer',
                                style: TextStyle(fontSize: 11, color: AppColors.accentAmber)),
                          ],
                        ),
                      ],
                      // Show intimation badges for approvers
                      if (widget.isApproverView && visit.intimations.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 6,
                          children: visit.intimations.map((MedicalIntimation intim) {
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: intim.acknowledged
                                    ? AppColors.accentGreen.withValues(alpha: 0.1)
                                    : AppColors.accentAmber.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '${intim.acknowledged ? '✓' : '⏳'} ${intim.role}',
                                style: TextStyle(
                                    fontSize: 9,
                                    color: intim.acknowledged
                                        ? AppColors.accentGreen
                                        : AppColors.accentAmber,
                                    fontWeight: FontWeight.w600),
                              ),
                            );
                          }).toList(),
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

  void _showRecordDetail(MedicalVisit visit) {
    final user = widget.service.currentUser!;

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.bgCard,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.65,
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
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.glassBorder,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Header with fitness badge
              Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: _fitnessColor(visit.fitnessStatus).withValues(alpha: 0.12),
                    child: Icon(Icons.medical_services_rounded,
                        color: _fitnessColor(visit.fitnessStatus), size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.isApproverView ? visit.studentName : 'Medical Record',
                            style: Theme.of(context).textTheme.headlineMedium),
                        Text('By ${visit.createdByOfficerName}',
                            style: Theme.of(context).textTheme.bodySmall),
                      ],
                    ),
                  ),
                  StatusBadge(
                      label: visit.fitnessStatus.label,
                      color: _fitnessColor(visit.fitnessStatus)),
                ],
              ),
              const SizedBox(height: 20),

              // Full details
              _detailRow('Symptoms', visit.symptoms),
              if (visit.diagnosis != null) _detailRow('Diagnosis', visit.diagnosis!),
              if (visit.prescription != null) _detailRow('Prescription', visit.prescription!),
              if (visit.restDays != null) _detailRow('Rest Days', '${visit.restDays} days'),
              _detailRow('Movement', visit.movementRestricted ? '🔴 Restricted' : '🟢 Allowed'),
              _detailRow('Status', visit.status.label),
              _detailRow('Date', DateFormat('dd MMM yyyy, HH:mm').format(visit.createdAt)),
              if (visit.medicalOfficerNote != null)
                _detailRow('Officer Note', visit.medicalOfficerNote!),
              if (visit.clearedAt != null)
                _detailRow('Cleared On', DateFormat('dd MMM yyyy').format(visit.clearedAt!)),

              // Intimation status
              if (visit.intimations.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text('Notification Status',
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                ...visit.intimations.map((MedicalIntimation intim) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        children: [
                          Icon(
                            intim.acknowledged
                                ? Icons.check_circle_rounded
                                : Icons.schedule_rounded,
                            size: 16,
                            color: intim.acknowledged
                                ? AppColors.accentGreen
                                : AppColors.accentAmber,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '${intim.role} — ${intim.personName}',
                              style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary),
                            ),
                          ),
                          Text(
                            intim.acknowledged ? 'Acknowledged' : 'Pending',
                            style: TextStyle(
                              fontSize: 10,
                              color: intim.acknowledged
                                  ? AppColors.accentGreen
                                  : AppColors.accentAmber,
                            ),
                          ),
                        ],
                      ),
                    )),
              ],

              const SizedBox(height: 16),

              // Student: Request review (ONLY action students can do)
              if (!widget.isApproverView &&
                  visit.status != MedicalStatus.cleared) ...[
                if (visit.reviewRequested)
                  GlassCard(
                    borderColor: AppColors.accentAmber.withValues(alpha: 0.3),
                    backgroundColor: AppColors.accentAmber.withValues(alpha: 0.05),
                    child: Row(
                      children: [
                        Icon(Icons.schedule_rounded,
                            color: AppColors.accentAmber, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Review already requested on ${DateFormat('dd MMM, HH:mm').format(visit.reviewRequestedAt!)}',
                            style: TextStyle(fontSize: 12, color: AppColors.accentAmber),
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  SizedBox(
                    width: double.infinity,
                    child: GlassButton(
                      label: 'Request Review',
                      icon: Icons.rate_review_rounded,
                      gradient: LinearGradient(
                          colors: [AppColors.accentCyan, const Color(0xFF0284C7)]),
                      onPressed: () {
                        Navigator.pop(ctx);
                        _showReviewRequestDialog(visit);
                      },
                    ),
                  ),
              ],

              // Approver: Acknowledge intimation
              if (widget.isApproverView) ...[
                // Find if this approver has an unacknowledged intimation
                ...(() {
                  final roleLabel = user.role.label;
                  final intimation = visit.intimations
                      .where((i) => i.role == roleLabel && !i.acknowledged)
                      .toList();
                  if (intimation.isNotEmpty) {
                    return [
                      SizedBox(
                        width: double.infinity,
                        child: GlassButton(
                          label: 'Acknowledge Receipt',
                          icon: Icons.check_circle_rounded,
                          gradient: LinearGradient(
                              colors: [AppColors.accentGreen, const Color(0xFF047857)]),
                          onPressed: () async {
                            await widget.service.acknowledgeMedicalIntimation(
                              visitId: visit.id,
                              role: roleLabel,
                            );
                            if (mounted) Navigator.pop(ctx);
                            setState(() {});
                          },
                        ),
                      ),
                    ];
                  }
                  return <Widget>[];
                })(),
              ],
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  void _showReviewRequestDialog(MedicalVisit visit) {
    final noteCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.bgCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Request Medical Review',
            style: TextStyle(color: AppColors.textPrimary)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'This will notify the Medical Officer to re-evaluate your fitness status.',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: noteCtrl,
              maxLines: 3,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: const InputDecoration(
                  hintText: 'Reason for review (e.g. feeling better)...'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textMuted)),
          ),
          ElevatedButton(
            onPressed: () async {
              await widget.service.requestMedicalReview(
                visitId: visit.id,
                note: noteCtrl.text.trim().isEmpty
                    ? 'Student has requested a review'
                    : noteCtrl.text.trim(),
              );
              if (mounted) Navigator.pop(ctx);
              setState(() {});
            },
            child: const Text('Submit Request'),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(label,
                style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textMuted,
                    fontWeight: FontWeight.w600)),
          ),
          Expanded(
            child: Text(value,
                style: const TextStyle(
                    fontSize: 13, color: AppColors.textPrimary)),
          ),
        ],
      ),
    );
  }
}
