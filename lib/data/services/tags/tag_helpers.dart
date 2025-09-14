import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/venues/tag.dart';
import 'tags_sso.dart';

/// Your preferred display order (edit anytime)
final tagTypeOrderProvider = StateProvider<List<TagType>>((_) => const [
  TagType.venue_type, // put anywhere you like
  TagType.entry_price,
  TagType.vibe,
  TagType.music,
  TagType.amenity,
  TagType.smoking_policy,

//TODO make others equally valuable
  TagType.dress_code,
  TagType.event,
  TagType.crowd,
  TagType.payment,
  TagType.hours,
  TagType.reservation,
  TagType.accessibility,
  TagType.service,
  TagType.neighborhood,
  TagType.sound,
  TagType.special,
  TagType.age_restriction,
  TagType.other,
]);

int _rank(TagType t, List<TagType> order) {
  final i = order.indexOf(t);
  return i == -1 ? 9999 : i;
}

/// Get tags for a set of IDs from local SSO (no network), sorted by your order then A–Z.
final localSortedTagsByIdsProvider =
Provider.family<List<Tag>, List<String>>((ref, ids) {
  final mapAsync = ref.watch(tagsSsoProvider);
  return mapAsync.maybeWhen(
    data: (map) {
      final list = <Tag>[];
      for (final id in ids) {
        final t = map[id.trim()];
        if (t != null) list.add(t);
      }
      final order = ref.watch(tagTypeOrderProvider);
      list.sort((a, b) {
        final r = _rank(a.type, order).compareTo(_rank(b.type, order));
        if (r != 0) return r;
        return a.name.toLowerCase().compareTo(b.name.toLowerCase());
      });
      return List.unmodifiable(list);
    },
    orElse: () => const <Tag>[],
  );
});
