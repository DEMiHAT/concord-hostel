import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../models/enums.dart';
import '../../models/leave_request.dart';
import '../../services/app_service.dart';
import '../../widgets/glass_widgets.dart';

class CreateLeaveScreen extends StatefulWidget {
  final AppService service;
  const CreateLeaveScreen({super.key, required this.service});

  @override
  State<CreateLeaveScreen> createState() => _CreateLeaveScreenState();
}

class _CreateLeaveScreenState extends State<CreateLeaveScreen> {
  LeaveType _selectedType = LeaveType.dayPass;
  final _reasonController = TextEditingController();
  DateTime _fromDate = DateTime.now().add(const Duration(hours: 2));
  DateTime _toDate = DateTime.now().add(const Duration(hours: 10));
  bool _isSubmitting = false;

  final _leaveTypeInfo = {
    LeaveType.dayPass: {
      'icon': Icons.wb_sunny_rounded,
      'color': AppColors.accentAmber,
      'desc': 'Leave for a few hours within the same day',
    },
    LeaveType.overnight: {
      'icon': Icons.nights_stay_rounded,
      'color': AppColors.primaryStart,
      'desc': 'Overnight stay outside campus',
    },
    LeaveType.weekend: {
      'icon': Icons.calendar_today_rounded,
      'color': AppColors.accentCyan,
      'desc': 'Weekend leave to visit home',
    },
    LeaveType.emergency: {
      'icon': Icons.warning_amber_rounded,
      'color': AppColors.accentRed,
      'desc': 'Urgent/emergency situations',
    },
    LeaveType.academic: {
      'icon': Icons.menu_book_rounded,
      'color': AppColors.accentGreen,
      'desc': 'Academic events, conferences, etc.',
    },
    LeaveType.extended: {
      'icon': Icons.flight_takeoff_rounded,
      'color': AppColors.accentPink,
      'desc': 'Extended leave (more than 3 days)',
    },
    LeaveType.workingDayHoliday: {
      'icon': Icons.beach_access_rounded,
      'color': const Color(0xFF8B5CF6),
      'desc': 'Leave on a working day',
    },
  };

  Future<void> _submit() async {
    if (_reasonController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please provide a reason for your leave')),
      );
      return;
    }

    final user = widget.service.currentUser!;

    // ─── Overlap check ────────────────────────────────
    final overlapping = widget.service.getOverlappingPasses(
      user.uid,
      _fromDate,
      _toDate,
    );

    if (overlapping.isNotEmpty && mounted) {
      final proceed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: AppColors.bgCard,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: AppColors.accentAmber, size: 24),
              const SizedBox(width: 10),
              const Text('Overlapping Pass',
                  style: TextStyle(color: AppColors.textPrimary, fontSize: 16)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'You already have ${overlapping.length} active pass(es) during this time:',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
              const SizedBox(height: 12),
              ...overlapping.map((p) => Container(
                    margin: const EdgeInsets.only(bottom: 6),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.accentAmber.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: AppColors.accentAmber.withValues(alpha: 0.2),
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
                'Do you still want to submit this request?',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
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
              child: const Text('Submit Anyway'),
            ),
          ],
        ),
      );
      if (proceed != true) return;
    }
    // ─────────────────────────────────────────────────────

    setState(() => _isSubmitting = true);
    final request = LeaveRequest(
      id: 'lr_${DateTime.now().millisecondsSinceEpoch}',
      studentId: user.uid,
      studentName: user.name,
      studentRollNumber: user.rollNumber ?? '',
      hostelBlock: user.hostelBlock ?? '',
      roomNumber: user.roomNumber ?? '',
      leaveType: _selectedType,
      status: LeaveStatus.pending,
      reason: _reasonController.text.trim(),
      fromDate: _fromDate,
      toDate: _toDate,
    );

    await widget.service.createLeaveRequest(request);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${_selectedType.label} request submitted!'),
          backgroundColor: AppColors.accentGreen,
        ),
      );
      Navigator.pop(context);
    }
  }

  /// Shared dark theme for all picker dialogs — ensures nothing is white-on-white.
  ThemeData get _pickerTheme {
    const accent = Color(0xFF6366F1);
    const bg = Color(0xFF1E1E2E);
    const surfaceAlt = Color(0xFF2A2A3E);

    return ThemeData.dark().copyWith(
      colorScheme: const ColorScheme.dark(
        primary: accent,
        onPrimary: Colors.white,
        secondary: accent,
        onSecondary: Colors.white,
        tertiary: accent,
        onTertiary: Colors.white,
        surface: bg,
        onSurface: Colors.white,
        surfaceContainerHighest: surfaceAlt,
        outline: Color(0xFF444466),
      ),
      dialogBackgroundColor: bg,
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: accent),
      ),
      // ─── Date Picker ────────────────────────────────
      datePickerTheme: DatePickerThemeData(
        backgroundColor: bg,
        surfaceTintColor: Colors.transparent,
        headerBackgroundColor: accent,
        headerForegroundColor: Colors.white,
        dayForegroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return Colors.white;
          if (states.contains(WidgetState.disabled)) {
            return Colors.white38;
          }
          return Colors.white.withValues(alpha: 0.87);
        }),
        dayBackgroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return accent;
          return Colors.transparent;
        }),
        todayForegroundColor: WidgetStateProperty.all(accent),
        todayBorder: const BorderSide(color: accent),
        yearForegroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return Colors.white;
          return Colors.white70;
        }),
        yearBackgroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return accent;
          return Colors.transparent;
        }),
        weekdayStyle: const TextStyle(color: Colors.white60, fontSize: 12),
        dayOverlayColor:
            WidgetStateProperty.all(accent.withValues(alpha: 0.12)),
      ),
      // ─── Time Picker (clock dial) ───────────────────
      timePickerTheme: TimePickerThemeData(
        backgroundColor: bg,
        dialBackgroundColor: surfaceAlt,
        dialHandColor: accent,
        dialTextColor: WidgetStateColor.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return Colors.white;
          return Colors.white.withValues(alpha: 0.87);
        }),
        hourMinuteColor: WidgetStateColor.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return accent.withValues(alpha: 0.25);
          }
          return surfaceAlt;
        }),
        hourMinuteTextColor: WidgetStateColor.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return accent;
          return Colors.white;
        }),
        dayPeriodColor: WidgetStateColor.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return accent.withValues(alpha: 0.25);
          }
          return surfaceAlt;
        }),
        dayPeriodTextColor: WidgetStateColor.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return accent;
          return Colors.white70;
        }),
        dayPeriodBorderSide: const BorderSide(color: Color(0xFF444466)),
        entryModeIconColor: Colors.white70,
        helpTextStyle:
            const TextStyle(color: Colors.white60, fontSize: 12),
        hourMinuteTextStyle: const TextStyle(
          fontSize: 44,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Future<void> _pickDate(bool isFrom) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isFrom ? _fromDate : _toDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
      builder: (context, child) => Theme(data: _pickerTheme, child: child!),
    );
    if (picked != null) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(isFrom ? _fromDate : _toDate),
        builder: (context, child) => Theme(data: _pickerTheme, child: child!),
      );
      if (time != null) {
        setState(() {
          final dt = DateTime(picked.year, picked.month, picked.day, time.hour, time.minute);
          if (isFrom) {
            _fromDate = dt;
            if (_toDate.isBefore(_fromDate)) {
              _toDate = _fromDate.add(const Duration(hours: 8));
            }
          } else {
            _toDate = dt;
          }
        });
      }
    }
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GlassScaffold(
      appBar: AppBar(
        title: const Text('New Leave Request'),
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

            // Leave Type Selection
            Text(
              'Leave Type',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 110,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                itemCount: LeaveType.values.length,
                itemBuilder: (context, index) {
                  final type = LeaveType.values[index];
                  final info = _leaveTypeInfo[type]!;
                  final isSelected = type == _selectedType;
                  final color = info['color'] as Color;

                  return GestureDetector(
                    onTap: () => setState(() => _selectedType = type),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 100,
                      margin: const EdgeInsets.only(right: 10),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? color.withValues(alpha: 0.15)
                            : AppColors.glassWhite,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected
                              ? color.withValues(alpha: 0.5)
                              : AppColors.glassBorder,
                          width: isSelected ? 1.5 : 0.5,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            info['icon'] as IconData,
                            color: isSelected ? color : AppColors.textMuted,
                            size: 28,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            type.label,
                            style: TextStyle(
                              fontSize: 11,
                              color: isSelected ? color : AppColors.textSecondary,
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ).animate().fadeIn(
                        delay: Duration(milliseconds: index * 60),
                        duration: 300.ms,
                      );
                },
              ),
            ),
            const SizedBox(height: 8),

            // Selected type description
            GlassCard(
              padding: const EdgeInsets.all(14),
              borderColor: (_leaveTypeInfo[_selectedType]!['color'] as Color)
                  .withValues(alpha: 0.3),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    color: _leaveTypeInfo[_selectedType]!['color'] as Color,
                    size: 18,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _leaveTypeInfo[_selectedType]!['desc'] as String,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    ),
                  ),
                ],
              ),
            ),

            // Approval Chain Preview
            GlassCard(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Approval Chain',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 10),
                  ApprovalChainWidget(
                    steps: _selectedType.approvalChain,
                    currentStep: 0,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Date Selection
            Text(
              'Duration',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _dateCard('From', _fromDate, () => _pickDate(true)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _dateCard('To', _toDate, () => _pickDate(false)),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Reason
            Text(
              'Reason',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _reasonController,
              maxLines: 4,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: const InputDecoration(
                hintText: 'Provide a detailed reason for your leave...',
              ),
            ),
            const SizedBox(height: 28),

            // Submit
            SizedBox(
              width: double.infinity,
              child: GlassButton(
                label: 'Submit Request',
                icon: Icons.send_rounded,
                isLoading: _isSubmitting,
                onPressed: _isSubmitting ? null : _submit,
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _dateCard(String label, DateTime date, VoidCallback onTap) {
    return GlassCard(
      onTap: onTap,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 6),
          Text(
            '${date.day}/${date.month}/${date.year}',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          Text(
            '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}',
            style: TextStyle(
              color: AppColors.primaryStart,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}
