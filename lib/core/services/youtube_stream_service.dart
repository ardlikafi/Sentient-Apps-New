import 'package:flutter/foundation.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

class YoutubeStreamService {
  static final YoutubeExplode _yt = YoutubeExplode();
  static final Map<String, Uri> _cache = {};

  static String? extractVideoId(String urlOrId) {
    if (urlOrId.isEmpty) return null;
    final trimmed = urlOrId.trim();
    if (trimmed.length == 11 && RegExp(r'^[0-9A-Za-z_-]{11}$').hasMatch(trimmed)) {
      return trimmed;
    }
    final RegExp regExp = RegExp(
      r'(?:youtube\.com\/watch\?v=|youtu\.be\/|youtube\.com\/embed\/|\/v\/|embed\/|v=)([0-9A-Za-z_-]{11})',
      caseSensitive: false,
    );
    final match = regExp.firstMatch(trimmed);
    return match?.group(1);
  }

  /// Resolves direct stream URI for a given YouTube video ID or URL.
  static Future<Uri?> getDirectStreamUri(String urlOrId) async {
    final videoId = extractVideoId(urlOrId);
    if (videoId == null) return null;

    if (_cache.containsKey(videoId)) {
      return _cache[videoId];
    }

    try {
      final manifest = await _yt.videos.streamsClient.getManifest(videoId);
      
      // Get all muxed streams (video + audio combined in single mp4 container)
      final muxedStreams = manifest.muxed.sortByVideoQuality();
      if (muxedStreams.isNotEmpty) {
        final selectedStream = muxedStreams.last;
        _cache[videoId] = selectedStream.url;
        return selectedStream.url;
      }
      return null;
    } catch (e) {
      debugPrint('YoutubeStreamService error: $e');
      return null;
    }
  }

  static void dispose() {
    _yt.close();
  }
}
