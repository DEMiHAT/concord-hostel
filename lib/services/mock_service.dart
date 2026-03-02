import 'package:flutter/material.dart';
import '../models/enums.dart';
import '../models/user_model.dart';
import '../models/leave_request.dart';
import '../models/qr_pass.dart';

/// Mock authentication and data service for demo purposes.
/// Replace with actual Firebase calls when Firebase is configured.
class MockService extends ChangeNotifier {
  AppUser? _currentUser;
  final List<LeaveRequest> _leaveRequests = [];
  final List<QrPass> _qrPasses = [];
  final List<AppUser> _users = [];
  bool _busMode = false;

  AppUser? get currentUser => _currentUser;
  List<LeaveRequest> get leaveRequests => List.unmodifiable(_leaveRequests);
  List<QrPass> get qrPasses => List.unmodifiable(_qrPasses);
  List<AppUser> get users => List.unmodifiable(_users);
  bool get busMode => _busMode;

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
  }

  // Auth methods
  Future<AppUser?> loginWithRole(UserRole role) async {
    await Future.delayed(const Duration(milliseconds: 800));
    _currentUser = _users.firstWhere((u) => u.role == role);
    notifyListeners();
    return _currentUser;
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
}
