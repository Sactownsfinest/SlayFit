import 'dart:convert';
import 'package:http/http.dart' as http;

const _kYouTubeApiKey = 'AIzaSyBNn8BP8C2URuDBZLgpFvp-WYhM8q8VRjY';

class YouTubeService {
  // In-memory cache so we don't re-query for the same workout each session
  static final _cache = <String, String>{};

  static Future<String?> searchVideoId(String query, {int? durationMinutes}) async {
    final cacheKey = '$query|${durationMinutes ?? ""}';
    if (_cache.containsKey(cacheKey)) return _cache[cacheKey];
    try {
      // Map duration to YouTube's videoDuration filter for better matches
      String durationFilter = '';
      if (durationMinutes != null) {
        if (durationMinutes <= 4) {
          durationFilter = '&videoDuration=short';
        } else if (durationMinutes <= 60) {
          durationFilter = '&videoDuration=medium';
        } else {
          durationFilter = '&videoDuration=long';
        }
      }
      final uri = Uri.parse(
        'https://www.googleapis.com/youtube/v3/search'
        '?part=snippet'
        '&q=${Uri.encodeComponent(query)}'
        '&type=video'
        '&videoEmbeddable=true'
        '&maxResults=1'
        '$durationFilter'
        '&key=$_kYouTubeApiKey',
      );
      final res = await http.get(uri).timeout(const Duration(seconds: 8));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        final items = data['items'] as List?;
        if (items != null && items.isNotEmpty) {
          final id = items[0]['id']['videoId'] as String?;
          if (id != null) {
            _cache[cacheKey] = id;
            return id;
          }
        }
      }
    } catch (_) {}
    return null;
  }
}
