import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../config/app_config.dart';

/// A single bird-sound recording from xeno-canto, with the attribution the
/// Creative-Commons licenses require us to display.
class BirdRecording {
  const BirdRecording({
    required this.audioUrl,
    required this.recordist,
    required this.type,
    required this.quality,
    required this.country,
    required this.licenseUrl,
    required this.pageUrl,
  });

  final String audioUrl;
  final String recordist;
  final String type; // 'song', 'call', …
  final String quality; // 'A'..'E'
  final String country;
  final String licenseUrl;
  final String pageUrl;

  String get attribution {
    final bits = <String>[
      if (recordist.isNotEmpty) recordist,
      if (country.isNotEmpty) country,
    ];
    return bits.isEmpty ? 'xeno-canto' : '${bits.join(' · ')} · xeno-canto';
  }
}

/// Fetches bird recordings from the xeno-canto v3 API.
///
/// Requires a free API key (`AppConfig.xenoCantoApiKey`). Without one,
/// [recordingFor] returns null and the call card stays on its written
/// mnemonic. Best A/B-quality recordings are preferred. Cached per species.
class XenoCantoService {
  XenoCantoService({http.Client? client}) : _client = client ?? http.Client();

  static const _host = 'xeno-canto.org';
  final http.Client _client;
  final Map<String, BirdRecording?> _cache = {};
  final Map<String, Future<BirdRecording?>> _inFlight = {};

  bool get enabled => AppConfig.hasXenoCantoKey;

  Future<BirdRecording?> recordingFor(String scientificName) {
    if (!enabled || scientificName.isEmpty) return Future.value(null);
    if (_cache.containsKey(scientificName)) {
      return Future.value(_cache[scientificName]);
    }
    return _inFlight.putIfAbsent(scientificName, () async {
      try {
        final rec = await _fetch(scientificName);
        _cache[scientificName] = rec;
        return rec;
      } finally {
        _inFlight.remove(scientificName);
      }
    });
  }

  Future<BirdRecording?> _fetch(String scientificName) async {
    try {
      // v3 only accepts tag-based queries: gen:<genus> sp:<species>.
      final parts = scientificName.trim().split(RegExp(r'\s+'));
      final genus = parts.isNotEmpty ? parts[0] : '';
      final species = parts.length > 1 ? parts[1] : '';
      if (genus.isEmpty) return null;
      final query = species.isEmpty
          ? 'gen:$genus grp:birds'
          : 'gen:$genus sp:$species grp:birds';
      final uri = Uri.https(_host, '/api/3/recordings', {
        'query': query,
        'per_page': '20',
        'key': AppConfig.xenoCantoApiKey,
      });
      final res = await _client.get(uri, headers: {
        'accept': 'application/json',
      }).timeout(const Duration(seconds: 12));
      if (res.statusCode != 200) {
        debugPrint('XenoCantoService HTTP ${res.statusCode} for $scientificName');
        return null;
      }
      final json = jsonDecode(res.body) as Map<String, dynamic>;
      final recordings = (json['recordings'] as List<dynamic>?) ?? const [];
      if (recordings.isEmpty) return null;

      final maps = recordings.map((e) => e as Map<String, dynamic>).where((e) {
        final file = _normalizeUrl(e['file'] as String?);
        return file != null;
      }).toList();
      if (maps.isEmpty) return null;

      // Prefer the best quality; within that, prefer songs over calls.
      maps.sort((a, b) {
        final q = _qualityRank(a['q']).compareTo(_qualityRank(b['q']));
        if (q != 0) return q;
        return _typeRank(a['type']).compareTo(_typeRank(b['type']));
      });
      final best = maps.first;
      return BirdRecording(
        audioUrl: _normalizeUrl(best['file'] as String?)!,
        recordist: (best['rec'] as String?)?.trim() ?? '',
        type: (best['type'] as String?)?.trim() ?? '',
        quality: (best['q'] as String?)?.trim() ?? '',
        country: (best['cnt'] as String?)?.trim() ?? '',
        licenseUrl: _normalizeUrl(best['lic'] as String?) ?? '',
        pageUrl: _normalizeUrl(best['url'] as String?) ?? '',
      );
    } catch (e) {
      debugPrint('XenoCantoService $scientificName: $e');
      return null;
    }
  }

  // xeno-canto sometimes returns protocol-relative URLs (//…).
  String? _normalizeUrl(String? url) {
    if (url == null || url.isEmpty) return null;
    if (url.startsWith('//')) return 'https:$url';
    if (url.startsWith('http')) return url;
    return null;
  }

  int _qualityRank(Object? q) => switch (q) {
        'A' => 0,
        'B' => 1,
        'C' => 2,
        'D' => 3,
        'E' => 4,
        _ => 5,
      };

  int _typeRank(Object? type) {
    final t = (type as String? ?? '').toLowerCase();
    if (t.contains('song')) return 0;
    if (t.contains('call')) return 1;
    return 2;
  }
}
