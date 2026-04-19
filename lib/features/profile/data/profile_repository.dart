import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/constants/app_constants.dart';

class ProfileRepository {
  ProfileRepository(this._firestore, this._storage);

  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;

  Future<void> updateProfile({
    required String uid,
    required String name,
    String? district,
    String? constituency,
    XFile? pickedFile,
  }) async {
    String? photoUrl;
    if (pickedFile != null) {
      final ref = _storage.ref('profiles/$uid.jpg');
      await ref.putFile(File(pickedFile.path));
      photoUrl = await ref.getDownloadURL();
    }

    await _firestore.collection(AppConstants.firestoreUsers).doc(uid).update({
      'name': name,
      'homeDistrict': district,
      'homeConstituency': constituency,
      if (photoUrl != null) 'photoUrl': photoUrl,
    });
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> watchMyMessages(String uid) {
    return _firestore
        .collectionGroup('items')
        .where('uid', isEqualTo: uid)
        .where('isDeleted', isEqualTo: false)
        .orderBy('timestamp', descending: true)
        .limit(10)
        .snapshots();
  }

  Future<void> softDeleteMyMessage({required String roomId, required String messageId}) async {
    await _firestore.collection(AppConstants.firestoreMessages).doc(roomId).collection('items').doc(messageId).update({'isDeleted': true});
  }
}

