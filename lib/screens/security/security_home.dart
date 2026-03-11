import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_theme.dart';
import '../../models/enums.dart';
import '../../services/app_service.dart';
import '../../widgets/glass_widgets.dart';

class SecurityHomeScreen extends StatefulWidget {
  final AppService service;
  const SecurityHomeScreen({super.key, required this.service});

  @override
  State<SecurityHomeScreen> createState() => _SecurityHomeScreenState();
}

class _SecurityHomeScreenState extends State<SecurityHomeScreen> {
  int _currentIndex = 0;
  GateType _selectedGate = GateType.hostel;
  LaneType _selectedLane = LaneType.scanLane;
  String _scanResult = '';
  bool _isScanning = false;
  final TextEditingController _exceptionController = TextEditingController();
  final TextEditingController _exceptionReasonController = TextEditingController();

  @override
  void dispose() {
    _exceptionController.dispose();
    _exceptionReasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GlassScaffold(
      bottomNavigationBar: _buildBottomNav(),
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _buildScanView(),
          _buildActivePasses(),
          _buildProfile(),
        ],
      ),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      margin: const EdgeInsets.all(16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.bgCard.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.glassBorder, width: 0.5),
          ),
          child: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: (i) => setState(() => _currentIndex = i),
            backgroundColor: Colors.transparent,
            elevation: 0,
            type: BottomNavigationBarType.fixed,
            selectedItemColor: AppColors.primaryStart,
            unselectedItemColor: AppColors.textMuted,
            selectedFontSize: 11,
            unselectedFontSize: 10,
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.qr_code_scanner_rounded),
                label: 'Scan',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.badge_rounded),
                label: 'Active',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person_rounded),
                label: 'Profile',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildScanView() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Gate Security',
                      style: Theme.of(context).textTheme.headlineLarge,
                    ),
                    Text(
                      'Scan & validate gate passes',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () {
                  widget.service.logout();
                  Navigator.of(context).pushReplacementNamed('/');
                },
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.security_rounded,
                      color: Colors.white, size: 22),
                ),
              ),
            ],
          ).animate().fadeIn(duration: 400.ms),

          // Bus Mode active banner
          if (widget.service.busMode) ...[
            const SizedBox(height: 12),
            GlassCard(
              borderColor: AppColors.accentGreen.withValues(alpha: 0.4),
              backgroundColor: AppColors.accentGreen.withValues(alpha: 0.05),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  const Icon(Icons.directions_bus_rounded,
                      color: AppColors.accentGreen, size: 20),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Bus Mode Active — Bus lane enabled',
                      style: TextStyle(
                        color: AppColors.accentGreen,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 300.ms),
          ],

          const SizedBox(height: 20),

          // Gate Type Selection
          Text('Select Gate', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: GlassCard(
                  onTap: () =>
                      setState(() => _selectedGate = GateType.hostel),
                  padding: const EdgeInsets.all(16),
                  borderColor: _selectedGate == GateType.hostel
                      ? AppColors.accentCyan
                      : null,
                  backgroundColor: _selectedGate == GateType.hostel
                      ? AppColors.accentCyan.withValues(alpha: 0.1)
                      : null,
                  child: Column(
                    children: [
                      Icon(Icons.apartment_rounded,
                          color: _selectedGate == GateType.hostel
                              ? AppColors.accentCyan
                              : AppColors.textMuted,
                          size: 32),
                      const SizedBox(height: 8),
                      Text(
                        'Hostel Gate',
                        style: TextStyle(
                          color: _selectedGate == GateType.hostel
                              ? AppColors.accentCyan
                              : AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GlassCard(
                  onTap: () =>
                      setState(() => _selectedGate = GateType.main),
                  padding: const EdgeInsets.all(16),
                  borderColor: _selectedGate == GateType.main
                      ? AppColors.accentAmber
                      : null,
                  backgroundColor: _selectedGate == GateType.main
                      ? AppColors.accentAmber.withValues(alpha: 0.1)
                      : null,
                  child: Column(
                    children: [
                      Icon(Icons.door_front_door_rounded,
                          color: _selectedGate == GateType.main
                              ? AppColors.accentAmber
                              : AppColors.textMuted,
                          size: 32),
                      const SizedBox(height: 8),
                      Text(
                        'Main Gate',
                        style: TextStyle(
                          color: _selectedGate == GateType.main
                              ? AppColors.accentAmber
                              : AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ).animate().fadeIn(delay: 200.ms, duration: 400.ms),

          // Lane Type Selection (only for hostel gate)
          if (_selectedGate == GateType.hostel) ...[
            const SizedBox(height: 16),
            Text('Select Lane', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: LaneType.values.where((lane) {
                // Only show bus mode lane if bus mode is active
                if (lane == LaneType.busMode && !widget.service.busMode) {
                  return false;
                }
                return true;
              }).map((lane) => GestureDetector(
                    onTap: () => setState(() => _selectedLane = lane),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: _selectedLane == lane
                            ? lane.color.withValues(alpha: 0.15)
                            : AppColors.glassWhite,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _selectedLane == lane
                              ? lane.color
                              : AppColors.glassBorder,
                          width: _selectedLane == lane ? 1.5 : 0.5,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(lane.icon,
                              color: _selectedLane == lane
                                  ? lane.color
                                  : AppColors.textMuted,
                              size: 18),
                          const SizedBox(width: 6),
                          Text(
                            lane.label,
                            style: TextStyle(
                              color: _selectedLane == lane
                                  ? lane.color
                                  : AppColors.textSecondary,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )).toList(),
            ).animate().fadeIn(delay: 250.ms, duration: 400.ms),
          ],

          const SizedBox(height: 20),

          // Exception Lane — manual override form
          if (_selectedGate == GateType.hostel &&
              _selectedLane == LaneType.exception) ...[
            _buildExceptionLane(),
          ] else ...[
            // Standard Simulated Scanner
            _buildStandardScanner(),
          ],

          // Scan Result
          if (_scanResult.isNotEmpty) ...[
            const SizedBox(height: 12),
            GlassCard(
              borderColor: _scanResult.startsWith('✓')
                  ? AppColors.accentGreen.withValues(alpha: 0.4)
                  : _scanResult.startsWith('⚠')
                      ? AppColors.accentAmber.withValues(alpha: 0.4)
                      : AppColors.accentRed.withValues(alpha: 0.4),
              backgroundColor: _scanResult.startsWith('✓')
                  ? AppColors.accentGreen.withValues(alpha: 0.05)
                  : _scanResult.startsWith('⚠')
                      ? AppColors.accentAmber.withValues(alpha: 0.05)
                      : AppColors.accentRed.withValues(alpha: 0.05),
              child: Row(
                children: [
                  Icon(
                    _scanResult.startsWith('✓')
                        ? Icons.check_circle_rounded
                        : _scanResult.startsWith('⚠')
                            ? Icons.warning_rounded
                            : Icons.error_rounded,
                    color: _scanResult.startsWith('✓')
                        ? AppColors.accentGreen
                        : _scanResult.startsWith('⚠')
                            ? AppColors.accentAmber
                            : AppColors.accentRed,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _scanResult,
                      style: TextStyle(
                        color: _scanResult.startsWith('✓')
                            ? AppColors.accentGreen
                            : _scanResult.startsWith('⚠')
                                ? AppColors.accentAmber
                                : AppColors.accentRed,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 300.ms).shake(
                  hz: 2,
                  delay: 100.ms,
                ),
          ],
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildStandardScanner() {
    return GlassCard(
      borderColor: AppColors.primaryStart.withValues(alpha: 0.3),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            height: 200,
            decoration: BoxDecoration(
              color: AppColors.bgDark,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _isScanning
                    ? AppColors.accentGreen
                    : AppColors.glassBorder,
                width: _isScanning ? 2 : 0.5,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _isScanning
                      ? Icons.qr_code_scanner_rounded
                      : Icons.qr_code_2_rounded,
                  color: _isScanning
                      ? AppColors.accentGreen
                      : AppColors.textMuted,
                  size: 64,
                ),
                const SizedBox(height: 12),
                Text(
                  _isScanning
                      ? 'Scanning...'
                      : 'Ready to Scan',
                  style: TextStyle(
                    color: _isScanning
                        ? AppColors.accentGreen
                        : AppColors.textMuted,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (_selectedGate == GateType.hostel) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Lane: ${_selectedLane.label}',
                    style: TextStyle(
                      color: _selectedLane.color.withValues(alpha: 0.7),
                      fontSize: 11,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Demo scan buttons
          Text(
            'Demo: Simulate QR Scan',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: GlassButton(
                  label: 'Scan Exit',
                  icon: Icons.logout_rounded,
                  isSmall: true,
                  gradient: const LinearGradient(
                    colors: [AppColors.accentAmber, Color(0xFFD97706)],
                  ),
                  onPressed: () => _simulateScan('exit'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: GlassButton(
                  label: 'Scan Entry',
                  icon: Icons.login_rounded,
                  isSmall: true,
                  gradient: const LinearGradient(
                    colors: [AppColors.accentGreen, Color(0xFF059669)],
                  ),
                  onPressed: () => _simulateScan('entry'),
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(delay: 300.ms, duration: 400.ms);
  }

  Widget _buildExceptionLane() {
    return GlassCard(
      borderColor: AppColors.accentRed.withValues(alpha: 0.3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.warning_amber_rounded,
                  color: AppColors.accentRed, size: 20),
              const SizedBox(width: 8),
              Text('Exception Lane — Manual Override',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(color: AppColors.accentRed)),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _exceptionController,
            style: const TextStyle(color: AppColors.textPrimary),
            decoration: InputDecoration(
              labelText: 'Student Roll Number',
              hintText: 'e.g., CS21B1045',
              filled: true,
              fillColor: AppColors.glassWhite,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.glassBorder),
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _exceptionReasonController,
            maxLines: 2,
            style: const TextStyle(color: AppColors.textPrimary),
            decoration: InputDecoration(
              labelText: 'Override Reason',
              hintText: 'Why manual override is needed...',
              filled: true,
              fillColor: AppColors.glassWhite,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.glassBorder),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: GlassButton(
                  label: 'Override Exit',
                  icon: Icons.logout_rounded,
                  isSmall: true,
                  gradient: const LinearGradient(
                    colors: [AppColors.accentAmber, Color(0xFFD97706)],
                  ),
                  onPressed: () => _handleException('exit'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: GlassButton(
                  label: 'Override Entry',
                  icon: Icons.login_rounded,
                  isSmall: true,
                  gradient: const LinearGradient(
                    colors: [AppColors.accentGreen, Color(0xFF059669)],
                  ),
                  onPressed: () => _handleException('entry'),
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(delay: 300.ms, duration: 400.ms);
  }

  Future<void> _simulateScan(String action) async {
    setState(() => _isScanning = true);
    await Future.delayed(const Duration(milliseconds: 800));

    // Try to scan the active pass
    final passes = widget.service.qrPasses.where((p) => p.isActive).toList();
    if (passes.isEmpty) {
      setState(() {
        _isScanning = false;
        _scanResult = '✗ No active passes found';
      });
      return;
    }

    final error = await widget.service.scanQr(
      passes.first.id,
      _selectedGate,
      action,
      laneType: _selectedGate == GateType.hostel ? _selectedLane : null,
    );

    setState(() {
      _isScanning = false;
      if (error != null) {
        _scanResult = '✗ $error';
      } else {
        final laneInfo = _selectedGate == GateType.hostel
            ? ' [${_selectedLane.label}]'
            : '';
        _scanResult =
            '✓ ${action.toUpperCase()} recorded at ${_selectedGate == GateType.hostel ? "Hostel" : "Main"} Gate$laneInfo';
      }
    });
  }

  Future<void> _handleException(String action) async {
    final rollNumber = _exceptionController.text.trim();
    final reason = _exceptionReasonController.text.trim();

    if (rollNumber.isEmpty) {
      setState(() => _scanResult = '⚠ Please enter student roll number');
      return;
    }
    if (reason.isEmpty) {
      setState(() => _scanResult = '⚠ Please provide override reason');
      return;
    }

    setState(() => _isScanning = true);
    await Future.delayed(const Duration(milliseconds: 500));

    setState(() {
      _isScanning = false;
      _scanResult = '✓ EXCEPTION: ${action.toUpperCase()} override for $rollNumber recorded';
      _exceptionController.clear();
      _exceptionReasonController.clear();
    });
  }

  Widget _buildActivePasses() {
    final activePasses =
        widget.service.qrPasses.where((p) => p.isActive).toList();
    final allPasses = widget.service.qrPasses;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          Text(
            'Active Passes',
            style: Theme.of(context).textTheme.headlineLarge,
          ),
          const SizedBox(height: 4),
          Text(
            '${activePasses.length} active • ${allPasses.length} total',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          if (activePasses.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(40),
                child: Column(
                  children: [
                    Icon(Icons.badge_rounded,
                        size: 64, color: AppColors.textMuted),
                    const SizedBox(height: 16),
                    Text('No active passes',
                        style: TextStyle(
                            color: AppColors.textMuted, fontSize: 16)),
                  ],
                ),
              ),
            )
          else
            ...activePasses.map((pass) {
              Color stateColor;
              switch (pass.state) {
                case QrState.unused:
                  stateColor = AppColors.accentCyan;
                  break;
                case QrState.hostelExited:
                  stateColor = AppColors.accentAmber;
                  break;
                case QrState.campusExited:
                  stateColor = AppColors.accentPink;
                  break;
                case QrState.campusEntered:
                  stateColor = AppColors.accentGreen;
                  break;
                default:
                  stateColor = AppColors.textMuted;
              }

              return GlassCard(
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: stateColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(Icons.qr_code_2_rounded,
                          color: stateColor, size: 24),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(pass.studentName,
                              style:
                                  Theme.of(context).textTheme.titleMedium),
                          Text(pass.studentRollNumber,
                              style:
                                  Theme.of(context).textTheme.bodySmall),
                        ],
                      ),
                    ),
                    StatusBadge(
                      label: pass.state.label,
                      color: stateColor,
                    ),
                  ],
                ),
              );
            }),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildProfile() {
    final user = widget.service.currentUser;
    if (user == null) return const SizedBox.shrink();
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          const SizedBox(height: 40),
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Icon(Icons.security_rounded,
                color: Colors.white, size: 36),
          ),
          const SizedBox(height: 16),
          Text(user.name, style: Theme.of(context).textTheme.headlineMedium),
          Text(user.email, style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 8),
          StatusBadge(label: 'Security', color: AppColors.accentRed),
          const SizedBox(height: 32),
          GlassButton(
            label: 'Logout',
            icon: Icons.logout_rounded,
            gradient: const LinearGradient(
              colors: [AppColors.accentRed, Color(0xFFDC2626)],
            ),
            onPressed: () {
              widget.service.logout();
              Navigator.of(context).pushReplacementNamed('/');
            },
          ),
          const SizedBox(height: 100),
        ],
      ),
    );
  }
}
