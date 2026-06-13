import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/models.dart';

/// User-Agent sent with every request, including image loads. Wikimedia
/// throttles (429) requests that omit a descriptive UA, which is what made
/// some photos silently fall back to the monogram.
const String kBirdCherryUserAgent = 'BirdCherry/0.1 (demo Flutter app)';

/// Resolves live bird photos from open sources, no API key required.
///
/// For each bird there's an ordered list of candidate image URLs, resolved
/// lazily so we only do the work we need:
///   0. Wikipedia lead image, hi-res (≤960px)
///   1. Wikipedia lead image, the exact thumbnail Wikipedia served (always valid)
///   2. iNaturalist default photo (Creative-Commons), by scientific name
///
/// The [BirdImage] widget walks this list: if the URL at one index fails to
/// load, it advances to the next, only showing the tinted monogram once every
/// candidate is exhausted. That's what makes a flaky Wikipedia image recover
/// to iNaturalist instead of getting stuck.
class BirdImageService {
  BirdImageService({http.Client? client}) : _client = client ?? http.Client();

  static const _maxConcurrent = 6;

  final http.Client _client;
  final Map<String, Future<({String hi, String safe})?>> _wiki = {};
  final Map<String, Future<String?>> _inat = {};

  int _active = 0;
  final _waiters = <Completer<void>>[];

  /// The candidate image URL at [attempt] (0,1,2), or null when there is none.
  /// Callers advance through attempts on load failure.
  ///
  /// Order depends on provenance: curated birds have a hand-set Wikipedia
  /// title (very reliable) so Wikipedia leads; eBird species are keyed on an
  /// exact scientific name, so iNaturalist leads (their common name → Wikipedia
  /// title mapping is lossy and often lands on the wrong/disambiguation page).
  Future<String?> sourceAt(Bird bird, int attempt) async {
    if (bird.curated) {
      switch (attempt) {
        case 0:
          return (await _wikiFor(bird))?.hi;
        case 1:
          return (await _wikiFor(bird))?.safe;
        case 2:
          return _inatFor(bird);
      }
    } else {
      switch (attempt) {
        case 0:
          return _inatFor(bird);
        case 1:
          return (await _wikiFor(bird))?.hi;
        case 2:
          return (await _wikiFor(bird))?.safe;
      }
    }
    return null;
  }

  Future<({String hi, String safe})?> _wikiFor(Bird bird) {
    return _wiki.putIfAbsent(
        bird.id, () => _throttled(() => _fetchWiki(bird.wikiTitle)));
  }

  Future<String?> _inatFor(Bird bird) {
    return _inat.putIfAbsent(
        bird.id, () => _throttled(() => _fetchINat(bird.scientificName)));
  }

  /// Semaphore so we never fire dozens of metadata requests at once (429).
  Future<T> _throttled<T>(Future<T> Function() task) async {
    while (_active >= _maxConcurrent) {
      final waiter = Completer<void>();
      _waiters.add(waiter);
      await waiter.future;
    }
    _active++;
    try {
      return await task();
    } finally {
      _active--;
      if (_waiters.isNotEmpty) _waiters.removeAt(0).complete();
    }
  }

  Future<({String hi, String safe})?> _fetchWiki(String wikiTitle,
      {int attempt = 0}) async {
    try {
      final uri = Uri.https(
        'en.wikipedia.org',
        '/api/rest_v1/page/summary/${wikiTitle.replaceAll(' ', '_')}',
      );
      final res = await _client.get(uri, headers: {
        'accept': 'application/json',
        'user-agent': kBirdCherryUserAgent,
        'api-user-agent': kBirdCherryUserAgent,
      }).timeout(const Duration(seconds: 8));

      if (res.statusCode == 429 && attempt < 2) {
        final retryAfter =
            int.tryParse(res.headers['retry-after'] ?? '') ?? (attempt + 1);
        await Future<void>.delayed(Duration(seconds: retryAfter.clamp(1, 5)));
        return _fetchWiki(wikiTitle, attempt: attempt + 1);
      }
      if (res.statusCode != 200) return null;

      final json = jsonDecode(res.body) as Map<String, dynamic>;
      final safe = (json['thumbnail'] as Map<String, dynamic>?)?['source'] as String?;
      if (safe == null) return null;
      // Bump to ≤960px for hero shots when the original is big enough.
      final origWidth =
          (json['originalimage'] as Map<String, dynamic>?)?['width'] as int? ?? 0;
      final hi = origWidth > 960
          ? safe.replaceFirst(RegExp(r'/\d+px-'), '/960px-')
          : safe;
      return (hi: hi, safe: safe);
    } catch (e) {
      debugPrint('BirdImageService(wiki): $wikiTitle -> $e');
      return null;
    }
  }

  Future<String?> _fetchINat(String scientificName) async {
    if (scientificName.isEmpty) return null;
    try {
      final uri = Uri.https('api.inaturalist.org', '/v1/taxa', {
        'q': scientificName,
        'rank': 'species',
        'per_page': '1',
      });
      final res = await _client.get(uri, headers: {
        'accept': 'application/json',
        'user-agent': kBirdCherryUserAgent,
      }).timeout(const Duration(seconds: 8));
      if (res.statusCode != 200) return null;

      final results = (jsonDecode(res.body)
          as Map<String, dynamic>)['results'] as List<dynamic>?;
      if (results == null || results.isEmpty) return null;
      final photo = (results.first as Map<String, dynamic>)['default_photo']
          as Map<String, dynamic>?;
      final medium = photo?['medium_url'] as String?;
      return medium?.replaceFirst('/medium.', '/large.');
    } catch (e) {
      debugPrint('BirdImageService(inat): $scientificName -> $e');
      return null;
    }
  }
}
