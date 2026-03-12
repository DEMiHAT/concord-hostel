import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../core/theme/app_theme.dart';
import '../models/enums.dart';
import '../services/app_service.dart';
import '../widgets/glass_widgets.dart';
import 'student/student_home.dart';
import 'approver/approver_home.dart';
import 'parent/parent_home.dart';
import 'security/security_home.dart';
import 'admin/admin_home.dart';
import 'medical_officer/medical_officer_home.dart';

class LoginScreen extends StatefulWidget {
  final AppService service;
  const LoginScreen({super.key, required this.service});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  bool _isLoading = false;
  String? _selectedRole;

  final _roles = [
    {'role': UserRole.student, 'icon': Icons.school_rounded, 'label': 'Student', 'color': AppColors.accentCyan},
    {'role': UserRole.rt, 'icon': Icons.supervisor_account_rounded, 'label': 'Resident Tutor', 'color': AppColors.accentGreen},
    {'role': UserRole.parent, 'icon': Icons.family_restroom_rounded, 'label': 'Parent', 'color': AppColors.accentAmber},
    {'role': UserRole.faculty, 'icon': Icons.person_4_rounded, 'label': 'Faculty Advisor', 'color': AppColors.accentPink},
    {'role': UserRole.hod, 'icon': Icons.workspace_premium_rounded, 'label': 'Head of Dept', 'color': AppColors.primaryStart},
    {'role': UserRole.warden, 'icon': Icons.shield_rounded, 'label': 'Warden', 'color': const Color(0xFF8B5CF6)},
    {'role': UserRole.security, 'icon': Icons.security_rounded, 'label': 'Security', 'color': AppColors.accentRed},
    {'role': UserRole.admin, 'icon': Icons.admin_panel_settings_rounded, 'label': 'Admin', 'color': const Color(0xFF14B8A6)},
    {'role': UserRole.medicalOfficer, 'icon': Icons.local_hospital_rounded, 'label': 'Medical Officer', 'color': const Color(0xFFE11D48)},
  ];

  Future<void> _login(UserRole role) async {
    setState(() {
      _isLoading = true;
      _selectedRole = role.label;
    });

    final user = await widget.service.loginWithRole(role);
    if (user != null && mounted) {
      Widget screen;
      switch (user.role) {
        case UserRole.student:
          screen = StudentHomeScreen(service: widget.service);
          break;
        case UserRole.security:
          screen = SecurityHomeScreen(service: widget.service);
          break;
        case UserRole.admin:
          screen = AdminHomeScreen(service: widget.service);
          break;
        case UserRole.medicalOfficer:
          screen = MedicalOfficerHomeScreen(service: widget.service);
          break;
        case UserRole.parent:
          screen = ParentHomeScreen(service: widget.service);
          break;
        default:
          screen = ApproverHomeScreen(service: widget.service);
          break;
      }

      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => screen,
          transitionsBuilder: (_, animation, __, child) {
            return FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.05),
                  end: Offset.zero,
                ).animate(CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeOut,
                )),
                child: child,
              ),
            );
          },
          transitionDuration: const Duration(milliseconds: 400),
        ),
      );
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GlassScaffold(
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          children: [
            const SizedBox(height: 60),
            // Logo & Title
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryStart.withValues(alpha: 0.3),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Icon(
                Icons.verified_user_rounded,
                color: Colors.white,
                size: 40,
              ),
            )
                .animate()
                .fadeIn(duration: 600.ms)
                .scale(begin: const Offset(0.5, 0.5)),
            const SizedBox(height: 20),
            Text(
              'H.A.I.L.M.A.R.Y.',
              style: Theme.of(context).textTheme.displayMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                    letterSpacing: 3,
                    foreground: Paint()
                      ..shader = const LinearGradient(
                        colors: [
                          AppColors.primaryStart,
                          AppColors.accentCyan,
                        ],
                      ).createShader(
                        const Rect.fromLTWH(0, 0, 300, 40),
                      ),
                  ),
            ).animate().fadeIn(delay: 200.ms, duration: 600.ms),
            const SizedBox(height: 8),
            Text(
              'Hostel Administrative Intelligence\n& Logistics Management for Access, Regulation and Systems',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.5,
                  ),
            ).animate().fadeIn(delay: 400.ms, duration: 600.ms),
            const SizedBox(height: 40),

            // Role Selection
            Text(
              'Select your role',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.textMuted,
                  ),
            ).animate().fadeIn(delay: 500.ms),
            const SizedBox(height: 16),

            // Role Grid
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.5,
              ),
              itemCount: _roles.length,
              itemBuilder: (context, index) {
                final role = _roles[index];
                final isSelected = _selectedRole == (role['label'] as String);
                final color = role['color'] as Color;

                return GlassCard(
                  margin: EdgeInsets.zero,
                  padding: const EdgeInsets.all(14),
                  borderColor: isSelected ? color : null,
                  backgroundColor: isSelected
                      ? color.withValues(alpha: 0.1)
                      : null,
                  onTap: _isLoading
                      ? null
                      : () => _login(role['role'] as UserRole),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: _isLoading && isSelected
                            ? Padding(
                                padding: const EdgeInsets.all(10),
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: color,
                                ),
                              )
                            : Icon(
                                role['icon'] as IconData,
                                color: color,
                                size: 22,
                              ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        role['label'] as String,
                        style: TextStyle(
                          color: isSelected ? color : AppColors.textPrimary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                )
                    .animate()
                    .fadeIn(
                      delay: Duration(milliseconds: 600 + (index * 80)),
                      duration: 400.ms,
                    )
                    .slideY(begin: 0.1);
              },
            ),
            const SizedBox(height: 32),
            Text(
              'Demo Mode — Select a role to explore',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textMuted,
              ),
            ).animate().fadeIn(delay: 1200.ms),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
