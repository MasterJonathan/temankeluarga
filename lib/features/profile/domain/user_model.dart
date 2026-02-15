import 'package:cloud_firestore/cloud_firestore.dart';

enum UserRole {
  elderly, // Lansia
  guardian, // Pendamping
}

class UserProfile {
  final String id;
  final String name;
  final String email;
  final String photoUrl;
  final UserRole role;
  final String phone; // Tambahan
  final String? ageRange; // Tambahan: Dewasa muda, Dewasa mapan, Lansia
  final double textSize; // 0.8: Kecil, 1.0: Normal, 1.2: Besar
  final String? familyId;
  final List<String> enabledFeatures; 
  final DateTime createdAt; // Tambahan untuk sorting

  UserProfile({
    required this.id,
    required this.name,
    required this.email,
    required this.photoUrl,
    required this.role,
    this.phone = '',
    this.ageRange,
    this.textSize = 1.0,
    this.familyId,
    this.enabledFeatures = const ['health', 'activity', 'memory', 'chat'],

    required this.createdAt,
  });

  // --- SERIALIZATION FOR FIRESTORE ---

  // Konversi Object ke JSON (Untuk Simpan ke Firestore)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'photoUrl': photoUrl,
      'role': role.name, // Simpan sebagai string 'elderly' atau 'guardian'
      'phone': phone,
      'ageRange': ageRange,
      'textSize': textSize,
      'familyId': familyId,
      'enabledFeatures': enabledFeatures,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  // Konversi JSON ke Object (Untuk Baca dari Firestore)
  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      id: map['id'] ?? '',
      name: map['name'] ?? 'Tanpa Nama',
      email: map['email'] ?? '',
      photoUrl: map['photoUrl'] ?? 'https://ui-avatars.com/api/?name=User',
      // Convert String 'elderly' kembali ke Enum
      role: map['role'] == 'guardian' ? UserRole.guardian : UserRole.elderly,
      phone: map['phone'] ?? '',
      ageRange: map['ageRange'],
      textSize: (map['textSize'] as num?)?.toDouble() ?? 1.0,
      familyId: map['familyId'],
      enabledFeatures: List<String>.from(map['enabledFeatures'] ?? ['health', 'activity', 'memory', 'chat']),
      createdAt: (map['createdAt'] as Timestamp).toDate(),
    );
  }

  // CopyWith (Untuk update state lokal)
  UserProfile copyWith({
    String? name,
    String? photoUrl,
    UserRole? role,
    String? phone,
    String? ageRange,
    double? textSize,
    String? familyId,
  }) {
    return UserProfile(
      id: id,
      name: name ?? this.name,
      email: email,
      photoUrl: photoUrl ?? this.photoUrl,
      role: role ?? this.role,
      phone: phone ?? this.phone,
      ageRange: ageRange ?? this.ageRange,
      textSize: textSize ?? this.textSize,
      familyId: familyId ?? this.familyId,
      createdAt: createdAt,
    );
  }
}
