import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';

import '../../../core/constants/app_constants.dart';
import '../models/candidate_profile.dart';
import 'symbol_assets.dart';

class CandidateRepository {
  CandidateRepository(this._firestore, this._functions);

  final FirebaseFirestore _firestore;
  final FirebaseFunctions _functions;

  static const Map<String, _PartyMeta> _partyMeta = {
    'dmk': _PartyMeta('dmk', 'DMK', 'Dravida Munnetra Kazhagam', 'M.K. Stalin / Udhayanidhi Stalin', Color(0xFF0D47A1)),
    'aiadmk': _PartyMeta('aiadmk', 'AIADMK', 'All India Anna Dravida Munnetra Kazhagam', 'Edappadi K. Palaniswami', Color(0xFFB71C1C)),
    'bjp': _PartyMeta('bjp', 'BJP', 'Bharatiya Janata Party', 'Nainar Nagendran', Color(0xFFF57C00)),
    'inc': _PartyMeta('inc', 'INC', 'Indian National Congress', 'State leadership', Color(0xFF1565C0)),
    'pmk': _PartyMeta('pmk', 'PMK', 'Pattali Makkal Katchi', 'State leadership', Color(0xFFFFB300)),
    'vck': _PartyMeta('vck', 'VCK', 'Viduthalai Chiruthaigal Katchi', 'Thol. Thirumavalavan', Color(0xFF7B1FA2)),
    'admk': _PartyMeta('admk', 'ADMK', 'Amma Makkal Munnettra Kazhagam', 'TTV Dhinakaran camp', Color(0xFF2E7D32)),
    'mnm': _PartyMeta('mnm', 'MNM', 'Makkal Needhi Maiam', 'Kamal Haasan', Color(0xFF00796B)),
    'ntk': _PartyMeta('ntk', 'NTK', 'Naam Tamilar Katchi', 'Seeman', Color(0xFF212121)),
    'tvk': _PartyMeta('tvk', 'TVK', 'Tamizhaga Vetri Kazhagam', 'Vijay', Color(0xFFE91E63)),
    'mdmk': _PartyMeta('mdmk', 'MDMK', 'Marumalarchi Dravida Munnetra Kazhagam', 'Vaiko / Durai Vaiko', Color(0xFF5E35B1)),
    'dmdk': _PartyMeta('dmdk', 'DMDK', 'Desiya Murpokku Dravida Kazhagam', 'Premalatha Vijayakanth', Color(0xFF6D4C41)),
    'ind': _PartyMeta('ind', 'IND', 'Independent', 'Independent candidate', Color(0xFF455A64)),
  };

  Future<List<CandidateProfile>> fetchLiveCandidates({
    required String district,
    required String constituency,
    String? partyId,
  }) async {
    final constituencyKey = _normalize('${district}_$constituency');
    Query<Map<String, dynamic>> query = _firestore
        .collection(AppConstants.firestoreCandidates)
        .where('constituencyKey', isEqualTo: constituencyKey);

    if (partyId != null && partyId.isNotEmpty) {
      query = query.where('partyId', isEqualTo: partyId);
    }

    var snapshot = await query.get();
    if (snapshot.docs.isEmpty) {
      await _triggerCandidateSync(district: district, constituency: constituency);
      snapshot = await query.get();
    }
    final mapped = snapshot.docs.map((doc) {
      final data = doc.data();
      final resolvedPartyId = (data['partyId'] as String?) ?? 'ind';
      final meta = _partyMeta[resolvedPartyId] ?? _partyMeta['ind']!;
      final symbolName = data['symbolName'] as String? ?? data['symbol'] as String?;

      return CandidateProfile.fromFirestore(
        {
          ...data,
          'id': (data['id'] as String?) ?? doc.id,
          'leader': (data['leader'] as String?) ?? meta.leader,
          'symbolName': symbolName,
          'symbolAssetPath': (data['symbolAssetPath'] as String?) ?? resolveSymbolAssetPath(symbolName),
        },
        accentColor: meta.accent,
        fallbackDistrict: district,
        fallbackConstituency: constituency,
      );
    }).toList(growable: false);

    mapped.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return mapped;
  }

  Future<void> _triggerCandidateSync({
    required String district,
    required String constituency,
  }) async {
    try {
      await _functions.httpsCallable('syncCandidates').call(<String, dynamic>{
        'district': district,
        'constituency': constituency,
      });
    } catch (_) {
      // If sync fails, caller still gets whatever is currently in Firestore.
    }
  }

  String _normalize(String value) {
    return value.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '_').replaceAll(RegExp(r'^_+|_+$'), '');
  }

}

class _PartyMeta {
  const _PartyMeta(this.id, this.shortName, this.partyName, this.leader, this.accent);

  final String id;
  final String shortName;
  final String partyName;
  final String leader;
  final Color accent;
}

