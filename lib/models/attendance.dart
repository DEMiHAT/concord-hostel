import 'package:cloud_firestore/cloud_firestore.dart';

/// Attendance status derived from movement data
enum AttendanceStatus {
  present,
  outValid,
  onLeave,
  nonResident,
  unaccounted,
  medicalRestricted,
}

extension AttendanceStatusExtension on AttendanceStatus {
  String get label {
    switch (this) {
      case AttendanceStatus.present:
        return 'Present';
      case AttendanceStatus.outValid:
        return 'Out (Valid)';
      case AttendanceStatus.onLeave:
        return 'On Leave';
      case AttendanceStatus.nonResident:
        return 'Non-Resident';
      case AttendanceStatus.unaccounted:
        return 'Unaccounted';
      case AttendanceStatus.medicalRestricted:
        return 'Medical Restricted';
    }
  }

  String get firestoreValue {
    switch (this) {
      case AttendanceStatus.present:
        return 'present';
      case AttendanceStatus.outValid:
        return 'out_valid';
      case AttendanceStatus.onLeave:
        return 'on_leave';
      case AttendanceStatus.nonResident:
        return 'non_resident';
      case AttendanceStatus.unaccounted:
        return 'unaccounted';
      case AttendanceStatus.medicalRestricted:
        return 'medical_restricted';
    }
  }

  static AttendanceStatus fromFirestore(String value) {
    switch (value) {
      case 'present':
        return AttendanceStatus.present;
      case 'out_valid':
        return AttendanceStatus.outValid;
      case 'on_leave':
        return AttendanceStatus.onLeave;
      case 'non_resident':
        return AttendanceStatus.nonResident;
      case 'unaccounted':
        return AttendanceStatus.unaccounted;
      case 'medical_restricted':
        return AttendanceStatus.medicalRestricted;
      default:
        return AttendanceStatus.present;
    }
  }
}

/// Daily attendance record for a student
class AttendanceRecord {
  final String id;
  final String studentId;
  final String studentName;
  final String hostelBlock;
  final DateTime date;
  final AttendanceStatus status;
  final String derivedFrom; // e.g., "gate_scan", "leave_approved", "medical"
  final DateTime generatedAt;

  AttendanceRecord({
    required this.id,
    required this.studentId,
    required this.studentName,
    required this.hostelBlock,
    required this.date,
    required this.status,
    required this.derivedFrom,
    DateTime? generatedAt,
  }) : generatedAt = generatedAt ?? DateTime.now();

  factory AttendanceRecord.fromFirestore(Map<String, dynamic> data, String id) {
    return AttendanceRecord(
      id: id,
      studentId: data['studentId'] ?? '',
      studentName: data['studentName'] ?? '',
      hostelBlock: data['hostelBlock'] ?? '',
      date: (data['date'] as Timestamp).toDate(),
      status: AttendanceStatusExtension.fromFirestore(data['status'] ?? 'present'),
      derivedFrom: data['derivedFrom'] ?? '',
      generatedAt: (data['generatedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'studentId': studentId,
      'studentName': studentName,
      'hostelBlock': hostelBlock,
      'date': Timestamp.fromDate(date),
      'status': status.firestoreValue,
      'derivedFrom': derivedFrom,
      'generatedAt': Timestamp.fromDate(generatedAt),
    };
  }
}

/// Exception type for attendance anomalies
enum AttendanceExceptionType {
  exitWithoutReturn,
  noHostelScanButCampusEntry,
  invalidGateOrder,
}

extension AttendanceExceptionTypeExtension on AttendanceExceptionType {
  String get label {
    switch (this) {
      case AttendanceExceptionType.exitWithoutReturn:
        return 'Exit Without Return';
      case AttendanceExceptionType.noHostelScanButCampusEntry:
        return 'No Hostel Scan But Campus Entry';
      case AttendanceExceptionType.invalidGateOrder:
        return 'Invalid Gate Order';
    }
  }
}

/// Attendance exception log entry
class AttendanceException {
  final String id;
  final String studentId;
  final String studentName;
  final AttendanceExceptionType type;
  final String description;
  final DateTime timestamp;
  final bool resolved;

  AttendanceException({
    required this.id,
    required this.studentId,
    required this.studentName,
    required this.type,
    required this.description,
    DateTime? timestamp,
    this.resolved = false,
  }) : timestamp = timestamp ?? DateTime.now();
}
