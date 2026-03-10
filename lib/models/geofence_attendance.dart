import 'package:cloud_firestore/cloud_firestore.dart';

/// Status of a geofence attendance session
enum GeofenceSessionStatus {
  active,
  closed,
  expired,
}

extension GeofenceSessionStatusExtension on GeofenceSessionStatus {
  String get label {
    switch (this) {
      case GeofenceSessionStatus.active:
        return 'Active';
      case GeofenceSessionStatus.closed:
        return 'Closed';
      case GeofenceSessionStatus.expired:
        return 'Expired';
    }
  }

  String get firestoreValue {
    switch (this) {
      case GeofenceSessionStatus.active:
        return 'active';
      case GeofenceSessionStatus.closed:
        return 'closed';
      case GeofenceSessionStatus.expired:
        return 'expired';
    }
  }
}

/// Type of attendance anomaly raised by the RT
enum AnomalyType {
  frequentAbsence,
  suspiciousLocation,
  lateEntry,
  proxyAttempt,
  consecutiveMiss,
}

extension AnomalyTypeExtension on AnomalyType {
  String get label {
    switch (this) {
      case AnomalyType.frequentAbsence:
        return 'Frequent Absence';
      case AnomalyType.suspiciousLocation:
        return 'Suspicious Location';
      case AnomalyType.lateEntry:
        return 'Late Entry';
      case AnomalyType.proxyAttempt:
        return 'Proxy Attempt';
      case AnomalyType.consecutiveMiss:
        return 'Consecutive Miss';
    }
  }

  String get icon {
    switch (this) {
      case AnomalyType.frequentAbsence:
        return '📉';
      case AnomalyType.suspiciousLocation:
        return '📍';
      case AnomalyType.lateEntry:
        return '⏰';
      case AnomalyType.proxyAttempt:
        return '🚫';
      case AnomalyType.consecutiveMiss:
        return '⚠️';
    }
  }
}

/// A geofence attendance session opened by the RT
class GeofenceSession {
  final String id;
  final String rtId;
  final String rtName;
  final String hostelBlock;
  final double centerLat;
  final double centerLng;
  final double radiusMeters;
  final DateTime startTime;
  final DateTime? endTime;
  final GeofenceSessionStatus status;
  final int totalStudents;
  final int markedCount;

  GeofenceSession({
    required this.id,
    required this.rtId,
    required this.rtName,
    required this.hostelBlock,
    required this.centerLat,
    required this.centerLng,
    this.radiusMeters = 100.0,
    required this.startTime,
    this.endTime,
    this.status = GeofenceSessionStatus.active,
    this.totalStudents = 0,
    this.markedCount = 0,
  });

  bool get isActive => status == GeofenceSessionStatus.active;

  Duration get duration {
    final end = endTime ?? DateTime.now();
    return end.difference(startTime);
  }

  double get completionRate {
    if (totalStudents == 0) return 0;
    return markedCount / totalStudents;
  }

  GeofenceSession copyWith({
    DateTime? endTime,
    GeofenceSessionStatus? status,
    int? markedCount,
    int? totalStudents,
  }) {
    return GeofenceSession(
      id: id,
      rtId: rtId,
      rtName: rtName,
      hostelBlock: hostelBlock,
      centerLat: centerLat,
      centerLng: centerLng,
      radiusMeters: radiusMeters,
      startTime: startTime,
      endTime: endTime ?? this.endTime,
      status: status ?? this.status,
      totalStudents: totalStudents ?? this.totalStudents,
      markedCount: markedCount ?? this.markedCount,
    );
  }

  factory GeofenceSession.fromFirestore(Map<String, dynamic> data, String id) {
    return GeofenceSession(
      id: id,
      rtId: data['rtId'] ?? '',
      rtName: data['rtName'] ?? '',
      hostelBlock: data['hostelBlock'] ?? '',
      centerLat: (data['centerLat'] ?? 0.0).toDouble(),
      centerLng: (data['centerLng'] ?? 0.0).toDouble(),
      radiusMeters: (data['radiusMeters'] ?? 100.0).toDouble(),
      startTime: (data['startTime'] as Timestamp).toDate(),
      endTime: (data['endTime'] as Timestamp?)?.toDate(),
      status: GeofenceSessionStatus.values.firstWhere(
        (s) => s.firestoreValue == (data['status'] ?? 'active'),
        orElse: () => GeofenceSessionStatus.active,
      ),
      totalStudents: data['totalStudents'] ?? 0,
      markedCount: data['markedCount'] ?? 0,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'rtId': rtId,
      'rtName': rtName,
      'hostelBlock': hostelBlock,
      'centerLat': centerLat,
      'centerLng': centerLng,
      'radiusMeters': radiusMeters,
      'startTime': Timestamp.fromDate(startTime),
      'endTime': endTime != null ? Timestamp.fromDate(endTime!) : null,
      'status': status.firestoreValue,
      'totalStudents': totalStudents,
      'markedCount': markedCount,
    };
  }
}

/// Individual student attendance check-in record
class GeofenceCheckIn {
  final String id;
  final String sessionId;
  final String studentId;
  final String studentName;
  final String rollNumber;
  final String hostelBlock;
  final DateTime timestamp;
  final bool insideGeofence;
  final double? distanceFromCenter; // meters

  GeofenceCheckIn({
    required this.id,
    required this.sessionId,
    required this.studentId,
    required this.studentName,
    required this.rollNumber,
    required this.hostelBlock,
    DateTime? timestamp,
    this.insideGeofence = true,
    this.distanceFromCenter,
  }) : timestamp = timestamp ?? DateTime.now();

  factory GeofenceCheckIn.fromFirestore(Map<String, dynamic> data, String id) {
    return GeofenceCheckIn(
      id: id,
      sessionId: data['sessionId'] ?? '',
      studentId: data['studentId'] ?? '',
      studentName: data['studentName'] ?? '',
      rollNumber: data['rollNumber'] ?? '',
      hostelBlock: data['hostelBlock'] ?? '',
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      insideGeofence: data['insideGeofence'] ?? true,
      distanceFromCenter: (data['distanceFromCenter'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'sessionId': sessionId,
      'studentId': studentId,
      'studentName': studentName,
      'rollNumber': rollNumber,
      'hostelBlock': hostelBlock,
      'timestamp': Timestamp.fromDate(timestamp),
      'insideGeofence': insideGeofence,
      'distanceFromCenter': distanceFromCenter,
    };
  }
}

/// Attendance anomaly raised by the RT
class AttendanceAnomaly {
  final String id;
  final String studentId;
  final String studentName;
  final String rollNumber;
  final String hostelBlock;
  final AnomalyType type;
  final String description;
  final String raisedById;
  final String raisedByName;
  final DateTime raisedAt;
  final bool parentNotified;
  final bool resolved;
  final String? parentResponse;
  final DateTime? resolvedAt;

  AttendanceAnomaly({
    required this.id,
    required this.studentId,
    required this.studentName,
    required this.rollNumber,
    required this.hostelBlock,
    required this.type,
    required this.description,
    required this.raisedById,
    required this.raisedByName,
    DateTime? raisedAt,
    this.parentNotified = true,
    this.resolved = false,
    this.parentResponse,
    this.resolvedAt,
  }) : raisedAt = raisedAt ?? DateTime.now();

  AttendanceAnomaly copyWith({
    bool? resolved,
    String? parentResponse,
    DateTime? resolvedAt,
  }) {
    return AttendanceAnomaly(
      id: id,
      studentId: studentId,
      studentName: studentName,
      rollNumber: rollNumber,
      hostelBlock: hostelBlock,
      type: type,
      description: description,
      raisedById: raisedById,
      raisedByName: raisedByName,
      raisedAt: raisedAt,
      parentNotified: parentNotified,
      resolved: resolved ?? this.resolved,
      parentResponse: parentResponse ?? this.parentResponse,
      resolvedAt: resolvedAt ?? this.resolvedAt,
    );
  }
}

/// Summary analytics for a student's geofence attendance
class StudentAttendanceSummary {
  final String studentId;
  final String studentName;
  final String rollNumber;
  final int totalSessions;
  final int attended;
  final int missed;
  final double percentage;
  final int anomalyCount;

  StudentAttendanceSummary({
    required this.studentId,
    required this.studentName,
    required this.rollNumber,
    required this.totalSessions,
    required this.attended,
    required this.missed,
    required this.percentage,
    this.anomalyCount = 0,
  });
}
