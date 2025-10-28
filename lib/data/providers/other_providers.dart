import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;

import 'package:nightowlcode/data/repositories/users/auth/auth_repository.dart';
import 'package:nightowlcode/data/repositories/users/auth/user_finalize_service.dart';
import 'package:nightowlcode/data/repositories/users/user_repository.dart';
import 'package:nightowlcode/data/repositories/venues/venue_converters.dart';
import 'package:nightowlcode/data/repositories/venues/venue_repository.dart';
import 'package:nightowlcode/data/services/users/profile_picture_service.dart';
import 'package:nightowlcode/models/users/user.dart' as model;
import 'package:nightowlcode/models/venues/venue.dart';

import '../../core/app_config.dart';
import '../../core/storage/venues_sso.dart';
import '../../features/explore/presentation/ranked_venues_controller.dart';
import '../../features/explore/search/search_controller.dart';
import '../../features/explore/search/search_filter.dart';
import '../../models/venues/tag.dart';
import '../firestore_paths.dart';
import '../repositories/storage_repository.dart';
import '../repositories/venues/tag_repository.dart';

//TODO Only keep "OTHER" providers in here.

// --- Low-level singletons ---
final firebaseAuthProvider =
Provider<fb.FirebaseAuth>((ref) => fb.FirebaseAuth.instance);
final firestoreProvider =
Provider<FirebaseFirestore>((ref) => FirebaseFirestore.instance);

// Current Firebase user (null when signed out)
final authStateProvider = StreamProvider<fb.User?>(
      (ref) => ref.watch(firebaseAuthProvider).authStateChanges(),
);

// --- Repos ---
final userRepositoryProvider = Provider<UserRepository>(
      (ref) => UserRepository(ref.watch(firestoreProvider)),
);

final profilePictureServiceProvider = Provider<ProfilePictureService>((ref) {
  return ProfilePictureService(ref.read(firebaseStorageProvider));
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final cfg = AppConfig.current;
  return AuthRepository(
    auth: ref.watch(firebaseAuthProvider),
    users: ref.watch(userRepositoryProvider),
    googleServerClientId: cfg.googleServerClientId,
    googleIosClientId:
    cfg.googleIosClientId.isEmpty ? null : cfg.googleIosClientId,
  );
});

final authUserProvider = StreamProvider<model.User?>(
      (ref) => ref.watch(authRepositoryProvider).authUser$(),
);

final userFinalizeServiceProvider = Provider<UserFinalizeService>((ref) {
  final users = ref.watch(userRepositoryProvider);
  final auth = fb.FirebaseAuth.instance;
  return UserFinalizeService(users, auth);
});

final firebaseStorageProvider =
Provider<FirebaseStorage>((ref) => FirebaseStorage.instance);
final storageRepositoryProvider = Provider<StorageRepository>(
      (ref) => StorageRepository(ref.watch(firebaseStorageProvider)),
);

// --- Tags (recommended: live streams, no Hive) ---
// DI for repo
final tagRepositoryProvider = Provider<TagRepository>(
      (ref) => TagRepository(db: ref.watch(firestoreProvider)),
);

// Fixed priority: first 3 per your requirement, then sensible order.
const _typePriority = <TagType>[
  TagType.venue_type,
  TagType.entry_price,
  TagType.music,
  TagType.dress_code,
  TagType.vibe,
  TagType.crowd,
  TagType.age_restriction,
  TagType.event,
  TagType.amenity,
  TagType.service,
  TagType.reservation,
  TagType.accessibility,
  TagType.payment,
  TagType.hours,
  TagType.line_policy,
  TagType.smoking_policy,
  TagType.sound,
  TagType.neighborhood,
  TagType.special,
  TagType.other,
];

int _typeRank(TagType t) {
  final i = _typePriority.indexOf(t);
  return i == -1 ? 9999 : i;
}

/// Live tags for a venue (reactive to website edits)
final venueTagsStreamProvider =
StreamProvider.family<List<Tag>, List<String>>((ref, tagIds) {
  return ref.watch(tagRepositoryProvider).watchByIds(tagIds);
});

/// Live + sorted by type priority, then A–Z //TODO want to fetch and store all tags (update storage if changes).
final venueSortedTagsProvider =
StreamProvider.family<List<Tag>, List<String>>((ref, tagIds) {
  return ref.watch(venueTagsStreamProvider(tagIds).stream).map((tags) {
    final list = List<Tag>.from(tags);
    list.sort((a, b) {
      final r = _typeRank(a.type).compareTo(_typeRank(b.type));
      if (r != 0) return r;
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });
    return List<Tag>.unmodifiable(list);
  });
});

// --- Venues ---
final venueRepositoryProvider = Provider<VenueRepository>((ref) {
  final db = ref.watch(firestoreProvider);
  return VenueRepository(db: db);
});

/// One-shot (if you need it)
final allVenuesFutureProvider = FutureProvider<List<Venue>>(
      (ref) => ref.watch(venueRepositoryProvider).getAll(),
  name: 'allVenuesFutureProvider',
);

/// Live stream of **all** venues (reactive)
// lib/data/providers.dart  (or where you define this)
final allVenuesStreamProvider = StreamProvider<List<Venue>>((ref) {
  final db = ref.watch(firestoreProvider);
  final col = db.collection(DocumentPaths.venues).withConverter<Venue>(
    fromFirestore: (snap, _) => VenueFirestore.fromSnapshot(snap), // ✅
    toFirestore: (v, _) => VenueFirestore.toMap(v), // ✅
  );
  return col.snapshots().map((q) => q.docs.map((d) => d.data()).toList());
}, name: 'allVenuesStreamProvider');

final rankedVenuesProvider = StateNotifierProvider.autoDispose<
    RankedVenuesNotifier, AsyncValue<RankedVenuesState>>((ref) {
  return RankedVenuesNotifier(ref);
});

/// Ready-to-use filtered list for the Explore screen:
/// - watches rankedVenuesProvider (source of truth)
/// - watches searchQueryProvider (user input)
final exploreFilteredVenuesProvider = Provider.autoDispose<List<Venue>>((ref) {
  final base = ref.watch(venuesListProvider); // <-- from local SSO
  final q = ref.watch(searchQueryProvider);
  return filterVenues(base, q);
});

/// Single Source Of Truth for Venues:
/// - Immediately serves locally cached venues (fast start)
/// - On first-ever run (no cache): fetches all venues once and caches them
/// - Then listens for Firestore changes and incrementally updates the cache
/// - Exposes the up-to-date in-memory list at all times

final venuesListProvider = Provider<List<Venue>>((ref) {
  final async = ref.watch(venuesSsoProvider);
  return async.maybeWhen(data: (l) => l, orElse: () => const <Venue>[]);
});

// Grab a single venue by id (updates reactively when SSO changes)
final venueByIdProvider = Provider.family<Venue?, String>((ref, id) {
  final all = ref.watch(venuesListProvider);
  try {
    return all.firstWhere((v) => v.id == id);
  } catch (_) {
    return null;
  }
});

final visibleVenuesProvider = Provider.autoDispose<List<Venue>>((ref) {
  // Later you can intersect with viewport. For now: use filtered list.
  return ref.watch(exploreFilteredVenuesProvider);
});
