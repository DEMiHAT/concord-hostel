import 'package:flutter/material.dart';
import '../models/enums.dart';
import '../models/user_model.dart';
import '../models/leave_request.dart';
import '../models/qr_pass.dart';
import '../models/attendance.dart';
import '../models/medical.dart';
import '../models/grievance.dart';
import '../models/geofence_attendance.dart';

/// Abstract service contract for the Concord system.
/// Both [MockService] (demo) and [FirebaseService] (production) implement this.
abstract class AppService extends ChangeNotifier {
  // ════════════════════════════════════════════════════════
  // AUTH
  // ════════════════════════════════════════════════════════

  AppUser? get currentUser;

  /// Demo login — select role directly (mock mode only).
  Future<AppUser?> loginWithRole(UserRole role);

  /// Production login — email + password.
  Future<AppUser?> loginWithEmail(String email, String password);

  /// Sign out.
  void logout();

  // ════════════════════════════════════════════════════════
  // LEAVE REQUESTS
  // ════════════════════════════════════════════════════════

  List<LeaveRequest> get leaveRequests;

  List<LeaveRequest> getStudentLeaves(String studentId);

  List<LeaveRequest> getPendingApprovalsForRole(UserRole role);

  Future<void> createLeaveRequest(LeaveRequest request);

  Future<void> approveRequest(
    String requestId,
    String approverId,
    String approverName,
    String role,
  );

  Future<void> rejectRequest(
    String requestId,
    String approverId,
    String approverName,
    String role,
    String reason,
  );

  Future<void> requestDocuments(
    String requestId,
    String approverId,
    String approverName,
    String comment,
  );

  Future<void> submitDocuments(
    String requestId,
    List<String> documentUrls,
  );

  // ════════════════════════════════════════════════════════
  // QR PASSES & GATE
  // ════════════════════════════════════════════════════════

  List<QrPass> get qrPasses;

  QrPass? getQrPass(String passId);

  List<QrPass> getStudentPasses(String studentId);

  Future<String?> scanQr(
    String passId,
    GateType gate,
    String action, {
    LaneType? laneType,
  });

  bool get busMode;
  void setBusMode(bool value);

  // ════════════════════════════════════════════════════════
  // ADMIN / STATS
  // ════════════════════════════════════════════════════════

  Map<String, int> getStats();

  List<Map<String, dynamic>> getAllGateLogs();

  List<Map<String, dynamic>> getAllApprovalHistory();

  Map<String, List<AppUser>> getStudentsByBlock();

  Map<String, dynamic> getTodayAttendance();

  // ════════════════════════════════════════════════════════
  // ATTENDANCE MODULE
  // ════════════════════════════════════════════════════════

  Future<void> generateDailyAttendance();

  List<AttendanceRecord> getAttendanceForDate(DateTime date);

  List<AttendanceRecord> getStudentAttendance(String studentId);

  List<AttendanceException> getUnresolvedExceptions();

  Map<AttendanceStatus, int> getAttendanceSummary(DateTime date);

  // ════════════════════════════════════════════════════════
  // MEDICAL MODULE
  // ════════════════════════════════════════════════════════

  Future<void> createMedicalRecord({
    required String studentId,
    required String symptoms,
    required String diagnosis,
    required int restDays,
    required FitnessStatus fitnessStatus,
    required bool restrictMovement,
    String? prescription,
    String? note,
  });

  Future<void> updateFitnessStatus({
    required String visitId,
    required FitnessStatus fitnessStatus,
    String? note,
  });

  Future<void> updateMedicalRecord({
    required String visitId,
    String? diagnosis,
    int? restDays,
    String? prescription,
    bool? restrictMovement,
    String? note,
  });

  Future<void> issueMedicalClearance(String visitId);

  Future<void> requestMedicalReview({
    required String visitId,
    String? note,
  });

  Future<void> acknowledgeMedicalIntimation({
    required String visitId,
    required String role,
  });

  bool isStudentMedicalRestricted(String studentId);

  FitnessStatus? getStudentFitnessStatus(String studentId);

  List<MedicalVisit> getStudentMedicalVisits(String studentId);

  List<MedicalVisit> getAllMedicalVisits();

  List<MedicalVisit> getReviewRequestedVisits();

  List<MedicalVisit> getActiveMedicalRecords();

  List<AppUser> getStudentUsers();

  // ════════════════════════════════════════════════════════
  // GRIEVANCE MODULE
  // ════════════════════════════════════════════════════════

  Future<void> submitGrievance({
    required GrievanceCategory category,
    required String description,
    String? imageUrl,
  });

  Future<void> respondToGrievance({
    required String grievanceId,
    required String comment,
  });

  Future<void> escalateGrievance({
    required String grievanceId,
    String? reason,
  });

  Future<void> resolveGrievance({
    required String grievanceId,
    String? comment,
  });

  List<Grievance> getStudentGrievances(String studentId);

  List<Grievance> getGrievancesForRole(UserRole role);

  List<Grievance> getAllGrievances();

  // ════════════════════════════════════════════════════════
  // GEOFENCE ATTENDANCE MODULE
  // ════════════════════════════════════════════════════════

  Future<GeofenceSession> openAttendanceWindow({
    required String hostelBlock,
    double lat = 12.9716,
    double lng = 77.5946,
    double radius = 100.0,
  });

  Future<void> closeAttendanceWindow(String sessionId);

  Future<String?> markGeofenceAttendance(String sessionId);

  GeofenceSession? getActiveSession(String hostelBlock);

  List<GeofenceSession> getBlockSessions(String hostelBlock);

  List<GeofenceCheckIn> getSessionCheckIns(String sessionId);

  bool hasStudentMarkedAttendance(String sessionId, String studentId);

  double getStudentGeofencePercentage(String studentId);

  List<StudentAttendanceSummary> getBlockAttendanceSummary(String hostelBlock);

  List<StudentAttendanceSummary> getDepartmentAttendancePatterns(String department);

  Future<void> raiseAttendanceAnomaly({
    required String studentId,
    required AnomalyType type,
    required String description,
  });

  List<AttendanceAnomaly> getAnomaliesForStudent(String studentId);

  List<AttendanceAnomaly> getAllAnomalies();

  int getUnresolvedAnomalyCount(String hostelBlock);

  Future<void> resolveAnomaly({
    required String anomalyId,
    String? response,
  });

  List<GeofenceSession> getAllGeofenceSessions();

  Map<String, dynamic> getGeofenceAttendanceStats();
}
