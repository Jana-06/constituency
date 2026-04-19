import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../../core/constants/app_constants.dart';

class AuthService {
  AuthService(this._auth, this._firestore);

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final GoogleSignIn _googleSignIn = GoogleSignIn(scopes: const ['email', 'profile']);

  Stream<User?> authStateChanges() => _auth.authStateChanges();

  Future<void> signInWithEmail({required String email, required String password}) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
    } on FirebaseAuthException catch (e) {
      throw _mapAuthError(e);
    }
  }

  Future<void> signUpWithEmail({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      await credential.user?.updateDisplayName(name);
      await _ensureUserDocument(credential.user!, fallbackName: name);
    } on FirebaseAuthException catch (e) {
      throw _mapAuthError(e);
    }
  }

  Future<void> signInWithGoogle() async {
    try {
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return;

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final result = await _auth.signInWithCredential(credential);
      if (result.user != null) {
        await _ensureUserDocument(result.user!);
      }
    } on PlatformException catch (e) {
      if ((e.message ?? '').contains('ApiException: 10') || e.code.toLowerCase().contains('sign_in_failed')) {
        throw 'Google Sign-In setup is incomplete. Add the Android SHA-1/SHA-256 fingerprints in Firebase and try again.';
      }
      throw 'Google Sign-In failed: ${e.message ?? e.code}';
    } on FirebaseAuthException catch (e) {
      throw _mapAuthError(e);
    } catch (e) {
      final message = e.toString();
      if (message.contains('ApiException: 10') || message.toLowerCase().contains('sha-1') || message.toLowerCase().contains('sign_in_failed')) {
        throw 'Google Sign-In setup is incomplete. Add the Android SHA-1/SHA-256 fingerprints in Firebase and try again.';
      }
      throw 'Google Sign-In failed: $e';
    }
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }

  Future<Map<String, dynamic>?> getUserData(String uid) async {
    final doc = await _firestore.collection(AppConstants.firestoreUsers).doc(uid).get();
    return doc.data();
  }

  Future<bool> isUserBanned(String uid) async {
    try {
      final doc = await _firestore.collection(AppConstants.firestoreUsers).doc(uid).get();
      return doc.data()?['isBanned'] ?? false;
    } catch (_) {
      return false;
    }
  }

  Future<void> resetPassword(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  String _mapAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-credential':
      case 'wrong-password':
      case 'user-not-found':
        return 'Invalid email or password.';
      case 'email-already-in-use':
        return 'This email is already in use.';
      case 'weak-password':
        return 'Password is too weak.';
      case 'network-request-failed':
        return 'No network connection. Please try again.';
      default:
        return e.message ?? 'Authentication failed.';
    }
  }

  Future<void> _ensureUserDocument(User user, {String? fallbackName}) async {
    final ref = _firestore.collection(AppConstants.firestoreUsers).doc(user.uid);
    final snapshot = await ref.get();

    if (!snapshot.exists) {
      await ref.set({
        'uid': user.uid,
        'name': user.displayName ?? fallbackName ?? 'Citizen',
        'email': user.email,
        'role': 'user',
        'createdAt': FieldValue.serverTimestamp(),
        'photoUrl': user.photoURL,
        'isBanned': false,
        'votedPollIds': <String>[],
        'homeDistrict': null,
        'homeConstituency': null,
      });
    }
  }
}
