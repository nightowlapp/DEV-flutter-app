import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

import '../../data/other_providers.dart';
import '../../models/venues/tag.dart';

final venueTagsProvider = FutureProvider.family<List<Tag>, List<String>>((ref, tagIds) async {
  final box = await Hive.openBox('tags_cache');
  final cached = box.get('tags_${tagIds.join('_')}') as List<dynamic>?;
  if (cached != null) return cached.cast<Tag>();
  final tags = await ref.watch(tagRepositoryProvider).getByIds(tagIds);
  await box.put('tags_${tagIds.join('_')}', tags);
  return tags;
});