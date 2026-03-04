import 'package:cloud_firestore/cloud_firestore.dart';

/// Fitness status — visible to all stakeholders
enum FitnessStatus {
  fit,
  notFit,
  underObservation,
}

extension FitnessStatusExtension on FitnessStatus {
  String get label {
    switch (this) {
      case FitnessStatus.fit:
        return 'Fit for Class';
      case FitnessStatus.notFit:
        return 'Not Fit for Class';
      case FitnessStatus.underObservation:
        return 'Under Observation';
    }
  }

  String get firestoreValue {
    switch (this) {
      case FitnessStatus.fit:
        return 'fit';
      case FitnessStatus.notFit:
        return 'not_fit';
      case FitnessStatus.underObservation:
        return 'under_observation';
    }
  }

  static FitnessStatus fromFirestore(String value) {
    switch (value) {
      case 'fit':
        return FitnessStatus.fit;
      case 'not_fit':
        return FitnessStatus.notFit;
      case 'under_observation':
        return FitnessStatus.underObservation;
      default:
        return FitnessStatus.underObservation;
    }
  }
}

/// Medical record status lifecycle
enum MedicalStatus {
  pending,
  medicalVisit,
  medicalRest,
  medicalLeave,
  medicalRestricted,
  cleared,
}

extension MedicalStatusExtension on MedicalStatus {
  String get label {
    switch (this) {
      case MedicalStatus.pending:
        return 'Pending';
      case MedicalStatus.medicalVisit:
        return 'Medical Visit';
      case MedicalStatus.medicalRest:
        return 'Medical Rest';
      case MedicalStatus.medicalLeave:
        return 'Medical Leave';
      case MedicalStatus.medicalRestricted:
        return 'Movement Restricted';
      case MedicalStatus.cleared:
        return 'Cleared';
    }
  }

  String get firestoreValue {
    switch (this) {
      case MedicalStatus.pending:
        return 'pending';
      case MedicalStatus.medicalVisit:
        return 'medical_visit';
      case MedicalStatus.medicalRest:
        return 'medical_rest';
      case MedicalStatus.medicalLeave:
        return 'medical_leave';
      case MedicalStatus.medicalRestricted:
        return 'medical_restricted';
      case MedicalStatus.cleared:
        return 'cleared';
    }
  }

  static MedicalStatus fromFirestore(String value) {
    switch (value) {
      case 'pending':
        return MedicalStatus.pending;
      case 'medical_visit':
        return MedicalStatus.medicalVisit;
      case 'medical_rest':
        return MedicalStatus.medicalRest;
      case 'medical_leave':
        return MedicalStatus.medicalLeave;
      case 'medical_restricted':
        return MedicalStatus.medicalRestricted;
      case 'cleared':
        return MedicalStatus.cleared;
      default:
        return MedicalStatus.pending;
    }
  }
}

/// Intimation record — tracks who has been notified and acknowledged
class MedicalIntimation {
  final String role; // rt, faculty, warden, hod
  final String personName;
  final DateTime notifiedAt;
  final bool acknowledged;
  final DateTime? acknowledgedAt;

  MedicalIntimation({
    required this.role,
    required this.personName,
    required this.notifiedAt,
    this.acknowledged = false,
    this.acknowledgedAt,
  });

  factory MedicalIntimation.fromMap(Map<String, dynamic> data) {
    return MedicalIntimation(
      role: data['role'] ?? '',
      personName: data['personName'] ?? '',
      notifiedAt: (data['notifiedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      acknowledged: data['acknowledged'] ?? false,
      acknowledgedAt: (data['acknowledgedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'role': role,
      'personName': personName,
      'notifiedAt': Timestamp.fromDate(notifiedAt),
      'acknowledged': acknowledged,
      'acknowledgedAt': acknowledgedAt != null
          ? Timestamp.fromDate(acknowledgedAt!)
          : null,
    };
  }

  MedicalIntimation copyWith({bool? acknowledged, DateTime? acknowledgedAt}) {
    return MedicalIntimation(
      role: role,
      personName: personName,
      notifiedAt: notifiedAt,
      acknowledged: acknowledged ?? this.acknowledged,
      acknowledgedAt: acknowledgedAt ?? this.acknowledgedAt,
    );
  }
}

/// Medical visit record — created by Medical Officer
class MedicalVisit {
  final String id;
  final String studentId;
  final String studentName;
  final String hostelBlock;
  final String? rollNumber;

  // Created by Medical Officer
  final String createdByOfficerId;
  final String createdByOfficerName;

  // Clinical details
  final String symptoms;
  final String? diagnosis;
  final int? restDays;
  final FitnessStatus fitnessStatus;
  final MedicalStatus status;
  final bool movementRestricted;
  final List<String> documentUrls;

  // Officer notes
  final String? medicalOfficerNote;
  final String? prescription;

  // Intimation tracking
  final List<MedicalIntimation> intimations;

  // Student review request
  final bool reviewRequested;
  final String? reviewRequestNote;
  final DateTime? reviewRequestedAt;

  final DateTime createdAt;
  final DateTime? clearedAt;
  final String? clearedBy;

  MedicalVisit({
    required this.id,
    required this.studentId,
    required this.studentName,
    required this.hostelBlock,
    this.rollNumber,
    required this.createdByOfficerId,
    required this.createdByOfficerName,
    required this.symptoms,
    this.diagnosis,
    this.restDays,
    this.fitnessStatus = FitnessStatus.underObservation,
    required this.status,
    this.movementRestricted = false,
    this.documentUrls = const [],
    this.medicalOfficerNote,
    this.prescription,
    this.intimations = const [],
    this.reviewRequested = false,
    this.reviewRequestNote,
    this.reviewRequestedAt,
    DateTime? createdAt,
    this.clearedAt,
    this.clearedBy,
  }) : createdAt = createdAt ?? DateTime.now();

  factory MedicalVisit.fromFirestore(Map<String, dynamic> data, String id) {
    return MedicalVisit(
      id: id,
      studentId: data['studentId'] ?? '',
      studentName: data['studentName'] ?? '',
      hostelBlock: data['hostelBlock'] ?? '',
      rollNumber: data['rollNumber'],
      createdByOfficerId: data['createdByOfficerId'] ?? '',
      createdByOfficerName: data['createdByOfficerName'] ?? '',
      symptoms: data['symptoms'] ?? '',
      diagnosis: data['diagnosis'],
      restDays: data['restDays'],
      fitnessStatus: FitnessStatusExtension.fromFirestore(
          data['fitnessStatus'] ?? 'under_observation'),
      status: MedicalStatusExtension.fromFirestore(data['status'] ?? 'pending'),
      movementRestricted: data['movementRestricted'] ?? false,
      documentUrls: List<String>.from(data['documentUrls'] ?? []),
      medicalOfficerNote: data['medicalOfficerNote'],
      prescription: data['prescription'],
      intimations: (data['intimations'] as List<dynamic>?)
              ?.map((e) => MedicalIntimation.fromMap(e as Map<String, dynamic>))
              .toList() ?? [],
      reviewRequested: data['reviewRequested'] ?? false,
      reviewRequestNote: data['reviewRequestNote'],
      reviewRequestedAt: (data['reviewRequestedAt'] as Timestamp?)?.toDate(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      clearedAt: (data['clearedAt'] as Timestamp?)?.toDate(),
      clearedBy: data['clearedBy'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'studentId': studentId,
      'studentName': studentName,
      'hostelBlock': hostelBlock,
      'rollNumber': rollNumber,
      'createdByOfficerId': createdByOfficerId,
      'createdByOfficerName': createdByOfficerName,
      'symptoms': symptoms,
      'diagnosis': diagnosis,
      'restDays': restDays,
      'fitnessStatus': fitnessStatus.firestoreValue,
      'status': status.firestoreValue,
      'movementRestricted': movementRestricted,
      'documentUrls': documentUrls,
      'medicalOfficerNote': medicalOfficerNote,
      'prescription': prescription,
      'intimations': intimations.map((i) => i.toMap()).toList(),
      'reviewRequested': reviewRequested,
      'reviewRequestNote': reviewRequestNote,
      'reviewRequestedAt': reviewRequestedAt != null
          ? Timestamp.fromDate(reviewRequestedAt!)
          : null,
      'createdAt': Timestamp.fromDate(createdAt),
      'clearedAt': clearedAt != null ? Timestamp.fromDate(clearedAt!) : null,
      'clearedBy': clearedBy,
    };
  }

  MedicalVisit copyWith({
    MedicalStatus? status,
    String? diagnosis,
    int? restDays,
    FitnessStatus? fitnessStatus,
    bool? movementRestricted,
    List<String>? documentUrls,
    String? medicalOfficerNote,
    String? prescription,
    List<MedicalIntimation>? intimations,
    bool? reviewRequested,
    String? reviewRequestNote,
    DateTime? reviewRequestedAt,
    DateTime? clearedAt,
    String? clearedBy,
  }) {
    return MedicalVisit(
      id: id,
      studentId: studentId,
      studentName: studentName,
      hostelBlock: hostelBlock,
      rollNumber: rollNumber,
      createdByOfficerId: createdByOfficerId,
      createdByOfficerName: createdByOfficerName,
      symptoms: symptoms,
      status: status ?? this.status,
      diagnosis: diagnosis ?? this.diagnosis,
      restDays: restDays ?? this.restDays,
      fitnessStatus: fitnessStatus ?? this.fitnessStatus,
      movementRestricted: movementRestricted ?? this.movementRestricted,
      documentUrls: documentUrls ?? this.documentUrls,
      medicalOfficerNote: medicalOfficerNote ?? this.medicalOfficerNote,
      prescription: prescription ?? this.prescription,
      intimations: intimations ?? this.intimations,
      reviewRequested: reviewRequested ?? this.reviewRequested,
      reviewRequestNote: reviewRequestNote ?? this.reviewRequestNote,
      reviewRequestedAt: reviewRequestedAt ?? this.reviewRequestedAt,
      createdAt: createdAt,
      clearedAt: clearedAt ?? this.clearedAt,
      clearedBy: clearedBy ?? this.clearedBy,
    );
  }
}
