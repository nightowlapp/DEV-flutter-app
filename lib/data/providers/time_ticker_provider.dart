import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

final timeTickerProvider = StreamProvider<DateTime>((ref) {
  // tick immediately
  final controller = StreamController<DateTime>();

  void emitNow([Timer? _]) {
    if (!controller.isClosed) {
      controller.add(DateTime.now());
    }
  }

  // emit once now
  emitNow();

  // then every 60 seconds
  final timer = Timer.periodic(const Duration(seconds: 60), emitNow);

  ref.onDispose(() {
    timer.cancel();
    controller.close();
  });

  return controller.stream;
});
