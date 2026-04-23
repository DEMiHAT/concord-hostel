import 'package:flutter/material.dart';
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

/// Mock authentication and data service for demo purposes.
/// Replace with actual Firebase calls when Firebase is configured.
class MockService extends AppService {
  AppUser? _currentUser;
  final List<LeaveRequest> _leaveRequests = [];
  final List<QrPass> _qrPasses = [];
  final List<AppUser> _users = [];
  bool _busMode = false;
  final List<AttendanceRecord> _attendanceRecords = [];
  final List<AttendanceException> _attendanceExceptions = [];
  final List<MedicalVisit> _medicalVisits = [];
  final List<Grievance> _grievances = [];
  final List<GeofenceSession> _geofenceSessions = [];
  final List<GeofenceCheckIn> _geofenceCheckIns = [];
  final List<AttendanceAnomaly> _attendanceAnomalies = [];

  AppUser? get currentUser => _currentUser;
  List<LeaveRequest> get leaveRequests => List.unmodifiable(_leaveRequests);
  List<QrPass> get qrPasses => List.unmodifiable(_qrPasses);
  List<AppUser> get users => List.unmodifiable(_users);
  bool get busMode => _busMode;
  List<AttendanceRecord> get attendanceRecords => List.unmodifiable(_attendanceRecords);
  List<AttendanceException> get attendanceExceptions => List.unmodifiable(_attendanceExceptions);
  List<MedicalVisit> get medicalVisits => List.unmodifiable(_medicalVisits);
  List<Grievance> get grievances => List.unmodifiable(_grievances);
  List<GeofenceSession> get geofenceSessions => List.unmodifiable(_geofenceSessions);
  List<GeofenceCheckIn> get geofenceCheckIns => List.unmodifiable(_geofenceCheckIns);
  List<AttendanceAnomaly> get attendanceAnomalies => List.unmodifiable(_attendanceAnomalies);

  void setBusMode(bool value) {
    _busMode = value;
    notifyListeners();
  }

  MockService() {
    _initMockData();
  }

  void _initMockData() {
    // Mock users
    _users.addAll([
      AppUser(
        uid: 'student1',
        name: 'Arjun Mehta',
        email: 'arjun@university.edu',
        role: UserRole.student,
        rollNumber: 'CS21B1045',
        hostelBlock: 'Block A',
        roomNumber: 'A-204',
        department: 'Computer Science',
        phone: '+91 98765 43210',
        parentPhone: '+91 98765 43211',
      ),
      AppUser(
        uid: 'rt1',
        name: 'Dr. Priya Sharma',
        email: 'priya.rt@university.edu',
        role: UserRole.rt,
        hostelBlock: 'Block A',
        department: 'Computer Science',
      ),
      AppUser(
        uid: 'parent1',
        name: 'Rajesh Mehta',
        email: 'rajesh.mehta@gmail.com',
        role: UserRole.parent,
        phone: '+91 98765 43211',
      ),
      AppUser(
        uid: 'hod1',
        name: 'Prof. Vikram Singh',
        email: 'vikram.hod@university.edu',
        role: UserRole.hod,
        department: 'Computer Science',
      ),
      AppUser(
        uid: 'warden1',
        name: 'Mr. Suresh Kumar',
        email: 'suresh.warden@university.edu',
        role: UserRole.warden,
        hostelBlock: 'Block A',
      ),
      AppUser(
        uid: 'faculty1',
        name: 'Dr. Anita Patel',
        email: 'anita.faculty@university.edu',
        role: UserRole.faculty,
        department: 'Computer Science',
      ),
      AppUser(
        uid: 'security1',
        name: 'Ram Singh',
        email: 'ram.security@university.edu',
        role: UserRole.security,
      ),
      AppUser(
        uid: 'admin1',
        name: 'System Admin',
        email: 'admin@university.edu',
        role: UserRole.admin,
      ),
      AppUser(
        uid: 'medofficer1',
        name: 'Dr. Kavitha Nair',
        email: 'kavitha.medical@university.edu',
        role: UserRole.medicalOfficer,
        department: 'Health Services',
      ),
      // Additional students for attendance module
      AppUser(
        uid: 'student2',
        name: 'Neha Kumar',
        email: 'neha@university.edu',
        role: UserRole.student,
        rollNumber: 'CS21B1046',
        hostelBlock: 'Block A',
        roomNumber: 'A-210',
        department: 'Computer Science',
        phone: '+91 98765 43212',
        parentPhone: '+91 98765 43213',
      ),
      AppUser(
        uid: 'student3',
        name: 'Rahul Verma',
        email: 'rahul@university.edu',
        role: UserRole.student,
        rollNumber: 'CS21B1047',
        hostelBlock: 'Block A',
        roomNumber: 'A-305',
        department: 'Computer Science',
        phone: '+91 98765 43214',
        parentPhone: '+91 98765 43215',
      ),
      AppUser(
        uid: 'student4',
        name: 'Priya Patel',
        email: 'priyap@university.edu',
        role: UserRole.student,
        rollNumber: 'EC21B1012',
        hostelBlock: 'Block A',
        roomNumber: 'A-108',
        department: 'Electronics',
        phone: '+91 98765 43216',
        parentPhone: '+91 98765 43217',
      ),
      AppUser(
        uid: 'student5',
        name: 'Aditya Singh',
        email: 'aditya@university.edu',
        role: UserRole.student,
        rollNumber: 'ME21B1005',
        hostelBlock: 'Block A',
        roomNumber: 'A-412',
        department: 'Mechanical',
        phone: '+91 98765 43218',
        parentPhone: '+91 98765 43219',
      ),
      AppUser(
        uid: 'student6',
        name: 'Kavya Sharma',
        email: 'kavya@university.edu',
        role: UserRole.student,
        rollNumber: 'CS21B1048',
        hostelBlock: 'Block A',
        roomNumber: 'A-202',
        department: 'Computer Science',
        phone: '+91 98765 43220',
        parentPhone: '+91 98765 43221',
      ),
    ]);

    // Mock leave requests
    final now = DateTime.now();
    _leaveRequests.addAll([
      LeaveRequest(
        id: 'lr1',
        studentId: 'student1',
        studentName: 'Arjun Mehta',
        studentRollNumber: 'CS21B1045',
        hostelBlock: 'Block A',
        roomNumber: 'A-204',
        leaveType: LeaveType.dayPass,
        status: LeaveStatus.approved,
        reason: 'Medical appointment at city hospital',
        fromDate: now.subtract(const Duration(days: 1)),
        toDate: now.subtract(const Duration(days: 1)),
        createdAt: now.subtract(const Duration(days: 2)),
        qrPassId: 'qr1',
        approvalHistory: [
          ApprovalStep(
            approverId: 'rt1',
            approverName: 'Dr. Priya Sharma',
            approverRole: 'RT',
            action: 'approved',
            comment: 'Valid medical reason',
            timestamp: now.subtract(const Duration(days: 1, hours: 20)),
          ),
        ],
      ),
      LeaveRequest(
        id: 'lr2',
        studentId: 'student1',
        studentName: 'Arjun Mehta',
        studentRollNumber: 'CS21B1045',
        hostelBlock: 'Block A',
        roomNumber: 'A-204',
        leaveType: LeaveType.weekend,
        status: LeaveStatus.forwardedToParent,
        reason: 'Family gathering at home',
        fromDate: now.add(const Duration(days: 3)),
        toDate: now.add(const Duration(days: 5)),
        createdAt: now.subtract(const Duration(hours: 6)),
        approvalHistory: [
          ApprovalStep(
            approverId: 'rt1',
            approverName: 'Dr. Priya Sharma',
            approverRole: 'RT',
            action: 'forwarded',
            comment: 'Forwarded to parent for approval',
            timestamp: now.subtract(const Duration(hours: 3)),
          ),
        ],
      ),
      LeaveRequest(
        id: 'lr3',
        studentId: 'student1',
        studentName: 'Arjun Mehta',
        studentRollNumber: 'CS21B1045',
        hostelBlock: 'Block A',
        roomNumber: 'A-204',
        leaveType: LeaveType.emergency,
        status: LeaveStatus.pending,
        reason: 'Urgent family emergency - grandmother hospitalized',
        fromDate: now,
        toDate: now.add(const Duration(days: 2)),
        createdAt: now.subtract(const Duration(minutes: 30)),
      ),
      LeaveRequest(
        id: 'lr4',
        studentId: 'student1',
        studentName: 'Arjun Mehta',
        studentRollNumber: 'CS21B1045',
        hostelBlock: 'Block A',
        roomNumber: 'A-204',
        leaveType: LeaveType.academic,
        status: LeaveStatus.rejected,
        reason: 'Conference attendance in Bangalore',
        fromDate: now.subtract(const Duration(days: 10)),
        toDate: now.subtract(const Duration(days: 8)),
        createdAt: now.subtract(const Duration(days: 12)),
        rejectionReason: 'Insufficient academic justification',
        approvalHistory: [
          ApprovalStep(
            approverId: 'rt1',
            approverName: 'Dr. Priya Sharma',
            approverRole: 'RT',
            action: 'rejected',
            comment: 'Insufficient academic justification',
            timestamp: now.subtract(const Duration(days: 11)),
          ),
        ],
      ),
      LeaveRequest(
        id: 'lr5',
        studentId: 'student1',
        studentName: 'Arjun Mehta',
        studentRollNumber: 'CS21B1045',
        hostelBlock: 'Block A',
        roomNumber: 'A-204',
        leaveType: LeaveType.overnight,
        status: LeaveStatus.approved,
        reason: 'Visiting family for mother\'s birthday',
        fromDate: now.add(const Duration(days: 1)),
        toDate: now.add(const Duration(days: 2)),
        createdAt: now.subtract(const Duration(days: 3)),
        qrPassId: 'qr2',
        approvalHistory: [
          ApprovalStep(
            approverId: 'rt1',
            approverName: 'Dr. Priya Sharma',
            approverRole: 'RT',
            action: 'approved',
            timestamp: now.subtract(const Duration(days: 2, hours: 12)),
          ),
          ApprovalStep(
            approverId: 'parent1',
            approverName: 'Rajesh Mehta',
            approverRole: 'Parent',
            action: 'approved',
            timestamp: now.subtract(const Duration(days: 2)),
          ),
        ],
      ),
    ]);

    // Mock QR passes
    _qrPasses.addAll([
      QrPass(
        id: 'qr1',
        leaveRequestId: 'lr1',
        studentId: 'student1',
        studentName: 'Arjun Mehta',
        studentRollNumber: 'CS21B1045',
        state: QrState.hostelEntered,
        validFrom: now.subtract(const Duration(days: 1, hours: 8)),
        validUntil: now.subtract(const Duration(days: 1)).add(const Duration(hours: 20)),
        gateLogs: [
          GateLog(
            gateType: 'hostel',
            action: 'exit',
            securityId: 'security1',
            laneType: 'scanLane',
            timestamp: now.subtract(const Duration(days: 1, hours: 6)),
          ),
          GateLog(
            gateType: 'main',
            action: 'exit',
            securityId: 'security1',
            timestamp: now.subtract(const Duration(days: 1, hours: 5, minutes: 50)),
          ),
          GateLog(
            gateType: 'main',
            action: 'entry',
            securityId: 'security1',
            timestamp: now.subtract(const Duration(hours: 18)),
          ),
          GateLog(
            gateType: 'hostel',
            action: 'entry',
            securityId: 'security1',
            laneType: 'scanLane',
            timestamp: now.subtract(const Duration(hours: 17, minutes: 50)),
          ),
        ],
      ),
      QrPass(
        id: 'qr2',
        leaveRequestId: 'lr5',
        studentId: 'student1',
        studentName: 'Arjun Mehta',
        studentRollNumber: 'CS21B1045',
        state: QrState.unused,
        validFrom: now.add(const Duration(days: 1)),
        validUntil: now.add(const Duration(days: 2, hours: 20)),
      ),
    ]);

    // Seed geofence attendance data
    _initGeofenceData();
  }

  // Auth methods
  @override
  Future<AppUser?> loginWithRole(UserRole role) async {
    await Future.delayed(const Duration(milliseconds: 800));
    _currentUser = _users.firstWhere((u) => u.role == role);
    notifyListeners();
    return _currentUser;
  }

  @override
  Future<AppUser?> loginWithEmail(String email, String password) async {
    // Not supported in demo mode
    return null;
  }

  void logout() {
    _currentUser = null;
    notifyListeners();
  }

  // Leave request methods
  List<LeaveRequest> getStudentLeaves(String studentId) {
    return _leaveRequests.where((l) => l.studentId == studentId).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  List<LeaveRequest> getPendingApprovalsForRole(UserRole role) {
    switch (role) {
      case UserRole.rt:
        return _leaveRequests
            .where(
              (l) =>
                  l.status == LeaveStatus.pending ||
                  l.status == LeaveStatus.returnedToRt,
            )
            .toList();
      case UserRole.parent:
        return _leaveRequests
            .where((l) => l.status == LeaveStatus.forwardedToParent)
            .toList();
      case UserRole.hod:
        return _leaveRequests
            .where(
              (l) =>
                  l.status == LeaveStatus.forwardedToHod ||
                  l.status == LeaveStatus.awaitingHodAfterFaculty,
            )
            .toList();
      case UserRole.warden:
        return _leaveRequests
            .where((l) => l.status == LeaveStatus.forwardedToWarden)
            .toList();
      case UserRole.faculty:
        return _leaveRequests
            .where((l) => l.status == LeaveStatus.forwardedToFaculty)
            .toList();
      default:
        return [];
    }
  }

  Future<void> createLeaveRequest(LeaveRequest request) async {
    await Future.delayed(const Duration(milliseconds: 500));
    _leaveRequests.add(request);
    notifyListeners();
  }

  Future<void> approveRequest(String requestId, String approverId,
      String approverName, String role) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final index = _leaveRequests.indexWhere((l) => l.id == requestId);
    if (index == -1) return;

    final request = _leaveRequests[index];
    final step = ApprovalStep(
      approverId: approverId,
      approverName: approverName,
      approverRole: role,
      action: 'approved',
    );

    LeaveStatus newStatus = _getNextApprovalStatus(request);
    final updatedHistory = [...request.approvalHistory, step];

    String? qrPassId;
    if (newStatus == LeaveStatus.approved) {
      qrPassId = 'qr_${DateTime.now().millisecondsSinceEpoch}';
      _qrPasses.add(QrPass(
        id: qrPassId,
        leaveRequestId: requestId,
        studentId: request.studentId,
        studentName: request.studentName,
        studentRollNumber: request.studentRollNumber,
        state: QrState.unused,
        validFrom: request.fromDate,
        validUntil: request.toDate,
      ));
    }

    _leaveRequests[index] = request.copyWith(
      status: newStatus,
      updatedAt: DateTime.now(),
      approvalHistory: updatedHistory,
      qrPassId: qrPassId,
    );
    notifyListeners();
  }

  Future<void> rejectRequest(
    String requestId,
    String approverId,
    String approverName,
    String role,
    String reason,
  ) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final index = _leaveRequests.indexWhere((l) => l.id == requestId);
    if (index == -1) return;

    final request = _leaveRequests[index];
    final step = ApprovalStep(
      approverId: approverId,
      approverName: approverName,
      approverRole: role,
      action: 'rejected',
      comment: reason,
    );

    _leaveRequests[index] = request.copyWith(
      status: LeaveStatus.rejected,
      rejectionReason: reason,
      updatedAt: DateTime.now(),
      approvalHistory: [...request.approvalHistory, step],
    );
    notifyListeners();
  }

  /// Faculty can request documents from student
  Future<void> requestDocuments(
    String requestId,
    String approverId,
    String approverName,
    String comment,
  ) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final index = _leaveRequests.indexWhere((l) => l.id == requestId);
    if (index == -1) return;

    final request = _leaveRequests[index];
    final step = ApprovalStep(
      approverId: approverId,
      approverName: approverName,
      approverRole: 'Faculty',
      action: 'documents_requested',
      comment: comment,
    );

    _leaveRequests[index] = request.copyWith(
      status: LeaveStatus.documentsRequested,
      updatedAt: DateTime.now(),
      approvalHistory: [...request.approvalHistory, step],
    );
    notifyListeners();
  }

  /// Student uploads documents and resubmits to faculty
  Future<void> submitDocuments(
    String requestId,
    List<String> documentUrls,
  ) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final index = _leaveRequests.indexWhere((l) => l.id == requestId);
    if (index == -1) return;

    final request = _leaveRequests[index];
    final step = ApprovalStep(
      approverId: request.studentId,
      approverName: request.studentName,
      approverRole: 'Student',
      action: 'documents_submitted',
      comment: 'Uploaded ${documentUrls.length} document(s)',
    );

    _leaveRequests[index] = request.copyWith(
      status: LeaveStatus.forwardedToFaculty,
      updatedAt: DateTime.now(),
      proofDocumentUrls: [...request.proofDocumentUrls, ...documentUrls],
      approvalHistory: [...request.approvalHistory, step],
    );
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
          // Last step: Parent/Warden — use forwardedToWarden since it covers both
          return LeaveStatus.forwardedToWarden;
        }
        if (request.status == LeaveStatus.forwardedToWarden) {
          return LeaveStatus.approved;
        }
        return LeaveStatus.approved;
    }
  }

  // QR Pass Generation
  @override
  Future<QrPass?> generateQrPass(String leaveRequestId) async {
    await Future.delayed(const Duration(milliseconds: 500));

    final reqIndex = _leaveRequests.indexWhere((l) => l.id == leaveRequestId);
    if (reqIndex == -1) return null;

    final request = _leaveRequests[reqIndex];

    // Only generate for approved requests
    if (request.status != LeaveStatus.approved) return null;

    // Check if already has a pass
    if (request.qrPassId != null) {
      return getQrPass(request.qrPassId!);
    }

    // Generate new pass
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

    _qrPasses.add(newPass);

    // Link pass to leave request
    _leaveRequests[reqIndex] = request.copyWith(
      qrPassId: passId,
      updatedAt: DateTime.now(),
    );

    notifyListeners();
    return newPass;
  }

  // QR methods
  QrPass? getQrPass(String passId) {
    try {
      return _qrPasses.firstWhere((q) => q.id == passId);
    } catch (_) {
      return null;
    }
  }

  List<QrPass> getStudentPasses(String studentId) {
    return _qrPasses.where((q) => q.studentId == studentId).toList();
  }

  Future<String?> scanQr(String passId, GateType gate, String action, {LaneType? laneType}) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final index = _qrPasses.indexWhere((q) => q.id == passId);
    if (index == -1) return 'Pass not found';

    final pass = _qrPasses[index];
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
        // Student changed mind before reaching main gate — return to unused
        newState = QrState.unused;
      } else if (pass.state == QrState.unused) {
        // Already unused, cancel
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

    _qrPasses[index] = pass.copyWith(
      state: newState,
      gateLogs: [...pass.gateLogs, log],
    );
    notifyListeners();
    return null;
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
    // Delegate to the existing state-machine method
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

    // Search all active passes for the matching verification code
    QrPass? matched;
    for (final pass in _qrPasses) {
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

    // Return the updated pass
    final updated = getQrPass(matched.id);
    return (null, updated);
  }

  // ─── Overlap detection ──────────────────────────────
  @override
  List<QrPass> getOverlappingPasses(String studentId, DateTime from, DateTime to) {
    return _qrPasses.where((p) {
      if (p.studentId != studentId) return false;
      if (!p.isActive) return false;
      // Check overlap: pass.validFrom < to AND pass.validUntil > from
      return p.validFrom.isBefore(to) && p.validUntil.isAfter(from);
    }).toList();
  }

  // Stats
  Map<String, int> getStats() {
    return {
      'total': _leaveRequests.length,
      'pending': _leaveRequests.where((l) => l.status == LeaveStatus.pending).length,
      'approved': _leaveRequests.where((l) => l.status == LeaveStatus.approved).length,
      'rejected': _leaveRequests.where((l) => l.status == LeaveStatus.rejected).length,
      'activeQr': _qrPasses.where((q) => q.isActive).length,
      'totalStudents': _users.where((u) => u.role == UserRole.student).length,
    };
  }

  /// Get all gate logs across all passes for admin audit view
  List<Map<String, dynamic>> getAllGateLogs() {
    final logs = <Map<String, dynamic>>[];
    for (final pass in _qrPasses) {
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
    logs.sort((a, b) => (b['timestamp'] as DateTime).compareTo(a['timestamp'] as DateTime));
    return logs;
  }

  /// Get all approval steps across all requests for admin audit
  List<Map<String, dynamic>> getAllApprovalHistory() {
    final history = <Map<String, dynamic>>[];
    for (final req in _leaveRequests) {
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
    history.sort((a, b) => (b['timestamp'] as DateTime).compareTo(a['timestamp'] as DateTime));
    return history;
  }

  /// Get students by block for admin block management
  Map<String, List<AppUser>> getStudentsByBlock() {
    final students = _users.where((u) => u.role == UserRole.student).toList();
    final blocks = <String, List<AppUser>>{};
    for (final s in students) {
      final block = s.hostelBlock ?? 'Unassigned';
      blocks.putIfAbsent(block, () => []).add(s);
    }
    return blocks;
  }

  /// Get today's attendance from gate logs
  Map<String, dynamic> getTodayAttendance() {
    final today = DateTime.now();
    final todayStart = DateTime(today.year, today.month, today.day);
    int exitedHostel = 0;
    int exitedCampus = 0;
    int returned = 0;
    int stillOut = 0;

    for (final pass in _qrPasses) {
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

  /// Generate daily attendance for all students (scheduler logic)
  Future<void> generateDailyAttendance() async {
    await Future.delayed(const Duration(milliseconds: 500));
    final today = DateTime.now();
    final studentUsers = _users.where((u) => u.role == UserRole.student);

    for (final student in studentUsers) {
      // Check if already generated for today
      final existing = _attendanceRecords.where((a) =>
          a.studentId == student.uid &&
          a.date.year == today.year &&
          a.date.month == today.month &&
          a.date.day == today.day);
      if (existing.isNotEmpty) continue;

      // Determine status based on movement data
      AttendanceStatus status;
      String derivedFrom;

      // 1. Check medical restriction
      final medRestricted = _medicalVisits.any((m) =>
          m.studentId == student.uid &&
          m.movementRestricted &&
          m.status != MedicalStatus.cleared);
      if (medRestricted) {
        status = AttendanceStatus.medicalRestricted;
        derivedFrom = 'medical';
      }
      // 2. Check active approved leave
      else if (_leaveRequests.any((l) =>
          l.studentId == student.uid &&
          l.status == LeaveStatus.approved &&
          l.fromDate.isBefore(today) &&
          l.toDate.isAfter(today))) {
        final leave = _leaveRequests.firstWhere((l) =>
            l.studentId == student.uid &&
            l.status == LeaveStatus.approved &&
            l.fromDate.isBefore(today) &&
            l.toDate.isAfter(today));
        if (leave.leaveType == LeaveType.workingDayHoliday) {
          status = AttendanceStatus.nonResident;
          derivedFrom = 'holiday_leave';
        } else {
          status = AttendanceStatus.onLeave;
          derivedFrom = 'approved_leave';
        }
      }
      // 3. Check gate scans
      else {
        final studentPasses = _qrPasses.where((p) => p.studentId == student.uid);
        final activePass = studentPasses.where((p) => p.isActive);

        if (activePass.isEmpty) {
          // Never exited today
          status = AttendanceStatus.present;
          derivedFrom = 'no_exit';
        } else {
          final pass = activePass.first;
          if (pass.state == QrState.hostelEntered || pass.state == QrState.unused) {
            status = AttendanceStatus.present;
            derivedFrom = 'gate_scan_returned';
          } else if (pass.state == QrState.hostelExited || pass.state == QrState.campusExited) {
            status = AttendanceStatus.unaccounted;
            derivedFrom = 'gate_scan_no_return';
            // Create exception
            _attendanceExceptions.add(AttendanceException(
              id: 'exc_${DateTime.now().millisecondsSinceEpoch}_${student.uid}',
              studentId: student.uid,
              studentName: student.name,
              type: AttendanceExceptionType.exitWithoutReturn,
              description: 'Student exited but has not returned by curfew',
            ));
          } else {
            status = AttendanceStatus.outValid;
            derivedFrom = 'gate_scan_valid';
          }
        }
      }

      _attendanceRecords.add(AttendanceRecord(
        id: 'att_${today.millisecondsSinceEpoch}_${student.uid}',
        studentId: student.uid,
        studentName: student.name,
        hostelBlock: student.hostelBlock ?? 'Unknown',
        date: today,
        status: status,
        derivedFrom: derivedFrom,
      ));
    }
    notifyListeners();
  }

  /// Get attendance records for a specific date
  List<AttendanceRecord> getAttendanceForDate(DateTime date) {
    return _attendanceRecords.where((a) =>
        a.date.year == date.year &&
        a.date.month == date.month &&
        a.date.day == date.day).toList();
  }

  /// Get attendance history for a specific student
  List<AttendanceRecord> getStudentAttendance(String studentId) {
    return _attendanceRecords.where((a) => a.studentId == studentId).toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  /// Get unresolved attendance exceptions
  List<AttendanceException> getUnresolvedExceptions() {
    return _attendanceExceptions.where((e) => !e.resolved).toList();
  }

  /// Get attendance summary counts for a date
  Map<AttendanceStatus, int> getAttendanceSummary(DateTime date) {
    final records = getAttendanceForDate(date);
    final summary = <AttendanceStatus, int>{};
    for (final status in AttendanceStatus.values) {
      summary[status] = records.where((r) => r.status == status).length;
    }
    return summary;
  }

  // ════════════════════════════════════════════════════════
  // MEDICAL MODULE (Officer-Driven Flow)
  // ════════════════════════════════════════════════════════

  /// Medical Officer creates a medical record for a student
  /// Auto-intimates RT, Faculty Advisor, Warden, and HoD
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
    await Future.delayed(const Duration(milliseconds: 400));
    final officer = _currentUser!;
    final student = _users.firstWhere((u) => u.uid == studentId);

    // Find stakeholders to auto-intimate
    final rt = _users.where((u) => u.role == UserRole.rt).toList();
    final faculty = _users.where((u) => u.role == UserRole.faculty).toList();
    final warden = _users.where((u) => u.role == UserRole.warden).toList();
    final hod = _users.where((u) => u.role == UserRole.hod).toList();

    final now = DateTime.now();
    final intimations = <MedicalIntimation>[
      if (rt.isNotEmpty)
        MedicalIntimation(role: 'Resident Tutor', personName: rt.first.name, notifiedAt: now),
      if (faculty.isNotEmpty)
        MedicalIntimation(role: 'Faculty Advisor', personName: faculty.first.name, notifiedAt: now),
      if (warden.isNotEmpty)
        MedicalIntimation(role: 'Warden', personName: warden.first.name, notifiedAt: now),
      if (hod.isNotEmpty)
        MedicalIntimation(role: 'Head of Department', personName: hod.first.name, notifiedAt: now),
    ];

    _medicalVisits.add(MedicalVisit(
      id: 'med_${now.millisecondsSinceEpoch}',
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
      status: restrictMovement ? MedicalStatus.medicalRestricted : MedicalStatus.medicalRest,
      movementRestricted: restrictMovement,
      prescription: prescription,
      medicalOfficerNote: note,
      intimations: intimations,
    ));
    notifyListeners();
  }

  /// Medical Officer updates fitness status of a student record
  Future<void> updateFitnessStatus({
    required String visitId,
    required FitnessStatus fitnessStatus,
    String? note,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final index = _medicalVisits.indexWhere((m) => m.id == visitId);
    if (index != -1) {
      _medicalVisits[index] = _medicalVisits[index].copyWith(
        fitnessStatus: fitnessStatus,
        medicalOfficerNote: note ?? _medicalVisits[index].medicalOfficerNote,
        // If fit, auto-clear restrictions
        movementRestricted: fitnessStatus == FitnessStatus.fit ? false : _medicalVisits[index].movementRestricted,
        status: fitnessStatus == FitnessStatus.fit ? MedicalStatus.cleared : _medicalVisits[index].status,
        clearedAt: fitnessStatus == FitnessStatus.fit ? DateTime.now() : null,
        clearedBy: fitnessStatus == FitnessStatus.fit ? _currentUser?.name : null,
      );
      notifyListeners();
    }
  }

  /// Medical Officer updates diagnosis/prescription
  Future<void> updateMedicalRecord({
    required String visitId,
    String? diagnosis,
    int? restDays,
    String? prescription,
    bool? restrictMovement,
    String? note,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final index = _medicalVisits.indexWhere((m) => m.id == visitId);
    if (index != -1) {
      _medicalVisits[index] = _medicalVisits[index].copyWith(
        diagnosis: diagnosis,
        restDays: restDays,
        prescription: prescription,
        movementRestricted: restrictMovement,
        medicalOfficerNote: note,
        // If restriction changed, update status
        status: (restrictMovement == true)
            ? MedicalStatus.medicalRestricted
            : _medicalVisits[index].status,
      );
      notifyListeners();
    }
  }

  /// Issue medical clearance (officer declares fit)
  Future<void> issueMedicalClearance(String visitId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final index = _medicalVisits.indexWhere((m) => m.id == visitId);
    if (index != -1) {
      _medicalVisits[index] = _medicalVisits[index].copyWith(
        status: MedicalStatus.cleared,
        fitnessStatus: FitnessStatus.fit,
        movementRestricted: false,
        clearedAt: DateTime.now(),
        clearedBy: _currentUser?.name ?? 'System',
        reviewRequested: false,
      );
      notifyListeners();
    }
  }

  /// Student requests review of an existing record (cannot create new ones)
  Future<void> requestMedicalReview({
    required String visitId,
    String? note,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final index = _medicalVisits.indexWhere((m) => m.id == visitId);
    if (index != -1) {
      _medicalVisits[index] = _medicalVisits[index].copyWith(
        reviewRequested: true,
        reviewRequestNote: note ?? 'Student has requested a review',
        reviewRequestedAt: DateTime.now(),
      );
      notifyListeners();
    }
  }

  /// Stakeholder acknowledges receipt of medical intimation
  Future<void> acknowledgeMedicalIntimation({
    required String visitId,
    required String role,
  }) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final index = _medicalVisits.indexWhere((m) => m.id == visitId);
    if (index != -1) {
      final intimations = List<MedicalIntimation>.from(_medicalVisits[index].intimations);
      final iIdx = intimations.indexWhere((i) => i.role == role);
      if (iIdx != -1) {
        intimations[iIdx] = intimations[iIdx].copyWith(
          acknowledged: true,
          acknowledgedAt: DateTime.now(),
        );
        _medicalVisits[index] = _medicalVisits[index].copyWith(
          intimations: intimations,
        );
        notifyListeners();
      }
    }
  }

  /// Check if student is medically restricted (gate check)
  bool isStudentMedicalRestricted(String studentId) {
    return _medicalVisits.any((m) =>
        m.studentId == studentId &&
        m.movementRestricted &&
        m.status != MedicalStatus.cleared);
  }

  /// Get fitness status for a student (latest record)
  FitnessStatus? getStudentFitnessStatus(String studentId) {
    final visits = _medicalVisits.where((m) => m.studentId == studentId).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    if (visits.isEmpty) return null;
    return visits.first.fitnessStatus;
  }

  /// Get medical visits for a student (read-only view)
  List<MedicalVisit> getStudentMedicalVisits(String studentId) {
    return _medicalVisits.where((m) => m.studentId == studentId).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  /// Get all medical visits (officer + warden view)
  List<MedicalVisit> getAllMedicalVisits() {
    return List<MedicalVisit>.from(_medicalVisits)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  /// Get records that have review requests pending
  List<MedicalVisit> getReviewRequestedVisits() {
    return _medicalVisits.where((m) => m.reviewRequested).toList()
      ..sort((a, b) => b.reviewRequestedAt!.compareTo(a.reviewRequestedAt!));
  }

  /// Get active (non-cleared) records
  List<MedicalVisit> getActiveMedicalRecords() {
    return _medicalVisits.where((m) => m.status != MedicalStatus.cleared).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  /// Get all student users (for officer's student selection)
  List<AppUser> getStudentUsers() {
    return _users.where((u) => u.role == UserRole.student).toList();
  }

  // ════════════════════════════════════════════════════════
  // GRIEVANCE MODULE
  // ════════════════════════════════════════════════════════

  /// Student submits a grievance
  Future<void> submitGrievance({
    required GrievanceCategory category,
    required String description,
    String? imageUrl,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final user = _currentUser!;
    _grievances.add(Grievance(
      id: 'grv_${DateTime.now().millisecondsSinceEpoch}',
      studentId: user.uid,
      studentName: user.name,
      hostelBlock: user.hostelBlock ?? '',
      roomNumber: user.roomNumber ?? '',
      category: category,
      description: description,
      status: GrievanceStatus.open,
      imageUrl: imageUrl,
      assignedTo: 'rt', // auto-assign to RT
    ));
    notifyListeners();
  }

  /// RT/Warden responds to a grievance
  Future<void> respondToGrievance({
    required String grievanceId,
    required String comment,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final user = _currentUser!;
    final index = _grievances.indexWhere((g) => g.id == grievanceId);
    if (index != -1) {
      final actions = List<GrievanceAction>.from(_grievances[index].actions)
        ..add(GrievanceAction(
          actorId: user.uid,
          actorName: user.name,
          actorRole: user.role.label,
          action: 'Responded',
          comment: comment,
        ));
      _grievances[index] = _grievances[index].copyWith(
        status: GrievanceStatus.underReview,
        actions: actions,
      );
      notifyListeners();
    }
  }

  /// Escalate a grievance to the next level
  Future<void> escalateGrievance({
    required String grievanceId,
    String? reason,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final user = _currentUser!;
    final index = _grievances.indexWhere((g) => g.id == grievanceId);
    if (index != -1) {
      final current = _grievances[index];
      final newLevel = (current.escalationLevel + 1).clamp(0, 2);
      final assignedTo = newLevel == 1 ? 'warden' : 'admin';

      final actions = List<GrievanceAction>.from(current.actions)
        ..add(GrievanceAction(
          actorId: user.uid,
          actorName: user.name,
          actorRole: user.role.label,
          action: 'Escalated to $assignedTo',
          comment: reason,
        ));

      _grievances[index] = current.copyWith(
        status: GrievanceStatus.escalated,
        escalationLevel: newLevel,
        assignedTo: assignedTo,
        actions: actions,
      );
      notifyListeners();
    }
  }

  /// Resolve a grievance
  Future<void> resolveGrievance({
    required String grievanceId,
    String? comment,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final user = _currentUser!;
    final index = _grievances.indexWhere((g) => g.id == grievanceId);
    if (index != -1) {
      final actions = List<GrievanceAction>.from(_grievances[index].actions)
        ..add(GrievanceAction(
          actorId: user.uid,
          actorName: user.name,
          actorRole: user.role.label,
          action: 'Resolved',
          comment: comment,
        ));
      _grievances[index] = _grievances[index].copyWith(
        status: GrievanceStatus.resolved,
        resolvedAt: DateTime.now(),
        actions: actions,
      );
      notifyListeners();
    }
  }

  /// Get grievances for a student
  List<Grievance> getStudentGrievances(String studentId) {
    return _grievances.where((g) => g.studentId == studentId).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  /// Get grievances assigned to a role
  List<Grievance> getGrievancesForRole(UserRole role) {
    String roleKey;
    switch (role) {
      case UserRole.rt:
        roleKey = 'rt';
        break;
      case UserRole.warden:
        roleKey = 'warden';
        break;
      case UserRole.admin:
        roleKey = 'admin';
        break;
      default:
        return [];
    }
    return _grievances.where((g) =>
        g.assignedTo == roleKey &&
        g.status != GrievanceStatus.resolved).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  /// Get all grievances (admin view)
  List<Grievance> getAllGrievances() {
    return List.from(_grievances)..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  // ════════════════════════════════════════════════════════
  // GEOFENCE ATTENDANCE MODULE
  // ════════════════════════════════════════════════════════

  void _initGeofenceData() {
    final now = DateTime.now();
    final blockAStudents = _users.where((u) => u.role == UserRole.student && u.hostelBlock == 'Block A').toList();

    // Create 15 historical sessions over the past 30 days
    for (int i = 29; i >= 0; i--) {
      final sessionDate = now.subtract(Duration(days: i));
      // Skip weekends
      if (sessionDate.weekday == DateTime.saturday || sessionDate.weekday == DateTime.sunday) continue;

      final sessionStart = DateTime(sessionDate.year, sessionDate.month, sessionDate.day, 21, 0);
      final sessionEnd = sessionStart.add(const Duration(minutes: 30));
      final sessionId = 'gfs_${sessionDate.millisecondsSinceEpoch}';

      int markedCount = 0;

      // Each student has varying attendance
      for (final student in blockAStudents) {
        // Simulate ~75-95% attendance per student, some students more irregular
        bool attended;
        switch (student.uid) {
          case 'student1': // Arjun - 90% attendance
            attended = i % 10 != 3;
            break;
          case 'student2': // Neha - 95% attendance
            attended = i % 20 != 7;
            break;
          case 'student3': // Rahul - 70% attendance (low)
            attended = i % 3 != 0;
            break;
          case 'student4': // Priya - 85% attendance
            attended = i % 7 != 2;
            break;
          case 'student5': // Aditya - 80% attendance
            attended = i % 5 != 1;
            break;
          case 'student6': // Kavya - 93% attendance
            attended = i % 15 != 4;
            break;
          default:
            attended = i % 4 != 0;
        }

        if (attended) {
          markedCount++;
          _geofenceCheckIns.add(GeofenceCheckIn(
            id: 'gfc_${sessionDate.millisecondsSinceEpoch}_${student.uid}',
            sessionId: sessionId,
            studentId: student.uid,
            studentName: student.name,
            rollNumber: student.rollNumber ?? '',
            hostelBlock: student.hostelBlock ?? '',
            timestamp: sessionStart.add(Duration(minutes: (2 + (student.uid.hashCode.abs() % 15)))),
            insideGeofence: true,
            distanceFromCenter: 10.0 + (student.uid.hashCode.abs() % 60).toDouble(),
          ));
        }
      }

      _geofenceSessions.add(GeofenceSession(
        id: sessionId,
        rtId: 'rt1',
        rtName: 'Dr. Priya Sharma',
        hostelBlock: 'Block A',
        centerLat: 12.9716,
        centerLng: 77.5946,
        radiusMeters: 100,
        startTime: sessionStart,
        endTime: sessionEnd,
        status: GeofenceSessionStatus.closed,
        totalStudents: blockAStudents.length,
        markedCount: markedCount,
      ));
    }

    // Add anomalies for students with low attendance
    _attendanceAnomalies.addAll([
      AttendanceAnomaly(
        id: 'ano_1',
        studentId: 'student3',
        studentName: 'Rahul Verma',
        rollNumber: 'CS21B1047',
        hostelBlock: 'Block A',
        type: AnomalyType.frequentAbsence,
        description: 'Missed 10 out of last 30 sessions. Attendance below 70%.',
        raisedById: 'rt1',
        raisedByName: 'Dr. Priya Sharma',
        raisedAt: now.subtract(const Duration(days: 3)),
        parentNotified: true,
      ),
      AttendanceAnomaly(
        id: 'ano_2',
        studentId: 'student5',
        studentName: 'Aditya Singh',
        rollNumber: 'ME21B1005',
        hostelBlock: 'Block A',
        type: AnomalyType.consecutiveMiss,
        description: 'Missed 3 consecutive attendance sessions without leave.',
        raisedById: 'rt1',
        raisedByName: 'Dr. Priya Sharma',
        raisedAt: now.subtract(const Duration(days: 1)),
        parentNotified: true,
      ),
      AttendanceAnomaly(
        id: 'ano_3',
        studentId: 'student3',
        studentName: 'Rahul Verma',
        rollNumber: 'CS21B1047',
        hostelBlock: 'Block A',
        type: AnomalyType.lateEntry,
        description: 'Marked attendance 25 min after window opened on multiple occasions.',
        raisedById: 'rt1',
        raisedByName: 'Dr. Priya Sharma',
        raisedAt: now.subtract(const Duration(days: 7)),
        parentNotified: true,
        resolved: true,
        parentResponse: 'Will speak with my child about punctuality.',
        resolvedAt: now.subtract(const Duration(days: 5)),
      ),
    ]);
  }

  /// RT opens an attendance window for their block
  Future<GeofenceSession> openAttendanceWindow({
    required String hostelBlock,
    double lat = 12.9716,
    double lng = 77.5946,
    double radius = 100.0,
  }) async {
    await Future.delayed(const Duration(milliseconds: 400));
    final rt = _currentUser!;
    final blockStudents = _users.where(
      (u) => u.role == UserRole.student && u.hostelBlock == hostelBlock,
    ).length;

    final session = GeofenceSession(
      id: 'gfs_${DateTime.now().millisecondsSinceEpoch}',
      rtId: rt.uid,
      rtName: rt.name,
      hostelBlock: hostelBlock,
      centerLat: lat,
      centerLng: lng,
      radiusMeters: radius,
      startTime: DateTime.now(),
      totalStudents: blockStudents,
    );

    _geofenceSessions.add(session);
    notifyListeners();
    return session;
  }

  /// RT closes the active attendance window
  Future<void> closeAttendanceWindow(String sessionId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final index = _geofenceSessions.indexWhere((s) => s.id == sessionId);
    if (index != -1) {
      _geofenceSessions[index] = _geofenceSessions[index].copyWith(
        status: GeofenceSessionStatus.closed,
        endTime: DateTime.now(),
      );
      notifyListeners();
    }
  }

  /// Student marks attendance (simulates geofence verification)
  Future<String?> markGeofenceAttendance(String sessionId) async {
    await Future.delayed(const Duration(milliseconds: 400));
    final student = _currentUser!;
    final session = _geofenceSessions.firstWhere(
      (s) => s.id == sessionId,
      orElse: () => throw Exception('Session not found'),
    );

    if (session.status != GeofenceSessionStatus.active) {
      return 'Attendance window is closed';
    }

    // Check if already marked
    final alreadyMarked = _geofenceCheckIns.any(
      (c) => c.sessionId == sessionId && c.studentId == student.uid,
    );
    if (alreadyMarked) {
      return 'Attendance already marked for this session';
    }

    // Simulate geofence check — always inside for demo
    final distance = 15.0 + (student.uid.hashCode.abs() % 50).toDouble();

    _geofenceCheckIns.add(GeofenceCheckIn(
      id: 'gfc_${DateTime.now().millisecondsSinceEpoch}_${student.uid}',
      sessionId: sessionId,
      studentId: student.uid,
      studentName: student.name,
      rollNumber: student.rollNumber ?? '',
      hostelBlock: student.hostelBlock ?? '',
      insideGeofence: true,
      distanceFromCenter: distance,
    ));

    // Update session marked count
    final sessionIndex = _geofenceSessions.indexWhere((s) => s.id == sessionId);
    if (sessionIndex != -1) {
      final currentCount = _geofenceCheckIns.where((c) => c.sessionId == sessionId).length;
      _geofenceSessions[sessionIndex] = _geofenceSessions[sessionIndex].copyWith(
        markedCount: currentCount,
      );
    }

    notifyListeners();
    return null; // success
  }

  /// Get active session for a block
  GeofenceSession? getActiveSession(String hostelBlock) {
    try {
      return _geofenceSessions.firstWhere(
        (s) => s.hostelBlock == hostelBlock && s.status == GeofenceSessionStatus.active,
      );
    } catch (_) {
      return null;
    }
  }

  /// Get all sessions for a block
  List<GeofenceSession> getBlockSessions(String hostelBlock) {
    return _geofenceSessions.where((s) => s.hostelBlock == hostelBlock).toList()
      ..sort((a, b) => b.startTime.compareTo(a.startTime));
  }

  /// Get check-ins for a session
  List<GeofenceCheckIn> getSessionCheckIns(String sessionId) {
    return _geofenceCheckIns.where((c) => c.sessionId == sessionId).toList()
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
  }

  /// Check if student already marked attendance for a session
  bool hasStudentMarkedAttendance(String sessionId, String studentId) {
    return _geofenceCheckIns.any(
      (c) => c.sessionId == sessionId && c.studentId == studentId,
    );
  }

  /// Get student's geofence attendance percentage
  double getStudentGeofencePercentage(String studentId) {
    final studentBlock = _users.firstWhere((u) => u.uid == studentId).hostelBlock ?? '';
    final blockSessions = _geofenceSessions.where(
      (s) => s.hostelBlock == studentBlock && s.status == GeofenceSessionStatus.closed,
    ).toList();
    if (blockSessions.isEmpty) return 100.0;

    final attended = _geofenceCheckIns.where(
      (c) => c.studentId == studentId && blockSessions.any((s) => s.id == c.sessionId),
    ).length;

    return (attended / blockSessions.length * 100).clamp(0, 100);
  }

  /// Get attendance summary for each student in a block
  List<StudentAttendanceSummary> getBlockAttendanceSummary(String hostelBlock) {
    final students = _users.where(
      (u) => u.role == UserRole.student && u.hostelBlock == hostelBlock,
    ).toList();
    final blockSessions = _geofenceSessions.where(
      (s) => s.hostelBlock == hostelBlock && s.status == GeofenceSessionStatus.closed,
    ).toList();

    return students.map((student) {
      final attended = _geofenceCheckIns.where(
        (c) => c.studentId == student.uid && blockSessions.any((s) => s.id == c.sessionId),
      ).length;
      final total = blockSessions.length;
      final missed = total - attended;
      final percentage = total > 0 ? (attended / total * 100) : 100.0;
      final anomalies = _attendanceAnomalies.where((a) => a.studentId == student.uid && !a.resolved).length;

      return StudentAttendanceSummary(
        studentId: student.uid,
        studentName: student.name,
        rollNumber: student.rollNumber ?? '',
        totalSessions: total,
        attended: attended,
        missed: missed,
        percentage: percentage,
        anomalyCount: anomalies,
      );
    }).toList()
      ..sort((a, b) => a.percentage.compareTo(b.percentage));
  }

  /// Get attendance patterns for a department (faculty advisor view)
  List<StudentAttendanceSummary> getDepartmentAttendancePatterns(String department) {
    final students = _users.where(
      (u) => u.role == UserRole.student && u.department == department,
    ).toList();

    return students.map((student) {
      final studentBlock = student.hostelBlock ?? '';
      final blockSessions = _geofenceSessions.where(
        (s) => s.hostelBlock == studentBlock && s.status == GeofenceSessionStatus.closed,
      ).toList();
      final attended = _geofenceCheckIns.where(
        (c) => c.studentId == student.uid && blockSessions.any((s) => s.id == c.sessionId),
      ).length;
      final total = blockSessions.length;
      final missed = total - attended;
      final percentage = total > 0 ? (attended / total * 100) : 100.0;
      final anomalies = _attendanceAnomalies.where((a) => a.studentId == student.uid && !a.resolved).length;

      return StudentAttendanceSummary(
        studentId: student.uid,
        studentName: student.name,
        rollNumber: student.rollNumber ?? '',
        totalSessions: total,
        attended: attended,
        missed: missed,
        percentage: percentage,
        anomalyCount: anomalies,
      );
    }).toList()
      ..sort((a, b) => a.percentage.compareTo(b.percentage));
  }

  /// RT raises an attendance anomaly
  Future<void> raiseAttendanceAnomaly({
    required String studentId,
    required AnomalyType type,
    required String description,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final rt = _currentUser!;
    final student = _users.firstWhere((u) => u.uid == studentId);

    _attendanceAnomalies.add(AttendanceAnomaly(
      id: 'ano_${DateTime.now().millisecondsSinceEpoch}',
      studentId: student.uid,
      studentName: student.name,
      rollNumber: student.rollNumber ?? '',
      hostelBlock: student.hostelBlock ?? '',
      type: type,
      description: description,
      raisedById: rt.uid,
      raisedByName: rt.name,
      parentNotified: true,
    ));
    notifyListeners();
  }

  /// Get anomalies for a parent's child
  List<AttendanceAnomaly> getAnomaliesForStudent(String studentId) {
    return _attendanceAnomalies.where((a) => a.studentId == studentId).toList()
      ..sort((a, b) => b.raisedAt.compareTo(a.raisedAt));
  }

  /// Get all anomalies (warden / admin view)
  List<AttendanceAnomaly> getAllAnomalies() {
    return List.from(_attendanceAnomalies)
      ..sort((a, b) => b.raisedAt.compareTo(a.raisedAt));
  }

  /// Get unresolved anomalies count for a block
  int getUnresolvedAnomalyCount(String hostelBlock) {
    return _attendanceAnomalies.where(
      (a) => a.hostelBlock == hostelBlock && !a.resolved,
    ).length;
  }

  /// Resolve an anomaly (with optional parent response)
  Future<void> resolveAnomaly({
    required String anomalyId,
    String? response,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final index = _attendanceAnomalies.indexWhere((a) => a.id == anomalyId);
    if (index != -1) {
      _attendanceAnomalies[index] = _attendanceAnomalies[index].copyWith(
        resolved: true,
        parentResponse: response,
        resolvedAt: DateTime.now(),
      );
      notifyListeners();
    }
  }

  /// Get all sessions (warden / admin overview)
  List<GeofenceSession> getAllGeofenceSessions() {
    return List.from(_geofenceSessions)
      ..sort((a, b) => b.startTime.compareTo(a.startTime));
  }

  /// Get overall attendance stats for analytics
  Map<String, dynamic> getGeofenceAttendanceStats() {
    final closedSessions = _geofenceSessions.where(
      (s) => s.status == GeofenceSessionStatus.closed,
    ).toList();

    if (closedSessions.isEmpty) {
      return {
        'totalSessions': 0,
        'avgAttendance': 0.0,
        'totalCheckIns': 0,
        'unresolvedAnomalies': 0,
      };
    }

    final totalRate = closedSessions.fold<double>(
      0, (sum, s) => sum + s.completionRate,
    ) / closedSessions.length;

    return {
      'totalSessions': closedSessions.length,
      'avgAttendance': totalRate * 100,
      'totalCheckIns': _geofenceCheckIns.length,
      'unresolvedAnomalies': _attendanceAnomalies.where((a) => !a.resolved).length,
    };
  }
}
