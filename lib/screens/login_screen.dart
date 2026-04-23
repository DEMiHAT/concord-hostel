import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../core/theme/app_theme.dart';
import '../models/enums.dart';
import '../services/app_service.dart';
import '../services/mock_service.dart';
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
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();

  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;

  // Demo role login
  bool _showDemoPanel = false;
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

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  // ═══════════════════════════════════════════════════
  // EMAIL / PASSWORD LOGIN
  // ═══════════════════════════════════════════════════

  Future<void> _loginWithEmail() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      setState(() => _errorMessage = 'Please enter both email and password');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final user = await widget.service.loginWithEmail(email, password);
      if (user != null && mounted) {
        _navigateToHome(user.role);
      } else if (mounted) {
        setState(() {
          _errorMessage = 'Invalid email or password';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        String message = 'Login failed. Please try again.';
        final errorStr = e.toString().toLowerCase();
        if (errorStr.contains('user-not-found') || errorStr.contains('wrong-password') || errorStr.contains('invalid-credential')) {
          message = 'Invalid email or password';
        } else if (errorStr.contains('too-many-requests')) {
          message = 'Too many attempts. Please try again later.';
        } else if (errorStr.contains('network')) {
          message = 'Network error. Check your connection.';
        }
        setState(() {
          _errorMessage = message;
          _isLoading = false;
        });
      }
    }
  }

  // Shared demo service instance — persists data across role switches
  static MockService? _sharedDemoService;

  // ═══════════════════════════════════════════════════
  // DEMO ROLE LOGIN
  // ═══════════════════════════════════════════════════

  Future<void> _loginWithRole(UserRole role) async {
    setState(() {
      _isLoading = true;
      _selectedRole = role.label;
      _errorMessage = null;
    });

    try {
      // Reuse the same MockService so data persists across role switches
      _sharedDemoService ??= MockService();
      final demoService = _sharedDemoService!;
      final user = await demoService.loginWithRole(role);
      if (user != null && mounted) {
        _navigateToHomeWithService(user.role, demoService);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Demo login failed';
          _isLoading = false;
        });
      }
    }
  }

  // ═══════════════════════════════════════════════════
  // NAVIGATION
  // ═══════════════════════════════════════════════════

  void _navigateToHome(UserRole role) {
    _navigateToHomeWithService(role, widget.service);
  }

  void _navigateToHomeWithService(UserRole role, AppService service) {
    Widget screen;
    switch (role) {
      case UserRole.student:
        screen = StudentHomeScreen(service: service);
        break;
      case UserRole.security:
        screen = SecurityHomeScreen(service: service);
        break;
      case UserRole.admin:
        screen = AdminHomeScreen(service: service);
        break;
      case UserRole.medicalOfficer:
        screen = MedicalOfficerHomeScreen(service: service);
        break;
      case UserRole.parent:
        screen = ParentHomeScreen(service: service);
        break;
      default:
        screen = ApproverHomeScreen(service: service);
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

  // ═══════════════════════════════════════════════════
  // BUILD
  // ═══════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    return GlassScaffold(
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          children: [
            const SizedBox(height: 60),
            _buildLogo(),
            const SizedBox(height: 40),
            if (_showDemoPanel) _buildDemoPanel() else _buildLoginForm(),
            const SizedBox(height: 24),
            _buildBottomToggle(),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // ─── Logo & Branding ───

  Widget _buildLogo() {
    return Column(
      children: [
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
                    colors: [AppColors.primaryStart, AppColors.accentCyan],
                  ).createShader(const Rect.fromLTWH(0, 0, 300, 40)),
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
      ],
    );
  }

  // ─── Email/Password Login Form ───

  Widget _buildLoginForm() {
    return Column(
      children: [
        Text(
          'Sign in to continue',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppColors.textMuted,
              ),
        ).animate().fadeIn(delay: 500.ms),
        const SizedBox(height: 24),

        // Email field
        GlassCard(
          margin: EdgeInsets.zero,
          padding: EdgeInsets.zero,
          child: TextField(
            controller: _emailController,
            focusNode: _emailFocus,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            enabled: !_isLoading,
            onSubmitted: (_) => _passwordFocus.requestFocus(),
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
            decoration: InputDecoration(
              hintText: 'Email address',
              hintStyle: TextStyle(
                color: AppColors.textMuted.withValues(alpha: 0.6),
                fontSize: 15,
                fontWeight: FontWeight.w400,
              ),
              prefixIcon: Icon(
                Icons.email_outlined,
                color: AppColors.textMuted.withValues(alpha: 0.6),
                size: 20,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            ),
          ),
        ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.1),
        const SizedBox(height: 12),

        // Password field
        GlassCard(
          margin: EdgeInsets.zero,
          padding: EdgeInsets.zero,
          child: TextField(
            controller: _passwordController,
            focusNode: _passwordFocus,
            obscureText: _obscurePassword,
            textInputAction: TextInputAction.done,
            enabled: !_isLoading,
            onSubmitted: (_) => _loginWithEmail(),
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
            decoration: InputDecoration(
              hintText: 'Password',
              hintStyle: TextStyle(
                color: AppColors.textMuted.withValues(alpha: 0.6),
                fontSize: 15,
                fontWeight: FontWeight.w400,
              ),
              prefixIcon: Icon(
                Icons.lock_outline_rounded,
                color: AppColors.textMuted.withValues(alpha: 0.6),
                size: 20,
              ),
              suffixIcon: GestureDetector(
                onTap: () => setState(() => _obscurePassword = !_obscurePassword),
                child: Icon(
                  _obscurePassword
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: AppColors.textMuted.withValues(alpha: 0.6),
                  size: 20,
                ),
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            ),
          ),
        ).animate().fadeIn(delay: 700.ms).slideY(begin: 0.1),
        const SizedBox(height: 8),

        // Error message
        if (_errorMessage != null)
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(top: 8),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.accentRed.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.accentRed.withValues(alpha: 0.2),
                width: 0.5,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.error_outline_rounded,
                  color: AppColors.accentRed,
                  size: 18,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _errorMessage!,
                    style: TextStyle(
                      color: AppColors.accentRed,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(duration: 300.ms).shake(hz: 2, offset: const Offset(2, 0)),

        const SizedBox(height: 24),

        // Login button
        SizedBox(
          width: double.infinity,
          child: GlassButton(
            label: _isLoading ? 'Signing in...' : 'Sign In',
            icon: _isLoading ? null : Icons.login_rounded,
            isLoading: _isLoading,
            onPressed: _isLoading ? null : _loginWithEmail,
          ),
        ).animate().fadeIn(delay: 800.ms).slideY(begin: 0.1),
      ],
    );
  }

  // ─── Demo Role Selector Panel ───

  Widget _buildDemoPanel() {
    return Column(
      children: [
        Text(
          'Select a role to explore',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppColors.textMuted,
              ),
        ).animate().fadeIn(delay: 100.ms),
        const SizedBox(height: 16),

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
                  : () => _loginWithRole(role['role'] as UserRole),
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
                  delay: Duration(milliseconds: 100 + (index * 60)),
                  duration: 400.ms,
                )
                .slideY(begin: 0.1);
          },
        ),
      ],
    );
  }

  // ─── Bottom Toggle between Login / Demo ───

  Widget _buildBottomToggle() {
    return Column(
      children: [
        // Divider with "or"
        Row(
          children: [
            Expanded(
              child: Container(
                height: 0.5,
                color: AppColors.glassBorder,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'or',
                style: TextStyle(
                  color: AppColors.textMuted.withValues(alpha: 0.5),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Expanded(
              child: Container(
                height: 0.5,
                color: AppColors.glassBorder,
              ),
            ),
          ],
        ).animate().fadeIn(delay: 900.ms),
        const SizedBox(height: 16),

        // Toggle button
        GestureDetector(
          onTap: _isLoading
              ? null
              : () {
                  setState(() {
                    _showDemoPanel = !_showDemoPanel;
                    _errorMessage = null;
                    _selectedRole = null;
                  });
                },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.glassBorder,
                width: 0.5,
              ),
              color: AppColors.glassWhite,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _showDemoPanel
                      ? Icons.email_outlined
                      : Icons.explore_rounded,
                  color: AppColors.accentCyan,
                  size: 18,
                ),
                const SizedBox(width: 10),
                Text(
                  _showDemoPanel
                      ? 'Sign in with email instead'
                      : 'Try Demo Mode',
                  style: const TextStyle(
                    color: AppColors.accentCyan,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ).animate().fadeIn(delay: 1000.ms),

        if (_showDemoPanel) ...[
          const SizedBox(height: 12),
          Text(
            'Demo Mode — No account needed',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textMuted.withValues(alpha: 0.5),
            ),
          ).animate().fadeIn(delay: 200.ms),
        ],
      ],
    );
  }
}
