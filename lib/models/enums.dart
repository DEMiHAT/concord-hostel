import 'package:flutter/material.dart';

/// Leave type enumeration
enum LeaveType {
  dayPass,
  overnight,
  weekend,
  emergency,
  academic,
  extended,
  workingDayHoliday,
}

extension LeaveTypeExtension on LeaveType {
  String get label {
    switch (this) {
      case LeaveType.dayPass:
        return 'Day Pass';
      case LeaveType.overnight:
        return 'Overnight';
      case LeaveType.weekend:
        return 'Weekend';
      case LeaveType.emergency:
        return 'Emergency';
      case LeaveType.academic:
        return 'Academic';
      case LeaveType.extended:
        return 'Extended';
      case LeaveType.workingDayHoliday:
        return 'Working Day Holiday';
    }
  }

  String get icon {
    switch (this) {
      case LeaveType.dayPass:
        return '☀️';
      case LeaveType.overnight:
        return '🌙';
      case LeaveType.weekend:
        return '🗓️';
      case LeaveType.emergency:
        return '🚨';
      case LeaveType.academic:
        return '📚';
      case LeaveType.extended:
        return '✈️';
      case LeaveType.workingDayHoliday:
        return '🏖️';
    }
  }

  List<String> get approvalChain {
    switch (this) {
      case LeaveType.dayPass:
        return ['RT'];
      case LeaveType.overnight:
        return ['RT', 'Parent'];
      case LeaveType.weekend:
        return ['RT', 'Parent'];
      case LeaveType.emergency:
        return ['RT'];
      case LeaveType.academic:
        return ['RT', 'HoD'];
      case LeaveType.extended:
        return ['RT', 'Parent', 'Warden'];
      case LeaveType.workingDayHoliday:
        return ['RT', 'Faculty', 'HoD', 'RT Final', 'Parent/Warden'];
    }
  }
}

/// Leave request status
enum LeaveStatus {
  pending,
  forwardedToParent,
  forwardedToHod,
  forwardedToWarden,
  forwardedToFaculty,
  documentsRequested,
  awaitingHodAfterFaculty,
  returnedToRt,
  approved,
  rejected,
}

extension LeaveStatusExtension on LeaveStatus {
  String get label {
    switch (this) {
      case LeaveStatus.pending:
        return 'Pending';
      case LeaveStatus.forwardedToParent:
        return 'Forwarded to Parent';
      case LeaveStatus.forwardedToHod:
        return 'Forwarded to HoD';
      case LeaveStatus.forwardedToWarden:
        return 'Forwarded to Warden';
      case LeaveStatus.forwardedToFaculty:
        return 'Forwarded to Faculty';
      case LeaveStatus.documentsRequested:
        return 'Documents Requested';
      case LeaveStatus.awaitingHodAfterFaculty:
        return 'Awaiting HoD Review';
      case LeaveStatus.returnedToRt:
        return 'Returned to RT';
      case LeaveStatus.approved:
        return 'Approved';
      case LeaveStatus.rejected:
        return 'Rejected';
    }
  }

  String get firestoreValue {
    switch (this) {
      case LeaveStatus.pending:
        return 'pending';
      case LeaveStatus.forwardedToParent:
        return 'forwarded_to_parent';
      case LeaveStatus.forwardedToHod:
        return 'forwarded_to_hod';
      case LeaveStatus.forwardedToWarden:
        return 'forwarded_to_warden';
      case LeaveStatus.forwardedToFaculty:
        return 'forwarded_to_faculty';
      case LeaveStatus.documentsRequested:
        return 'documents_requested';
      case LeaveStatus.awaitingHodAfterFaculty:
        return 'awaiting_hod_after_faculty';
      case LeaveStatus.returnedToRt:
        return 'returned_to_rt';
      case LeaveStatus.approved:
        return 'approved';
      case LeaveStatus.rejected:
        return 'rejected';
    }
  }

  static LeaveStatus fromFirestore(String value) {
    switch (value) {
      case 'pending':
        return LeaveStatus.pending;
      case 'forwarded_to_parent':
        return LeaveStatus.forwardedToParent;
      case 'forwarded_to_hod':
        return LeaveStatus.forwardedToHod;
      case 'forwarded_to_warden':
        return LeaveStatus.forwardedToWarden;
      case 'forwarded_to_faculty':
        return LeaveStatus.forwardedToFaculty;
      case 'documents_requested':
        return LeaveStatus.documentsRequested;
      case 'awaiting_hod_after_faculty':
        return LeaveStatus.awaitingHodAfterFaculty;
      case 'returned_to_rt':
        return LeaveStatus.returnedToRt;
      case 'approved':
        return LeaveStatus.approved;
      case 'rejected':
        return LeaveStatus.rejected;
      default:
        return LeaveStatus.pending;
    }
  }
}

/// QR Code state machine
enum QrState {
  unused,
  hostelExited,
  campusExited,
  campusEntered,
  hostelEntered,
  expired,
}

extension QrStateExtension on QrState {
  String get label {
    switch (this) {
      case QrState.unused:
        return 'Unused';
      case QrState.hostelExited:
        return 'Hostel Exited';
      case QrState.campusExited:
        return 'Campus Exited';
      case QrState.campusEntered:
        return 'Campus Entered';
      case QrState.hostelEntered:
        return 'Hostel Entered';
      case QrState.expired:
        return 'Expired';
    }
  }

  String get firestoreValue {
    switch (this) {
      case QrState.unused:
        return 'unused';
      case QrState.hostelExited:
        return 'hostel_exited';
      case QrState.campusExited:
        return 'campus_exited';
      case QrState.campusEntered:
        return 'campus_entered';
      case QrState.hostelEntered:
        return 'hostel_entered';
      case QrState.expired:
        return 'expired';
    }
  }

  static QrState fromFirestore(String value) {
    switch (value) {
      case 'unused':
        return QrState.unused;
      case 'hostel_exited':
        return QrState.hostelExited;
      case 'campus_exited':
        return QrState.campusExited;
      case 'campus_entered':
        return QrState.campusEntered;
      case 'hostel_entered':
        return QrState.hostelEntered;
      case 'expired':
        return QrState.expired;
      default:
        return QrState.unused;
    }
  }
}

/// User roles
enum UserRole {
  student,
  rt,
  faculty,
  hod,
  warden,
  parent,
  security,
  admin,
}

extension UserRoleExtension on UserRole {
  String get label {
    switch (this) {
      case UserRole.student:
        return 'Student';
      case UserRole.rt:
        return 'Resident Tutor';
      case UserRole.faculty:
        return 'Faculty Advisor';
      case UserRole.hod:
        return 'Head of Department';
      case UserRole.warden:
        return 'Warden';
      case UserRole.parent:
        return 'Parent';
      case UserRole.security:
        return 'Security';
      case UserRole.admin:
        return 'Admin';
    }
  }

  String get firestoreValue {
    switch (this) {
      case UserRole.student:
        return 'student';
      case UserRole.rt:
        return 'rt';
      case UserRole.faculty:
        return 'faculty';
      case UserRole.hod:
        return 'hod';
      case UserRole.warden:
        return 'warden';
      case UserRole.parent:
        return 'parent';
      case UserRole.security:
        return 'security';
      case UserRole.admin:
        return 'admin';
    }
  }

  static UserRole fromFirestore(String value) {
    switch (value) {
      case 'student':
        return UserRole.student;
      case 'rt':
        return UserRole.rt;
      case 'faculty':
        return UserRole.faculty;
      case 'hod':
        return UserRole.hod;
      case 'warden':
        return UserRole.warden;
      case 'parent':
        return UserRole.parent;
      case 'security':
        return UserRole.security;
      case 'admin':
        return UserRole.admin;
      default:
        return UserRole.student;
    }
  }
}

/// Gate types
enum GateType { hostel, main }

/// Lane types for hostel gate
enum LaneType { fastLane, scanLane, busMode, exception }

extension LaneTypeExtension on LaneType {
  String get label {
    switch (this) {
      case LaneType.fastLane:
        return 'Fast Lane';
      case LaneType.scanLane:
        return 'Scan Lane';
      case LaneType.busMode:
        return 'Bus Mode';
      case LaneType.exception:
        return 'Exception';
    }
  }

  String get description {
    switch (this) {
      case LaneType.fastLane:
        return 'Pre-scanned quick exit';
      case LaneType.scanLane:
        return 'Standard QR scanning';
      case LaneType.busMode:
        return 'Bus departure queue';
      case LaneType.exception:
        return 'Manual override';
    }
  }

  IconData get icon {
    switch (this) {
      case LaneType.fastLane:
        return Icons.flash_on_rounded;
      case LaneType.scanLane:
        return Icons.qr_code_scanner_rounded;
      case LaneType.busMode:
        return Icons.directions_bus_rounded;
      case LaneType.exception:
        return Icons.warning_amber_rounded;
    }
  }

  Color get color {
    switch (this) {
      case LaneType.fastLane:
        return const Color(0xFF10B981);
      case LaneType.scanLane:
        return const Color(0xFF6C63FF);
      case LaneType.busMode:
        return const Color(0xFFF59E0B);
      case LaneType.exception:
        return const Color(0xFFEF4444);
    }
  }
}
