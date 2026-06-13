import 'package:shared_preferences/shared_preferences.dart';

import '../models/models.dart';
import 'seed.dart';

/// Data access contracts.
///
/// Every screen reads through these interfaces via [AppState], never through
/// `Seed` directly. To move to a real backend, implement these interfaces with
/// Supabase (auth via supabase_flutter; tables: `profiles`, `friendships`,
/// `friend_requests`, `sightings`, `birds`) and swap the instances in
/// `main.dart`. No widget code changes.
abstract interface class BirdRepository {
  Future<List<Bird>> getBirds();
}

abstract interface class SightingRepository {
  Future<List<Sighting>> getSightings();
  Future<Sighting> addSighting(Sighting sighting);
}

/// Authentication. The demo implementation fakes a session persisted on the
/// device; the Supabase implementation wraps `supabase.auth` with a magic
/// link (free-tier friendly — the default email already sends one).
abstract interface class AuthRepository {
  /// The active user, or null when signed out.
  Future<AppUser?> currentUser();

  /// Whether a saved session exists from a previous launch (→ offer Face ID).
  Future<bool> hasSavedSession();

  /// Real auth signs in via an emailed magic link (vs. immediate demo sign-in).
  bool get usesMagicLink;

  /// Immediate demo sign-in (used only when [usesMagicLink] is false).
  Future<AppUser> signIn({String? email});

  /// Email a magic link (used only when [usesMagicLink] is true). The session
  /// arrives asynchronously via [authChanges] once the user taps the link.
  Future<void> sendMagicLink(String email);

  /// Emits true when a session appears (e.g. after a magic link is opened),
  /// false on sign-out. Empty for the demo repo.
  Stream<bool> get authChanges;

  Future<void> signOut();
}

/// The social graph: your profile, friends, incoming requests and discovery.
abstract interface class SocialRepository {
  Future<AppUser> getCurrentUser();
  Future<List<AppUser>> getFriends();
  Future<List<AppUser>> getFriendRequests();
  Future<List<AppUser>> getSuggestions();

  /// You requested [userId]; they move to "pending" until accepted.
  Future<void> sendRequest(String userId);

  /// Accept an incoming request from [userId]; they become a friend.
  Future<void> acceptRequest(String userId);
  Future<void> declineRequest(String userId);
  Future<void> removeFriend(String userId);
}

// ---------------------------------------------------------------------------
// Static demo implementations.
// ---------------------------------------------------------------------------

class StaticBirdRepository implements BirdRepository {
  @override
  Future<List<Bird>> getBirds() async => Seed.birds;
}

class StaticSightingRepository implements SightingRepository {
  StaticSightingRepository() : _sightings = Seed.sightings();

  final List<Sighting> _sightings;

  @override
  Future<List<Sighting>> getSightings() async => List.unmodifiable(_sightings);

  @override
  Future<Sighting> addSighting(Sighting sighting) async {
    _sightings.add(sighting);
    return sighting;
  }
}

class DemoAuthRepository implements AuthRepository {
  AppUser? _user; // active session for this launch
  static const _key = 'bc_signed_in';

  // Prefs access is defensive so unit tests (no plugin) degrade gracefully.
  Future<SharedPreferences?> _prefs() async {
    try {
      return await SharedPreferences.getInstance();
    } catch (_) {
      return null;
    }
  }

  @override
  bool get usesMagicLink => false;

  @override
  Stream<bool> get authChanges => const Stream.empty();

  @override
  Future<AppUser?> currentUser() async => _user;

  @override
  Future<bool> hasSavedSession() async {
    return (await _prefs())?.getBool(_key) ?? false;
  }

  @override
  Future<AppUser> signIn({String? email}) async {
    // No real backend yet: any credentials sign you in as the demo profile.
    await (await _prefs())?.setBool(_key, true);
    return _user = Seed.me;
  }

  @override
  Future<void> sendMagicLink(String email) => signIn(email: email);

  @override
  Future<void> signOut() async {
    await (await _prefs())?.remove(_key);
    _user = null;
  }
}

class StaticSocialRepository implements SocialRepository {
  StaticSocialRepository()
      : _friends = List.of(Seed.friends),
        _requests = List.of(Seed.friendRequests),
        _suggestions = List.of(Seed.discoverable);

  final List<AppUser> _friends;
  final List<AppUser> _requests;
  final List<AppUser> _suggestions;

  @override
  Future<AppUser> getCurrentUser() async => Seed.me;

  @override
  Future<List<AppUser>> getFriends() async => List.unmodifiable(_friends);

  @override
  Future<List<AppUser>> getFriendRequests() async => List.unmodifiable(_requests);

  @override
  Future<List<AppUser>> getSuggestions() async => List.unmodifiable(_suggestions);

  @override
  Future<void> sendRequest(String userId) async {
    _suggestions.removeWhere((u) => u.id == userId);
  }

  @override
  Future<void> acceptRequest(String userId) async {
    final i = _requests.indexWhere((u) => u.id == userId);
    if (i != -1) _friends.add(_requests.removeAt(i));
  }

  @override
  Future<void> declineRequest(String userId) async {
    _requests.removeWhere((u) => u.id == userId);
  }

  @override
  Future<void> removeFriend(String userId) async {
    final i = _friends.indexWhere((u) => u.id == userId);
    if (i != -1) _suggestions.add(_friends.removeAt(i));
  }
}
