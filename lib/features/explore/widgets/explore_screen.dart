// lib/features/explore/presentation/explore_screen.dart
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nightowlcode/features/explore/widgets/venue_card.dart';
import 'package:nightowlcode/shared/constants/colors.dart';
import 'package:nightowlcode/shared/constants/values.dart';
import 'package:nightowlcode/shared/constants/icons.dart';
import 'package:nightowlcode/shared/reusable/ui/loading_indicator.dart';
import 'package:nightowlcode/shared/reusable/ui/loading_screen.dart';

import '../presentation/ranked_venues_provider.dart';

class ExploreScreen extends ConsumerStatefulWidget {
  const ExploreScreen({super.key});
  @override
  ConsumerState<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends ConsumerState<ExploreScreen> {
  final _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(() {
      final q = _searchCtrl.text.trim().toLowerCase();
      if (q != _query) setState(() => _query = q);
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(
                top: horizontalSpacerDefault,
                right: horizontalSpacerDefault,
                left: horizontalSpacerDefault,
                bottom: 0,
              ),
              child: TextField(
                controller: _searchCtrl,
                decoration: InputDecoration(
                  hintText: "Search Venues...",
                  prefixIcon: Icon(exploreIcon, color: white),
                  suffixIcon: Icon(tuneIcon, color: white),
                  filled: true,
                  fillColor: owlOrange.withOpacity(0.01),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(borderRadiusDefault),
                    borderSide: const BorderSide(color: grey, width: 0.7),
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 0),
                ),
                style: const TextStyle(color: white),
              ),
            ),
            const SizedBox(height: verticalSpacerSmall),

            Expanded(
              child: ref.watch(rankedVenuesLiveProvider).when(
                loading: () => const LoadingIndicator(),
                error: (e, _) =>
                    Center(child: Text('Error: $e', style: const TextStyle(color: red))),
                data: (result) {
                  final sorted  = result.venues;   // already ranked
                  final media   = result.media;
                  final userLoc = result.userLoc;

                  final list = _query.isEmpty
                      ? sorted
                      : sorted.where((v) {
                    final title = (v.displayName.isNotEmpty ? v.displayName : v.name).toLowerCase();
                    return title.contains(_query) ||
                        v.description.toLowerCase().contains(_query) ||
                        v.city.toLowerCase().contains(_query);
                  }).toList();

                  if (list.isEmpty) {
                    return const Center(child: Text('No venues found', style: TextStyle(color: red)));
                  }

                  int visibleCount = math.min(12, list.length);

                  return StatefulBuilder(builder: (context, setInner) {
                    return NotificationListener<ScrollNotification>(
                      onNotification: (n) {
                        if (n.metrics.pixels > n.metrics.maxScrollExtent - 200 &&
                            visibleCount < list.length) {
                          setInner(() {
                            visibleCount = math.min(list.length, visibleCount + 12);
                          });
                        }
                        return false;
                      },
                      child: GridView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: horizontalSpacerDefault),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: horizontalSpacerLarge,
                          childAspectRatio: 0.7,
                        ),
                        itemCount: visibleCount,
                        itemBuilder: (_, i) {
                          final v = list[i];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: VenueCard(
                              key: ValueKey(v.id), // stable key → smooth “jump”
                              venue: v,
                              userLocation: userLoc,
                              media: media[v.id],
                            ),
                          );
                        },
                      ),
                    );
                  });
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
