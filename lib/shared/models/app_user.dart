import 'package:cloud_firestore/cloud_firestore.dart';

class AppUser {
  const AppUser({
    required this.uid,
    required this.name,
    required this.email,
    required this.role,
    required this.createdAt,
    this.homeDistrict,
    this.homeConstituency,
    this.photoUrl,
    this.isBanned = false,
    this.votedPollIds = const <String>[],
  });

  final String uid;
  final String name;
  final String email;
  final String role;
  final Timestamp createdAt;
  final String? homeDistrict;
  final String? homeConstituency;
  final String? photoUrl;
  final bool isBanned;
  final List<String> votedPollIds;

  bool get isAdmin => role == 'admin';

  factory AppUser.fromMap(Map<String, dynamic> map) {
    return AppUser(
      uid: map['uid'] as String,
      name: map['name'] as String? ?? '',
      email: map['email'] as String? ?? '',
      role: map['role'] as String? ?? 'user',
      createdAt: map['createdAt'] as Timestamp? ?? Timestamp.now(),
      homeDistrict: map['homeDistrict'] as String?,
      homeConstituency: map['homeConstituency'] as String?,
      photoUrl: map['photoUrl'] as String?,
      isBanned: map['isBanned'] as bool? ?? false,
      votedPollIds: ((map['votedPollIds'] as List<dynamic>?) ?? <dynamic>[])
          .map((e) => e.toString())
          .toList(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'role': role,
      'createdAt': createdAt,
      'homeDistrict': homeDistrict,
      'homeConstituency': homeConstituency,
      'photoUrl': photoUrl,
      'isBanned': isBanned,
      'votedPollIds': votedPollIds,
    };
  }
}

