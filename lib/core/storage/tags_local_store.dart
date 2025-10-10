import 'dart:convert';
import 'package:hive/hive.dart';
import '../../models/venues/tag.dart';

class TagsLocalStore {
  static const _boxName = 'tags_all_json';
  static const _key = 'tags';

  Future<List<Tag>> readAll() async {
    final box = await Hive.openBox<String>(_boxName);
    final jsonStr = box.get(_key);
    if (jsonStr == null) return const <Tag>[];
    final list = (jsonDecode(jsonStr) as List).cast<Map<String, dynamic>>();
    return [
      for (final m in list)
        Tag.fromJson(m['data'] as Map<String, dynamic>, m['id'] as String),
    ];
  }

  Future<void> writeAll(List<Tag> tags) async {
    final box = await Hive.openBox<String>(_boxName);
    final payload = [
      for (final t in tags) {'id': t.id, 'data': t.toJson()}
    ];
    await box.put(_key, jsonEncode(payload));
  }
}
