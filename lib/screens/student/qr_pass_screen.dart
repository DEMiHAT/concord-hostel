import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../core/theme/app_theme.dart';
import '../../models/enums.dart';
import '../../models/qr_pass.dart';
import '../../services/app_service.dart';
import '../../services/qr_generation_service.dart';
import '../../widgets/glass_widgets.dart';

class QrPassScreen extends StatefulWidget {
  final AppService service;
  final QrPass pass;

  const QrPassScreen({super.key, required this.service, required this.pass});

  @override
  State<QrPassScreen> createState() => _QrPassScreenState();
}

class _QrPassScreenState extends State<QrPassScreen> {
  late String _qrData;
  late String _verificationCode;
  int _secondsRemaining = 0;
  Timer? _refreshTimer;
  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();
    _generateQrData();
    _startAutoRefresh();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _countdownTimer?.cancel();
    super.dispose();
  }

  void _generateQrData() {
    _qrData = QrGenerationService.generateQrData(
      passId: widget.pass.id,
      studentId: widget.pass.studentId,
      stateValue: widget.pass.state.firestoreValue,
    );
    _verificationCode = QrGenerationService.generateVerificationCode(
      widget.pass.id,
      widget.pass.studentId,
    );
    _secondsRemaining = QrGenerationService.secondsUntilTokenExpiry();
  }

  void _startAutoRefresh() {
    // Refresh QR data every 30 seconds (token rotation)
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) {
        setState(() => _generateQrData());
      }
    });

    // Countdown timer updates every second
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {
          _secondsRemaining = QrGenerationService.secondsUntilTokenExpiry();
        });
      }
    });
  }

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

  String _getStateInstruction(QrState state) {
    switch (state) {
      case QrState.unused:
        return 'Show this to security at the hostel gate to exit';
      case QrState.hostelExited:
        return 'Proceed to main gate and show this QR to exit campus';
      case QrState.campusExited:
        return 'You are outside campus. Show QR at main gate when returning';
      case QrState.campusEntered:
        return 'Head back to hostel and scan at hostel gate to complete';
      case QrState.hostelEntered:
        return 'Journey complete! This pass has been fully used';
      case QrState.expired:
        return 'This pass has expired and can no longer be used';
    }
  }

  @override
  Widget build(BuildContext context) {
    final pass = widget.pass;
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

            // ── QR Code Card ──────────────────────────────────
            GlassCard(
              borderColor: stateColor.withValues(alpha: 0.4),
              child: Column(
                children: [
                  // Student info header
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

                  // QR Code with rotating token
                  Stack(
                    alignment: Alignment.center,
                    children: [
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
                          data: _qrData,
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
                      ),
                      // Expired overlay
                      if (!pass.isActive)
                        Container(
                          width: 240,
                          height: 240,
                          decoration: BoxDecoration(
                            color: AppColors.bgDark.withValues(alpha: 0.85),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                pass.state == QrState.hostelEntered
                                    ? Icons.check_circle_rounded
                                    : Icons.block_rounded,
                                color: pass.state == QrState.hostelEntered
                                    ? AppColors.accentGreen
                                    : AppColors.accentRed,
                                size: 48,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                pass.state == QrState.hostelEntered
                                    ? 'COMPLETED'
                                    : 'EXPIRED',
                                style: TextStyle(
                                  color: pass.state == QrState.hostelEntered
                                      ? AppColors.accentGreen
                                      : AppColors.accentRed,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 2,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  )
                      .animate(onPlay: (c) => c.repeat(reverse: true))
                      .shimmer(
                        delay: 2000.ms,
                        duration: 1500.ms,
                        color: stateColor.withValues(alpha: 0.1),
                      ),
                  const SizedBox(height: 16),

                  // Token refresh indicator
                  if (pass.isActive) ...[
                    _buildTokenTimer(stateColor),
                    const SizedBox(height: 12),
                  ],

                  // Verification Code
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: stateColor.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: stateColor.withValues(alpha: 0.15),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.verified_rounded,
                            color: stateColor, size: 16),
                        const SizedBox(width: 8),
                        Text(
                          'Verification Code: ',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          _verificationCode,
                          style: TextStyle(
                            fontSize: 16,
                            color: stateColor,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 3,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

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
            ).animate().fadeIn(duration: 500.ms).scale(
                  begin: const Offset(0.95, 0.95),
                ),

            // ── Instruction Banner ────────────────────────────
            GlassCard(
              borderColor: stateColor.withValues(alpha: 0.3),
              backgroundColor: stateColor.withValues(alpha: 0.04),
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: stateColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.info_outline_rounded,
                        color: stateColor, size: 18),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _getStateInstruction(pass.state),
                      style: TextStyle(
                        fontSize: 13,
                        color: stateColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(delay: 150.ms, duration: 400.ms),

            // ── Validity ──────────────────────────────────────
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
                      const Spacer(),
                      if (pass.isExpired)
                        StatusBadge(
                          label: 'Expired',
                          color: AppColors.accentRed,
                        )
                      else
                        StatusBadge(
                          label: 'Valid',
                          color: AppColors.accentGreen,
                        ),
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
                                style:
                                    Theme.of(context).textTheme.bodySmall),
                            Text(dateFormat.format(pass.validFrom),
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(fontSize: 13)),
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
                                style:
                                    Theme.of(context).textTheme.bodySmall),
                            Text(dateFormat.format(pass.validUntil),
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(fontSize: 13)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // ── Journey Progress ──────────────────────────────
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

            // ── Gate Logs ─────────────────────────────────────
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
                            style:
                                Theme.of(context).textTheme.titleMedium),
                        const Spacer(),
                        StatusBadge(
                          label: '${pass.gateLogs.length} scans',
                          color: AppColors.accentCyan,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ...pass.gateLogs.asMap().entries.map((entry) {
                      final log = entry.value;
                      final isLast =
                          entry.key == pass.gateLogs.length - 1;
                      return _buildGateLogItem(
                          context, log, isLast, stateColor);
                    }),
                  ],
                ),
              ),
            ],

            // ── Anti-Fraud Notice ─────────────────────────────
            if (pass.isActive)
              GlassCard(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 12),
                borderColor: AppColors.textMuted.withValues(alpha: 0.15),
                child: Row(
                  children: [
                    Icon(Icons.security_rounded,
                        color: AppColors.textMuted, size: 16),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'This QR auto-refreshes every 30 seconds. Screenshots will not work at the gate.',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.textMuted,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn(delay: 400.ms, duration: 400.ms),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildTokenTimer(Color stateColor) {
    final progress = _secondsRemaining / 30;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(
            value: progress,
            strokeWidth: 2.5,
            backgroundColor: AppColors.glassBorder,
            valueColor: AlwaysStoppedAnimation<Color>(
              _secondsRemaining <= 5
                  ? AppColors.accentRed
                  : stateColor,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          'Refreshes in ${_secondsRemaining}s',
          style: TextStyle(
            fontSize: 11,
            color: _secondsRemaining <= 5
                ? AppColors.accentRed
                : AppColors.textMuted,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildGateLogItem(
      BuildContext context, GateLog log, bool isLast, Color passColor) {
    final isEntry = log.action == 'entry';
    final logColor =
        isEntry ? AppColors.accentGreen : AppColors.accentAmber;

    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 10),
      child: Row(
        children: [
          Column(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: logColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  isEntry ? Icons.login_rounded : Icons.logout_rounded,
                  color: logColor,
                  size: 16,
                ),
              ),
              if (!isLast)
                Container(
                  width: 2,
                  height: 16,
                  color: AppColors.glassBorder,
                ),
            ],
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
                  DateFormat('dd MMM, hh:mm a').format(log.timestamp),
                  style: Theme.of(context).textTheme.bodySmall,
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
    );
  }

  Widget _buildJourneySteps(BuildContext context) {
    final pass = widget.pass;
    final steps = [
      {
        'label': 'Pass Ready',
        'state': QrState.unused,
        'icon': Icons.qr_code_2_rounded
      },
      {
        'label': 'Hostel Exit',
        'state': QrState.hostelExited,
        'icon': Icons.door_front_door_rounded
      },
      {
        'label': 'Campus Exit',
        'state': QrState.campusExited,
        'icon': Icons.exit_to_app_rounded
      },
      {
        'label': 'Campus Entry',
        'state': QrState.campusEntered,
        'icon': Icons.login_rounded
      },
      {
        'label': 'Hostel Entry',
        'state': QrState.hostelEntered,
        'icon': Icons.home_rounded
      },
    ];

    final currentIndex =
        steps.indexWhere((s) => s['state'] == pass.state);

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
                color:
                    color.withValues(alpha: isCurrent ? 0.2 : 0.1),
                shape: BoxShape.circle,
                border: Border.all(
                    color: color, width: isCurrent ? 2 : 1),
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
                fontWeight:
                    isCurrent ? FontWeight.w700 : FontWeight.w400,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        );
      }),
    );
  }
}
