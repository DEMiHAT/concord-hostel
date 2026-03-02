
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../core/theme/app_theme.dart';
import '../../models/enums.dart';
import '../../models/qr_pass.dart';
import '../../services/mock_service.dart';
import '../../widgets/glass_widgets.dart';

class QrPassScreen extends StatelessWidget {
  final MockService service;
  final QrPass pass;

  const QrPassScreen({super.key, required this.service, required this.pass});

  Color _getStateColor(QrState state) {
    switch (state) {
      case QrState.unused:
        return AppColors.accentGreen;
      case QrState.hostelExited:
        return AppColors.accentAmber;
      case QrState.campusExited:
        return AppColors.accentPink;
      case QrState.campusEntered:
        return AppColors.accentCyan;
      case QrState.hostelEntered:
        return AppColors.primaryStart;
      case QrState.expired:
        return AppColors.textMuted;
    }
  }

  @override
  Widget build(BuildContext context) {
    final stateColor = _getStateColor(pass.state);
    final dateFormat = DateFormat('dd MMM yyyy, hh:mm a');

    return GlassScaffold(
      appBar: AppBar(
        title: const Text('Gate Pass'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          children: [
            const SizedBox(height: 16),

            // QR Code Card
            GlassCard(
              borderColor: stateColor.withValues(alpha: 0.4),
              child: Column(
                children: [
                  // Student info
                  Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          gradient: AppColors.primaryGradient,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Center(
                          child: Text(
                            pass.studentName[0],
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(pass.studentName,
                                style: Theme.of(context).textTheme.titleMedium),
                            Text(pass.studentRollNumber,
                                style: Theme.of(context).textTheme.bodySmall),
                          ],
                        ),
                      ),
                      StatusBadge(label: pass.state.label, color: stateColor),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // QR Code
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: stateColor.withValues(alpha: 0.15),
                          blurRadius: 30,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: QrImageView(
                      data: 'CONCORD:${pass.id}:${pass.studentId}:${pass.state.firestoreValue}',
                      version: QrVersions.auto,
                      size: 200,
                      eyeStyle: QrEyeStyle(
                        eyeShape: QrEyeShape.square,
                        color: stateColor,
                      ),
                      dataModuleStyle: QrDataModuleStyle(
                        dataModuleShape: QrDataModuleShape.square,
                        color: AppColors.bgDark,
                      ),
                    ),
                  )
                      .animate(onPlay: (c) => c.repeat(reverse: true))
                      .shimmer(
                        delay: 2000.ms,
                        duration: 1500.ms,
                        color: stateColor.withValues(alpha: 0.1),
                      ),
                  const SizedBox(height: 16),

                  // Pass ID
                  Text(
                    pass.id.toUpperCase(),
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textMuted,
                      letterSpacing: 2,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 500.ms).scale(begin: const Offset(0.95, 0.95)),

            // Validity
            GlassCard(
              child: Column(
                children: [
                  Row(
                    children: [
                      const Icon(Icons.schedule_rounded,
                          color: AppColors.primaryStart, size: 20),
                      const SizedBox(width: 10),
                      Text('Validity',
                          style: Theme.of(context).textTheme.titleMedium),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('From',
                                style: Theme.of(context).textTheme.bodySmall),
                            Text(dateFormat.format(pass.validFrom),
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontSize: 13)),
                          ],
                        ),
                      ),
                      Icon(Icons.arrow_forward_rounded,
                          color: AppColors.textMuted, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text('Until',
                                style: Theme.of(context).textTheme.bodySmall),
                            Text(dateFormat.format(pass.validUntil),
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontSize: 13)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // State Machine Visualization
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.route_rounded,
                          color: AppColors.primaryStart, size: 20),
                      const SizedBox(width: 10),
                      Text('Journey Progress',
                          style: Theme.of(context).textTheme.titleMedium),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildJourneySteps(context),
                ],
              ),
            ),

            // Gate Logs
            if (pass.gateLogs.isNotEmpty) ...[
              GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.receipt_long_rounded,
                            color: AppColors.primaryStart, size: 20),
                        const SizedBox(width: 10),
                        Text('Gate Logs',
                            style: Theme.of(context).textTheme.titleMedium),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ...pass.gateLogs.map((log) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Row(
                            children: [
                              Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: log.action == 'exit'
                                      ? AppColors.accentAmber.withValues(alpha: 0.15)
                                      : AppColors.accentGreen.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(
                                  log.action == 'exit'
                                      ? Icons.logout_rounded
                                      : Icons.login_rounded,
                                  color: log.action == 'exit'
                                      ? AppColors.accentAmber
                                      : AppColors.accentGreen,
                                  size: 16,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${log.gateType.toUpperCase()} Gate ${log.action.toUpperCase()}',
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium
                                          ?.copyWith(fontSize: 13),
                                    ),
                                    Text(
                                      DateFormat('dd MMM, hh:mm a')
                                          .format(log.timestamp),
                                      style:
                                          Theme.of(context).textTheme.bodySmall,
                                    ),
                                  ],
                                ),
                              ),
                              if (log.laneType != null)
                                StatusBadge(
                                  label: log.laneType!,
                                  color: AppColors.accentCyan,
                                ),
                            ],
                          ),
                        )),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildJourneySteps(BuildContext context) {
    final steps = [
      {'label': 'Pass Ready', 'state': QrState.unused, 'icon': Icons.qr_code_2_rounded},
      {'label': 'Hostel Exit', 'state': QrState.hostelExited, 'icon': Icons.door_front_door_rounded},
      {'label': 'Campus Exit', 'state': QrState.campusExited, 'icon': Icons.exit_to_app_rounded},
      {'label': 'Campus Entry', 'state': QrState.campusEntered, 'icon': Icons.login_rounded},
      {'label': 'Hostel Entry', 'state': QrState.hostelEntered, 'icon': Icons.home_rounded},
    ];

    final currentIndex = steps.indexWhere((s) => s['state'] == pass.state);

    return Row(
      children: List.generate(steps.length * 2 - 1, (index) {
        if (index.isOdd) {
          final stepIdx = index ~/ 2;
          final isCompleted = stepIdx < currentIndex;
          return Expanded(
            child: Container(
              height: 2,
              color: isCompleted
                  ? AppColors.accentGreen
                  : AppColors.glassWhite,
            ),
          );
        }

        final stepIdx = index ~/ 2;
        final step = steps[stepIdx];
        final isCompleted = stepIdx < currentIndex;
        final isCurrent = stepIdx == currentIndex;

        Color color;
        if (isCompleted) {
          color = AppColors.accentGreen;
        } else if (isCurrent) {
          color = _getStateColor(pass.state);
        } else {
          color = AppColors.textMuted;
        }

        return Column(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: color.withValues(alpha: isCurrent ? 0.2 : 0.1),
                shape: BoxShape.circle,
                border: Border.all(color: color, width: isCurrent ? 2 : 1),
              ),
              child: Icon(
                isCompleted
                    ? Icons.check_rounded
                    : step['icon'] as IconData,
                color: color,
                size: 14,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              step['label'] as String,
              style: TextStyle(
                fontSize: 9,
                color: color,
                fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w400,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        );
      }),
    );
  }
}
