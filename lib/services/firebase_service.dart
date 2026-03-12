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

/// Production Firebase service implementing [AppService].
/// Uses Firebase Auth for authentication and Cloud Firestore for data.
class FirebaseService extends AppService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  AppUser? _currentUser;
  bool _busMode = false;

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
    notifyListeners();
  }

  // ════════════════════════════════════════════════════════
  // LEAVE REQUESTS
  // ════════════════════════════════════════════════════════

  @override
  List<LeaveRequest> get leaveRequests => []; // Use stream or fetch methods instead

  /// Async version to fetch all leave requests.
  Future<List<LeaveRequest>> getAllLeaveRequestsAsync() async {
    final snap = await _db
        .collection('leave_requests')
        .orderBy('createdAt', descending: true)
        .get();
    return snap.docs
        .map((d) => LeaveRequest.fromFirestore(d.data(), d.id))
        .toList();
  }

  @override
  List<LeaveRequest> getStudentLeaves(String studentId) {
    // For synchronous compatibility, return empty.
    // Use getStudentLeavesAsync for production.
    return [];
  }

  /// Async version for production use.
  Future<List<LeaveRequest>> getStudentLeavesAsync(String studentId) async {
    final snap = await _db
        .collection('leave_requests')
        .where('studentId', isEqualTo: studentId)
        .orderBy('createdAt', descending: true)
        .get();
    return snap.docs
        .map((d) => LeaveRequest.fromFirestore(d.data(), d.id))
        .toList();
  }

  @override
  List<LeaveRequest> getPendingApprovalsForRole(UserRole role) {
    return [];
  }

  Future<List<LeaveRequest>> getPendingApprovalsForRoleAsync(
      UserRole role) async {
    final List<String> statusFilters;
    switch (role) {
      case UserRole.rt:
        statusFilters = ['pending', 'returned_to_rt'];
        break;
      case UserRole.parent:
        statusFilters = ['forwarded_to_parent'];
        break;
      case UserRole.hod:
        statusFilters = ['forwarded_to_hod', 'awaiting_hod_after_faculty'];
        break;
      case UserRole.warden:
        statusFilters = ['forwarded_to_warden'];
        break;
      case UserRole.faculty:
        statusFilters = ['forwarded_to_faculty'];
        break;
      default:
        return [];
    }

    final snap = await _db
        .collection('leave_requests')
        .where('status', whereIn: statusFilters)
        .get();
    return snap.docs
        .map((d) => LeaveRequest.fromFirestore(d.data(), d.id))
        .toList();
  }

  @override
  Future<void> createLeaveRequest(LeaveRequest request) async {
    await _db
        .collection('leave_requests')
        .doc(request.id)
        .set(request.toFirestore());
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
    notifyListeners();
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
    notifyListeners();
  }

  // ════════════════════════════════════════════════════════
  // QR PASSES & GATE
  // ════════════════════════════════════════════════════════

  @override
  List<QrPass> get qrPasses => [];

  @override
  QrPass? getQrPass(String passId) {
    return null; // Use async version
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
    return [];
  }

  Future<List<QrPass>> getStudentPassesAsync(String studentId) async {
    final snap = await _db
        .collection('qr_passes')
        .where('studentId', isEqualTo: studentId)
        .get();
    return snap.docs
        .map((d) => QrPass.fromFirestore(d.data(), d.id))
        .toList();
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

    notifyListeners();
    return newPass;
  }

  @override
  bool get busMode => _busMode;

  @override
  void setBusMode(bool value) {
    _busMode = value;
    notifyListeners();
  }

  // ════════════════════════════════════════════════════════
  // ADMIN / STATS
  // ════════════════════════════════════════════════════════

  @override
  Map<String, int> getStats() {
    return {
      'total': 0,
      'pending': 0,
      'approved': 0,
      'rejected': 0,
      'activeQr': 0,
      'totalStudents': 0,
    };
  }

  Future<Map<String, int>> getStatsAsync() async {
    final leaves = await _db.collection('leave_requests').get();
    final qr = await _db
        .collection('qr_passes')
        .where('state', whereNotIn: ['expired', 'hostel_entered']).get();
    final students = await _db
        .collection('users')
        .where('role', isEqualTo: 'student')
        .get();

    return {
      'total': leaves.docs.length,
      'pending': leaves.docs
          .where((d) => d.data()['status'] == 'pending')
          .length,
      'approved': leaves.docs
          .where((d) => d.data()['status'] == 'approved')
          .length,
      'rejected': leaves.docs
          .where((d) => d.data()['status'] == 'rejected')
          .length,
      'activeQr': qr.docs.length,
      'totalStudents': students.docs.length,
    };
  }

  @override
  List<Map<String, dynamic>> getAllGateLogs() => [];

  @override
  List<Map<String, dynamic>> getAllApprovalHistory() => [];

  @override
  Map<String, List<AppUser>> getStudentsByBlock() => {};

  @override
  Map<String, dynamic> getTodayAttendance() => {
        'exitedHostel': 0,
        'exitedCampus': 0,
        'returned': 0,
        'stillOut': 0,
        'total': 0,
      };

  // ════════════════════════════════════════════════════════
  // ATTENDANCE MODULE
  // ════════════════════════════════════════════════════════

  @override
  Future<void> generateDailyAttendance() async {
    // In production, this would be a Cloud Function scheduled daily
  }

  @override
  List<AttendanceRecord> getAttendanceForDate(DateTime date) => [];

  @override
  List<AttendanceRecord> getStudentAttendance(String studentId) => [];

  @override
  List<AttendanceException> getUnresolvedExceptions() => [];

  @override
  Map<AttendanceStatus, int> getAttendanceSummary(DateTime date) => {};

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
    notifyListeners();
  }

  @override
  bool isStudentMedicalRestricted(String studentId) {
    return false; // Use async version for production
  }

  @override
  FitnessStatus? getStudentFitnessStatus(String studentId) {
    return null;
  }

  @override
  List<MedicalVisit> getStudentMedicalVisits(String studentId) => [];

  @override
  List<MedicalVisit> getAllMedicalVisits() => [];

  @override
  List<MedicalVisit> getReviewRequestedVisits() => [];

  @override
  List<MedicalVisit> getActiveMedicalRecords() => [];

  @override
  List<AppUser> getStudentUsers() => [];

  Future<List<AppUser>> getStudentUsersAsync() async {
    final snap = await _db
        .collection('users')
        .where('role', isEqualTo: 'student')
        .get();
    return snap.docs
        .map((d) => AppUser.fromFirestore(d.data(), d.id))
        .toList();
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
    notifyListeners();
  }

  @override
  List<Grievance> getStudentGrievances(String studentId) => [];

  @override
  List<Grievance> getGrievancesForRole(UserRole role) => [];

  @override
  List<Grievance> getAllGrievances() => [];

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
    notifyListeners();
    return session;
  }

  @override
  Future<void> closeAttendanceWindow(String sessionId) async {
    await _db.collection('geofence_sessions').doc(sessionId).update({
      'status': GeofenceSessionStatus.closed.firestoreValue,
      'endTime': Timestamp.fromDate(DateTime.now()),
    });
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

    notifyListeners();
    return null;
  }

  @override
  GeofenceSession? getActiveSession(String hostelBlock) {
    return null; // Use async version
  }

  @override
  List<GeofenceSession> getBlockSessions(String hostelBlock) => [];

  @override
  List<GeofenceCheckIn> getSessionCheckIns(String sessionId) => [];

  @override
  bool hasStudentMarkedAttendance(String sessionId, String studentId) {
    return false;
  }

  @override
  double getStudentGeofencePercentage(String studentId) => 0.0;

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
    notifyListeners();
  }

  @override
  List<AttendanceAnomaly> getAnomaliesForStudent(String studentId) => [];

  @override
  List<AttendanceAnomaly> getAllAnomalies() => [];

  @override
  int getUnresolvedAnomalyCount(String hostelBlock) => 0;

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
    notifyListeners();
  }

  @override
  List<GeofenceSession> getAllGeofenceSessions() => [];

  @override
  Map<String, dynamic> getGeofenceAttendanceStats() => {
        'totalSessions': 0,
        'avgAttendance': 0.0,
        'totalCheckIns': 0,
        'unresolvedAnomalies': 0,
      };
}
