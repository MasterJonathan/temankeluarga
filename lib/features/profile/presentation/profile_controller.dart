import 'dart:async';
import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:silver_guide/features/authentication/presentation/auth_controller.dart';
import '../domain/user_model.dart';
import '../data/profile_repository.dart';

// 1. Provider untuk Request List (BARU)
final joinRequestsProvider = StreamProvider.autoDispose.family<List<UserProfile>, String>((ref, familyId) {
  final repo = ref.read(profileRepositoryProvider);
  return repo.watchJoinRequests(familyId);
});

// 2. Provider untuk Family Members (LAMA - Tetap ada)
final familyMembersProvider = FutureProvider.autoDispose<List<UserProfile>>((
  ref,
) async {
  final userProfile = await ref.watch(profileControllerProvider.future);
  if (userProfile.familyId == null) return [];

  final repo = ref.read(profileRepositoryProvider);
  return repo.getFamilyMembers(userProfile.familyId!);
});

// 3. Main Controller Provider
final profileControllerProvider =
    StreamNotifierProvider<ProfileController, UserProfile>(
      () => ProfileController(),
    );

class ProfileController extends StreamNotifier<UserProfile> {
  @override
  Stream<UserProfile> build() {
    final authState = ref.watch(authStateProvider);
    return authState.when(
      data: (user) {
        if (user == null) return const Stream.empty();
        final repo = ref.read(profileRepositoryProvider);
        return repo.watchUser(user.uid);
      },
      error: (e, st) => Stream.error(e, st),
      loading: () => const Stream.empty(),
    );
  }

  // GANTI joinFamily JADI requestJoinFamily
  Future<void> requestJoinFamily(String code) async {
    final repo = ref.read(profileRepositoryProvider);
    await repo.requestJoinFamily(code.toUpperCase().trim());
  }

  // Create Family (Tetap sama)
  Future<void> createFamily() async {
    final repo = ref.read(profileRepositoryProvider);
    await repo.createFamilyGroup();
  }

  // ACTION ADMIN: Accept Member
  Future<void> acceptMember(String targetUserId) async {
    final currentUser = state.value;
    if (currentUser?.familyId == null) return;
    
    final repo = ref.read(profileRepositoryProvider);
    await repo.acceptJoinRequest(currentUser!.familyId!, targetUserId);
  }

  // ACTION ADMIN: Remove Member / Kick
  Future<void> removeMember(String targetUserId) async {
    final currentUser = state.value;
    if (currentUser?.familyId == null) return;

    final repo = ref.read(profileRepositoryProvider);
    await repo.removeMember(currentUser!.familyId!, targetUserId);
  }
  
  // ACTION ADMIN: Update Fitur Lansia
  Future<void> updateFeatures(String userId, List<String> features) async {
    final repo = ref.read(profileRepositoryProvider);
    await repo.updateElderlyFeatures(userId, features);
  }

  // Fungsi Leave Family (Self) - DIUPDATE
  Future<void> leaveFamily() async {
    final currentUser = state.value;
    if (currentUser == null) return;
    
    final repo = ref.read(profileRepositoryProvider);
    // Remove diri sendiri menggunakan logic removeMember
    await repo.removeMember(currentUser.familyId!, currentUser.id);
  }

  // Update Profile Data (Tetap sama)
  Future<void> updateProfile(String name, String phone) async {
    final user = state.value;
    if (user == null) return;

    final repo = ref.read(profileRepositoryProvider);
    await repo.updateProfile(uid: user.id, name: name, phone: phone);
  }

  // Update Photo (Tetap sama)
  Future<void> updatePhoto(Uint8List imageBytes) async {
    final user = state.value;
    if (user == null) return;

    final repo = ref.read(profileRepositoryProvider);
    await repo.updateProfilePicture(user.id, imageBytes);
  }

  // Update Text Size (Tetap sama)
  Future<void> updateTextSize(double size) async {
    final user = state.value;
    if (user == null) return;

    final repo = ref.read(profileRepositoryProvider);
    await repo.updateTextSize(user.id, size);
  }
}