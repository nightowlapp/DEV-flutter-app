// lib/features/explore/search/search_controller.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nightowlcode/features/explore/search/search_query.dart';

final searchQueryProvider =
AutoDisposeNotifierProvider<SearchController, SearchQuery>(SearchController.new);

class SearchController extends AutoDisposeNotifier<SearchQuery> {
  Timer? _debounce;
  TextEditingController? _attached;

  @override
  SearchQuery build() => const SearchQuery.empty();

  void attach(TextEditingController c, {Duration debounce = const Duration(milliseconds: 160)}) {
    if (_attached == c) return;
    _attached?.removeListener(_onText);
    _attached = c..addListener(_onText);
    state = SearchQuery.fromRaw(c.text);
    ref.onDispose(() {
      _debounce?.cancel();
      _attached?.removeListener(_onText);
    });
  }

  void _onText() {
    final text = _attached?.text ?? '';
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 160), () {
      state = SearchQuery.fromRaw(text);
    });
  }

  void clear() => state = const SearchQuery.empty();
}
