import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class NomineeResult {
  const NomineeResult({
    required this.name,
    required this.link,
    required this.constituency,
    required this.party,
    this.thumbnail,
  });

  final String name;
  final String link;
  final String constituency;
  final String party;
  final String? thumbnail;
}

class NomineeSearchService {
  final Dio _dio = Dio(BaseOptions(connectTimeout: const Duration(seconds: 15)));

  Future<List<NomineeResult>> fetchNominees({
    required String party,
    required String constituency,
  }) async {
    final apiKey = dotenv.env['CUSTOM_SEARCH_API_KEY'];
    final cx = dotenv.env['CUSTOM_SEARCH_ENGINE_ID'];

    if (apiKey == null || apiKey.isEmpty || cx == null || cx.isEmpty) {
      return _fallbackResults(party, constituency);
    }

    final query = '$party candidate $constituency Tamil Nadu 2026 election';
    final response = await _dio.get(
      'https://www.googleapis.com/customsearch/v1',
      queryParameters: {
        'key': apiKey,
        'cx': cx,
        'q': query,
      },
    );

    final items = (response.data['items'] as List<dynamic>?) ?? <dynamic>[];
    if (items.isEmpty) {
      return _fallbackResults(party, constituency);
    }

    return items.take(5).map((item) {
      final map = item as Map<String, dynamic>;
      final pageMap = map['pagemap'] as Map<String, dynamic>?;
      final cseImage = (pageMap?['cse_image'] as List<dynamic>?)?.cast<Map<String, dynamic>>();

      return NomineeResult(
        name: (map['title'] as String? ?? 'Candidate').split('-').first.trim(),
        link: map['link'] as String? ?? '',
        constituency: constituency,
        party: party,
        thumbnail: cseImage?.isNotEmpty == true ? cseImage!.first['src'] as String? : null,
      );
    }).toList();
  }

  Future<String> fetchLeadership(String party) async {
    final results = await fetchNominees(party: party, constituency: 'Tamil Nadu');
    return results.isEmpty ? 'Leadership information currently unavailable.' : 'Leadership references: ${results.first.name}';
  }

  List<NomineeResult> _fallbackResults(String party, String constituency) {
    return List<NomineeResult>.generate(
      3,
      (index) => NomineeResult(
        name: '$party Candidate ${index + 1}',
        link: 'https://www.google.com/search?q=${Uri.encodeComponent('$party $constituency candidate')} ',
        constituency: constituency,
        party: party,
        thumbnail: 'https://placehold.co/256x256/ff6b35/FFFFFF.png?text=${Uri.encodeComponent(party)}',
      ),
    );
  }
}

