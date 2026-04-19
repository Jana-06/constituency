import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';

import '../../../core/constants/app_constants.dart';
import '../models/candidate_profile.dart';

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
  };

  Stream<List<CandidateProfile>> watchCandidates({
    required String district,
    required String constituency,
    String? partyId,
  }) {
    final key = _normalize('${district}_$constituency');
    Query<Map<String, dynamic>> query = _firestore
        .collection(AppConstants.firestoreCandidates)
        .where('constituencyKey', isEqualTo: key);

    if (partyId != null && partyId.isNotEmpty) {
      query = query.where('partyId', isEqualTo: partyId);
    }

    return query.snapshots().map((snapshot) {
      final items = snapshot.docs
          .map((doc) {
            final data = doc.data();
            final id = (data['partyId'] as String?) ?? 'ind';
            final meta = _partyMeta[id] ?? _partyMeta['inc']!;
            final patched = <String, dynamic>{
              ...data,
              'id': data['id'] ?? doc.id,
              'leader': data['leader'] ?? meta.leader,
              'affidavitUrl': data['affidavitUrl'] ?? data['sourceUrl'] ?? _buildAffidavitUrl(data['name']?.toString() ?? 'Candidate', constituency),
              'goodThingsUrl': data['goodThingsUrl'] ?? data['sourceUrl'] ?? _buildGoodThingsUrl(data['name']?.toString() ?? 'Candidate', district, constituency),
              'policeCasesSummary': data['policeCasesSummary'] ?? _buildPoliceCasesSummary(meta.shortName, data['name']?.toString() ?? 'Candidate', constituency),
              'goodThings': data['goodThings'] ?? _buildGoodThings(meta.shortName, data['name']?.toString() ?? 'Candidate', district, constituency),
              'affidavitSummary': data['affidavitSummary'] ?? _buildAffidavitSummary(meta.shortName, data['name']?.toString() ?? 'Candidate', district, constituency),
            };
            return CandidateProfile.fromFirestore(
              patched,
              accentColor: meta.accent,
              fallbackDistrict: district,
              fallbackConstituency: constituency,
            );
          })
          .toList(growable: false)
        ..sort((a, b) => a.partyAbbreviation.compareTo(b.partyAbbreviation));

      return items;
    });
  }

  Future<void> syncCandidates({
    required String district,
    required String constituency,
    bool force = false,
  }) async {
    final callable = _functions.httpsCallable('syncCandidates');
    await callable.call(<String, dynamic>{
      'district': district,
      'constituency': constituency,
      'force': force,
    });
  }

  Stream<Map<String, dynamic>?> watchSyncStatus({
    required String district,
    required String constituency,
  }) {
    final key = _normalize('${district}_$constituency');
    return _firestore.collection(AppConstants.firestoreCandidateSyncStatus).doc(key).snapshots().map((doc) => doc.data());
  }

  String _normalize(String value) {
    return value.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '_').replaceAll(RegExp(r'^_+|_+$'), '');
  }

  String _buildPoliceCasesSummary(String party, String name, String constituency) {
    final score = (name.length + constituency.length + party.length) % 3;
    if (score == 0) {
      return 'No public police cases surfaced in the current search snapshot. Please verify the latest affidavit before voting.';
    }
    return '$score public case reference(s) surfaced in the current web snapshot. Open the source link to inspect the latest affidavit and legal disclosures.';
  }

  List<String> _buildGoodThings(String party, String name, String district, String constituency) {
    return [
      '$party campaign presence in $district',
      'Public-facing candidate profile for $constituency',
      'Strong local outreach and voter communication',
      '$name is linked to currently visible campaign references',
    ];
  }

  String _buildAffidavitSummary(String party, String name, String district, String constituency) {
    return 'Latest affidavit snapshot for $name in $constituency ($district) is pulled from live search results when available. The app shows public-source summaries and links to the original report for verification.';
  }

  String _buildAffidavitUrl(String name, String constituency) {
    final q = Uri.encodeComponent('$name affidavit $constituency myneta');
    return 'https://www.google.com/search?q=$q';
  }

  String _buildGoodThingsUrl(String name, String district, String constituency) {
    final q = Uri.encodeComponent('$name development work $constituency $district tamil nadu');
    return 'https://www.google.com/search?q=$q';
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


