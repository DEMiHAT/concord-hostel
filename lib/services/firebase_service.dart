import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/enums.dart';
import '../models/user_model.dart';
import '../models/leave_request.dart';
import '../models/qr_pass.dart';
import '../models/attendance.dart';
import '../models/medical.dart';
import '../models/grievance.dart';
import '../models/geofence_attendance.dart';
import 'app_service.dart';
import 'qr_generation_service.dart';

/// Production Firebase service implementing [AppService].
/// Uses Firebase Auth for authentication and Cloud Firestore for data.
/// All sync getters are backed by in-memory caches that are populated
/// on login and refreshed after every mutation.
class FirebaseService extends AppService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  AppUser? _currentUser;
  bool _busMode = false;

  // ── In-memory caches ──
  List<LeaveRequest> _leaveRequestsCache = [];
  List<QrPass> _qrPassesCache = [];
  List<AppUser> _usersCache = [];
  List<MedicalVisit> _medicalVisitsCache = [];
  List<Grievance> _grievancesCache = [];
  List<GeofenceSession> _geofenceSessionsCache = [];
  List<GeofenceCheckIn> _geofenceCheckInsCache = [];
  List<AttendanceAnomaly> _anomaliesCache = [];
  List<AttendanceRecord> _attendanceCache = [];

  // ════════════════════════════════════════════════════════
  // CACHE REFRESH
  // ════════════════════════════════════════════════════════

  /// Refresh all caches — called after login and after mutations.
  Future<void> _refreshCaches() async {
    await Future.wait([
      _refreshLeaveRequests(),
      _refreshQrPasses(),
      _refreshUsers(),
      _refreshMedicalVisits(),
      _refreshGrievances(),
      _refreshGeofenceSessions(),
      _refreshGeofenceCheckIns(),
      _refreshAnomalies(),
    ]);
    notifyListeners();
  }

  Future<void> _refreshLeaveRequests() async {
    try {
      final snap = await _db
          .collection('leave_requests')
          .orderBy('createdAt', descending: true)
          .get();
      _leaveRequestsCache = snap.docs
          .map((d) => LeaveRequest.fromFirestore(d.data(), d.id))
          .toList();
    } catch (_) {}
  }

  Future<void> _refreshQrPasses() async {
    try {
      final snap = await _db.collection('qr_passes').get();
      _qrPassesCache = snap.docs
          .map((d) => QrPass.fromFirestore(d.data(), d.id))
          .toList();
    } catch (_) {}
  }

  Future<void> _refreshUsers() async {
    try {
      final snap = await _db.collection('users').get();
      _usersCache = snap.docs
          .map((d) => AppUser.fromFirestore(d.data(), d.id))
          .toList();
    } catch (_) {}
  }

  Future<void> _refreshMedicalVisits() async {
    try {
      final snap = await _db
          .collection('medical_visits')
          .orderBy('createdAt', descending: true)
          .get();
      _medicalVisitsCache = snap.docs
          .map((d) => MedicalVisit.fromFirestore(d.data(), d.id))
          .toList();
    } catch (_) {}
  }

  Future<void> _refreshGrievances() async {
    try {
      final snap = await _db.collection('grievances').get();
      _grievancesCache = snap.docs
          .map((d) => Grievance.fromFirestore(d.data(), d.id))
          .toList();
    } catch (_) {}
  }

  Future<void> _refreshGeofenceSessions() async {
    try {
      final snap = await _db.collection('geofence_sessions').get();
      _geofenceSessionsCache = snap.docs
          .map((d) => GeofenceSession.fromFirestore(d.data(), d.id))
          .toList();
    } catch (_) {}
  }

  Future<void> _refreshGeofenceCheckIns() async {
    try {
      final snap = await _db.collection('geofence_checkins').get();
      _geofenceCheckInsCache = snap.docs
          .map((d) => GeofenceCheckIn.fromFirestore(d.data(), d.id))
          .toList();
    } catch (_) {}
  }

  Future<void> _refreshAnomalies() async {
    try {
      final snap = await _db.collection('attendance_anomalies').get();
      _anomaliesCache = snap.docs.map((d) {
        final data = d.data();
        return AttendanceAnomaly(
          id: d.id,
          studentId: data['studentId'] ?? '',
          studentName: data['studentName'] ?? '',
          rollNumber: data['rollNumber'] ?? '',
          hostelBlock: data['hostelBlock'] ?? '',
          type: AnomalyType.values.firstWhere(
            (e) => e.name == data['type'],
            orElse: () => AnomalyType.frequentAbsence,
          ),
          description: data['description'] ?? '',
          raisedById: data['raisedById'] ?? '',
          raisedByName: data['raisedByName'] ?? '',
          raisedAt: (data['raisedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
          parentNotified: data['parentNotified'] ?? false,
          resolved: data['resolved'] ?? false,
          parentResponse: data['parentResponse'],
        );
      }).toList();
    } catch (_) {}
  }

  // ════════════════════════════════════════════════════════
  // AUTH
  // ════════════════════════════════════════════════════════

  @override
  AppUser? get currentUser => _currentUser;

  @override
  Future<AppUser?> loginWithRole(UserRole role) async {
    // Not supported in production mode
    throw UnsupportedError('loginWithRole is only available in demo mode');
  }

  @override
  Future<AppUser?> loginWithEmail(String email, String password) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    if (credential.user != null) {
      final doc = await _db.collection('users').doc(credential.user!.uid).get();
      if (doc.exists) {
        _currentUser = AppUser.fromFirestore(doc.data()!, doc.id);
        // Pre-load all caches after successful login
        await _refreshCaches();
        notifyListeners();
        return _currentUser;
      }
    }
    return null;
  }

  @override
  void logout() {
    _auth.signOut();
    _currentUser = null;
    // Clear caches
    _leaveRequestsCache = [];
    _qrPassesCache = [];
    _usersCache = [];
    _medicalVisitsCache = [];
    _grievancesCache = [];
    _geofenceSessionsCache = [];
    _geofenceCheckInsCache = [];
    _anomaliesCache = [];
    _attendanceCache = [];
    notifyListeners();
  }

  // ════════════════════════════════════════════════════════
  // LEAVE REQUESTS
  // ════════════════════════════════════════════════════════

  @override
  List<LeaveRequest> get leaveRequests => List.unmodifiable(_leaveRequestsCache);

  /// Async version to fetch all leave requests.
  Future<List<LeaveRequest>> getAllLeaveRequestsAsync() async {
    await _refreshLeaveRequests();
    return _leaveRequestsCache;
  }

  @override
  List<LeaveRequest> getStudentLeaves(String studentId) {
    return _leaveRequestsCache
        .where((l) => l.studentId == studentId)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  /// Async version for production use.
  Future<List<LeaveRequest>> getStudentLeavesAsync(String studentId) async {
    await _refreshLeaveRequests();
    return getStudentLeaves(studentId);
  }

  @override
  List<LeaveRequest> getPendingApprovalsForRole(UserRole role) {
    switch (role) {
      case UserRole.rt:
        return _leaveRequestsCache
            .where(
              (l) =>
                  l.status == LeaveStatus.pending ||
                  l.status == LeaveStatus.returnedToRt,
            )
            .toList();
      case UserRole.parent:
        return _leaveRequestsCache
            .where((l) => l.status == LeaveStatus.forwardedToParent)
            .toList();
      case UserRole.hod:
        return _leaveRequestsCache
            .where(
              (l) =>
                  l.status == LeaveStatus.forwardedToHod ||
                  l.status == LeaveStatus.awaitingHodAfterFaculty,
            )
            .toList();
      case UserRole.warden:
        return _leaveRequestsCache
            .where((l) => l.status == LeaveStatus.forwardedToWarden)
            .toList();
      case UserRole.faculty:
        return _leaveRequestsCache
            .where((l) => l.status == LeaveStatus.forwardedToFaculty)
            .toList();
      default:
        return [];
    }
  }

  Future<List<LeaveRequest>> getPendingApprovalsForRoleAsync(
      UserRole role) async {
    await _refreshLeaveRequests();
    return getPendingApprovalsForRole(role);
  }

  @override
  Future<void> createLeaveRequest(LeaveRequest request) async {
    await _db
        .collection('leave_requests')
        .doc(request.id)
        .set(request.toFirestore());

    // Write audit log
    await _writeAuditLog(
      action: 'leave_created',
      actorId: request.studentId,
      actorName: request.studentName,
      actorRole: 'Student',
      targetId: request.id,
      details: 'Created ${request.leaveType.label} leave request',
    );

    await _refreshLeaveRequests();
    notifyListeners();
  }

  @override
  Future<void> approveRequest(
    String requestId,
    String approverId,
    String approverName,
    String role,
  ) async {
    final doc = await _db.collection('leave_requests').doc(requestId).get();
    if (!doc.exists) return;

    final request = LeaveRequest.fromFirestore(doc.data()!, doc.id);
    final step = ApprovalStep(
      approverId: approverId,
      approverName: approverName,
      approverRole: role,
      action: 'approved',
    );

    final newStatus = _getNextApprovalStatus(request);
    final updatedHistory = [...request.approvalHistory, step];

    final updates = <String, dynamic>{
      'status': newStatus.firestoreValue,
      'updatedAt': Timestamp.fromDate(DateTime.now()),
      'approvalHistory': updatedHistory.map((e) => e.toMap()).toList(),
    };

    // Auto-generate QR pass on full approval
    if (newStatus == LeaveStatus.approved) {
      final qrPassId = 'qr_${DateTime.now().millisecondsSinceEpoch}';
      final qrPass = QrPass(
        id: qrPassId,
        leaveRequestId: requestId,
        studentId: request.studentId,
        studentName: request.studentName,
        studentRollNumber: request.studentRollNumber,
        state: QrState.unused,
        validFrom: request.fromDate,
        validUntil: request.toDate,
      );
      await _db
          .collection('qr_passes')
          .doc(qrPassId)
          .set(qrPass.toFirestore());
      updates['qrPassId'] = qrPassId;
    }

    await _db.collection('leave_requests').doc(requestId).update(updates);

    // Write audit log
    final actionLabel = newStatus == LeaveStatus.approved
        ? 'approved'
        : 'forwarded to ${newStatus.label}';
    await _writeAuditLog(
      action: 'leave_$actionLabel',
      actorId: approverId,
      actorName: approverName,
      actorRole: role,
      targetId: requestId,
      details:
          '$role $actionLabel leave request for ${request.studentName}',
    );

    await _refreshCaches();
  }

  LeaveStatus _getNextApprovalStatus(LeaveRequest request) {
    switch (request.leaveType) {
      case LeaveType.dayPass:
      case LeaveType.emergency:
        return LeaveStatus.approved;
      case LeaveType.overnight:
      case LeaveType.weekend:
        if (request.status == LeaveStatus.pending) {
          return LeaveStatus.forwardedToParent;
        }
        return LeaveStatus.approved;
      case LeaveType.academic:
        if (request.status == LeaveStatus.pending) {
          return LeaveStatus.forwardedToHod;
        }
        return LeaveStatus.approved;
      case LeaveType.extended:
        if (request.status == LeaveStatus.pending) {
          return LeaveStatus.forwardedToParent;
        }
        if (request.status == LeaveStatus.forwardedToParent) {
          return LeaveStatus.forwardedToWarden;
        }
        return LeaveStatus.approved;
      case LeaveType.workingDayHoliday:
        if (request.status == LeaveStatus.pending) {
          return LeaveStatus.forwardedToFaculty;
        }
        if (request.status == LeaveStatus.forwardedToFaculty) {
          return LeaveStatus.awaitingHodAfterFaculty;
        }
        if (request.status == LeaveStatus.awaitingHodAfterFaculty) {
          return LeaveStatus.returnedToRt;
        }
        if (request.status == LeaveStatus.returnedToRt) {
          return LeaveStatus.forwardedToWarden;
        }
        if (request.status == LeaveStatus.forwardedToWarden) {
          return LeaveStatus.approved;
        }
        return LeaveStatus.approved;
    }
  }

  @override
  Future<void> rejectRequest(
    String requestId,
    String approverId,
    String approverName,
    String role,
    String reason,
  ) async {
    final doc = await _db.collection('leave_requests').doc(requestId).get();
    if (!doc.exists) return;

    final request = LeaveRequest.fromFirestore(doc.data()!, doc.id);
    final step = ApprovalStep(
      approverId: approverId,
      approverName: approverName,
      approverRole: role,
      action: 'rejected',
      comment: reason,
    );

    await _db.collection('leave_requests').doc(requestId).update({
      'status': LeaveStatus.rejected.firestoreValue,
      'rejectionReason': reason,
      'updatedAt': Timestamp.fromDate(DateTime.now()),
      'approvalHistory':
          [...request.approvalHistory, step].map((e) => e.toMap()).toList(),
    });

    await _writeAuditLog(
      action: 'leave_rejected',
      actorId: approverId,
      actorName: approverName,
      actorRole: role,
      targetId: requestId,
      details: '$role rejected leave for ${request.studentName}: $reason',
    );

    await _refreshLeaveRequests();
    notifyListeners();
  }

  @override
  Future<void> requestDocuments(
    String requestId,
    String approverId,
    String approverName,
    String comment,
  ) async {
    final doc = await _db.collection('leave_requests').doc(requestId).get();
    if (!doc.exists) return;

    final request = LeaveRequest.fromFirestore(doc.data()!, doc.id);
    final step = ApprovalStep(
      approverId: approverId,
      approverName: approverName,
      approverRole: 'Faculty',
      action: 'documents_requested',
      comment: comment,
    );

    await _db.collection('leave_requests').doc(requestId).update({
      'status': LeaveStatus.documentsRequested.firestoreValue,
      'updatedAt': Timestamp.fromDate(DateTime.now()),
      'approvalHistory':
          [...request.approvalHistory, step].map((e) => e.toMap()).toList(),
    });

    await _writeAuditLog(
      action: 'documents_requested',
      actorId: approverId,
      actorName: approverName,
      actorRole: 'Faculty',
      targetId: requestId,
      details: 'Faculty requested documents for ${request.studentName}',
    );

    await _refreshLeaveRequests();
    notifyListeners();
  }

  @override
  Future<void> submitDocuments(
    String requestId,
    List<String> documentUrls,
  ) async {
    final doc = await _db.collection('leave_requests').doc(requestId).get();
    if (!doc.exists) return;

    final request = LeaveRequest.fromFirestore(doc.data()!, doc.id);
    final step = ApprovalStep(
      approverId: request.studentId,
      approverName: request.studentName,
      approverRole: 'Student',
      action: 'documents_submitted',
      comment: 'Uploaded ${documentUrls.length} document(s)',
    );

    await _db.collection('leave_requests').doc(requestId).update({
      'status': LeaveStatus.forwardedToFaculty.firestoreValue,
      'updatedAt': Timestamp.fromDate(DateTime.now()),
      'proofDocumentUrls': FieldValue.arrayUnion(documentUrls),
      'approvalHistory':
          [...request.approvalHistory, step].map((e) => e.toMap()).toList(),
    });

    await _refreshLeaveRequests();
    notifyListeners();
  }

  // ════════════════════════════════════════════════════════
  // QR PASSES & GATE
  // ════════════════════════════════════════════════════════

  @override
  List<QrPass> get qrPasses => List.unmodifiable(_qrPassesCache);

  @override
  QrPass? getQrPass(String passId) {
    try {
      return _qrPassesCache.firstWhere((q) => q.id == passId);
    } catch (_) {
      return null;
    }
  }

  Future<QrPass?> getQrPassAsync(String passId) async {
    final doc = await _db.collection('qr_passes').doc(passId).get();
    if (doc.exists) {
      return QrPass.fromFirestore(doc.data()!, doc.id);
    }
    return null;
  }

  @override
  List<QrPass> getStudentPasses(String studentId) {
    return _qrPassesCache.where((q) => q.studentId == studentId).toList();
  }

  Future<List<QrPass>> getStudentPassesAsync(String studentId) async {
    await _refreshQrPasses();
    return getStudentPasses(studentId);
  }

  @override
  Future<String?> scanQr(
    String passId,
    GateType gate,
    String action, {
    LaneType? laneType,
  }) async {
    final doc = await _db.collection('qr_passes').doc(passId).get();
    if (!doc.exists) return 'Pass not found';

    final pass = QrPass.fromFirestore(doc.data()!, doc.id);
    if (pass.isExpired) return 'Pass has expired';

    QrState? newState;
    String? error;

    if (gate == GateType.hostel && action == 'exit') {
      if (pass.state == QrState.unused) {
        newState = QrState.hostelExited;
      } else {
        error = 'Invalid state for hostel exit: ${pass.state.label}';
      }
    } else if (gate == GateType.main && action == 'exit') {
      if (pass.state == QrState.hostelExited) {
        newState = QrState.campusExited;
      } else if (pass.state == QrState.unused) {
        error = 'Must exit hostel gate first!';
      } else {
        error = 'Invalid state for main gate exit: ${pass.state.label}';
      }
    } else if (gate == GateType.main && action == 'entry') {
      if (pass.state == QrState.campusExited) {
        newState = QrState.campusEntered;
      } else {
        error = 'Invalid state for main gate entry: ${pass.state.label}';
      }
    } else if (gate == GateType.hostel && action == 'entry') {
      if (pass.state == QrState.campusEntered) {
        newState = QrState.hostelEntered;
      } else if (pass.state == QrState.hostelExited) {
        newState = QrState.unused;
      } else if (pass.state == QrState.unused) {
        return null;
      } else {
        error = 'Invalid state for hostel entry: ${pass.state.label}';
      }
    }

    if (error != null) return error;
    if (newState == null) return 'Unknown action';

    final log = GateLog(
      gateType: gate == GateType.hostel ? 'hostel' : 'main',
      action: action,
      securityId: _currentUser?.uid ?? 'security1',
      laneType: laneType?.name,
    );

    await _db.collection('qr_passes').doc(passId).update({
      'state': newState.firestoreValue,
      'gateLogs': FieldValue.arrayUnion([log.toMap()]),
    });

    // Write audit log for gate scan
    await _writeAuditLog(
      action: 'gate_scan',
      actorId: _currentUser?.uid ?? 'security1',
      actorName: _currentUser?.name ?? 'Security',
      actorRole: 'Security',
      targetId: passId,
      details:
          '${pass.studentName} ${action.toUpperCase()} at ${gate == GateType.hostel ? 'Hostel' : 'Main'} gate → ${newState.label}',
    );

    await _refreshQrPasses();
    notifyListeners();
    return null;
  }

  @override
  Future<QrPass?> generateQrPass(String leaveRequestId) async {
    final doc = await _db.collection('leave_requests').doc(leaveRequestId).get();
    if (!doc.exists) return null;

    final request = LeaveRequest.fromFirestore(doc.data()!, doc.id);
    if (request.status != LeaveStatus.approved) return null;

    // Return existing pass if already generated
    if (request.qrPassId != null) {
      return await getQrPassAsync(request.qrPassId!);
    }

    final passId = 'QP${DateTime.now().millisecondsSinceEpoch}';
    final newPass = QrPass(
      id: passId,
      leaveRequestId: leaveRequestId,
      studentId: request.studentId,
      studentName: request.studentName,
      studentRollNumber: request.studentRollNumber,
      state: QrState.unused,
      validFrom: request.fromDate,
      validUntil: request.toDate,
    );

    await _db.collection('qr_passes').doc(passId).set(newPass.toFirestore());
    await _db.collection('leave_requests').doc(leaveRequestId).update({
      'qrPassId': passId,
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    });

    await _refreshCaches();
    return newPass;
  }

  // ─── Real QR scan processing ─────────────────────────
  @override
  Future<String?> processQrScan(
    String rawQrData,
    GateType gate,
    String action, {
    LaneType? laneType,
  }) async {
    final result = QrGenerationService.parseQrData(rawQrData);
    if (!result.isValid) {
      return result.error ?? 'Invalid QR code';
    }
    return scanQr(result.passId!, gate, action, laneType: laneType);
  }

  // ─── Manual verification code entry ─────────────────
  @override
  Future<(String? error, QrPass? pass)> scanQrByVerificationCode(
    String verificationCode,
    GateType gate,
    String action, {
    LaneType? laneType,
  }) async {
    final code = verificationCode.trim().toUpperCase();
    if (code.isEmpty) {
      return ('Please enter a verification code', null);
    }

    QrPass? matched;
    for (final pass in _qrPassesCache) {
      if (!pass.isActive) continue;
      final passCode = QrGenerationService.generateVerificationCode(
        pass.id,
        pass.studentId,
      );
      if (passCode == code) {
        matched = pass;
        break;
      }
    }

    if (matched == null) {
      return ('No active pass found for code "$code"', null);
    }

    final error = await scanQr(matched.id, gate, action, laneType: laneType);
    if (error != null) {
      return (error, matched);
    }

    final updated = getQrPass(matched.id);
    return (null, updated);
  }

  // ─── Overlap detection ──────────────────────────────
  @override
  List<QrPass> getOverlappingPasses(String studentId, DateTime from, DateTime to) {
    return _qrPassesCache.where((p) {
      if (p.studentId != studentId) return false;
      if (!p.isActive) return false;
      return p.validFrom.isBefore(to) && p.validUntil.isAfter(from);
    }).toList();
  }

  @override
  bool get busMode => _busMode;

  @override
  void setBusMode(bool value) {
    _busMode = value;
    notifyListeners();
  }

  // ════════════════════════════════════════════════════════
  // ADMIN / STATS — now uses caches
  // ════════════════════════════════════════════════════════

  @override
  Map<String, int> getStats() {
    return {
      'total': _leaveRequestsCache.length,
      'pending': _leaveRequestsCache
          .where((l) => l.status == LeaveStatus.pending)
          .length,
      'approved': _leaveRequestsCache
          .where((l) => l.status == LeaveStatus.approved)
          .length,
      'rejected': _leaveRequestsCache
          .where((l) => l.status == LeaveStatus.rejected)
          .length,
      'activeQr': _qrPassesCache.where((q) => q.isActive).length,
      'totalStudents':
          _usersCache.where((u) => u.role == UserRole.student).length,
    };
  }

  Future<Map<String, int>> getStatsAsync() async {
    await _refreshCaches();
    return getStats();
  }

  @override
  List<Map<String, dynamic>> getAllGateLogs() {
    final logs = <Map<String, dynamic>>[];
    for (final pass in _qrPassesCache) {
      for (final log in pass.gateLogs) {
        logs.add({
          'studentName': pass.studentName,
          'rollNumber': pass.studentRollNumber,
          'passId': pass.id,
          'gateType': log.gateType,
          'action': log.action,
          'laneType': log.laneType,
          'timestamp': log.timestamp,
          'securityId': log.securityId,
        });
      }
    }
    logs.sort(
        (a, b) => (b['timestamp'] as DateTime).compareTo(a['timestamp'] as DateTime));
    return logs;
  }

  @override
  List<Map<String, dynamic>> getAllApprovalHistory() {
    final history = <Map<String, dynamic>>[];
    for (final req in _leaveRequestsCache) {
      for (final step in req.approvalHistory) {
        history.add({
          'requestId': req.id,
          'studentName': req.studentName,
          'leaveType': req.leaveType.label,
          'approverName': step.approverName,
          'approverRole': step.approverRole,
          'action': step.action,
          'comment': step.comment,
          'timestamp': step.timestamp,
        });
      }
    }
    history.sort(
        (a, b) => (b['timestamp'] as DateTime).compareTo(a['timestamp'] as DateTime));
    return history;
  }

  @override
  Map<String, List<AppUser>> getStudentsByBlock() {
    final students =
        _usersCache.where((u) => u.role == UserRole.student).toList();
    final blocks = <String, List<AppUser>>{};
    for (final s in students) {
      final block = s.hostelBlock ?? 'Unassigned';
      blocks.putIfAbsent(block, () => []).add(s);
    }
    return blocks;
  }

  @override
  Map<String, dynamic> getTodayAttendance() {
    final today = DateTime.now();
    final todayStart = DateTime(today.year, today.month, today.day);
    int exitedHostel = 0;
    int exitedCampus = 0;
    int returned = 0;
    int stillOut = 0;

    for (final pass in _qrPassesCache) {
      final hasActivityToday = pass.gateLogs.any(
        (l) => l.timestamp.isAfter(todayStart),
      );
      if (!hasActivityToday) continue;

      switch (pass.state) {
        case QrState.hostelExited:
          exitedHostel++;
          stillOut++;
          break;
        case QrState.campusExited:
          exitedCampus++;
          stillOut++;
          break;
        case QrState.campusEntered:
          stillOut++;
          break;
        case QrState.hostelEntered:
          returned++;
          break;
        default:
          break;
      }
    }

    return {
      'exitedHostel': exitedHostel,
      'exitedCampus': exitedCampus,
      'returned': returned,
      'stillOut': stillOut,
      'total': exitedHostel + exitedCampus + returned,
    };
  }

  // ════════════════════════════════════════════════════════
  // ATTENDANCE MODULE
  // ════════════════════════════════════════════════════════

  @override
  Future<void> generateDailyAttendance() async {
    // In production, this would be a Cloud Function scheduled daily
  }

  @override
  List<AttendanceRecord> getAttendanceForDate(DateTime date) {
    return _attendanceCache
        .where((a) =>
            a.date.year == date.year &&
            a.date.month == date.month &&
            a.date.day == date.day)
        .toList();
  }

  @override
  List<AttendanceRecord> getStudentAttendance(String studentId) {
    return _attendanceCache
        .where((a) => a.studentId == studentId)
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  @override
  List<AttendanceException> getUnresolvedExceptions() => [];

  @override
  Map<AttendanceStatus, int> getAttendanceSummary(DateTime date) {
    final records = getAttendanceForDate(date);
    final summary = <AttendanceStatus, int>{};
    for (final status in AttendanceStatus.values) {
      summary[status] = records.where((r) => r.status == status).length;
    }
    return summary;
  }

  // ════════════════════════════════════════════════════════
  // MEDICAL MODULE
  // ════════════════════════════════════════════════════════

  @override
  Future<void> createMedicalRecord({
    required String studentId,
    required String symptoms,
    required String diagnosis,
    required int restDays,
    required FitnessStatus fitnessStatus,
    required bool restrictMovement,
    String? prescription,
    String? note,
  }) async {
    final officer = _currentUser!;
    final studentDoc = await _db.collection('users').doc(studentId).get();
    final student = AppUser.fromFirestore(studentDoc.data()!, studentDoc.id);

    // Find stakeholders for intimation
    final rtSnap = await _db
        .collection('users')
        .where('role', isEqualTo: 'rt')
        .limit(1)
        .get();
    final facultySnap = await _db
        .collection('users')
        .where('role', isEqualTo: 'faculty')
        .limit(1)
        .get();
    final wardenSnap = await _db
        .collection('users')
        .where('role', isEqualTo: 'warden')
        .limit(1)
        .get();
    final hodSnap = await _db
        .collection('users')
        .where('role', isEqualTo: 'hod')
        .limit(1)
        .get();

    final now = DateTime.now();
    final intimations = <Map<String, dynamic>>[];
    if (rtSnap.docs.isNotEmpty) {
      intimations.add(MedicalIntimation(
        role: 'Resident Tutor',
        personName: rtSnap.docs.first.data()['name'] ?? '',
        notifiedAt: now,
      ).toMap());
    }
    if (facultySnap.docs.isNotEmpty) {
      intimations.add(MedicalIntimation(
        role: 'Faculty Advisor',
        personName: facultySnap.docs.first.data()['name'] ?? '',
        notifiedAt: now,
      ).toMap());
    }
    if (wardenSnap.docs.isNotEmpty) {
      intimations.add(MedicalIntimation(
        role: 'Warden',
        personName: wardenSnap.docs.first.data()['name'] ?? '',
        notifiedAt: now,
      ).toMap());
    }
    if (hodSnap.docs.isNotEmpty) {
      intimations.add(MedicalIntimation(
        role: 'Head of Department',
        personName: hodSnap.docs.first.data()['name'] ?? '',
        notifiedAt: now,
      ).toMap());
    }

    final visitId = 'med_${now.millisecondsSinceEpoch}';
    final visit = MedicalVisit(
      id: visitId,
      studentId: student.uid,
      studentName: student.name,
      hostelBlock: student.hostelBlock ?? '',
      rollNumber: student.rollNumber,
      createdByOfficerId: officer.uid,
      createdByOfficerName: officer.name,
      symptoms: symptoms,
      diagnosis: diagnosis,
      restDays: restDays,
      fitnessStatus: fitnessStatus,
      status: restrictMovement
          ? MedicalStatus.medicalRestricted
          : MedicalStatus.medicalRest,
      movementRestricted: restrictMovement,
      prescription: prescription,
      medicalOfficerNote: note,
    );

    final data = visit.toFirestore();
    data['intimations'] = intimations;
    await _db.collection('medical_visits').doc(visitId).set(data);

    await _refreshMedicalVisits();
    notifyListeners();
  }

  @override
  Future<void> updateFitnessStatus({
    required String visitId,
    required FitnessStatus fitnessStatus,
    String? note,
  }) async {
    final updates = <String, dynamic>{
      'fitnessStatus': fitnessStatus.firestoreValue,
    };
    if (note != null) updates['medicalOfficerNote'] = note;
    if (fitnessStatus == FitnessStatus.fit) {
      updates['movementRestricted'] = false;
      updates['status'] = MedicalStatus.cleared.firestoreValue;
      updates['clearedAt'] = Timestamp.fromDate(DateTime.now());
      updates['clearedBy'] = _currentUser?.name ?? 'System';
    }
    await _db.collection('medical_visits').doc(visitId).update(updates);
    await _refreshMedicalVisits();
    notifyListeners();
  }

  @override
  Future<void> updateMedicalRecord({
    required String visitId,
    String? diagnosis,
    int? restDays,
    String? prescription,
    bool? restrictMovement,
    String? note,
  }) async {
    final updates = <String, dynamic>{};
    if (diagnosis != null) updates['diagnosis'] = diagnosis;
    if (restDays != null) updates['restDays'] = restDays;
    if (prescription != null) updates['prescription'] = prescription;
    if (restrictMovement != null) {
      updates['movementRestricted'] = restrictMovement;
      if (restrictMovement) {
        updates['status'] = MedicalStatus.medicalRestricted.firestoreValue;
      }
    }
    if (note != null) updates['medicalOfficerNote'] = note;
    await _db.collection('medical_visits').doc(visitId).update(updates);
    await _refreshMedicalVisits();
    notifyListeners();
  }

  @override
  Future<void> issueMedicalClearance(String visitId) async {
    await _db.collection('medical_visits').doc(visitId).update({
      'status': MedicalStatus.cleared.firestoreValue,
      'fitnessStatus': FitnessStatus.fit.firestoreValue,
      'movementRestricted': false,
      'clearedAt': Timestamp.fromDate(DateTime.now()),
      'clearedBy': _currentUser?.name ?? 'System',
      'reviewRequested': false,
    });
    await _refreshMedicalVisits();
    notifyListeners();
  }

  @override
  Future<void> requestMedicalReview({
    required String visitId,
    String? note,
  }) async {
    await _db.collection('medical_visits').doc(visitId).update({
      'reviewRequested': true,
      'reviewRequestNote': note ?? 'Student has requested a review',
      'reviewRequestedAt': Timestamp.fromDate(DateTime.now()),
    });
    await _refreshMedicalVisits();
    notifyListeners();
  }

  @override
  Future<void> acknowledgeMedicalIntimation({
    required String visitId,
    required String role,
  }) async {
    final doc = await _db.collection('medical_visits').doc(visitId).get();
    if (!doc.exists) return;

    final visit = MedicalVisit.fromFirestore(doc.data()!, doc.id);
    final intimations = visit.intimations.map((i) {
      if (i.role == role) {
        return i.copyWith(acknowledged: true, acknowledgedAt: DateTime.now());
      }
      return i;
    }).toList();

    await _db.collection('medical_visits').doc(visitId).update({
      'intimations': intimations.map((i) => i.toMap()).toList(),
    });
    await _refreshMedicalVisits();
    notifyListeners();
  }

  @override
  bool isStudentMedicalRestricted(String studentId) {
    return _medicalVisitsCache.any((m) =>
        m.studentId == studentId &&
        m.movementRestricted &&
        m.status != MedicalStatus.cleared);
  }

  @override
  FitnessStatus? getStudentFitnessStatus(String studentId) {
    final visits = _medicalVisitsCache
        .where((m) => m.studentId == studentId)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return visits.isEmpty ? null : visits.first.fitnessStatus;
  }

  @override
  List<MedicalVisit> getStudentMedicalVisits(String studentId) {
    return _medicalVisitsCache
        .where((m) => m.studentId == studentId)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  @override
  List<MedicalVisit> getAllMedicalVisits() => List.unmodifiable(_medicalVisitsCache);

  @override
  List<MedicalVisit> getReviewRequestedVisits() {
    return _medicalVisitsCache.where((m) => m.reviewRequested).toList();
  }

  @override
  List<MedicalVisit> getActiveMedicalRecords() {
    return _medicalVisitsCache
        .where((m) => m.status != MedicalStatus.cleared)
        .toList();
  }

  @override
  List<AppUser> getStudentUsers() {
    return _usersCache.where((u) => u.role == UserRole.student).toList();
  }

  Future<List<AppUser>> getStudentUsersAsync() async {
    await _refreshUsers();
    return getStudentUsers();
  }

  // ════════════════════════════════════════════════════════
  // GRIEVANCE MODULE
  // ════════════════════════════════════════════════════════

  @override
  Future<void> submitGrievance({
    required GrievanceCategory category,
    required String description,
    String? imageUrl,
  }) async {
    final user = _currentUser!;
    final id = 'grv_${DateTime.now().millisecondsSinceEpoch}';
    final grievance = Grievance(
      id: id,
      studentId: user.uid,
      studentName: user.name,
      hostelBlock: user.hostelBlock ?? '',
      roomNumber: user.roomNumber ?? '',
      category: category,
      description: description,
      status: GrievanceStatus.open,
      imageUrl: imageUrl,
      assignedTo: 'rt',
    );
    await _db
        .collection('grievances')
        .doc(id)
        .set(grievance.toFirestore());
    await _refreshGrievances();
    notifyListeners();
  }

  @override
  Future<void> respondToGrievance({
    required String grievanceId,
    required String comment,
  }) async {
    final doc =
        await _db.collection('grievances').doc(grievanceId).get();
    if (!doc.exists) return;

    final grievance = Grievance.fromFirestore(doc.data()!, doc.id);
    final action = GrievanceAction(
      actorId: _currentUser!.uid,
      actorName: _currentUser!.name,
      actorRole: _currentUser!.role.label,
      action: 'Responded',
      comment: comment,
    );

    await _db.collection('grievances').doc(grievanceId).update({
      'status': GrievanceStatus.actionTaken.firestoreValue,
      'actions': [...grievance.actions, action].map((a) => a.toMap()).toList(),
    });
    await _refreshGrievances();
    notifyListeners();
  }

  @override
  Future<void> escalateGrievance({
    required String grievanceId,
    String? reason,
  }) async {
    final doc =
        await _db.collection('grievances').doc(grievanceId).get();
    if (!doc.exists) return;

    final grievance = Grievance.fromFirestore(doc.data()!, doc.id);
    final nextLevel = grievance.escalationLevel + 1;
    final roles = ['rt', 'warden', 'admin'];
    final assignedTo =
        nextLevel < roles.length ? roles[nextLevel] : roles.last;

    final action = GrievanceAction(
      actorId: _currentUser!.uid,
      actorName: _currentUser!.name,
      actorRole: _currentUser!.role.label,
      action: 'Escalated',
      comment: reason ?? 'Escalated to ${assignedTo.toUpperCase()}',
    );

    await _db.collection('grievances').doc(grievanceId).update({
      'status': GrievanceStatus.escalated.firestoreValue,
      'escalationLevel': nextLevel,
      'assignedTo': assignedTo,
      'actions': [...grievance.actions, action].map((a) => a.toMap()).toList(),
    });
    await _refreshGrievances();
    notifyListeners();
  }

  @override
  Future<void> resolveGrievance({
    required String grievanceId,
    String? comment,
  }) async {
    final doc =
        await _db.collection('grievances').doc(grievanceId).get();
    if (!doc.exists) return;

    final grievance = Grievance.fromFirestore(doc.data()!, doc.id);
    final action = GrievanceAction(
      actorId: _currentUser!.uid,
      actorName: _currentUser!.name,
      actorRole: _currentUser!.role.label,
      action: 'Resolved',
      comment: comment ?? 'Issue resolved',
    );

    await _db.collection('grievances').doc(grievanceId).update({
      'status': GrievanceStatus.resolved.firestoreValue,
      'resolvedAt': Timestamp.fromDate(DateTime.now()),
      'actions': [...grievance.actions, action].map((a) => a.toMap()).toList(),
    });
    await _refreshGrievances();
    notifyListeners();
  }

  @override
  List<Grievance> getStudentGrievances(String studentId) {
    return _grievancesCache
        .where((g) => g.studentId == studentId)
        .toList();
  }

  @override
  List<Grievance> getGrievancesForRole(UserRole role) {
    return _grievancesCache;
  }

  @override
  List<Grievance> getAllGrievances() => List.unmodifiable(_grievancesCache);

  // ════════════════════════════════════════════════════════
  // GEOFENCE ATTENDANCE MODULE
  // ════════════════════════════════════════════════════════

  @override
  Future<GeofenceSession> openAttendanceWindow({
    required String hostelBlock,
    double lat = 12.9716,
    double lng = 77.5946,
    double radius = 100.0,
  }) async {
    final user = _currentUser!;
    final id = 'geo_${DateTime.now().millisecondsSinceEpoch}';

    // Count students in this block
    final studentsSnap = await _db
        .collection('users')
        .where('role', isEqualTo: 'student')
        .where('hostelBlock', isEqualTo: hostelBlock)
        .get();

    final session = GeofenceSession(
      id: id,
      rtId: user.uid,
      rtName: user.name,
      hostelBlock: hostelBlock,
      centerLat: lat,
      centerLng: lng,
      radiusMeters: radius,
      startTime: DateTime.now(),
      totalStudents: studentsSnap.docs.length,
    );

    await _db
        .collection('geofence_sessions')
        .doc(id)
        .set(session.toFirestore());
    await _refreshGeofenceSessions();
    notifyListeners();
    return session;
  }

  @override
  Future<void> closeAttendanceWindow(String sessionId) async {
    await _db.collection('geofence_sessions').doc(sessionId).update({
      'status': GeofenceSessionStatus.closed.firestoreValue,
      'endTime': Timestamp.fromDate(DateTime.now()),
    });
    await _refreshGeofenceSessions();
    notifyListeners();
  }

  @override
  Future<String?> markGeofenceAttendance(String sessionId) async {
    final user = _currentUser!;
    final sessionDoc =
        await _db.collection('geofence_sessions').doc(sessionId).get();
    if (!sessionDoc.exists) return 'Session not found';

    final session =
        GeofenceSession.fromFirestore(sessionDoc.data()!, sessionDoc.id);
    if (!session.isActive) return 'Session is not active';

    // Check if already marked
    final existing = await _db
        .collection('geofence_checkins')
        .where('sessionId', isEqualTo: sessionId)
        .where('studentId', isEqualTo: user.uid)
        .get();
    if (existing.docs.isNotEmpty) return 'Already marked';

    final checkInId = 'chk_${DateTime.now().millisecondsSinceEpoch}';
    final checkIn = GeofenceCheckIn(
      id: checkInId,
      sessionId: sessionId,
      studentId: user.uid,
      studentName: user.name,
      rollNumber: user.rollNumber ?? '',
      hostelBlock: user.hostelBlock ?? '',
    );

    await _db
        .collection('geofence_checkins')
        .doc(checkInId)
        .set(checkIn.toFirestore());

    // Increment marked count
    await _db.collection('geofence_sessions').doc(sessionId).update({
      'markedCount': FieldValue.increment(1),
    });

    await Future.wait([_refreshGeofenceSessions(), _refreshGeofenceCheckIns()]);
    notifyListeners();
    return null;
  }

  @override
  GeofenceSession? getActiveSession(String hostelBlock) {
    try {
      return _geofenceSessionsCache.firstWhere(
        (s) => s.hostelBlock == hostelBlock && s.isActive,
      );
    } catch (_) {
      return null;
    }
  }

  @override
  List<GeofenceSession> getBlockSessions(String hostelBlock) {
    return _geofenceSessionsCache
        .where((s) => s.hostelBlock == hostelBlock)
        .toList();
  }

  @override
  List<GeofenceCheckIn> getSessionCheckIns(String sessionId) {
    return _geofenceCheckInsCache
        .where((c) => c.sessionId == sessionId)
        .toList();
  }

  @override
  bool hasStudentMarkedAttendance(String sessionId, String studentId) {
    return _geofenceCheckInsCache.any(
        (c) => c.sessionId == sessionId && c.studentId == studentId);
  }

  @override
  double getStudentGeofencePercentage(String studentId) {
    final totalSessions = _geofenceSessionsCache
        .where((s) => s.status == GeofenceSessionStatus.closed)
        .length;
    if (totalSessions == 0) return 0.0;
    final attended = _geofenceCheckInsCache
        .where((c) => c.studentId == studentId)
        .length;
    return (attended / totalSessions) * 100;
  }

  @override
  List<StudentAttendanceSummary> getBlockAttendanceSummary(
          String hostelBlock) =>
      [];

  @override
  List<StudentAttendanceSummary> getDepartmentAttendancePatterns(
          String department) =>
      [];

  @override
  Future<void> raiseAttendanceAnomaly({
    required String studentId,
    required AnomalyType type,
    required String description,
  }) async {
    final user = _currentUser!;
    final studentDoc = await _db.collection('users').doc(studentId).get();
    final student = AppUser.fromFirestore(studentDoc.data()!, studentDoc.id);

    final id = 'anm_${DateTime.now().millisecondsSinceEpoch}';
    final anomaly = AttendanceAnomaly(
      id: id,
      studentId: student.uid,
      studentName: student.name,
      rollNumber: student.rollNumber ?? '',
      hostelBlock: student.hostelBlock ?? '',
      type: type,
      description: description,
      raisedById: user.uid,
      raisedByName: user.name,
    );

    await _db.collection('attendance_anomalies').doc(id).set({
      'studentId': anomaly.studentId,
      'studentName': anomaly.studentName,
      'rollNumber': anomaly.rollNumber,
      'hostelBlock': anomaly.hostelBlock,
      'type': anomaly.type.name,
      'description': anomaly.description,
      'raisedById': anomaly.raisedById,
      'raisedByName': anomaly.raisedByName,
      'raisedAt': Timestamp.fromDate(anomaly.raisedAt),
      'parentNotified': true,
      'resolved': false,
    });
    await _refreshAnomalies();
    notifyListeners();
  }

  @override
  List<AttendanceAnomaly> getAnomaliesForStudent(String studentId) {
    return _anomaliesCache
        .where((a) => a.studentId == studentId)
        .toList();
  }

  @override
  List<AttendanceAnomaly> getAllAnomalies() =>
      List.unmodifiable(_anomaliesCache);

  @override
  int getUnresolvedAnomalyCount(String hostelBlock) {
    return _anomaliesCache
        .where((a) => a.hostelBlock == hostelBlock && !a.resolved)
        .length;
  }

  @override
  Future<void> resolveAnomaly({
    required String anomalyId,
    String? response,
  }) async {
    await _db.collection('attendance_anomalies').doc(anomalyId).update({
      'resolved': true,
      'parentResponse': response,
      'resolvedAt': Timestamp.fromDate(DateTime.now()),
    });
    await _refreshAnomalies();
    notifyListeners();
  }

  @override
  List<GeofenceSession> getAllGeofenceSessions() =>
      List.unmodifiable(_geofenceSessionsCache);

  @override
  Map<String, dynamic> getGeofenceAttendanceStats() {
    final totalSessions = _geofenceSessionsCache.length;
    final totalCheckIns = _geofenceCheckInsCache.length;
    final closedSessions = _geofenceSessionsCache
        .where((s) => s.status == GeofenceSessionStatus.closed)
        .toList();
    double avgAttendance = 0;
    if (closedSessions.isNotEmpty) {
      final total = closedSessions.fold<int>(
          0, (sum, s) => sum + s.totalStudents);
      if (total > 0) {
        avgAttendance = (totalCheckIns / total) * 100;
      }
    }
    return {
      'totalSessions': totalSessions,
      'avgAttendance': avgAttendance,
      'totalCheckIns': totalCheckIns,
      'unresolvedAnomalies': _anomaliesCache.where((a) => !a.resolved).length,
    };
  }

  // ════════════════════════════════════════════════════════
  // AUDIT LOGGING
  // ════════════════════════════════════════════════════════

  /// Write an audit log entry to the `audit_logs` Firestore collection.
  Future<void> _writeAuditLog({
    required String action,
    required String actorId,
    required String actorName,
    required String actorRole,
    required String targetId,
    required String details,
  }) async {
    try {
      await _db.collection('audit_logs').add({
        'action': action,
        'actorId': actorId,
        'actorName': actorName,
        'actorRole': actorRole,
        'targetId': targetId,
        'details': details,
        'timestamp': Timestamp.fromDate(DateTime.now()),
      });
    } catch (_) {
      // Audit logging should never break the main flow
    }
  }
}
