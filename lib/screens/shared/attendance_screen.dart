import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../models/attendance.dart';
import '../../services/app_service.dart';
import '../../widgets/glass_widgets.dart';

class AttendanceScreen extends StatefulWidget {
  final AppService service;
  final bool isWardenView;
  const AttendanceScreen({super.key, required this.service, this.isWardenView = false});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  bool _generating = false;

  Color _statusColor(AttendanceStatus status) {
    switch (status) {
      case AttendanceStatus.present:
        return AppColors.accentGreen;
      case AttendanceStatus.outValid:
        return AppColors.accentCyan;
      case AttendanceStatus.onLeave:
        return const Color(0xFF8B5CF6);
      case AttendanceStatus.nonResident:
        return AppColors.textMuted;
      case AttendanceStatus.unaccounted:
        return AppColors.accentRed;
      case AttendanceStatus.medicalRestricted:
        return AppColors.accentAmber;
    }
  }

  IconData _statusIcon(AttendanceStatus status) {
    switch (status) {
      case AttendanceStatus.present:
        return Icons.check_circle_rounded;
      case AttendanceStatus.outValid:
        return Icons.directions_walk_rounded;
      case AttendanceStatus.onLeave:
        return Icons.luggage_rounded;
      case AttendanceStatus.nonResident:
        return Icons.home_work_rounded;
      case AttendanceStatus.unaccounted:
        return Icons.warning_rounded;
      case AttendanceStatus.medicalRestricted:
        return Icons.local_hospital_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.service.currentUser!;
    final records = widget.isWardenView
        ? widget.service.getAttendanceForDate(DateTime.now())
        : widget.service.getStudentAttendance(user.uid);
    final exceptions = widget.isWardenView
        ? widget.service.getUnresolvedExceptions()
        : <AttendanceException>[];
    final summary = widget.service.getAttendanceSummary(DateTime.now());

    return GlassScaffold(
      appBar: AppBar(
        title: Text(widget.isWardenView ? 'Attendance Dashboard' : 'My Attendance'),
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

            // Summary cards
            if (widget.isWardenView) ...[
              Text('Today\'s Summary', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              GridView.count(
                crossAxisCount: 3,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                childAspectRatio: 1.1,
                children: AttendanceStatus.values.map((status) {
                  final count = summary[status] ?? 0;
                  return GlassCard(
                    margin: EdgeInsets.zero,
                    padding: const EdgeInsets.all(10),
                    borderColor: _statusColor(status).withValues(alpha: 0.3),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(_statusIcon(status), color: _statusColor(status), size: 22),
                        const SizedBox(height: 4),
                        Text('$count',
                            style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textPrimary)),
                        Text(status.label,
                            style: TextStyle(fontSize: 9, color: _statusColor(status)),
                            textAlign: TextAlign.center,
                            maxLines: 1),
                      ],
                    ),
                  );
                }).toList(),
              ).animate().fadeIn(duration: 400.ms),
              const SizedBox(height: 16),

              // Generate button
              SizedBox(
                width: double.infinity,
                child: GlassButton(
                  label: 'Generate Today\'s Attendance',
                  icon: Icons.auto_fix_high_rounded,
                  isLoading: _generating,
                  onPressed: _generating
                      ? null
                      : () async {
                          setState(() => _generating = true);
                          await widget.service.generateDailyAttendance();
                          setState(() => _generating = false);
                        },
                ),
              ).animate().fadeIn(delay: 200.ms),
              const SizedBox(height: 16),

              // Exceptions
              if (exceptions.isNotEmpty) ...[
                Text('⚠ Exceptions', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                ...exceptions.map((exc) => GlassCard(
                      borderColor: AppColors.accentRed.withValues(alpha: 0.3),
                      backgroundColor: AppColors.accentRed.withValues(alpha: 0.05),
                      child: Row(
                        children: [
                          Icon(Icons.error_outline_rounded, color: AppColors.accentRed, size: 20),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(exc.studentName,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textPrimary)),
                                Text(exc.type.label,
                                    style: TextStyle(
                                        fontSize: 12, color: AppColors.accentRed)),
                                Text(exc.description,
                                    style: Theme.of(context).textTheme.bodySmall),
                              ],
                            ),
                          ),
                        ],
                      ),
                    )),
                const SizedBox(height: 16),
              ],
            ],

            // Records list
            Text(widget.isWardenView ? 'All Records' : 'Attendance History',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),

            if (records.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(40),
                  child: Column(
                    children: [
                      Icon(Icons.event_available_rounded,
                          size: 48, color: AppColors.textMuted),
                      const SizedBox(height: 12),
                      Text('No attendance records yet',
                          style: TextStyle(color: AppColors.textMuted)),
                      const SizedBox(height: 8),
                      if (widget.isWardenView)
                        Text('Tap "Generate" to create today\'s records',
                            style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                    ],
                  ),
                ),
              )
            else
              ...records.map((AttendanceRecord rec) {
                final color = _statusColor(rec.status);
                return GlassCard(
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(_statusIcon(rec.status), color: color, size: 20),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.isWardenView ? rec.studentName : DateFormat('dd MMM yyyy').format(rec.date),
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary),
                            ),
                            Text(
                              widget.isWardenView
                                  ? '${rec.hostelBlock} • ${DateFormat('HH:mm').format(rec.generatedAt)}'
                                  : 'Source: ${rec.derivedFrom.replaceAll('_', ' ')}',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      StatusBadge(label: rec.status.label, color: color),
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
}
