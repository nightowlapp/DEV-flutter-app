// lib/features/explore/presentation/search_wiring.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nightowlcode/features/explore/search/search_controller.dart';

void wireSearchController(WidgetRef ref, TextEditingController controller) {
  ref.read(searchQueryProvider.notifier).attach(controller);
}
