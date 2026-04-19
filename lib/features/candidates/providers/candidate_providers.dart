import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/firebase/firebase_providers.dart';
import '../data/candidate_repository.dart';
import '../models/candidate_profile.dart';

final candidateRepositoryProvider = Provider<CandidateRepository>((ref) {
  return CandidateRepository(
    ref.watch(firestoreProvider),
    ref.watch(functionsProvider),
  );
});

class CandidateSearchParams {
  const CandidateSearchParams({
    required this.district,
    required this.constituency,
    this.partyId,
  });

  final String district;
  final String constituency;
  final String? partyId;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CandidateSearchParams &&
        other.district == district &&
        other.constituency == constituency &&
        other.partyId == partyId;
  }

  @override
  int get hashCode => Object.hash(district, constituency, partyId);
}

final candidatesProvider = StreamProvider.family<List<CandidateProfile>, CandidateSearchParams>((ref, params) {
  return ref.read(candidateRepositoryProvider).watchCandidates(
        district: params.district,
        constituency: params.constituency,
        partyId: params.partyId,
      );
});

final candidateSyncStatusProvider = StreamProvider.family<Map<String, dynamic>?, CandidateSearchParams>((ref, params) {
  return ref.read(candidateRepositoryProvider).watchSyncStatus(
        district: params.district,
        constituency: params.constituency,
      );
});

final candidateSyncControllerProvider = Provider<CandidateSyncController>((ref) {
  return CandidateSyncController(ref.read(candidateRepositoryProvider));
});

class CandidateSyncController {
  CandidateSyncController(this._repository);

  final CandidateRepository _repository;

  Future<void> sync({
    required String district,
    required String constituency,
    bool force = false,
  }) {
    return _repository.syncCandidates(
      district: district,
      constituency: constituency,
      force: force,
    );
  }
}


