import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../models/enums.dart';
import '../../models/medical.dart';
import '../../models/user_model.dart';
import '../../services/mock_service.dart';
import '../../widgets/glass_widgets.dart';

class MedicalOfficerHomeScreen extends StatefulWidget {
  final MockService service;
  const MedicalOfficerHomeScreen({super.key, required this.service});

  @override
  State<MedicalOfficerHomeScreen> createState() => _MedicalOfficerHomeScreenState();
}

class _MedicalOfficerHomeScreenState extends State<MedicalOfficerHomeScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final user = widget.service.currentUser!;
    final allRecords = widget.service.getAllMedicalVisits();
    final activeRecords = widget.service.getActiveMedicalRecords();
    final reviewRequests = widget.service.getReviewRequestedVisits();

    return GlassScaffold(
      bottomNavigationBar: _buildBottomNav(),
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _buildDashboard(user, allRecords, activeRecords, reviewRequests),
          _buildAllRecords(allRecords),
          _buildReviewRequests(reviewRequests),
          _buildProfile(user),
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
                icon: Icon(Icons.dashboard_rounded),
                label: 'Dashboard',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.folder_shared_rounded),
                label: 'Records',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.rate_review_rounded),
                label: 'Reviews',
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

  // ─── Dashboard ───────────────────────────────────────

  Widget _buildDashboard(AppUser user, List<MedicalVisit> all,
      List<MedicalVisit> active, List<MedicalVisit> reviews) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Good ${_greeting()},',
              style: Theme.of(context).textTheme.bodyMedium),
          Text('Dr. ${user.name.split(' ').last}',
              style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 20),

          // Stats row
          Row(
            children: [
              Expanded(
                child: StatCard(
                  title: 'Active Cases',
                  value: '${active.length}',
                  icon: Icons.medical_services_rounded,
                  color: AppColors.accentRed,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: StatCard(
                  title: 'Review Requests',
                  value: '${reviews.length}',
                  icon: Icons.rate_review_rounded,
                  color: AppColors.accentAmber,
                ),
              ),
            ],
          ).animate().fadeIn(duration: 400.ms),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: StatCard(
                  title: 'Total Records',
                  value: '${all.length}',
                  icon: Icons.folder_rounded,
                  color: AppColors.accentCyan,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: StatCard(
                  title: 'Not Fit',
                  value: '${all.where((r) => r.fitnessStatus == FitnessStatus.notFit).length}',
                  icon: Icons.warning_rounded,
                  color: const Color(0xFF8B5CF6),
                ),
              ),
            ],
          ).animate().fadeIn(delay: 100.ms, duration: 400.ms),
          const SizedBox(height: 24),

          // Create new record button
          GlassButton(
            label: 'Create Medical Record',
            icon: Icons.add_circle_rounded,
            onPressed: () => _showCreateRecordDialog(),
          ).animate().fadeIn(delay: 200.ms, duration: 400.ms),
          const SizedBox(height: 24),

          // Review requests section
          if (reviews.isNotEmpty) ...[
            Text('🔔 Pending Review Requests',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            ...reviews.take(3).map((visit) => _buildRecordCard(visit, showReviewBadge: true)),
            const SizedBox(height: 16),
          ],

          // Active cases
          Text('Active Cases',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          if (active.isEmpty)
            _emptyState('No active medical cases', Icons.health_and_safety_rounded)
          else
            ...active.take(5).map((visit) => _buildRecordCard(visit)),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  // ─── All Records ─────────────────────────────────────

  Widget _buildAllRecords(List<MedicalVisit> records) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppBar(
          title: const Text('All Medical Records'),
          backgroundColor: Colors.transparent,
          elevation: 0,
          automaticallyImplyLeading: false,
        ),
        Expanded(
          child: records.isEmpty
              ? Center(child: _emptyState('No records yet', Icons.folder_open_rounded))
              : ListView.builder(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: records.length,
                  itemBuilder: (ctx, i) => _buildRecordCard(records[i]),
                ),
        ),
      ],
    );
  }

  // ─── Review Requests ─────────────────────────────────

  Widget _buildReviewRequests(List<MedicalVisit> reviews) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppBar(
          title: const Text('Student Review Requests'),
          backgroundColor: Colors.transparent,
          elevation: 0,
          automaticallyImplyLeading: false,
        ),
        Expanded(
          child: reviews.isEmpty
              ? Center(child: _emptyState('No review requests', Icons.rate_review_rounded))
              : ListView.builder(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: reviews.length,
                  itemBuilder: (ctx, i) => _buildRecordCard(reviews[i], showReviewBadge: true),
                ),
        ),
      ],
    );
  }

  // ─── Profile ─────────────────────────────────────────

  Widget _buildProfile(AppUser user) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
      child: Column(
        children: [
          const SizedBox(height: 20),
          CircleAvatar(
            radius: 50,
            backgroundColor: AppColors.accentRed.withValues(alpha: 0.12),
            child: const Icon(Icons.medical_services_rounded,
                size: 40, color: AppColors.accentRed),
          ),
          const SizedBox(height: 16),
          Text(user.name,
              style: Theme.of(context).textTheme.headlineMedium),
          Text(user.role.label,
              style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 8),
          Text(user.email, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 24),
          GlassCard(
            child: Column(
              children: [
                _profileRow(Icons.email_rounded, 'Email', user.email),
                const Divider(height: 1),
                _profileRow(Icons.business_rounded, 'Department',
                    user.department ?? 'Health Services'),
              ],
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: GlassButton(
              label: 'Logout',
              icon: Icons.logout_rounded,
              gradient: LinearGradient(
                  colors: [AppColors.accentRed, const Color(0xFFB91C1C)]),
              onPressed: () {
                widget.service.logout();
                Navigator.of(context).pushReplacementNamed('/');
              },
            ),
          ),
        ],
      ),
    );
  }

  // ─── Record Card ─────────────────────────────────────

  Widget _buildRecordCard(MedicalVisit visit, {bool showReviewBadge = false}) {
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
                    Text(visit.studentName,
                        style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary)),
                    Text(
                      '${visit.rollNumber ?? ''} • ${visit.hostelBlock}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  StatusBadge(label: visit.fitnessStatus.label, color: fitnessColor),
                  if (showReviewBadge && visit.reviewRequested) ...[
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.accentAmber.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text('Review Requested',
                          style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: AppColors.accentAmber)),
                    ),
                  ],
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text('Diagnosis: ${visit.diagnosis ?? visit.symptoms}',
              style: Theme.of(context).textTheme.bodyMedium,
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(Icons.calendar_today_rounded, size: 12, color: AppColors.textMuted),
              const SizedBox(width: 4),
              Text(DateFormat('dd MMM yyyy').format(visit.createdAt),
                  style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
              const SizedBox(width: 12),
              if (visit.restDays != null) ...[
                Icon(Icons.bed_rounded, size: 12, color: AppColors.textMuted),
                const SizedBox(width: 4),
                Text('${visit.restDays} days rest',
                    style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
              ],
              if (visit.movementRestricted) ...[
                const SizedBox(width: 12),
                Icon(Icons.block_rounded, size: 12, color: AppColors.accentRed),
                const SizedBox(width: 4),
                Text('Restricted',
                    style: TextStyle(fontSize: 11, color: AppColors.accentRed, fontWeight: FontWeight.w600)),
              ],
            ],
          ),
          // Intimation status
          if (visit.intimations.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: visit.intimations.map((MedicalIntimation intim) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: intim.acknowledged
                        ? AppColors.accentGreen.withValues(alpha: 0.1)
                        : Colors.grey.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: intim.acknowledged
                          ? AppColors.accentGreen.withValues(alpha: 0.3)
                          : Colors.grey.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        intim.acknowledged ? Icons.check_circle_rounded : Icons.schedule_rounded,
                        size: 10,
                        color: intim.acknowledged ? AppColors.accentGreen : AppColors.textMuted,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        intim.role,
                        style: TextStyle(
                          fontSize: 9,
                          color: intim.acknowledged
                              ? AppColors.accentGreen
                              : AppColors.textMuted,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    ).animate().fadeIn(duration: 300.ms);
  }

  // ─── Record Detail / Actions ─────────────────────────

  void _showRecordDetail(MedicalVisit visit) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.bgCard,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.3,
        maxChildSize: 0.95,
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
                    color: AppColors.glassBorder, borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 16),

              // Header
              Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: _fitnessColor(visit.fitnessStatus).withValues(alpha: 0.12),
                    child: Icon(Icons.person_rounded,
                        color: _fitnessColor(visit.fitnessStatus), size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(visit.studentName,
                            style: Theme.of(context).textTheme.headlineMedium),
                        Text('${visit.rollNumber ?? ''} • ${visit.hostelBlock}',
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

              // Details
              _detailRow('Symptoms', visit.symptoms),
              if (visit.diagnosis != null) _detailRow('Diagnosis', visit.diagnosis!),
              if (visit.prescription != null) _detailRow('Prescription', visit.prescription!),
              if (visit.restDays != null) _detailRow('Rest Days', '${visit.restDays} days'),
              _detailRow('Movement', visit.movementRestricted ? '🔴 Restricted' : '🟢 Allowed'),
              _detailRow('Status', visit.status.label),
              _detailRow('Created', DateFormat('dd MMM yyyy, HH:mm').format(visit.createdAt)),
              _detailRow('Officer', visit.createdByOfficerName),

              if (visit.medicalOfficerNote != null) ...[
                const SizedBox(height: 8),
                _detailRow('Officer Note', visit.medicalOfficerNote!),
              ],

              // Review request banner
              if (visit.reviewRequested) ...[
                const SizedBox(height: 16),
                GlassCard(
                  borderColor: AppColors.accentAmber.withValues(alpha: 0.5),
                  backgroundColor: AppColors.accentAmber.withValues(alpha: 0.06),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.rate_review_rounded,
                              color: AppColors.accentAmber, size: 18),
                          const SizedBox(width: 8),
                          Text('Student Review Request',
                              style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.accentAmber,
                                  fontSize: 14)),
                        ],
                      ),
                      if (visit.reviewRequestNote != null) ...[
                        const SizedBox(height: 6),
                        Text(visit.reviewRequestNote!,
                            style: Theme.of(context).textTheme.bodyMedium),
                      ],
                      Text(
                        'Requested: ${DateFormat('dd MMM, HH:mm').format(visit.reviewRequestedAt!)}',
                        style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                      ),
                    ],
                  ),
                ),
              ],

              // Intimation status
              const SizedBox(height: 16),
              Text('Intimation Status',
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
                          size: 18,
                          color: intim.acknowledged
                              ? AppColors.accentGreen
                              : AppColors.accentAmber,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('${intim.role} — ${intim.personName}',
                                  style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textPrimary)),
                              Text(
                                intim.acknowledged
                                    ? 'Acknowledged ${DateFormat('dd MMM, HH:mm').format(intim.acknowledgedAt!)}'
                                    : 'Notified ${DateFormat('dd MMM, HH:mm').format(intim.notifiedAt)} — Pending',
                                style: TextStyle(
                                    fontSize: 11, color: AppColors.textMuted),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  )),

              // Actions
              if (visit.status != MedicalStatus.cleared) ...[
                const SizedBox(height: 20),
                const Divider(),
                const SizedBox(height: 8),
                Text('Actions', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: GlassButton(
                        label: 'Mark Fit',
                        icon: Icons.check_circle_rounded,
                        isSmall: true,
                        gradient: LinearGradient(
                            colors: [AppColors.accentGreen, const Color(0xFF047857)]),
                        onPressed: () async {
                          await widget.service.updateFitnessStatus(
                            visitId: visit.id,
                            fitnessStatus: FitnessStatus.fit,
                            note: 'Declared fit by Medical Officer',
                          );
                          if (mounted) Navigator.pop(ctx);
                          setState(() {});
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: GlassButton(
                        label: 'Not Fit',
                        icon: Icons.cancel_rounded,
                        isSmall: true,
                        gradient: LinearGradient(
                            colors: [AppColors.accentRed, const Color(0xFFB91C1C)]),
                        onPressed: () async {
                          await widget.service.updateFitnessStatus(
                            visitId: visit.id,
                            fitnessStatus: FitnessStatus.notFit,
                            note: 'Student not yet fit for class',
                          );
                          if (mounted) Navigator.pop(ctx);
                          setState(() {});
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: GlassButton(
                    label: 'Issue Full Clearance',
                    icon: Icons.verified_rounded,
                    isSmall: true,
                    gradient: LinearGradient(
                        colors: [AppColors.accentGreen, AppColors.accentCyan]),
                    onPressed: () async {
                      await widget.service.issueMedicalClearance(visit.id);
                      if (mounted) Navigator.pop(ctx);
                      setState(() {});
                    },
                  ),
                ),
              ],
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Create Record Dialog ────────────────────────────

  void _showCreateRecordDialog() {
    final students = widget.service.getStudentUsers();
    AppUser? selectedStudent;
    final symptomsCtrl = TextEditingController();
    final diagnosisCtrl = TextEditingController();
    final restDaysCtrl = TextEditingController(text: '1');
    final prescriptionCtrl = TextEditingController();
    final noteCtrl = TextEditingController();
    FitnessStatus fitness = FitnessStatus.underObservation;
    bool restrict = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: AppColors.bgCard,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Create Medical Record',
              style: TextStyle(color: AppColors.textPrimary, fontSize: 18)),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Student dropdown
                  Text('Student', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: AppColors.bgSurface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.glassBorder),
                    ),
                    child: DropdownButton<AppUser>(
                      value: selectedStudent,
                      isExpanded: true,
                      underline: const SizedBox(),
                      hint: const Text('Select student'),
                      dropdownColor: AppColors.bgCard,
                      items: students.map((s) => DropdownMenuItem(
                        value: s,
                        child: Text('${s.name} (${s.rollNumber ?? ""})',
                            style: const TextStyle(color: AppColors.textPrimary, fontSize: 13)),
                      )).toList(),
                      onChanged: (v) => setDialogState(() => selectedStudent = v),
                    ),
                  ),
                  const SizedBox(height: 12),

                  _fieldLabel('Symptoms'),
                  _textField(symptomsCtrl, 'Describe symptoms...', 2),
                  const SizedBox(height: 10),

                  _fieldLabel('Diagnosis'),
                  _textField(diagnosisCtrl, 'Medical diagnosis...', 2),
                  const SizedBox(height: 10),

                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _fieldLabel('Rest Days'),
                            _textField(restDaysCtrl, '1', 1,
                                keyboardType: TextInputType.number),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _fieldLabel('Fitness'),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                              decoration: BoxDecoration(
                                color: AppColors.bgSurface,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppColors.glassBorder),
                              ),
                              child: DropdownButton<FitnessStatus>(
                                value: fitness,
                                isExpanded: true,
                                underline: const SizedBox(),
                                dropdownColor: AppColors.bgCard,
                                items: FitnessStatus.values.map((f) => DropdownMenuItem(
                                  value: f,
                                  child: Text(f.label,
                                      style: const TextStyle(
                                          color: AppColors.textPrimary, fontSize: 12)),
                                )).toList(),
                                onChanged: (v) =>
                                    setDialogState(() => fitness = v ?? fitness),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  _fieldLabel('Prescription (optional)'),
                  _textField(prescriptionCtrl, 'Medications, dosage...', 2),
                  const SizedBox(height: 10),

                  _fieldLabel('Notes (optional)'),
                  _textField(noteCtrl, 'Additional notes...', 2),
                  const SizedBox(height: 10),

                  // Restrict movement
                  SwitchListTile(
                    value: restrict,
                    onChanged: (v) => setDialogState(() => restrict = v),
                    title: const Text('Restrict Movement',
                        style: TextStyle(
                            color: AppColors.textPrimary, fontSize: 13)),
                    subtitle: Text('Block gate exit',
                        style: TextStyle(
                            color: AppColors.textMuted, fontSize: 11)),
                    activeColor: AppColors.accentRed,
                    contentPadding: EdgeInsets.zero,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel',
                  style: TextStyle(color: AppColors.textMuted)),
            ),
            ElevatedButton(
              onPressed: () async {
                if (selectedStudent != null &&
                    symptomsCtrl.text.trim().isNotEmpty &&
                    diagnosisCtrl.text.trim().isNotEmpty) {
                  await widget.service.createMedicalRecord(
                    studentId: selectedStudent!.uid,
                    symptoms: symptomsCtrl.text.trim(),
                    diagnosis: diagnosisCtrl.text.trim(),
                    restDays: int.tryParse(restDaysCtrl.text) ?? 1,
                    fitnessStatus: fitness,
                    restrictMovement: restrict,
                    prescription: prescriptionCtrl.text.trim().isEmpty
                        ? null
                        : prescriptionCtrl.text.trim(),
                    note: noteCtrl.text.trim().isEmpty
                        ? null
                        : noteCtrl.text.trim(),
                  );
                  if (mounted) Navigator.pop(ctx);
                  setState(() {});
                }
              },
              child: const Text('Create & Intimate'),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Helpers ─────────────────────────────────────────

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Morning';
    if (hour < 17) return 'Afternoon';
    return 'Evening';
  }

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

  Widget _emptyState(String msg, IconData icon) {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        children: [
          Icon(icon, size: 48, color: AppColors.textMuted),
          const SizedBox(height: 12),
          Text(msg, style: TextStyle(color: AppColors.textMuted)),
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

  Widget _profileRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.textMuted),
          const SizedBox(width: 12),
          Text(label,
              style: TextStyle(fontSize: 13, color: AppColors.textMuted)),
          const Spacer(),
          Text(value,
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary)),
        ],
      ),
    );
  }

  Widget _fieldLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(text,
          style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
    );
  }

  Widget _textField(TextEditingController ctrl, String hint, int lines,
      {TextInputType? keyboardType}) {
    return TextField(
      controller: ctrl,
      maxLines: lines,
      keyboardType: keyboardType,
      style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
      decoration: InputDecoration(
        hintText: hint,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      ),
    );
  }
}
