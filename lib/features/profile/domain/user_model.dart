enum UserRole {
  elderly,   // Lansia (User Utama)
  guardian,  // Anak/Pendamping (Admin)
}

class UserProfile {
  final String id;
  final String name;
  final String email;
  final String photoUrl;
  final UserRole role;
  final String? familyId; // Kode Keluarga (misal: "KEL-BUDI")
  
  // Khusus Guardian: Daftar ID lansia yang dia urus
  final List<String> managedElderlyIds; 

  UserProfile({
    required this.id,
    required this.name,
    required this.email,
    required this.photoUrl,
    required this.role,
    this.familyId,
    this.managedElderlyIds = const [],
  });

  // CopyWith untuk update state immutabel
  UserProfile copyWith({
    String? name,
    UserRole? role,
    String? familyId,
    List<String>? managedElderlyIds,
  }) {
    return UserProfile(
      id: id,
      name: name ?? this.name,
      email: email,
      photoUrl: photoUrl,
      role: role ?? this.role,
      familyId: familyId ?? this.familyId,
      managedElderlyIds: managedElderlyIds ?? this.managedElderlyIds,
    );
  }
}