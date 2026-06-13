import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/models.dart';
import 'repositories.dart';

/// Live Supabase implementations of the app's repository interfaces. Selected
/// in `main.dart` when `AppConfig.hasSupabase` is true; otherwise the Static*
/// / Demo* implementations run on local demo data. Screens never change.
///
/// Schema + RLS live in `supabase/migrations/`.

SupabaseClient get _db => Supabase.instance.client;

Color _parseColor(String? hex) {
  if (hex == null || hex.isEmpty) return const Color(0xFF2F5D45);
  final h = hex.replaceFirst('#', '');
  final v = int.tryParse(h.length == 6 ? 'FF$h' : h, radix: 16);
  return v == null ? const Color(0xFF2F5D45) : Color(v);
}

AppUser _userFromProfile(Map<String, dynamic> row, {bool isMe = false}) {
  final id = row['id'] as String;
  return AppUser(
    id: id,
    name: (row['name'] as String?)?.trim().isNotEmpty == true
        ? row['name'] as String
        : 'Birder',
    handle: (row['handle'] as String?) ?? '@${id.substring(0, 6)}',
    color: _parseColor(row['color'] as String?),
    home: (row['home'] as String?) ?? '',
    homePoint: LatLng(
      (row['home_lat'] as num?)?.toDouble() ?? 0,
      (row['home_lng'] as num?)?.toDouble() ?? 0,
    ),
    isMe: isMe,
  );
}

class SupabaseAuthRepository implements AuthRepository {
  @override
  bool get requiresOtp => true;

  @override
  Future<bool> hasSavedSession() async => _db.auth.currentSession != null;

  @override
  Future<AppUser?> currentUser() async {
    final user = _db.auth.currentUser;
    if (user == null) return null;
    final row =
        await _db.from('profiles').select().eq('id', user.id).maybeSingle();
    if (row != null) return _userFromProfile(row, isMe: true);
    // Profile row not created yet (trigger lag) — fall back to auth metadata.
    return AppUser(
      id: user.id,
      name: user.email?.split('@').first ?? 'Birder',
      handle: '@${user.id.substring(0, 6)}',
      color: const Color(0xFFC9473F),
      home: '',
      homePoint: const LatLng(0, 0),
      isMe: true,
    );
  }

  @override
  Future<void> sendOtp(String email) async {
    await _db.auth.signInWithOtp(email: email, shouldCreateUser: true);
  }

  @override
  Future<AppUser> verifyOtp(String email, String token) async {
    await _db.auth.verifyOTP(email: email, token: token, type: OtpType.email);
    return (await currentUser())!;
  }

  @override
  Future<AppUser> signIn({String? email}) =>
      throw UnsupportedError('Supabase auth uses sendOtp/verifyOtp');

  @override
  Future<void> signOut() => _db.auth.signOut();
}

class SupabaseSocialRepository implements SocialRepository {
  String get _uid => _db.auth.currentUser!.id;

  @override
  Future<AppUser> getCurrentUser() async {
    final row =
        await _db.from('profiles').select().eq('id', _uid).maybeSingle();
    return row != null
        ? _userFromProfile(row, isMe: true)
        : AppUser(
            id: _uid,
            name: 'Birder',
            handle: '@${_uid.substring(0, 6)}',
            color: const Color(0xFFC9473F),
            home: '',
            homePoint: const LatLng(0, 0),
            isMe: true,
          );
  }

  Future<List<Map<String, dynamic>>> _myFriendships() async {
    return await _db
        .from('friendships')
        .select('requester, addressee, status')
        .or('requester.eq.$_uid,addressee.eq.$_uid');
  }

  Future<List<AppUser>> _profiles(Iterable<String> ids) async {
    final list = ids.toList();
    if (list.isEmpty) return [];
    final rows = await _db.from('profiles').select().inFilter('id', list);
    return rows.map((r) => _userFromProfile(r)).toList();
  }

  @override
  Future<List<AppUser>> getFriends() async {
    final f = await _myFriendships();
    final ids = f
        .where((r) => r['status'] == 'accepted')
        .map((r) => r['requester'] == _uid ? r['addressee'] : r['requester'])
        .cast<String>()
        .toSet();
    return _profiles(ids);
  }

  @override
  Future<List<AppUser>> getFriendRequests() async {
    final f = await _myFriendships();
    final ids = f
        .where((r) => r['status'] == 'pending' && r['addressee'] == _uid)
        .map((r) => r['requester'] as String)
        .toSet();
    return _profiles(ids);
  }

  @override
  Future<List<AppUser>> getSuggestions() async {
    final f = await _myFriendships();
    final connected = <String>{
      _uid,
      for (final r in f) r['requester'] as String,
      for (final r in f) r['addressee'] as String,
    };
    final rows = await _db.from('profiles').select();
    return rows
        .where((r) => !connected.contains(r['id']))
        .map((r) => _userFromProfile(r))
        .toList();
  }

  @override
  Future<void> sendRequest(String userId) async {
    await _db.from('friendships').insert({
      'requester': _uid,
      'addressee': userId,
      'status': 'pending',
    });
  }

  @override
  Future<void> acceptRequest(String userId) async {
    await _db
        .from('friendships')
        .update({'status': 'accepted'})
        .eq('requester', userId)
        .eq('addressee', _uid);
  }

  @override
  Future<void> declineRequest(String userId) async {
    await _db
        .from('friendships')
        .delete()
        .eq('requester', userId)
        .eq('addressee', _uid);
  }

  @override
  Future<void> removeFriend(String userId) async {
    await _db.from('friendships').delete().or(
        'and(requester.eq.$_uid,addressee.eq.$userId),and(requester.eq.$userId,addressee.eq.$_uid)');
  }
}

class SupabaseSightingRepository implements SightingRepository {
  String get _uid => _db.auth.currentUser!.id;

  Sighting _fromRow(Map<String, dynamic> r) => Sighting(
        id: r['id'] as String,
        birdId: r['bird_id'] as String,
        userId: r['user_id'] as String,
        seenAt: DateTime.parse(r['seen_at'] as String).toLocal(),
        point: LatLng(
          (r['lat'] as num?)?.toDouble() ?? 0,
          (r['lng'] as num?)?.toDouble() ?? 0,
        ),
        place: (r['place'] as String?) ?? '',
        note: r['note'] as String?,
      );

  @override
  Future<List<Sighting>> getSightings() async {
    final rows = await _db.from('sightings').select().order('seen_at');
    return rows.map(_fromRow).toList();
  }

  @override
  Future<Sighting> addSighting(Sighting s) async {
    final row = await _db
        .from('sightings')
        .insert({
          'user_id': _uid,
          'bird_id': s.birdId,
          'seen_at': s.seenAt.toUtc().toIso8601String(),
          'lat': s.point.latitude,
          'lng': s.point.longitude,
          'place': s.place,
          'note': s.note,
        })
        .select()
        .single();
    return _fromRow(row);
  }
}
