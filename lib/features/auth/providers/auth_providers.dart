import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/firebase/firebase_providers.dart';
import '../../../shared/models/app_user.dart';
import '../data/auth_service.dart';

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService(ref.watch(firebaseAuthProvider), ref.watch(firestoreProvider));
});

final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(authServiceProvider).authStateChanges();
});

final currentUserDocProvider = StreamProvider<AppUser?>((ref) {
  final authState = ref.watch(authStateProvider).value;
  if (authState == null) {
    return const Stream<AppUser?>.empty();
  }

  return ref
      .watch(firestoreProvider)
      .collection(AppConstants.firestoreUsers)
      .doc(authState.uid)
      .snapshots()
      .map((event) => event.exists ? AppUser.fromMap(event.data()!) : null);
});

class AuthController extends StateNotifier<AsyncValue<void>> {
  AuthController(this.ref) : super(const AsyncData(null));

  final Ref ref;

  Future<void> signIn(String email, String password) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => ref.read(authServiceProvider).signInWithEmail(email: email, password: password));
  }

  Future<void> signUp({required String name, required String email, required String password}) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(authServiceProvider).signUpWithEmail(name: name, email: email, password: password),
    );
  }

  Future<void> signInWithGoogle() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => ref.read(authServiceProvider).signInWithGoogle());
  }

  Future<void> signOut() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => ref.read(authServiceProvider).signOut());
  }
}

final authControllerProvider = StateNotifierProvider<AuthController, AsyncValue<void>>((ref) {
  return AuthController(ref);
});


