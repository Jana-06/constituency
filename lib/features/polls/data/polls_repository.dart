import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/constants/app_constants.dart';
import '../../../shared/models/poll.dart';

class PollsRepository {
  PollsRepository(this._firestore);

  final FirebaseFirestore _firestore;

  Stream<List<Poll>> watchPolls() {
    return _firestore
        .collection(AppConstants.firestorePolls)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map(Poll.fromDoc).toList());
  }

  Future<void> castVote({
    required String pollId,
    required int selectedOption,
    required String uid,
  }) async {
    final pollRef = _firestore.collection(AppConstants.firestorePolls).doc(pollId);
    final userRef = _firestore.collection(AppConstants.firestoreUsers).doc(uid);

    await _firestore.runTransaction((transaction) async {
      final userSnap = await transaction.get(userRef);
      final pollSnap = await transaction.get(pollRef);

      if (!pollSnap.exists) {
        throw Exception('Poll not found.');
      }

      final pollData = pollSnap.data() ?? <String, dynamic>{};
      final options = ((pollData['options'] as List<dynamic>?) ?? const <dynamic>[]).length;
      if (selectedOption < 0 || selectedOption >= options) {
        throw Exception('Invalid poll option selected.');
      }

      final expiresAt = pollData['expiresAt'] as Timestamp?;
      if (expiresAt != null && expiresAt.toDate().isBefore(DateTime.now())) {
        throw Exception('This poll is already closed.');
      }

      final votedPolls = ((userSnap.data()?['votedPollIds'] as List<dynamic>?) ?? <dynamic>[])
          .map((e) => e.toString())
          .toList();
      if (votedPolls.contains(pollId)) {
        throw Exception('You already voted in this poll.');
      }

      final currentVotes = (pollData['votes'] as Map<String, dynamic>? ?? <String, dynamic>{});
      final current = (currentVotes['$selectedOption'] as num?)?.toInt() ?? 0;

      transaction.update(pollRef, {'votes.$selectedOption': current + 1});

      if (userSnap.exists) {
        transaction.update(userRef, {
          'votedPollIds': FieldValue.arrayUnion([pollId]),
        });
      } else {
        transaction.set(userRef, {
          'uid': uid,
          'role': 'user',
          'isBanned': false,
          'votedPollIds': [pollId],
          'createdAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }
    });
  }

  Future<void> createPoll({
    required String question,
    required List<String> options,
    DateTime? expiresAt,
    String constituency = 'all',
  }) async {
    final votes = <String, int>{};
    for (var i = 0; i < options.length; i++) {
      votes['$i'] = 0;
    }

    await _firestore.collection(AppConstants.firestorePolls).add({
      'question': question,
      'options': options,
      'votes': votes,
      'createdAt': FieldValue.serverTimestamp(),
      'expiresAt': expiresAt == null ? null : Timestamp.fromDate(expiresAt),
      'constituency': constituency,
    });
  }

  Future<void> closePoll(String pollId) async {
    await _firestore.collection(AppConstants.firestorePolls).doc(pollId).update({
      'expiresAt': Timestamp.now(),
    });
  }
}

