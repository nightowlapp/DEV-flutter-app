import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nightowlcode/shared/constants/colors.dart';
import 'package:nightowlcode/shared/constants/icons.dart';
import 'package:nightowlcode/shared/constants/styles.dart';
import 'package:nightowlcode/shared/constants/values.dart';
import 'package:nightowlcode/shared/reusable/ui/owl_snack.dart';

import '../filters/filter_controller.dart';
import 'nearby_venue_count_provider.dart';
import 'search_controller.dart';
import 'search_match_provider.dart';

class VenueSearchBar extends ConsumerStatefulWidget {
  // TODO later: dynamic suggestions like "Try: club 21+ 4*+"
  const VenueSearchBar({
    super.key,
    required this.controller,
    this.hint = 'Search name, tag, city, type, age, rating or other...',
    this.onTapTune,
  });

  final TextEditingController controller;
  final String hint;
  final VoidCallback? onTapTune;

  @override
  ConsumerState<VenueSearchBar> createState() => _VenueSearchBarState();
}

class _VenueSearchBarState extends ConsumerState<VenueSearchBar> {
  final _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    _focus.addListener(() => setState(() {}
      ));
    widget.controller.addListener(_handleTextChanged);
  }

  @override
  void dispose() {
    _focus.dispose();
    widget.controller.removeListener(_handleTextChanged);
    super.dispose();
  }

  void _handleTextChanged() {
    final text = widget.controller.text;
    // Push text into global search query provider
    ref.read(searchQueryProvider.notifier).state = text;
    setState(() {}
    ); // rebuild to switch nearby ↔ matches label
  }

  @override
  Widget build(BuildContext context) {
    final nearbyCount = ref.watch(nearbyVenueCountProvider);
    final matchCount = ref.watch(searchMatchCountProvider);
    final filterMatchCount = ref.watch(filterMatchCountProvider);
    final hasText = widget.controller.text.trim().isNotEmpty;
    final filtersActive = ref.watch(filtersActiveProvider);

    return Padding(
      padding: const EdgeInsets.only(
        top: horizontalSpacerDefault,
        right: horizontalSpacerDefault,
        left: horizontalSpacerDefault,
      ),
      child: TextField(
        focusNode: _focus,
        controller: widget.controller,
        style: const TextStyle(color: white),
        onChanged: (value) {
          // keep provider in sync even if controller is replaced
          ref.read(searchQueryProvider.notifier).state = value;
        },
        decoration: InputDecoration(
          hintText: widget.hint,
          hintStyle: Styles.greyedOutPopupText,
          isDense: true,
          filled: true,
          fillColor: owlPurple.withOpacity(0.03),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(borderRadiusDefault),
            borderSide: const BorderSide(color: grey, width: 0.7),
          ),
          prefixIcon: Icon(exploreIcon, color: white),
          suffixIconConstraints:
          const BoxConstraints(minWidth: 0, minHeight: 0),
          suffixIcon: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                switchInCurve: Curves.easeOut,
                switchOutCurve: Curves.easeIn,
                child: hasText
                  // ── SEARCH TEXT → show search matches ───────────────
                  ? Padding(
                    key: const ValueKey('matches'),
                    padding: const EdgeInsets.only(right: 0),
                    child: _CountText(
                      count: matchCount ?? 0,
                      label: ' matches',
                      semanticsLabelWhenUnknown: 'Search matches',
                    ),
                  )
                  // ── NO TEXT, FILTERS ACTIVE → show filter matches ───
                  : filtersActive
                    ? Padding(
                      key: const ValueKey('filterMatches'),
                      padding: const EdgeInsets.only(right: 0),
                      child: _CountText(
                        count: filterMatchCount ?? 0,
                        label: ' matches', // same style as search
                        semanticsLabelWhenUnknown: 'Filtered venues',
                      ),
                    )
                    // ── NO TEXT, NO FILTERS → show nearby count ─────
                    : Padding(
                      key: const ValueKey('nearby'),
                      padding: const EdgeInsets.only(right: 0),
                      child: _CountText(
                        count: nearbyCount,
                        label: ' nearby',
                        semanticsLabelWhenUnknown: 'Nearby venues',
                      ),
                    ),
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(horizontal: 0),
                constraints: const BoxConstraints(),
                icon: Icon(
                  tuneIcon,
                  color: filtersActive ? owlPurple : white,
                ),
                onPressed: () {
                  // clear search text
                  widget.controller.clear();
                  // (listener on controller will update searchQueryProvider)
                  // open filters popup
                  widget.onTapTune?.call();
                },
                onLongPress: () {
                  // long press → reset all filters back to defaults
                  ref.read(filtersProvider.notifier).reset();
                  if (filtersActive) {
                    OwlSnack.show(
                      context,
                      title: 'Filters reset',
                      variant: OwlSnackVariant.info, // or success/neutral
                      duration: const Duration(milliseconds: 1400),
                      showDivider: false,
                    );
                  }
                },
                tooltip: 'Filters',
              ),

            ],
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 0),
        ),
      ),
    );
  }
}

class _CountText extends StatelessWidget {
  const _CountText({
    required this.count,
    required this.label,
    required this.semanticsLabelWhenUnknown,
  });

  final int? count;
  final String label;
  final String semanticsLabelWhenUnknown;

  @override
  Widget build(BuildContext context) {
    Widget child;

    if (count == null) {
      // Invisible but still keeps semantics if you want SRs to read something
      child = Semantics(
        key: const ValueKey('count_empty'),
        label: semanticsLabelWhenUnknown,
        child: const SizedBox.shrink(),
      );
    } else {
      final isMatchesLabel =
          label.trim() == 'matches' || label.contains('matches');
      final plural = isMatchesLabel
          ? (count == 1 ? ' match' : ' matches')
          : label;
      final numColor = (count == 0) ? red : owlPurple;

      child = Semantics(
        key: ValueKey('count_${label}_$count'),
        label: '$count$plural',
        child: Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: '$count',
                style: TextStyle(
                  color: numColor,
                  fontWeight: FontWeight.w700,
                  fontSize: fontSizeSmall,
                ),
              ),
              TextSpan(
                text: plural,
                style: Styles.basicText,
              ),
            ],
          ),
        ),
      );
    }

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      switchInCurve: Curves.easeOut,
      switchOutCurve: Curves.easeIn,
      child: child,
    );
  }
}
