import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
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

    setState(() => _isSubmitting = true);
    final user = widget.service.currentUser!;
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

  Future<void> _pickDate(bool isFrom) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isFrom ? _fromDate : _toDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.primaryStart,
              surface: AppColors.bgCard,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(isFrom ? _fromDate : _toDate),
        builder: (context, child) {
          return Theme(
            data: Theme.of(context).copyWith(
              colorScheme: const ColorScheme.dark(
                primary: AppColors.primaryStart,
                surface: AppColors.bgCard,
              ),
            ),
            child: child!,
          );
        },
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
