import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/venues/tag.dart';
import '../../repositories/venues/tag_repository.dart';
import '../other_providers.dart';

/// Live + sorted by type priority, then A–Z //TODO want to fetch and store all tags (update storage if changes).
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
final tagRepositoryProvider = Provider<TagRepository>(
  (ref) => TagRepository(db: ref.watch(firestoreProvider)),
);

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
