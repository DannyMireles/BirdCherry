import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:path_provider/path_provider.dart';

import '../config/app_config.dart';
import '../models/models.dart';

/// One recent eBird observation near a point — the "what's being seen here"
/// signal that powers location-aware discovery.
class NearbyObservation {
  const NearbyObservation({
    required this.speciesCode,
    required this.comName,
    required this.sciName,
    required this.howMany,
    required this.point,
    required this.locName,
    required this.obsDt,
  });

  final String speciesCode;
  final String comName;
  final String sciName;
  final int howMany;
  final LatLng point;
  final String locName;
  final String obsDt;
}

/// Talks to the Cornell Lab's eBird API.
///
///  • [taxonomy] is open (no key) — the full ~17,400-species world checklist,
///    fetched once and cached to disk for the session and across launches.
///  • [recentNearby] needs a free key (`x-ebirdapitoken`); without one it
///    returns an empty list and callers fall back to curated data.
class EbirdService {
  EbirdService({http.Client? client}) : _client = client ?? http.Client();

  static const _host = 'api.ebird.org';
  static const _cacheFile = 'ebird_taxonomy_v2.json';
  static const _cacheTtl = Duration(days: 30);

  final http.Client _client;
  List<Bird>? _taxonomyMemo;

  /// Full eBird species list as [Bird]s. Returns null on failure so the caller
  /// can simply keep the curated set.
  Future<List<Bird>?> taxonomy() async {
    if (_taxonomyMemo != null) return _taxonomyMemo;
    final cached = await _readCache();
    final raw = cached ?? await _fetchTaxonomy();
    if (raw == null) return null;
    if (cached == null) await _writeCache(raw);
    try {
      final list = (jsonDecode(raw) as List<dynamic>)
          .map((e) => e as Map<String, dynamic>)
          .where((e) => e['category'] == 'species' && e['sciName'] != null)
          .map((e) => Bird.fromEbird(
                speciesCode: e['speciesCode'] as String,
                comName: (e['comName'] as String?) ?? 'Unknown bird',
                sciName: e['sciName'] as String,
                family: (e['familyComName'] as String?) ?? 'Birds',
              ))
          .toList();
      _taxonomyMemo = list;
      return list;
    } catch (e) {
      debugPrint('EbirdService.taxonomy parse: $e');
      return null;
    }
  }

  Future<String?> _fetchTaxonomy() async {
    try {
      final uri = Uri.https(_host, '/v2/ref/taxonomy/ebird', {
        'fmt': 'json',
        'cat': 'species',
      });
      final res = await _client
          .get(uri)
          .timeout(const Duration(seconds: 30));
      if (res.statusCode != 200) {
        debugPrint('EbirdService.taxonomy HTTP ${res.statusCode}');
        return null;
      }
      return res.body;
    } catch (e) {
      debugPrint('EbirdService.taxonomy fetch: $e');
      return null;
    }
  }

  /// Recent observations near [point]. Needs an eBird API key; empty without.
  Future<List<NearbyObservation>> recentNearby(
    LatLng point, {
    int distanceKm = 25,
    int backDays = 14,
    int maxResults = 60,
  }) async {
    if (!AppConfig.hasEbirdKey) return const [];
    try {
      final uri = Uri.https(_host, '/v2/data/obs/geo/recent', {
        'lat': point.latitude.toStringAsFixed(4),
        'lng': point.longitude.toStringAsFixed(4),
        'dist': '$distanceKm',
        'back': '$backDays',
        'maxResults': '$maxResults',
      });
      final res = await _client.get(uri, headers: {
        'x-ebirdapitoken': AppConfig.ebirdApiKey,
      }).timeout(const Duration(seconds: 12));
      if (res.statusCode != 200) {
        debugPrint('EbirdService.recentNearby HTTP ${res.statusCode}');
        return const [];
      }
      return (jsonDecode(res.body) as List<dynamic>)
          .map((e) => e as Map<String, dynamic>)
          .map((e) => NearbyObservation(
                speciesCode: (e['speciesCode'] as String?) ?? '',
                comName: (e['comName'] as String?) ?? 'Unknown bird',
                sciName: (e['sciName'] as String?) ?? '',
                howMany: (e['howMany'] as num?)?.toInt() ?? 0,
                point: LatLng(
                  (e['lat'] as num?)?.toDouble() ?? point.latitude,
                  (e['lng'] as num?)?.toDouble() ?? point.longitude,
                ),
                locName: (e['locName'] as String?) ?? '',
                obsDt: (e['obsDt'] as String?) ?? '',
              ))
          .toList();
    } catch (e) {
      debugPrint('EbirdService.recentNearby: $e');
      return const [];
    }
  }

  // --- disk cache --------------------------------------------------------

  Future<File?> _cacheHandle() async {
    try {
      final dir = await getTemporaryDirectory();
      return File('${dir.path}/$_cacheFile');
    } catch (e) {
      return null; // e.g. unit tests without a platform channel
    }
  }

  Future<String?> _readCache() async {
    try {
      final file = await _cacheHandle();
      if (file == null || !file.existsSync()) return null;
      final age = DateTime.now().difference(file.lastModifiedSync());
      if (age > _cacheTtl) return null;
      return await file.readAsString();
    } catch (e) {
      return null;
    }
  }

  Future<void> _writeCache(String raw) async {
    try {
      final file = await _cacheHandle();
      await file?.writeAsString(raw);
    } catch (e) {
      // best-effort; a missing cache just means we refetch next launch
    }
  }
}
