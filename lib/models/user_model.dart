import 'package:cloud_firestore/cloud_firestore.dart';
import 'enums.dart';

class AppUser {
  final String uid;
  final String name;
  final String email;
  final UserRole role;
  final String? rollNumber;
  final String? hostelBlock;
  final String? roomNumber;
  final String? department;
  final String? phone;
  final String? parentPhone;
  final String? profileImageUrl;
  final DateTime createdAt;

  AppUser({
    required this.uid,
    required this.name,
    required this.email,
    required this.role,
    this.rollNumber,
    this.hostelBlock,
    this.roomNumber,
    this.department,
    this.phone,
    this.parentPhone,
    this.profileImageUrl,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory AppUser.fromFirestore(Map<String, dynamic> data, String id) {
    return AppUser(
      uid: id,
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      role: UserRoleExtension.fromFirestore(data['role'] ?? 'student'),
      rollNumber: data['rollNumber'],
      hostelBlock: data['hostelBlock'],
      roomNumber: data['roomNumber'],
      department: data['department'],
      phone: data['phone'],
      parentPhone: data['parentPhone'],
      profileImageUrl: data['profileImageUrl'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'email': email,
      'role': role.firestoreValue,
      'rollNumber': rollNumber,
      'hostelBlock': hostelBlock,
      'roomNumber': roomNumber,
      'department': department,
      'phone': phone,
      'parentPhone': parentPhone,
      'profileImageUrl': profileImageUrl,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
