import 'package:cloud_firestore/cloud_firestore.dart';

/// Grievance categories
enum GrievanceCategory {
  room,
  maintenance,
  mess,
  safety,
  discipline,
  harassment,
  other,
}

extension GrievanceCategoryExtension on GrievanceCategory {
  String get label {
    switch (this) {
      case GrievanceCategory.room:
        return 'Room Issues';
      case GrievanceCategory.maintenance:
        return 'Maintenance';
      case GrievanceCategory.mess:
        return 'Mess / Food';
      case GrievanceCategory.safety:
        return 'Safety';
      case GrievanceCategory.discipline:
        return 'Discipline';
      case GrievanceCategory.harassment:
        return 'Harassment';
      case GrievanceCategory.other:
        return 'Other';
    }
  }

  String get icon {
    switch (this) {
      case GrievanceCategory.room:
        return '🚪';
      case GrievanceCategory.maintenance:
        return '🔧';
      case GrievanceCategory.mess:
        return '🍽️';
      case GrievanceCategory.safety:
        return '🛡️';
      case GrievanceCategory.discipline:
        return '⚖️';
      case GrievanceCategory.harassment:
        return '🚨';
      case GrievanceCategory.other:
        return '📝';
    }
  }

  String get firestoreValue {
    switch (this) {
      case GrievanceCategory.room:
        return 'room';
      case GrievanceCategory.maintenance:
        return 'maintenance';
      case GrievanceCategory.mess:
        return 'mess';
      case GrievanceCategory.safety:
        return 'safety';
      case GrievanceCategory.discipline:
        return 'discipline';
      case GrievanceCategory.harassment:
        return 'harassment';
      case GrievanceCategory.other:
        return 'other';
    }
  }
}

/// Grievance status lifecycle
enum GrievanceStatus {
  open,
  underReview,
  actionTaken,
  escalated,
  resolved,
}

extension GrievanceStatusExtension on GrievanceStatus {
  String get label {
    switch (this) {
      case GrievanceStatus.open:
        return 'Open';
      case GrievanceStatus.underReview:
        return 'Under Review';
      case GrievanceStatus.actionTaken:
        return 'Action Taken';
      case GrievanceStatus.escalated:
        return 'Escalated';
      case GrievanceStatus.resolved:
        return 'Resolved';
    }
  }

  String get firestoreValue {
    switch (this) {
      case GrievanceStatus.open:
        return 'open';
      case GrievanceStatus.underReview:
        return 'under_review';
      case GrievanceStatus.actionTaken:
        return 'action_taken';
      case GrievanceStatus.escalated:
        return 'escalated';
      case GrievanceStatus.resolved:
        return 'resolved';
    }
  }

  static GrievanceStatus fromFirestore(String value) {
    switch (value) {
      case 'open':
        return GrievanceStatus.open;
      case 'under_review':
        return GrievanceStatus.underReview;
      case 'action_taken':
        return GrievanceStatus.actionTaken;
      case 'escalated':
        return GrievanceStatus.escalated;
      case 'resolved':
        return GrievanceStatus.resolved;
      default:
        return GrievanceStatus.open;
    }
  }
}

/// Grievance action log entry
class GrievanceAction {
  final String actorId;
  final String actorName;
  final String actorRole;
  final String action; // e.g., "Responded", "Escalated", "Resolved"
  final String? comment;
  final DateTime timestamp;

  GrievanceAction({
    required this.actorId,
    required this.actorName,
    required this.actorRole,
    required this.action,
    this.comment,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  factory GrievanceAction.fromMap(Map<String, dynamic> data) {
    return GrievanceAction(
      actorId: data['actorId'] ?? '',
      actorName: data['actorName'] ?? '',
      actorRole: data['actorRole'] ?? '',
      action: data['action'] ?? '',
      comment: data['comment'],
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'actorId': actorId,
      'actorName': actorName,
      'actorRole': actorRole,
      'action': action,
      'comment': comment,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }
}

/// Grievance record
class Grievance {
  final String id;
  final String studentId;
  final String studentName;
  final String hostelBlock;
  final String roomNumber;
  final GrievanceCategory category;
  final String description;
  final GrievanceStatus status;
  final String? imageUrl;
  final List<GrievanceAction> actions;
  final int escalationLevel; // 0=RT, 1=Warden, 2=Admin
  final String? assignedTo; // role currently handling
  final DateTime createdAt;
  final DateTime? resolvedAt;

  Grievance({
    required this.id,
    required this.studentId,
    required this.studentName,
    required this.hostelBlock,
    required this.roomNumber,
    required this.category,
    required this.description,
    required this.status,
    this.imageUrl,
    this.actions = const [],
    this.escalationLevel = 0,
    this.assignedTo,
    DateTime? createdAt,
    this.resolvedAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory Grievance.fromFirestore(Map<String, dynamic> data, String id) {
    return Grievance(
      id: id,
      studentId: data['studentId'] ?? '',
      studentName: data['studentName'] ?? '',
      hostelBlock: data['hostelBlock'] ?? '',
      roomNumber: data['roomNumber'] ?? '',
      category: GrievanceCategory.values.firstWhere(
        (c) => c.firestoreValue == (data['category'] ?? 'other'),
        orElse: () => GrievanceCategory.other,
      ),
      description: data['description'] ?? '',
      status: GrievanceStatusExtension.fromFirestore(data['status'] ?? 'open'),
      imageUrl: data['imageUrl'],
      actions: (data['actions'] as List<dynamic>?)
              ?.map((e) => GrievanceAction.fromMap(e as Map<String, dynamic>))
              .toList() ??
          [],
      escalationLevel: data['escalationLevel'] ?? 0,
      assignedTo: data['assignedTo'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      resolvedAt: (data['resolvedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'studentId': studentId,
      'studentName': studentName,
      'hostelBlock': hostelBlock,
      'roomNumber': roomNumber,
      'category': category.firestoreValue,
      'description': description,
      'status': status.firestoreValue,
      'imageUrl': imageUrl,
      'actions': actions.map((a) => a.toMap()).toList(),
      'escalationLevel': escalationLevel,
      'assignedTo': assignedTo,
      'createdAt': Timestamp.fromDate(createdAt),
      'resolvedAt': resolvedAt != null ? Timestamp.fromDate(resolvedAt!) : null,
    };
  }

  Grievance copyWith({
    GrievanceStatus? status,
    List<GrievanceAction>? actions,
    int? escalationLevel,
    String? assignedTo,
    DateTime? resolvedAt,
  }) {
    return Grievance(
      id: id,
      studentId: studentId,
      studentName: studentName,
      hostelBlock: hostelBlock,
      roomNumber: roomNumber,
      category: category,
      description: description,
      status: status ?? this.status,
      imageUrl: imageUrl,
      actions: actions ?? this.actions,
      escalationLevel: escalationLevel ?? this.escalationLevel,
      assignedTo: assignedTo ?? this.assignedTo,
      createdAt: createdAt,
      resolvedAt: resolvedAt ?? this.resolvedAt,
    );
  }
}
