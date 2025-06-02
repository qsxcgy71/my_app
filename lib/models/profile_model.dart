import 'package:cloud_firestore/cloud_firestore.dart';

class ChildInfo {
  String id;
  String name;
  DateTime? birthDate;
  String? photoUrl;

  ChildInfo({
    required this.id,
    required this.name,
    this.birthDate,
    this.photoUrl,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'birthDate': birthDate?.toIso8601String(),
      'photoUrl': photoUrl,
    };
  }

  factory ChildInfo.fromMap(Map<String, dynamic> map) {
    return ChildInfo(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      birthDate: map['birthDate'] != null ? DateTime.parse(map['birthDate']) : null,
      photoUrl: map['photoUrl'],
    );
  }
}

class UserProfile {
  String userId;
  String name;
  String phone;
  String email;
  List<ChildInfo> children;

  UserProfile({
    required this.userId,
    required this.name,
    required this.phone,
    required this.email,
    this.children = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'name': name,
      'phone': phone,
      'email': email,
      'children': children.map((child) => child.toMap()).toList(),
    };
  }

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      userId: map['userId'] ?? '',
      name: map['name'] ?? '',
      phone: map['phone'] ?? '',
      email: map['email'] ?? '',
      children: (map['children'] as List<dynamic>?)
          ?.map((child) => ChildInfo.fromMap(child as Map<String, dynamic>))
          .toList() ?? [],
    );
  }
} 