import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/user_model.dart';

class ProfileRepository {
  // Mock Database
  UserProfile _currentUser = UserProfile(
    id: 'guardian_1',
    name: 'Budi Santoso',
    email: 'budi@gmail.com',
    photoUrl: 'https://i.pravatar.cc/300?img=11', // Foto Anak
    role: UserRole.guardian, // Default Login sebagai Guardian
    familyId: 'KEL-8899',
    managedElderlyIds: ['elderly_1'],
  );

  final UserProfile _managedElderly = UserProfile(
    id: 'elderly_1',
    name: 'Bapak Sutomo',
    email: 'sutomo@gmail.com',
    photoUrl: 'https://i.pravatar.cc/300?img=13', // Foto Bapak
    role: UserRole.elderly,
    familyId: 'KEL-8899',
  );

  // 1. Ambil Profil Saya
  Future<UserProfile> getCurrentUser() async {
    await Future.delayed(const Duration(milliseconds: 500));
    return _currentUser;
  }

  // 2. Simulasi Ganti Role (Untuk Demo/Testing)
  Future<UserProfile> switchRoleDemo() async {
    await Future.delayed(const Duration(milliseconds: 300));
    if (_currentUser.role == UserRole.guardian) {
      // Jadi Lansia
      _currentUser = _managedElderly; 
    } else {
      // Jadi Guardian (Reset ke Budi)
      _currentUser = UserProfile(
        id: 'guardian_1',
        name: 'Budi Santoso',
        email: 'budi@gmail.com',
        photoUrl: 'https://i.pravatar.cc/300?img=11',
        role: UserRole.guardian,
        familyId: 'KEL-8899',
        managedElderlyIds: ['elderly_1'],
      );
    }
    return _currentUser;
  }

  // 3. Gabung Keluarga
  Future<void> joinFamily(String code) async {
    await Future.delayed(const Duration(seconds: 1));
    // Simulasi sukses
    _currentUser = _currentUser.copyWith(familyId: code);
  }
}

final profileRepositoryProvider = Provider((ref) => ProfileRepository());