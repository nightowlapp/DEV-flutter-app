// data/user_repository.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nightowlcode/models/users/user.dart' as model;
import '../../../models/users/phone_number.dart' as phone;
import '../../firestore_paths.dart';

class UserRepository {

  /// True if the username looks like "nightowl" (night-owl, night_owl, night owl, etc.)
  /// Flags usernames that resemble "nightowl" (requires admin).
  /// Catches: n1ght0wl, nìghtøwł, night-owl, nighhtowll, nigthowl, nghtowl, etc.
  bool resemblesNightOwl(String name) {
    const target = 'nightowl';
    final s = _normalizeForBrandCheck(name);
    if (s.isEmpty) return false;

    // Exact/substring/compound "night" + "owl"
    if (s == target) return true;
    if (s.contains(target)) return true;
    if (s.contains('night') && s.contains('owl')) return true;

    // Near matches (typos, transpositions, single-missing-letter like "nghtowl")
    if (_damerauLevenshtein(s, target) <= 2) return true;

    // Consonant skeleton match (e.g., "nghtowl" -> "nghtwl")
    const targetSkel = 'nghtwl';
    final skel = _consonantSkeleton(s);
    if (skel == targetSkel) return true;
    if (_damerauLevenshtein(skel, targetSkel) <= 1) return true;

    return false;
  }

  /// Normalize for likeness check: lowercase, map leetspeak & diacritics,
  /// collapse doubles, drop non-letters.
  String _normalizeForBrandCheck(String input) {
    var s = input.toLowerCase();

    // common look-alikes / leetspeak
    s = s
      .replaceAll('0', 'o')
      .replaceAll('1', 'i')
      .replaceAll('!', 'i')
      .replaceAll('|', 'i')
      .replaceAll('3', 'e')
      .replaceAll('5', 's')
      .replaceAll('\$', 's')
      .replaceAll('7', 't')
      .replaceAll('@', 'a')
      .replaceAll('8', 'b')
      .replaceAll('9', 'g');

    // "vv" → "w"
    s = s.replaceAll(RegExp(r'vv'), 'w');

    // basic diacritic folding (no extra deps)
    const fold = {
      'á':'a','à':'a','â':'a','ä':'a','ã':'a','å':'a','ā':'a',
      'ç':'c',
      'ď':'d','đ':'d',
      'é':'e','è':'e','ê':'e','ë':'e','ē':'e',
      'í':'i','ì':'i','î':'i','ï':'i','ı':'i','ī':'i',
      'ñ':'n',
      'ó':'o','ò':'o','ô':'o','ö':'o','õ':'o','ø':'o','ō':'o',
      'ß':'ss',
      'ś':'s','š':'s',
      'ť':'t','þ':'th',
      'ú':'u','ù':'u','û':'u','ü':'u','ū':'u',
      'ý':'y','ÿ':'y',
      'ž':'z',
      'ł':'l'
    };
    final buf = StringBuffer();
    for (final r in s.runes) {
      final ch = String.fromCharCode(r);
      buf.write(fold[ch] ?? ch);
    }
    s = buf.toString();

    // keep only letters a-z
    s = s.replaceAll(RegExp('[^a-z]'), '');

    // collapse repeated letters: "nniight-owwl" → "nightowl"
    s = _collapseRuns(s);

    return s;
  }

  /// Live search by lowercased username prefix ('' = just first N users).
  /// Requires the `user_name_lc` field to be stored (you already do that).
  Stream<List<model.User>> searchUsersByUsernameLc({
    required String query,
    int limit = 40,
  }) {
    final q = query.trim().toLowerCase();

    Query<model.User> base =
    _users.orderBy(DocumentPaths.userNameLower).limit(limit);

    // Prefix search: [startAt(q), endAt(q + '\uf8ff')]
    if (q.isNotEmpty) {
      base = _users
          .orderBy(DocumentPaths.userNameLower)
          .startAt([q])
          .endAt([q + '\uf8ff'])
          .limit(limit);
    }

    return base.snapshots().map((snap) => snap.docs.map((d) => d.data()).toList());
  }

  String _collapseRuns(String s) {
    if (s.isEmpty) return s;
    final b = StringBuffer()..write(s[0]);
    for (var i = 1; i < s.length; i++) {
      if (s[i] != s[i - 1]) b.write(s[i]);
    }
    return b.toString();
  }

  String _consonantSkeleton(String s) {
    final noVowels = s.replaceAll(RegExp('[aeiouy]'), '');
    return _collapseRuns(noVowels);
  }

  /// Damerau-Levenshtein distance (handles transpositions).
  int _damerauLevenshtein(String a, String b) {
    final m = a.length, n = b.length;
    if (m == 0) return n;
    if (n == 0) return m;

    final dist = List.generate(m + 1, (_) => List<int>.filled(n + 1, 0));
    for (var i = 0; i <= m; i++) dist[i][0] = i;
    for (var j = 0; j <= n; j++) dist[0][j] = j;

    for (var i = 1; i <= m; i++) {
      for (var j = 1; j <= n; j++) {
        final cost = a[i - 1] == b[j - 1] ? 0 : 1;
        var v = [
          dist[i - 1][j] + 1,        // deletion
          dist[i][j - 1] + 1,        // insertion
          dist[i - 1][j - 1] + cost, // substitution
        ].reduce((x, y) => x < y ? x : y);

        if (i > 1 && j > 1 && a[i - 1] == b[j - 2] && a[i - 2] == b[j - 1]) {
          v = v < dist[i - 2][j - 2] + cost ? v : dist[i - 2][j - 2] + cost;
        }
        dist[i][j] = v;
      }
    }
    return dist[m][n];
  }

  UserRepository(FirebaseFirestore db)
    : _users = db.collection(DocumentPaths.users).withConverter<model.User>(
      fromFirestore: (snap, _) {
        final data = snap.data() ?? const <String, dynamic>{};
        // inject docId as 'id' for the Dart model; DO NOT store it
        return model.User.fromJson({'id': snap.id, ...data});
      },
      toFirestore: (u, _) => _userToFirestore(u),
    );

  final CollectionReference<model.User> _users;

  // --- Reads ---
  Stream<model.User?> watchById(String id) =>
  _users.doc(id).snapshots().map((s) => s.data());

  Future<model.User?> getById(String id) async =>
  (await _users.doc(id).get()).data();

  /// Users who have favorited [venueId], using collectionGroup('favorites')
  Stream<List<model.User>> byFavoriteVenue(String venueId) {
    final db = _users.firestore;

    // We used doc id == venueId in the favorites subcollection,
    // so we can query by documentId directly.
    final favoritesGroupQuery = db
      .collectionGroup(DocumentPaths.favorites)
      .where(FieldPath.documentId, isEqualTo: venueId);

    return favoritesGroupQuery.snapshots().asyncMap((q) async {
        final userIds = q.docs
          .map((d) => d.reference.parent.parent?.id)
          .whereType<String>()
          .toSet()
          .toList();

        if (userIds.isEmpty) return <model.User>[];

        // Fan-out reads; for large results consider chunking / index + in queries.
        final futures = userIds.map((uid) => _users.doc(uid).get());
        final snaps = await Future.wait(futures);

        return snaps
          .where((s) => s.data() != null)
          .map((s) => s.data()!)
          .toList();
      }
    );
  }

  // --- Mutations ---
  Future<void> setUsername(String id, String userName) async {
    final ref = _users.doc(id);
    await ref.update({
      'user_name': userName.trim(),
      'updated_at': FieldValue.serverTimestamp(),
    }
    );
  }

  Future<void> markVerified(String id, bool isVerified) async {
    await _users.doc(id).update({
      'is_verified': isVerified,
      'updated_at': FieldValue.serverTimestamp(),
    }
    );
  }

  Future<void> create(model.User u) async {
    final ref = _users.doc(u.id);
    final batch = ref.firestore.batch();
    batch.set(ref, u, SetOptions(merge: false)); // write all non-null fields
    batch.update(ref, {
        // authoritative timestamps from server
        'created_at': FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
      }
    );
    await batch.commit();
  }

  Future<void> upsert(model.User u) async {
    final ref = _users.doc(u.id);
    final batch = ref.firestore.batch();
    batch.set(ref, u, SetOptions(merge: true));
    batch.update(ref, {'updated_at': FieldValue.serverTimestamp()});
    await batch.commit();
  }

  Future<void> delete(String id) => _users.doc(id).delete();

  // Quick, scalable availability check (case-insensitive).
  // --- Availability: ALWAYS use lower-case key ---
  Future<bool> usernameAvailableFast(String userName) async {
    final lc = userName.trim().toLowerCase();
    final snap = await _users.firestore.doc(DocumentPaths.usernameDoc(lc)).get();
    return !snap.exists;
  }

  // --- Atomic rename that works with typed converters ---
  Future<void> renameUsername({
    required String uid,
    required String newUserName,
  }) async {
    final db = _users.firestore;
    final desired = newUserName.trim();
    final desiredLc = desired.toLowerCase();

    // Use RAW refs inside the transaction to avoid typed snapshot casting issues.
    final rawUserRef = db.doc(DocumentPaths.user(uid));
    final nameRef = db.doc(DocumentPaths.usernameDoc(desiredLc));

    await db.runTransaction((tx) async {
        // Read current user as Map
        final userSnap = await tx.get(rawUserRef);
        if (!userSnap.exists) {
          throw StateError('User $uid missing');
        }
        final data = userSnap.data() as Map<String, dynamic>;

        final current = (data['user_name'] as String? ?? '').trim();
        final currentLc = (data[DocumentPaths.userNameLower] as String? ?? current.toLowerCase());

        // If it's a case-only change, ensure mapping points to me and update case.
        if (currentLc == desiredLc && current != desired) {
          final curMapSnap = await tx.get(nameRef);
          if (curMapSnap.exists && (curMapSnap.get('uid') as String?) != uid) {
            throw StateError('Username taken');
          }
          tx.set(nameRef, {'uid': uid, 'created_at': FieldValue.serverTimestamp()});
          tx.update(rawUserRef, {
              'user_name': desired,
              DocumentPaths.userNameLower: desiredLc,
              DocumentPaths.updatedAt: FieldValue.serverTimestamp(),
            }
          );
          return;
        }

        // Check availability
        final nameSnap = await tx.get(nameRef);
        if (nameSnap.exists && (nameSnap.get('uid') as String?) != uid) {
          throw StateError('Username taken');
        }

        // Reserve new mapping
        tx.set(nameRef, {'uid': uid, 'created_at': FieldValue.serverTimestamp()});

        // Release old mapping
        if (currentLc.isNotEmpty && currentLc != desiredLc) {
          tx.delete(db.doc(DocumentPaths.usernameDoc(currentLc)));
        }

        // Update user doc
        tx.update(rawUserRef, {
            'user_name': desired,
            DocumentPaths.userNameLower: desiredLc,
            DocumentPaths.updatedAt: FieldValue.serverTimestamp(),
          }
        );
      }
    );
  }

  // (Optional) If you want a simple setter, make it private and DO NOT use it from UI.
  // Keeping it here for completeness, but prefer renameUsername everywhere.
  Future<void> _setUsernameUnsafe(String id, String userName) async {
    await _users.doc(id).update({
      'user_name': userName.trim(),
      DocumentPaths.userNameLower: userName.trim().toLowerCase(),
      DocumentPaths.updatedAt: FieldValue.serverTimestamp(),
    }
    );
  }

  Future<void> setEmail({required String uid, required String email}) async {
    await _users.doc(uid).update({
      'email': email.trim().toLowerCase(),
      DocumentPaths.updatedAt: FieldValue.serverTimestamp(),
    }
    );
  }

  /// Patch first/middle/last + phone in one call (only provided fields are updated)
  Future<void> updateNamesAndPhone({
    required String uid,
    String? firstName,
    String? middleName,
    String? lastName,
    phone.PhoneNumber? phone,
  }) async {
    final data = <String, dynamic>{
      DocumentPaths.updatedAt: FieldValue.serverTimestamp(),
    };
    if (firstName != null) data[DocumentPaths.firstName] = firstName.trim();
    if (middleName != null) data[DocumentPaths.middleName] = middleName.trim();
    if (lastName != null) data[DocumentPaths.lastName] = lastName.trim();
    if (phone != null) data[DocumentPaths.phoneNumber] = phone.toJson();

    await _users.doc(uid).update(data);
  }

  /// Create a user and atomically reserve the username (case preserved).
  /// Fails if taken or resembles "nightowl" and the creator isn't admin.
  Future<void> createUserWithUsername(model.User u) async {
    final db = _users.firestore;
    final uid = u.id;
    final desired = u.userName.trim();
    final desiredLc = desired.toLowerCase();

    if (desired.isEmpty) {
      throw StateError('Username is required at registration');
    }
    if (resemblesNightOwl(desired) && !u.isAdmin) {
      throw StateError('This username is reserved');
    }

    await db.runTransaction((tx) async {
        final nameRef = db.doc(DocumentPaths.usernameDoc(desiredLc));
        final nameSnap = await tx.get(nameRef);
        if (nameSnap.exists) {
          throw StateError('Username taken');
        }

        final userRef = _users.doc(uid);

        // Write user with case-preserved username, but also store lc for queries.
        tx.set(userRef, u);
        tx.update(userRef, {
            'email': u.email.trim().toLowerCase(),
            'user_name': desired,                         // as typed
            DocumentPaths.userNameLower: desiredLc,       // for lookups
            'created_at': FieldValue.serverTimestamp(),
            'updated_at': FieldValue.serverTimestamp(),
          }
        );

        // Reserve name (case-insensitive uniqueness)
        tx.set(nameRef, {'uid': uid, 'created_at': FieldValue.serverTimestamp()});
      }
    );
  }
}

// Optionally expose a provider
final userRepositoryProvider = Provider<UserRepository>(
  (ref) => UserRepository(FirebaseFirestore.instance),
);


Map<String, Object?> _userToFirestore(model.User u) {
  // Start from model JSON (snake_case keys).
  final json = Map<String, Object?>.from(u.toJson());

  // Ensure Firestore never stores the model id.
  json.remove('id');

  // Normalize
  json['email'] = u.email.trim().toLowerCase();
  json['user_name'] = u.userName.trim();

  // Convert date-ish fields to Timestamps for consistency
  json['birth_date'] = Timestamp.fromDate(u.birthDate);
  json['created_at'] = Timestamp.fromDate(u.createdAt);
  json['updated_at'] = Timestamp.fromDate(u.updatedAt);

  // Default the flag on write if someone forgot to set it
  json['is_verified'] = (json['is_verified'] as bool?) ?? false;

  // NOTE: favorites/likes/achievements are NOT stored on the user doc anymore.

  return json;
}


// Users who liked a venue:
Stream<List<String>> userIdsWhoLikedVenue(
  FirebaseFirestore db, String venueId) {
  return db
    .collectionGroup(DocumentPaths.likes)
    .where(FieldPath.documentId, isEqualTo: venueId)
    .snapshots()
    .map((q) => q.docs
        .map((d) => d.reference.parent.parent?.id)
        .whereType<String>()
        .toList());
}

// Count favorites for a venue:
Stream<int> favoriteCount(FirebaseFirestore db, String venueId) {
  return db
    .collectionGroup(DocumentPaths.favorites)
    .where(FieldPath.documentId, isEqualTo: venueId)
    .snapshots()
    .map((q) => q.size);


}



// Users with the most achievements: // TODO

// Users with the most xp/level: // TODO
