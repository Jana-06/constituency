import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../../../core/constants/app_constants.dart';
import '../../../shared/models/party.dart';

class PartyRepository {
  const PartyRepository();

  Future<List<Party>> getParties({
    required FirebaseFirestore firestore,
    required FirebaseStorage storage,
  }) async {
    final parties = _fallbackParties;
    final firestoreFlagUrls = await _fetchFirestoreFlagUrls(firestore);

    final resolved = await Future.wait(
      parties.map((party) async {
        final firestoreUrl = firestoreFlagUrls[party.id];
        if (firestoreUrl != null && firestoreUrl.trim().isNotEmpty) {
          return Party(
            id: party.id,
            tamilName: party.tamilName,
            englishName: party.englishName,
            shortName: party.shortName,
            flagUrl: firestoreUrl,
            ideology: party.ideology,
            leadership: party.leadership,
          );
        }

        final storageUrl = await _resolveFlagUrl(storage, party.id);
        if (storageUrl == null) {
          return party;
        }

        return Party(
          id: party.id,
          tamilName: party.tamilName,
          englishName: party.englishName,
          shortName: party.shortName,
          flagUrl: storageUrl,
          ideology: party.ideology,
          leadership: party.leadership,
        );
      }),
    );

    return resolved;
  }

  Future<Map<String, String>> _fetchFirestoreFlagUrls(FirebaseFirestore firestore) async {
    try {
      final snapshot = await firestore.collection(AppConstants.firestoreParties).get();
      final result = <String, String>{};

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final raw = data['flagUrl'];
        if (raw is String && raw.trim().isNotEmpty) {
          result[doc.id.toLowerCase()] = raw.trim();
        }
      }

      return result;
    } catch (_) {
      return const <String, String>{};
    }
  }

  Future<String?> _resolveFlagUrl(FirebaseStorage storage, String partyId) async {
    final candidates = <String>[
      'party_flags/$partyId.png',
      'party_flags/$partyId.jpg',
      'party_flags/$partyId.jpeg',
      'party_flags/$partyId.webp',
      'flags/$partyId.png',
      'flags/$partyId.jpg',
      'flags/$partyId.jpeg',
      'flags/$partyId.webp',
    ];

    for (final path in candidates) {
      try {
        return await storage.ref(path).getDownloadURL();
      } catch (_) {
        // Try next candidate path.
      }
    }

    return null;
  }

  static const List<Party> _fallbackParties = [
    Party(
      id: 'dmk',
      tamilName: 'திராவிட முன்னேற்றக் கழகம்',
      englishName: 'Dravida Munnetra Kazhagam',
      shortName: 'DMK',
      flagUrl: 'https://upload.wikimedia.org/wikipedia/commons/5/57/Flag_of_DMK.png',
      ideology: 'Dravidian social justice, federalism, and welfare-focused governance.',
      leadership: 'M.K. Stalin (President and Chief Minister), Udhayanidhi Stalin',
    ),
    Party(
      id: 'aiadmk',
      tamilName: 'அண்ணா திராவிட முன்னேற்றக் கழகம்',
      englishName: 'All India Anna Dravida Munnetra Kazhagam',
      shortName: 'AIADMK',
      flagUrl: 'https://upload.wikimedia.org/wikipedia/commons/0/0f/Flag_of_Aiadmk.svg',
      ideology: 'Centrist Dravidian movement with welfare and development agenda.',
      leadership: 'Edappadi K. Palaniswami (EPS)',
    ),
    Party(
      id: 'bjp',
      tamilName: 'பாரதீய ஜனதா கட்சி',
      englishName: 'Bharatiya Janata Party',
      shortName: 'BJP',
      flagUrl: 'https://upload.wikimedia.org/wikipedia/commons/d/d0/BJP_Flag.svg',
      ideology: 'Nationalist platform emphasizing development and governance reforms.',
      leadership: 'Nainar Nagendran (Tamil Nadu unit)',
    ),
    Party(
      id: 'inc',
      tamilName: 'இந்திய தேசிய காங்கிரஸ்',
      englishName: 'Indian National Congress',
      shortName: 'INC',
      flagUrl: 'https://upload.wikimedia.org/wikipedia/commons/4/45/Flag_of_the_Indian_National_Congress.svg',
      ideology: 'Secular democratic values with social welfare and inclusive growth.',
      leadership: 'Tamil Nadu Congress leadership',
    ),
    Party(
      id: 'pmk',
      tamilName: 'பட்டாளி மக்கள் கட்சி',
      englishName: 'Pattali Makkal Katchi',
      shortName: 'PMK',
      flagUrl: 'https://upload.wikimedia.org/wikipedia/commons/5/57/PMK_Flag.png',
      ideology: 'Social justice and rural development with youth employment focus.',
      leadership: 'Party leadership (state unit)',
    ),
    Party(
      id: 'vck',
      tamilName: 'விடுதலை சிறுத்தைகள் கட்சி',
      englishName: 'Viduthalai Chiruthaigal Katchi',
      shortName: 'VCK',
      flagUrl: 'https://upload.wikimedia.org/wikipedia/commons/8/85/VCK_Flag.png',
      ideology: 'Social equality, anti-discrimination, and grassroots mobilization.',
      leadership: 'Party leadership (state unit)',
    ),
    Party(
      id: 'admk',
      tamilName: 'அம்மா மக்கள் முன்னேற்றக் கழகம்',
      englishName: 'Amma Makkal Munnettra Kazhagam',
      shortName: 'ADMK',
      flagUrl: 'https://upload.wikimedia.org/wikipedia/commons/1/1f/AMMK_Flag.png',
      ideology: 'Regional development and welfare politics in Tamil Nadu.',
      leadership: 'Party leadership (state unit)',
    ),
    Party(
      id: 'mnm',
      tamilName: 'மக்கள் நீதி மய்யம்',
      englishName: 'Makkal Needhi Maiam',
      shortName: 'MNM',
      flagUrl: 'https://upload.wikimedia.org/wikipedia/commons/0/00/MNM_flag.jpg',
      ideology: 'Good governance, transparency, and anti-corruption reforms.',
      leadership: 'Party leadership (state unit)',
    ),
    Party(
      id: 'ntk',
      tamilName: 'நாம் தமிழர் கட்சி',
      englishName: 'Naam Tamilar Katchi',
      shortName: 'NTK',
      flagUrl: 'https://upload.wikimedia.org/wikipedia/commons/8/84/Naam_Tamilar_Katchi_flag.png',
      ideology: 'Tamil identity, environmental protection, and local empowerment.',
      leadership: 'Seeman',
    ),
    Party(
      id: 'tvk',
      tamilName: 'தமிழக வெற்றிக் கழகம்',
      englishName: 'Tamizhaga Vetri Kazhagam',
      shortName: 'TVK',
      flagUrl: 'https://placehold.co/600x360/ff6b35/FFFFFF.png?text=TVK',
      ideology: 'Emerging regional platform with youth and governance focus.',
      leadership: 'Actor Vijay (Founder and President)',
    ),
    Party(
      id: 'dmdk',
      tamilName: 'தேசிய முற்போக்கு திராவிட கழகம்',
      englishName: 'Desiya Murpokku Dravida Kazhagam',
      shortName: 'DMDK',
      flagUrl: 'https://placehold.co/600x360/4e342e/FFFFFF.png?text=DMDK',
      ideology: 'Regional welfare and governance-focused political platform.',
      leadership: 'Party leadership (state unit)',
    ),
    Party(
      id: 'mdmk',
      tamilName: 'மருமலர்ச்சி திராவிட முன்னேற்றக் கழகம்',
      englishName: 'Marumalarchi Dravida Munnetra Kazhagam',
      shortName: 'MDMK',
      flagUrl: 'https://upload.wikimedia.org/wikipedia/commons/0/06/MDMK_Flag.jpg',
      ideology: 'Regional federal rights, social justice, and coalition politics.',
      leadership: 'Party leadership (state unit)',
    ),
  ];
}

