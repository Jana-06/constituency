import 'package:cloud_firestore/cloud_firestore.dart';

class Poll {
  const Poll({
    required this.id,
    required this.question,
    required this.options,
    required this.votes,
    required this.createdAt,
    required this.expiresAt,
    required this.constituency,
  });

  final String id;
  final String question;
  final List<String> options;
  final Map<int, int> votes;
  final Timestamp createdAt;
  final Timestamp? expiresAt;
  final String constituency;

  bool get isClosed => expiresAt != null && expiresAt!.toDate().isBefore(DateTime.now());

  int get totalVotes => votes.values.fold<int>(0, (sum, item) => sum + item);

  factory Poll.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};
    return Poll(
      id: doc.id,
      question: data['question'] as String? ?? '',
      options: ((data['options'] as List<dynamic>?) ?? <dynamic>[]).map((e) => e.toString()).toList(),
      votes: ((data['votes'] as Map<String, dynamic>?) ?? <String, dynamic>{})
          .map((k, v) => MapEntry(int.tryParse(k) ?? 0, (v as num?)?.toInt() ?? 0)),
      createdAt: data['createdAt'] as Timestamp? ?? Timestamp.now(),
      expiresAt: data['expiresAt'] as Timestamp?,
      constituency: data['constituency'] as String? ?? 'all',
    );
  }
}

