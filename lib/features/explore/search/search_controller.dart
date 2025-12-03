// lib/features/explore/search/search_controller.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nightowlcode/features/explore/search/search_query.dart';

/// Raw text typed in the Explore search bar (debounced via [SearchController]).
final searchQueryProvider = StateProvider.autoDispose<String>(
  (_) => '',
  name: 'searchQueryProvider',
);

/// Main search state: parsed [SearchQuery] (normalized, tokens, etc.).
final searchControllerProvider =
    AutoDisposeNotifierProvider<SearchController, SearchQuery>(
  SearchController.new,
);

class SearchController extends AutoDisposeNotifier<SearchQuery> {
  Timer? _debounce;
  TextEditingController? _attached;

  @override
  SearchQuery build() => const SearchQuery.empty();

  /// Attach to a TextEditingController so changes in the text field
  /// update this notifier (debounced).
  void attach(
    TextEditingController c, {
    Duration debounce = const Duration(milliseconds: 160),
  }) {
    if (_attached == c) return;
    _attached?.removeListener(_onText);
    _attached = c..addListener(_onText);

    final text = c.text;
    state = SearchQuery.fromRaw(text);
    ref.read(searchQueryProvider.notifier).state = text;

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
      ref.read(searchQueryProvider.notifier).state = text;
    });
  }

  void clear() {
    _debounce?.cancel();
    state = const SearchQuery.empty();
    ref.read(searchQueryProvider.notifier).state = '';
    _attached?.clear();
  }
}
