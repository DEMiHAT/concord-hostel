import 'package:cloud_firestore/cloud_firestore.dart';
import 'enums.dart';

class LeaveRequest {
  final String id;
  final String studentId;
  final String studentName;
  final String studentRollNumber;
  final String hostelBlock;
  final String roomNumber;
  final LeaveType leaveType;
  final LeaveStatus status;
  final String reason;
  final DateTime fromDate;
  final DateTime toDate;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String? rtId;
  final String? parentId;
  final String? hodId;
  final String? wardenId;
  final String? facultyId;
  final String? rejectionReason;
  final List<String> proofDocumentUrls;
  final List<ApprovalStep> approvalHistory;
  final String? qrPassId;

  LeaveRequest({
    required this.id,
    required this.studentId,
    required this.studentName,
    required this.studentRollNumber,
    required this.hostelBlock,
    required this.roomNumber,
    required this.leaveType,
    required this.status,
    required this.reason,
    required this.fromDate,
    required this.toDate,
    DateTime? createdAt,
    this.updatedAt,
    this.rtId,
    this.parentId,
    this.hodId,
    this.wardenId,
    this.facultyId,
    this.rejectionReason,
    this.proofDocumentUrls = const [],
    this.approvalHistory = const [],
    this.qrPassId,
  }) : createdAt = createdAt ?? DateTime.now();

  factory LeaveRequest.fromFirestore(Map<String, dynamic> data, String id) {
    return LeaveRequest(
      id: id,
      studentId: data['studentId'] ?? '',
      studentName: data['studentName'] ?? '',
      studentRollNumber: data['studentRollNumber'] ?? '',
      hostelBlock: data['hostelBlock'] ?? '',
      roomNumber: data['roomNumber'] ?? '',
      leaveType: LeaveType.values.firstWhere(
        (e) => e.name == data['leaveType'],
        orElse: () => LeaveType.dayPass,
      ),
      status: LeaveStatusExtension.fromFirestore(data['status'] ?? 'pending'),
      reason: data['reason'] ?? '',
      fromDate: (data['fromDate'] as Timestamp).toDate(),
      toDate: (data['toDate'] as Timestamp).toDate(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
      rtId: data['rtId'],
      parentId: data['parentId'],
      hodId: data['hodId'],
      wardenId: data['wardenId'],
      facultyId: data['facultyId'],
      rejectionReason: data['rejectionReason'],
      proofDocumentUrls: List<String>.from(data['proofDocumentUrls'] ?? []),
      approvalHistory: (data['approvalHistory'] as List<dynamic>?)
              ?.map(
                (e) => ApprovalStep.fromMap(e as Map<String, dynamic>),
              )
              .toList() ??
          [],
      qrPassId: data['qrPassId'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'studentId': studentId,
      'studentName': studentName,
      'studentRollNumber': studentRollNumber,
      'hostelBlock': hostelBlock,
      'roomNumber': roomNumber,
      'leaveType': leaveType.name,
      'status': status.firestoreValue,
      'reason': reason,
      'fromDate': Timestamp.fromDate(fromDate),
      'toDate': Timestamp.fromDate(toDate),
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'rtId': rtId,
      'parentId': parentId,
      'hodId': hodId,
      'wardenId': wardenId,
      'facultyId': facultyId,
      'rejectionReason': rejectionReason,
      'proofDocumentUrls': proofDocumentUrls,
      'approvalHistory': approvalHistory.map((e) => e.toMap()).toList(),
      'qrPassId': qrPassId,
    };
  }

  LeaveRequest copyWith({
    LeaveStatus? status,
    String? rejectionReason,
    String? qrPassId,
    DateTime? updatedAt,
    List<ApprovalStep>? approvalHistory,
    List<String>? proofDocumentUrls,
  }) {
    return LeaveRequest(
      id: id,
      studentId: studentId,
      studentName: studentName,
      studentRollNumber: studentRollNumber,
      hostelBlock: hostelBlock,
      roomNumber: roomNumber,
      leaveType: leaveType,
      status: status ?? this.status,
      reason: reason,
      fromDate: fromDate,
      toDate: toDate,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rtId: rtId,
      parentId: parentId,
      hodId: hodId,
      wardenId: wardenId,
      facultyId: facultyId,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      proofDocumentUrls: proofDocumentUrls ?? this.proofDocumentUrls,
      approvalHistory: approvalHistory ?? this.approvalHistory,
      qrPassId: qrPassId ?? this.qrPassId,
    );
  }
}

class ApprovalStep {
  final String approverId;
  final String approverName;
  final String approverRole;
  final String action; // approved, rejected, forwarded
  final String? comment;
  final DateTime timestamp;

  ApprovalStep({
    required this.approverId,
    required this.approverName,
    required this.approverRole,
    required this.action,
    this.comment,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  factory ApprovalStep.fromMap(Map<String, dynamic> data) {
    return ApprovalStep(
      approverId: data['approverId'] ?? '',
      approverName: data['approverName'] ?? '',
      approverRole: data['approverRole'] ?? '',
      action: data['action'] ?? '',
      comment: data['comment'],
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'approverId': approverId,
      'approverName': approverName,
      'approverRole': approverRole,
      'action': action,
      'comment': comment,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }
}
