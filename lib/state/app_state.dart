import 'dart:async';

import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

import '../config/app_config.dart';
import '../data/badges.dart';
import '../data/repositories.dart';
import '../data/species_catalog.dart';
import '../models/models.dart';
import '../services/bird_image_service.dart';
import '../services/biometric.dart';
import '../services/ebird_service.dart';
import '../services/xeno_canto_service.dart';

/// What you get back for logging a sighting — drives the celebration screen.
class LogReward {
  const LogReward({
    required this.sighting,
    required this.bird,
    required this.points,
    required this.newBadges,
    required this.isLifer,
  });

  final Sighting sighting;
  final Bird bird;
  final int points;
  final List<BadgeDef> newBadges;

  /// First time ever seeing this species.
  final bool isLifer;
}

enum ActivityKind { friendSighting, friendRequest, lifer }

/// One row in the notifications / activity feed. Derived from the social graph
/// so it stays correct against static data or a future backend; real push
/// delivery is a separate concern (see README).
class ActivityItem {
  const ActivityItem({
    required this.kind,
    required this.user,
    required this.time,
    this.bird,
    this.sighting,
  });

  final ActivityKind kind;
  final AppUser user;
  final DateTime time;
  final Bird? bird;
  final Sighting? sighting;
}

/// Single source of truth for the whole app. Reads everything through the
/// repository interfaces, so the move to Supabase later is a constructor swap.
class AppState extends ChangeNotifier {
  AppState({
    required BirdRepository birdRepo,
    required SightingRepository sightingRepo,
    required SocialRepository socialRepo,
    required AuthRepository authRepo,
    BirdImageService? images,
    EbirdService? ebird,
    XenoCantoService? audio,
  })  : _birdRepo = birdRepo,
        _sightingRepo = sightingRepo,
        _socialRepo = socialRepo,
        _authRepo = authRepo,
        images = images ?? BirdImageService(),
        _ebird = ebird ?? EbirdService(),
        audio = audio ?? XenoCantoService();

  final BirdRepository _birdRepo;
  final SightingRepository _sightingRepo;
  final SocialRepository _socialRepo;
  final AuthRepository _authRepo;
  final BirdImageService images;
  final EbirdService _ebird;
  final XenoCantoService audio;

  // --- auth ---
  bool _authChecked = false;
  bool _signedIn = false;
  bool _signingIn = false;
  bool _locked = false;
  bool get authChecked => _authChecked;
  bool get signedIn => _signedIn;
  bool get signingIn => _signingIn;

  /// A saved session exists but is awaiting biometric unlock this launch.
  bool get locked => _locked && !_signedIn;

  bool _loaded = false;
  bool get loaded => _loaded;

  /// The hand-written featured birds (always available, offline).
  List<Bird> _curatedBirds = [];

  /// The full catalog: featured + the entire eBird world checklist once it
  /// finishes loading in the background. Starts equal to the curated set.
  List<Bird> _catalog = [];

  /// Catalog ordered for browsing: featured (curated) species first, then the
  /// rest alphabetically. Cached so the Birdpedia grid doesn't re-sort 11k.
  List<Bird> _catalogBrowse = [];
  bool _catalogLoaded = false;

  // Fast lookups, rebuilt whenever the catalog changes.
  Map<String, Bird> _byId = {};
  Map<String, Bird> _byEbirdCode = {};
  Map<String, Bird> _bySci = {};

  final Map<String, List<Bird>> _nearbyCache = {};

  List<Sighting> _sightings = [];
  AppUser _me = AppUser(
      id: 'me',
      name: '',
      handle: '',
      color: const Color(0xFF000000),
      home: '',
      homePoint: const LatLng(0, 0),
      isMe: true);
  List<AppUser> _friends = [];
  List<AppUser> _friendRequests = [];
  List<AppUser> _suggestions = [];
  final Set<String> _pendingSent = {};

  /// Featured birds — the curated set used for the home screen and as the
  /// default Birdpedia view.
  List<Bird> get birds => _curatedBirds;
  List<Bird> get catalog => _catalog;
  List<Bird> get catalogBrowse => _catalogBrowse;
  bool get catalogLoaded => _catalogLoaded;
  int get catalogCount => _catalog.length;

  /// Whether live eBird "near you" data is available (key present).
  bool get hasLiveNearby => AppConfig.hasEbirdKey;

  AppUser get me => _me;
  List<AppUser> get friends => _friends;
  List<AppUser> get friendRequests => _friendRequests;
  List<AppUser> get suggestions => _suggestions;
  bool isRequestPending(String userId) => _pendingSent.contains(userId);

  // -------------------------------------------------------------------
  // Auth lifecycle
  // -------------------------------------------------------------------

  /// Called once at startup. A saved session puts the app into [locked] state
  /// (awaiting Face ID); otherwise it shows onboarding. The optional
  /// `--dart-define=BC_DEMO_AUTOLOGIN=true` skips both for demos/screenshots.
  static const _autoLogin = bool.fromEnvironment('BC_DEMO_AUTOLOGIN');

  /// Real (Supabase) auth signs in via a magic link; demo signs in instantly.
  bool get usesMagicLink => _authRepo.usesMagicLink;

  StreamSubscription<bool>? _authSub;

  Future<void> bootstrap() async {
    // React to a magic link being opened (session appears asynchronously).
    _authSub ??= _authRepo.authChanges.listen((signedIn) {
      if (signedIn && !_signedIn) {
        load();
      } else if (!signedIn && _signedIn) {
        _signedIn = false;
        _loaded = false;
        notifyListeners();
      }
    });

    if (_autoLogin && !_authRepo.usesMagicLink) {
      await signIn();
      _authChecked = true;
      notifyListeners();
      return;
    }
    final saved = await _authRepo.hasSavedSession();
    _authChecked = true;
    _locked = saved;
    notifyListeners();
  }

  @override
  void dispose() {
    _authSub?.cancel();
    super.dispose();
  }

  /// Restore a saved session after a successful biometric unlock.
  Future<bool> unlock() async {
    final ok = await Biometric.authenticate(reason: 'Unlock BirdCherry');
    if (!ok) return false;
    if (_authRepo.usesMagicLink) {
      // Real backend: the session is already restored from storage; just load.
      _signingIn = true;
      notifyListeners();
      await load();
      _signingIn = false;
      _locked = false;
      notifyListeners();
    } else {
      await signIn();
    }
    return true;
  }

  /// Email a magic link. The session arrives via the auth-change subscription
  /// once the user taps the link.
  Future<void> sendMagicLink(String email) => _authRepo.sendMagicLink(email);

  Future<void> signIn({String? email}) async {
    _signingIn = true;
    notifyListeners();
    await _authRepo.signIn(email: email);
    await load();
    _signingIn = false;
    _locked = false;
    notifyListeners();
  }

  Future<void> signOut() async {
    await _authRepo.signOut();
    _signedIn = false;
    _locked = false;
    _loaded = false;
    _sightings = [];
    _friends = [];
    _friendRequests = [];
    _suggestions = [];
    _pendingSent.clear();
    notifyListeners();
  }

  Future<void> load() async {
    final results = await Future.wait([
      _birdRepo.getBirds(),
      _sightingRepo.getSightings(),
      _socialRepo.getCurrentUser(),
      _socialRepo.getFriends(),
      _socialRepo.getFriendRequests(),
      _socialRepo.getSuggestions(),
    ]);
    _curatedBirds = results[0] as List<Bird>;
    _sightings = List.of(results[1] as List<Sighting>);
    _me = results[2] as AppUser;
    _friends = List.of(results[3] as List<AppUser>);
    _friendRequests = List.of(results[4] as List<AppUser>);
    _suggestions = List.of(results[5] as List<AppUser>);
    _setCatalog(_curatedBirds);
    _signedIn = true;
    _loaded = true;
    notifyListeners();
    // Pull the full eBird taxonomy in the background; UI updates when ready.
    unawaited(_loadFullCatalog());
  }

  // -------------------------------------------------------------------
  // Friend management
  // -------------------------------------------------------------------

  Future<void> sendFriendRequest(String userId) async {
    _pendingSent.add(userId);
    _suggestions = _suggestions.where((u) => u.id != userId).toList();
    notifyListeners();
    await _socialRepo.sendRequest(userId);
  }

  Future<void> acceptFriendRequest(String userId) async {
    final user = _friendRequests.firstWhere((u) => u.id == userId);
    _friendRequests = _friendRequests.where((u) => u.id != userId).toList();
    _friends = [..._friends, user];
    notifyListeners();
    await _socialRepo.acceptRequest(userId);
  }

  Future<void> declineFriendRequest(String userId) async {
    _friendRequests = _friendRequests.where((u) => u.id != userId).toList();
    notifyListeners();
    await _socialRepo.declineRequest(userId);
  }

  Future<void> removeFriend(String userId) async {
    final user = _friends.firstWhere((u) => u.id == userId);
    _friends = _friends.where((u) => u.id != userId).toList();
    // Mirror the repo: a removed friend returns to suggestions.
    if (!_suggestions.any((u) => u.id == userId)) {
      _suggestions = [..._suggestions, user];
    }
    _pendingSent.remove(userId);
    notifyListeners();
    await _socialRepo.removeFriend(userId);
  }

  // -------------------------------------------------------------------
  // Activity feed (notifications)
  // -------------------------------------------------------------------

  /// Newest-first feed of what your flock is up to, plus incoming requests.
  List<ActivityItem> activityFeed() {
    final items = <ActivityItem>[];

    // Incoming friend requests sit at the top with a recent timestamp.
    final now = DateTime.now();
    for (var i = 0; i < _friendRequests.length; i++) {
      items.add(ActivityItem(
        kind: ActivityKind.friendRequest,
        user: _friendRequests[i],
        time: now.subtract(Duration(hours: 2 * (i + 1))),
      ));
    }

    // Friend sightings — rare/legendary ones read as "lifer" highlights.
    for (final s in friendSightings) {
      final bird = birdById(s.birdId);
      items.add(ActivityItem(
        kind: bird.rarity.index >= Rarity.rare.index
            ? ActivityKind.lifer
            : ActivityKind.friendSighting,
        user: userById(s.userId),
        time: s.seenAt,
        bird: bird,
        sighting: s,
      ));
    }

    items.sort((a, b) => b.time.compareTo(a.time));
    return items;
  }

  /// Badge count for the notifications bell: pending requests + fresh sightings.
  int get unreadCount {
    final cutoff = DateTime.now().subtract(const Duration(hours: 24));
    final fresh = friendSightings.where((s) => s.seenAt.isAfter(cutoff)).length;
    return _friendRequests.length + fresh;
  }

  Future<void> _loadFullCatalog() async {
    final taxonomy = await _ebird.taxonomy();
    if (taxonomy == null) return; // offline / failed — keep curated only.
    _setCatalog(SpeciesCatalog.merge(_curatedBirds, taxonomy));
    _catalogLoaded = true;
    _nearbyCache.clear();
    notifyListeners();
  }

  void _setCatalog(List<Bird> birds) {
    _catalog = birds;
    _catalogBrowse = [...birds]..sort((a, b) {
        if (a.curated != b.curated) return a.curated ? -1 : 1;
        return a.name.toLowerCase().compareTo(b.name.toLowerCase());
      });
    _byId = {for (final b in birds) b.id: b};
    _byEbirdCode = {
      for (final b in birds)
        if (b.ebirdCode != null) b.ebirdCode!: b,
    };
    _bySci = {for (final b in birds) b.scientificName.toLowerCase(): b};
  }

  // -------------------------------------------------------------------
  // Catalog search & nearby
  // -------------------------------------------------------------------

  /// Search the entire catalog. Curated birds rank first, then alphabetical.
  List<Bird> searchCatalog(String query, {int limit = 80}) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return const [];
    final matches = _catalog.where((b) {
      return b.name.toLowerCase().contains(q) ||
          b.scientificName.toLowerCase().contains(q) ||
          b.family.toLowerCase().contains(q);
    }).toList()
      ..sort((a, b) {
        if (a.curated != b.curated) return a.curated ? -1 : 1;
        return a.name.compareTo(b.name);
      });
    return matches.length > limit ? matches.sublist(0, limit) : matches;
  }

  /// Birds reported near [point]. Live eBird data when a key is configured,
  /// otherwise the curated region list so the feature always shows something.
  Future<List<Bird>> birdsNear(LatLng point) async {
    final key = '${point.latitude.toStringAsFixed(1)},'
        '${point.longitude.toStringAsFixed(1)}';
    final cached = _nearbyCache[key];
    if (cached != null) return cached;

    List<Bird> result;
    if (AppConfig.hasEbirdKey) {
      final obs = await _ebird.recentNearby(point);
      final seen = <String>{};
      result = [];
      for (final o in obs) {
        final bird = SpeciesCatalog.birdFor(o, _byEbirdCode, _bySci);
        if (seen.add(bird.id)) result.add(bird);
      }
      // If the key call returned nothing (e.g. remote area), fall back.
      if (result.isEmpty) result = birdsInRegion(Region.fromLatLng(point));
    } else {
      result = birdsInRegion(Region.fromLatLng(point));
    }
    _nearbyCache[key] = result;
    return result;
  }

  // -------------------------------------------------------------------
  // Lookups
  // -------------------------------------------------------------------
  Bird birdById(String id) =>
      _byId[id] ??
      _curatedBirds.firstWhere(
        (b) => b.id == id,
        orElse: () => Bird.fromEbird(
          speciesCode: id,
          comName: 'Unknown bird',
          sciName: '',
          family: 'Birds',
        ),
      );

  AppUser userById(String id) {
    if (id == _me.id) return _me;
    for (final pool in [_friends, _friendRequests, _suggestions]) {
      for (final u in pool) {
        if (u.id == id) return u;
      }
    }
    return AppUser(
      id: id,
      name: 'BirdCherry user',
      handle: '@$id',
      color: const Color(0xFF7C867E),
      home: '',
      homePoint: const LatLng(0, 0),
    );
  }

  List<Sighting> get allSightings {
    final list = List.of(_sightings)
      ..sort((a, b) => b.seenAt.compareTo(a.seenAt));
    return list;
  }

  List<Sighting> get mySightings =>
      allSightings.where((s) => s.userId == _me.id).toList();

  List<Sighting> get friendSightings =>
      allSightings.where((s) => s.userId != _me.id).toList();

  List<Sighting> sightingsOf(String userId) =>
      allSightings.where((s) => s.userId == userId).toList();

  List<Sighting> sightingsForBird(String birdId) =>
      allSightings.where((s) => s.birdId == birdId).toList();

  /// Species ids the given user has seen.
  Set<String> lifeListOf(String userId) =>
      sightingsOf(userId).map((s) => s.birdId).toSet();

  bool seenByMe(String birdId) => lifeListOf(_me.id).contains(birdId);

  List<Bird> birdsInRegion(Region region) =>
      _curatedBirds.where((b) => b.regions.contains(region)).toList()
        ..sort((a, b) => a.rarity.index.compareTo(b.rarity.index));

  // -------------------------------------------------------------------
  // Gamification
  // -------------------------------------------------------------------
  int pointsOf(String userId) => sightingsOf(userId)
      .fold(0, (sum, s) => sum + birdById(s.birdId).points);

  int weeklyPointsOf(String userId) {
    final cutoff = DateTime.now().subtract(const Duration(days: 7));
    return sightingsOf(userId)
        .where((s) => s.seenAt.isAfter(cutoff))
        .fold(0, (sum, s) => sum + birdById(s.birdId).points);
  }

  // Per-user gamification, so any profile (me or a friend) can be rendered.
  int streakOf(String userId) => Badges.streakOf(sightingsOf(userId));
  int levelOf(String userId) => pointsOf(userId) ~/ 150 + 1;
  double levelProgressOf(String userId) => (pointsOf(userId) % 150) / 150.0;
  int pointsToNextLevelOf(String userId) => 150 - pointsOf(userId) % 150;

  List<BadgeDef> earnedBadgesOf(String userId) {
    final s = sightingsOf(userId);
    return Badges.all.where((b) => b.isEarned(s, birdById)).toList();
  }

  List<BadgeDef> lockedBadgesOf(String userId) {
    final s = sightingsOf(userId);
    return Badges.all.where((b) => !b.isEarned(s, birdById)).toList();
  }

  int get myPoints => pointsOf(_me.id);
  int get myStreak => streakOf(_me.id);

  /// Level is earned every 150 points. Level 1 at 0 pts.
  int get myLevel => levelOf(_me.id);
  double get levelProgress => levelProgressOf(_me.id);
  int get pointsToNextLevel => pointsToNextLevelOf(_me.id);

  List<BadgeDef> get earnedBadges => earnedBadgesOf(_me.id);
  List<BadgeDef> get lockedBadges => lockedBadgesOf(_me.id);

  /// Weekly leaderboard: everyone, sorted by points earned in the last 7 days.
  List<(AppUser, int)> get weeklyLeaderboard {
    final rows = [_me, ..._friends]
        .map((u) => (u, weeklyPointsOf(u.id)))
        .toList()
      ..sort((a, b) => b.$2.compareTo(a.$2));
    return rows;
  }

  /// Weekly challenge: log [weeklyChallengeGoal] species this week.
  static const int weeklyChallengeGoal = 5;
  int get weeklyChallengeProgress {
    final cutoff = DateTime.now().subtract(const Duration(days: 7));
    return mySightings
        .where((s) => s.seenAt.isAfter(cutoff))
        .map((s) => s.birdId)
        .toSet()
        .length;
  }

  /// Species friends have seen that I haven't — fuel for friendly rivalry.
  List<(Bird, List<AppUser>)> get birdsFriendsHaveSeen {
    final mine = lifeListOf(_me.id);
    final result = <(Bird, List<AppUser>)>[];
    final byBird = <String, Set<String>>{};
    for (final s in friendSightings) {
      (byBird[s.birdId] ??= {}).add(s.userId);
    }
    for (final entry in byBird.entries) {
      if (!mine.contains(entry.key)) {
        result.add((
          birdById(entry.key),
          entry.value.map(userById).toList(),
        ));
      }
    }
    result.sort((a, b) => b.$1.points.compareTo(a.$1.points));
    return result;
  }

  // -------------------------------------------------------------------
  // Logging a sighting
  // -------------------------------------------------------------------
  Future<LogReward> logSighting({
    required Bird bird,
    required LatLng point,
    required String place,
    String? note,
    DateTime? seenAt,
  }) async {
    final badgesBefore = earnedBadges.map((b) => b.id).toSet();
    final isLifer = !seenByMe(bird.id);

    final sighting = await _sightingRepo.addSighting(Sighting(
      id: 'local-${DateTime.now().microsecondsSinceEpoch}',
      birdId: bird.id,
      userId: _me.id,
      seenAt: seenAt ?? DateTime.now(),
      point: point,
      place: place,
      note: (note == null || note.trim().isEmpty) ? null : note.trim(),
    ));
    _sightings.add(sighting);
    notifyListeners();

    final newBadges = earnedBadges
        .where((b) => !badgesBefore.contains(b.id))
        .toList();
    return LogReward(
      sighting: sighting,
      bird: bird,
      points: bird.points,
      newBadges: newBadges,
      isLifer: isLifer,
    );
  }
}
