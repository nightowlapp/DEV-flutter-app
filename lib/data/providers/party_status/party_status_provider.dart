import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nightowlcode/shared/constants/enums.dart';
import 'package:nightowlcode/shared/constants/colors.dart';
import '../../../core/storage/app_storage.dart';
import '../../other_providers.dart';
import '../../../shared/party_status_store.dart';
import '../../repositories/users/party_status_repository.dart';

// DI (unchanged)
final partyStatusRepositoryProvider = Provider<PartyStatusRepository>((ref) {
    final db = ref.watch(firestoreProvider);
    final auth = ref.watch(firebaseAuthProvider);
    return PartyStatusRepository(db, auth);
  }
);

final partyStatusStoreProvider = Provider<PartyStatusStore>((ref) {
    final prefs = ref.watch(sharedPrefsProvider);
    final local = SharedPrefsPartyStatusStore(prefs);
    final repo = ref.watch(partyStatusRepositoryProvider);
    return FirestorePartyStatusStore(repo, local);
  }
);

// ➊ Current status in memory (source of truth for UI)
final partyStatusStateProvider = StateProvider<PartyStatusTypes>(
  (ref) => PartyStatusTypes.still_planning,
);

// ➋ Color derived from the in-memory status (sync)
final partyStatusColorForProvider = Provider.family<Color, PartyStatusTypes>((ref, s) {
    switch (s) {
      case PartyStatusTypes.out_tonight: return purple;
      case PartyStatusTypes.house_party: return blue;
      case PartyStatusTypes.pregame:     return orange;
      case PartyStatusTypes.recovering:  return red;
      case PartyStatusTypes.still_planning:
      default:                           return greyLighter;
    }
  }
);

// ➌ One-time bootstrap to seed in-memory state from local store on app start
final partyStatusBootstrapProvider = FutureProvider<void>((ref) async {
    final store = ref.watch(partyStatusStoreProvider);
    final saved = await store.loadStatus();
    ref.read(partyStatusStateProvider.notifier).state = saved!;
  }
);

final partyStatusAutoResetProvider = Provider<void>((ref) {
    Timer? t;

    DateTime _next8am(DateTime now) {
      final today8 = DateTime(now.year, now.month, now.day, 8);
      return now.isBefore(today8) ? today8 : today8.add(const Duration(days: 1));
    }


    // Declare a function variable first so _fire() can use it
    late void Function() schedule;

    Future<void> _fire() async {
      // 1) update in-memory immediately
      ref.read(partyStatusStateProvider.notifier).state =
      PartyStatusTypes.still_planning;

      // 2) persist locally + cloud with automatic change
      final store = ref.read(partyStatusStoreProvider);
      await store.saveStatus(
        PartyStatusTypes.still_planning,
        change: PartyStatusChange.automatic,
        writeToCloud: false,
      );

      // 3) re-arm for the next day
      schedule();
    }

    // Assign the function AFTER _fire is defined
    schedule = () {
      final now = DateTime.now();
      final next = _next8am(now);
      t?.cancel();
      t = Timer(next.difference(now), _fire);
    };

    // First arm
    schedule();

    // Re-evaluate on app resume (DST/timezone/clock changes)
    final listener = AppLifecycleListener(
      onStateChange: (state) async {
        if (state == AppLifecycleState.resumed) {
          final store = ref.read(partyStatusStoreProvider);
          final current =
            await store.loadStatus() ?? PartyStatusTypes.still_planning;
          ref.read(partyStatusStateProvider.notifier).state = current;
          schedule(); // re-arm for new local 08:00 if needed
        }
      },
    );

    ref.onDispose(() {
        t?.cancel();
        listener.dispose();
      }
    );
  }
);

final partyStatusNeedsAnswerProvider = Provider<bool>((ref) {
    // Re-evaluate when the status changes anywhere in-app:
    ref.watch(partyStatusStateProvider);

    final prefs = ref.watch(sharedPrefsProvider);
    final answeredDay = prefs.getString(kPartyStatusAnsweredDayKey);
    final currentDay = partyStatusDayKey(DateTime.now());

    //TODO.
    // final answeredDay = ref.watch(partyStatusAnsweredDayProvider);
    // final currentDay = partyStatusDayKey(DateTime.now());
    // return answeredDay != currentDay;


  // Not answered if answeredDay != today’s day-key
    return answeredDay != currentDay;
  }
);

final partyStatusAnsweredDayProvider = StateProvider<String?>((ref) {
  final prefs = ref.watch(sharedPrefsProvider);
  return prefs.getString(kPartyStatusAnsweredDayKey);
});

final partyStatusColorProvider = Provider<Color>((ref) {
    final s = ref.watch(partyStatusStateProvider);
    return ref.watch(partyStatusColorForProvider(s));
  }
);

// Palette to pulse through when the user hasn’t answered “today”.
// (Interleave a neutral to make the pulse gentler.)
final partyStatusPulsePaletteProvider = Provider<List<Color>>((ref) {
    final c = (PartyStatusTypes s) => ref.read(partyStatusColorForProvider(s));
    return <Color>[
      c(PartyStatusTypes.out_tonight),
      c(PartyStatusTypes.house_party),
      c(PartyStatusTypes.pregame),
      c(PartyStatusTypes.still_planning),
    ];
  }
);
