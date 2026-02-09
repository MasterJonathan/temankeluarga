import 'dart:async';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:silver_guide/features/authentication/presentation/auth_controller.dart';
import '../domain/user_model.dart';
import '../data/profile_repository.dart';

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

  Future<void> joinFamily(String code) async {
    final repo = ref.read(profileRepositoryProvider);
    await repo.joinFamily(code.toUpperCase().trim());
  }

  Future<void> createFamily() async {
    final repo = ref.read(profileRepositoryProvider);
    await repo.createFamilyGroup();
  }

  Future<void> updateProfile(String name, String phone) async {
    final user = state.value;
    if (user == null) return;

    final repo = ref.read(profileRepositoryProvider);
    await repo.updateProfile(uid: user.id, name: name, phone: phone);
  }

  Future<void> updatePhoto(File imageFile) async {
    final user = state.value;
    if (user == null) return;

    final repo = ref.read(profileRepositoryProvider);
    await repo.updateProfilePicture(user.id, imageFile);
  }
}

final familyMembersProvider = FutureProvider.autoDispose<List<UserProfile>>((
  ref,
) async {
  final userProfile = await ref.watch(profileControllerProvider.future);
  if (userProfile.familyId == null) return [];

  final repo = ref.read(profileRepositoryProvider);
  return repo.getFamilyMembers(userProfile.familyId!);
});

final profileControllerProvider =
    StreamNotifierProvider<ProfileController, UserProfile>(
      () => ProfileController(),
    );
