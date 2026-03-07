import 'dart:convert';
import 'package:http/http.dart' as http;

const _kYouTubeApiKey = 'AIzaSyBNn8BP8C2URuDBZLgpFvp-WYhM8q8VRjY';

class YouTubeVideo {
  final String videoId;
  final String title;
  final String channelTitle;

  const YouTubeVideo({
    required this.videoId,
    required this.title,
    required this.channelTitle,
  });

  String get thumbnailUrl =>
      'https://img.youtube.com/vi/$videoId/mqdefault.jpg';
}

class YouTubeService {
  static final _cache = <String, List<YouTubeVideo>>{};

  /// Returns up to [maxResults] videos matching [query].
  static Future<List<YouTubeVideo>> searchVideos(
    String query, {
    int maxResults = 5,
    int? durationMinutes,
  }) async {
    final cacheKey = '$query|$maxResults|${durationMinutes ?? ""}';
    if (_cache.containsKey(cacheKey)) return _cache[cacheKey]!;

    try {
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
        '&maxResults=$maxResults'
        '$durationFilter'
        '&key=$_kYouTubeApiKey',
      );
      final res = await http.get(uri).timeout(const Duration(seconds: 10));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        final items = data['items'] as List? ?? [];
        final videos = items
            .map((item) {
              final id = item['id']['videoId'] as String?;
              if (id == null) return null;
              final snippet = item['snippet'] as Map<String, dynamic>;
              return YouTubeVideo(
                videoId: id,
                title: snippet['title'] as String? ?? '',
                channelTitle: snippet['channelTitle'] as String? ?? '',
              );
            })
            .whereType<YouTubeVideo>()
            .toList();
        _cache[cacheKey] = videos;
        return videos;
      }
    } catch (_) {}
    return [];
  }

  /// Legacy single-result lookup (used by existing code).
  static Future<String?> searchVideoId(String query,
      {int? durationMinutes}) async {
    final results =
        await searchVideos(query, maxResults: 1, durationMinutes: durationMinutes);
    return results.isNotEmpty ? results.first.videoId : null;
  }
}
