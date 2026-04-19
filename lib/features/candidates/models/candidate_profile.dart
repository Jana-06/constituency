import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CandidateProfile {
  const CandidateProfile({
    required this.id,
    required this.name,
    required this.partyId,
    required this.partyName,
    required this.partyAbbreviation,
    required this.district,
    required this.constituency,
    required this.leader,
    required this.sourceUrl,
    required this.affidavitUrl,
    required this.goodThingsUrl,
    required this.sourceLabel,
    required this.photoUrl,
    required this.policeCasesSummary,
    required this.goodThings,
    required this.affidavitSummary,
    required this.accentColor,
    this.partyFlagUrl,
    this.lastUpdated,
  });

  final String id;
  final String name;
  final String partyId;
  final String partyName;
  final String partyAbbreviation;
  final String district;
  final String constituency;
  final String leader;
  final String sourceUrl;
  final String affidavitUrl;
  final String goodThingsUrl;
  final String sourceLabel;
  final String photoUrl;
  final String policeCasesSummary;
  final List<String> goodThings;
  final String affidavitSummary;
  final Color accentColor;
  final String? partyFlagUrl;
  final DateTime? lastUpdated;

  String get headline => '$name · $partyAbbreviation';
  String get constituencyLabel => '$constituency, $district';

  factory CandidateProfile.fromFirestore(
    Map<String, dynamic> data, {
    required Color accentColor,
    required String fallbackDistrict,
    required String fallbackConstituency,
  }) {
    final updatedAt = data['updatedAt'];
    final updated = updatedAt is Timestamp ? updatedAt.toDate() : null;

    return CandidateProfile(
      id: (data['id'] as String?) ?? '',
      name: (data['name'] as String?) ?? 'Candidate',
      partyId: (data['partyId'] as String?) ?? 'ind',
      partyName: (data['partyName'] as String?) ?? 'Independent',
      partyAbbreviation: (data['partyAbbreviation'] as String?) ?? 'IND',
      district: (data['district'] as String?) ?? fallbackDistrict,
      constituency: (data['constituency'] as String?) ?? fallbackConstituency,
      leader: (data['leader'] as String?) ?? 'Leadership data pending',
      sourceUrl: (data['sourceUrl'] as String?) ?? 'https://www.myneta.info',
      affidavitUrl: (data['affidavitUrl'] as String?) ?? (data['sourceUrl'] as String?) ?? 'https://www.myneta.info',
      goodThingsUrl: (data['goodThingsUrl'] as String?) ?? (data['sourceUrl'] as String?) ?? 'https://www.myneta.info',
      sourceLabel: 'View profile',
      photoUrl: (data['photoUrl'] as String?) ?? 'https://placehold.co/256x256/eeeeee/333333.png?text=Candidate',
      policeCasesSummary: (data['policeCasesSummary'] as String?) ?? 'Check affidavit link for current police-case disclosures.',
      goodThings: ((data['goodThings'] as List<dynamic>?) ?? const <dynamic>[])
          .map((item) => item.toString())
          .where((item) => item.isNotEmpty)
          .toList(growable: false),
      affidavitSummary: (data['affidavitSummary'] as String?) ?? 'Affidavit information is sourced from public election references.',
      accentColor: accentColor,
      partyFlagUrl: data['partyFlagUrl'] as String?,
      lastUpdated: updated,
    );
  }
}

