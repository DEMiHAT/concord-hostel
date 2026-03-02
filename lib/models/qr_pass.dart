import 'package:cloud_firestore/cloud_firestore.dart';
import 'enums.dart';

class QrPass {
  final String id;
  final String leaveRequestId;
  final String studentId;
  final String studentName;
  final String studentRollNumber;
  final QrState state;
  final DateTime validFrom;
  final DateTime validUntil;
  final DateTime createdAt;
  final List<GateLog> gateLogs;

  QrPass({
    required this.id,
    required this.leaveRequestId,
    required this.studentId,
    required this.studentName,
    required this.studentRollNumber,
    required this.state,
    required this.validFrom,
    required this.validUntil,
    DateTime? createdAt,
    this.gateLogs = const [],
  }) : createdAt = createdAt ?? DateTime.now();

  bool get isExpired => DateTime.now().isAfter(validUntil);
  bool get isActive =>
      state != QrState.expired && state != QrState.hostelEntered && !isExpired;

  factory QrPass.fromFirestore(Map<String, dynamic> data, String id) {
    return QrPass(
      id: id,
      leaveRequestId: data['leaveRequestId'] ?? '',
      studentId: data['studentId'] ?? '',
      studentName: data['studentName'] ?? '',
      studentRollNumber: data['studentRollNumber'] ?? '',
      state: QrStateExtension.fromFirestore(data['state'] ?? 'unused'),
      validFrom: (data['validFrom'] as Timestamp).toDate(),
      validUntil: (data['validUntil'] as Timestamp).toDate(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      gateLogs: (data['gateLogs'] as List<dynamic>?)
              ?.map((e) => GateLog.fromMap(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'leaveRequestId': leaveRequestId,
      'studentId': studentId,
      'studentName': studentName,
      'studentRollNumber': studentRollNumber,
      'state': state.firestoreValue,
      'validFrom': Timestamp.fromDate(validFrom),
      'validUntil': Timestamp.fromDate(validUntil),
      'createdAt': Timestamp.fromDate(createdAt),
      'gateLogs': gateLogs.map((e) => e.toMap()).toList(),
    };
  }

  QrPass copyWith({QrState? state, List<GateLog>? gateLogs}) {
    return QrPass(
      id: id,
      leaveRequestId: leaveRequestId,
      studentId: studentId,
      studentName: studentName,
      studentRollNumber: studentRollNumber,
      state: state ?? this.state,
      validFrom: validFrom,
      validUntil: validUntil,
      createdAt: createdAt,
      gateLogs: gateLogs ?? this.gateLogs,
    );
  }
}

class GateLog {
  final String gateType; // hostel, main
  final String action; // entry, exit
  final String securityId;
  final String? laneType;
  final DateTime timestamp;
  final String? note;

  GateLog({
    required this.gateType,
    required this.action,
    required this.securityId,
    this.laneType,
    DateTime? timestamp,
    this.note,
  }) : timestamp = timestamp ?? DateTime.now();

  factory GateLog.fromMap(Map<String, dynamic> data) {
    return GateLog(
      gateType: data['gateType'] ?? '',
      action: data['action'] ?? '',
      securityId: data['securityId'] ?? '',
      laneType: data['laneType'],
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      note: data['note'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'gateType': gateType,
      'action': action,
      'securityId': securityId,
      'laneType': laneType,
      'timestamp': Timestamp.fromDate(timestamp),
      'note': note,
    };
  }
}
