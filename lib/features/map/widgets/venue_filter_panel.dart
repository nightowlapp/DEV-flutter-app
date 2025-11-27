import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:nightowlcode/models/venues/venue.dart';
import 'package:nightowlcode/shared/constants/icons.dart';
import 'package:nightowlcode/shared/constants/values.dart';
import 'package:nightowlcode/shared/constants/colors.dart';
import 'package:nightowlcode/shared/reusable/ui/owl_scrollbar.dart';
import 'package:nightowlcode/shared/utility/distance.dart';
import 'package:nightowlcode/shared/utility/lat_lng.dart';
import 'package:nightowlcode/shared/utility/utility.dart';

import '../../../shared/constants/enums.dart';
import '../../../shared/constants/styles.dart';
import '../../../shared/reusable/ui/venue_logo.dart';

class VenueFilterPanel extends StatefulWidget {
  const VenueFilterPanel({
    required this.selected,
    required this.allTypes,
    required this.counts,
    required this.venuesByType,
    required this.userLocation,
    required this.onSelectionChanged,
    required this.onVenueTap,
    required this.favoriteVenueIds,
    required this.showOnlyOpen,
    required this.onShowOnlyOpenChanged,
    required this.favoritesOnly,
    required this.onFavoritesOnlyChanged,
  });
  final Set<VenueType> selected;
  final List<VenueType> allTypes;
  final Map<VenueType, int> counts;
  final Map<VenueType, List<Venue>> venuesByType;
  final LatLng? userLocation;
  final Set<String> favoriteVenueIds;
  final bool favoritesOnly;
  final ValueChanged<bool> onFavoritesOnlyChanged;
  final bool showOnlyOpen;
  final ValueChanged<bool> onShowOnlyOpenChanged;
  final Future<void> Function(Set<VenueType>) onSelectionChanged;
  final Future<void> Function(Venue) onVenueTap;
  @override
  State<VenueFilterPanel> createState() => _VenueFilterPanelState();
}

class _VenueFilterPanelState extends State<VenueFilterPanel> {
  late Set<VenueType> _selected = Set<VenueType>.from(widget.selected);
  Set<VenueType>? _savedSelectionBeforeFavorites;
  bool? _savedShowOnlyOpenBeforeFavorites;
  String _labelFor(VenueType t) {
    final name = t.name.replaceAll('_', ' ');
    if (name.isEmpty) return '';
    return name[0].toUpperCase() + name.substring(1);
  }

  Future<void> _updateSelection(void Function() mutate) async {
    setState(mutate);
    await widget.onSelectionChanged(Set<VenueType>.from(_selected));
  }

  /// How many venues are currently actually visible on the map,
  /// given the selected types + "Open now" toggle.
  int _visibleOnMapCount() {
    int total = 0;
    widget.venuesByType.forEach((type, venues) {
      for (final v in venues) {
        final isFavorite = widget.favoriteVenueIds.contains(v.id);
        // Open-now filter
        if (widget.showOnlyOpen && !_isVenueOpenNow(v)) continue;
        // Favorites-only filter
        if (widget.favoritesOnly && !isFavorite) continue;
        // Type filter based on local selection
        if (_selected.isEmpty) {
          // No types selected:
          // - if not favorites-only → nothing on map
          if (!widget.favoritesOnly) continue;
          // - if favorites-only → allow favorites of ANY type
        } else {
          if (!_selected.contains(type)) continue;
        }
        total++;
      }
    });
    return total;
  }



  Future<void> _resetFilters() async {
    // 1) Reset types to "all on"
    await _updateSelection(() {
      _selected
        ..clear()
        ..addAll(widget.allTypes);
    });
    // 2) Reset "Open now" to off (show open + closed)
    if (widget.showOnlyOpen) {
      widget.onShowOnlyOpenChanged(false);
    }
    // 3) Reset "Favorites only" to off
    if (widget.favoritesOnly) {
      widget.onFavoritesOnlyChanged(false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final panelHeight = screenHeight * 0.7;
    final double outerRadius = borderRadiusDefault * 1.6;
    // Build an "effective" per-type map that already respects the
    // "Open now" toggle. When showOnlyOpen == true, we drop closed venues.
    final Map<VenueType, List<Venue>> effectiveByType = {
      for (final t in widget.allTypes) t: <Venue>[],
    };
    widget.venuesByType.forEach((type, venues) {
      final list = widget.showOnlyOpen
          ? venues.where(_isVenueOpenNow).toList()
          : List<Venue>.from(venues);
      effectiveByType[type] = list;
    });
    // Counts based on the effective list (so they also respect "Open now")
    final Map<VenueType, int> effectiveCounts = {
      for (final t in widget.allTypes) t: effectiveByType[t]?.length ?? 0,
    };
    // Total venues across all types, respecting "Open now"
    final totalCount =
    effectiveCounts.values.fold<int>(0, (prev, v) => prev + v);
    // True when ALL types are currently enabled
    final allOn = _selected.length == widget.allTypes.length;
    // All venues aggregated (for the "All" expandable row),
    // already filtered by open/closed depending on showOnlyOpen.
    final List<Venue> allVenues =
    effectiveByType.values.expand((v) => v).toList();
    // Only show types that actually have (effective) venues,
    // sorted by amount desc
    final visibleTypes = widget.allTypes
        .where((t) => (effectiveCounts[t] ?? 0) > 0)
        .toList()
      ..sort((a, b) {
        final ca = effectiveCounts[a] ?? 0;
        final cb = effectiveCounts[b] ?? 0;
        if (cb != ca) return cb.compareTo(ca); // most → first
        return _labelFor(a).compareTo(_labelFor(b));
      });
    final visibleOnMap = _visibleOnMapCount();
    // ===== FAVORITES CATEGORY (new) =========================================
    // All favorites from all types. We respect "Open now" for the list,
    // but type filters only affect whether they're active/visible on map.
    final List<Venue> favoriteVenues = widget.venuesByType.values
        .expand((v) => v)
        .where((v) => widget.favoriteVenueIds.contains(v.id))
        .toList();
    if (widget.showOnlyOpen) {
      favoriteVenues.removeWhere((v) => !_isVenueOpenNow(v));
    }
    final bool hasFavorites = favoriteVenues.isNotEmpty;
    // Header rows: "All" + optional "Favorites"
    final int headerRows = hasFavorites ? 2 : 1;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Material(
        color: black,
        elevation: 8,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(outerRadius),
          side: const BorderSide(color: grey, width: 1),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(outerRadius),
          child: SizedBox(
            height: panelHeight,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ===== HEADER (matches _FiltersCard) =======================
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    horizontalSpacerDefault,
                    horizontalSpacerDefault,
                    horizontalSpacerDefault,
                    horizontalSpacerSmall,
                  ),
                  child: Row(
                    children: [
                      Text('Filters', style: Styles.popupHeader),
                      const Spacer(),
                      Text('Open now', style: Styles.smallText),
                      const SizedBox(width: 6),
                      Switch.adaptive(
                        value: widget.showOnlyOpen,
                        onChanged: widget.onShowOnlyOpenChanged,
                        activeColor: owlPurple, //TODO make circle more grey not whit.
                        trackOutlineColor: WidgetStatePropertyAll(
                          grey.withOpacity(.5),
                        ),
                        inactiveThumbColor: grey,
                        inactiveTrackColor: grey.withOpacity(.35),
                      ),
                    ],
                  ),
                ),
                // ===== TOP CENTER INFO (your updated version) ===============
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  switchInCurve: Curves.easeOut,
                  switchOutCurve: Curves.easeIn,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(6, 0, 6, 0),
                    child: Row(
                      key: ValueKey<int>(visibleOnMap),
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Row( // Todo add when possible to change in settings.
                          children: [
                            // Text(
                            // 'Pro Tip: ',
                            // style: Styles.smallText.copyWith(color: owlPurple),
                            // ),
                            // Text(
                            // 'You can change your default filters in settings',
                            // style: Styles.smallText,
                            // ),
                          ],
                        ),
                        Row(
                          children: [
                            Text(
                              '$visibleOnMap ',
                              style: Styles.smallText.copyWith(
                                color: owlPurple,
                              ),
                            ),
                            Text(
                              'on map',
                              style: Styles.smallText,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                const Divider(color: grey),
                // ===== BODY: scrollable type list ==========================
                Expanded(
                  child: OwlScrollbar(
                    child: totalCount == 0
                        ? Center( //TODO Make sadfaceOwl to show when errors/isempty
                      child: Text(
                        'No venues match your filters',
                        style: Styles.smallText.copyWith(color: grey),
                      ),
                    )
                        : ListView.separated(
                      padding: const EdgeInsets.symmetric(
                        horizontal: horizontalSpacerDefault,
                        vertical: verticalSpacerDefault,
                      ),
                      itemCount: headerRows + visibleTypes.length,
                      separatorBuilder: (_, __) => Divider(
                        height: 1,
                        color: white.withOpacity(0.06),
                      ),
                      itemBuilder: (context, index) {
                        // Types start after all header rows:
                        // with favorites: 0=fav, 1=all, types from index 2
                        // without favorites: 0=all, types from index 1
                        final int typeOffset = headerRows;
                        final int allIndex = hasFavorites ? 1 : 0;
                        // 0: "Favorites" row (if any favorites exist)
                        if (hasFavorites && index == 0) {
                          return VenueFilterExpandableTile(
                            label: 'Favorites',
                            icon: filledStarIcon,
                            isOn: widget.favoritesOnly, // highlight when active
                            count: favoriteVenues.length,
                            venues: favoriteVenues,
                            userLocation: widget.userLocation,
                            favoriteVenueIds: widget.favoriteVenueIds,
                            showSwitch: true,
                            // A venue is "active" if it would be visible on map
                            isVenueActive: (venue) {
                              final type = venue.type;
                              final isFavorite = widget.favoriteVenueIds.contains(venue.id);
                              // Respect "Open now"
                              if (widget.showOnlyOpen && !_isVenueOpenNow(venue)) {
                                return false;
                              }
                              // Respect "Favorites only"
                              if (widget.favoritesOnly && !isFavorite) {
                                return false;
                              }
                              // Type filter (local selection in panel)
                              if (_selected.isEmpty) {
                                // No types selected:
                                // - if not favorites-only → nothing on map
                                if (!widget.favoritesOnly) return false;
                                // - if favorites-only → allow favorites of ANY type
                              } else {
                                if (type == null || !_selected.contains(type)) {
                                  return false;
                                }
                              }
                              return true;
                            },
                            // When favorites are toggled ON:
                            // - clear all type selections (so "All" is OFF)
                            // - turn "Open now" OFF
                            // Then propagate to parent.
                            onToggleChanged: (value) async {
                              final bool wasOn = widget.favoritesOnly;
                              // ── Turning Favorites ON ─────────────────────────────────────────
                              if (!wasOn && value) {
                                // Snapshot current filters
                                _savedSelectionBeforeFavorites =
                                Set<VenueType>.from(_selected);
                                _savedShowOnlyOpenBeforeFavorites = widget.showOnlyOpen;
                                // 1) Turn OFF all types (All off)
                                await _updateSelection(() {
                                  _selected.clear();
                                });
                                // 2) Turn OFF "Open now"
                                if (widget.showOnlyOpen) {
                                  widget.onShowOnlyOpenChanged(false);
                                }
                                // 3) Enable favorites-only mode
                                widget.onFavoritesOnlyChanged(true);
                                return;
                              }
                              // ── Turning Favorites OFF ────────────────────────────────────────
                              if (wasOn && !value) {
                                // Restore previous type selection (or fallback to "all on")
                                final prevSelection =
                                    _savedSelectionBeforeFavorites ??
                                        Set<VenueType>.from(widget.allTypes);
                                await _updateSelection(() {
                                  _selected
                                    ..clear()
                                    ..addAll(prevSelection);
                                });
                                // Restore previous "Open now" state if we had one
                                final prevShowOnlyOpen = _savedShowOnlyOpenBeforeFavorites;
                                if (prevShowOnlyOpen != null &&
                                    prevShowOnlyOpen != widget.showOnlyOpen) {
                                  widget.onShowOnlyOpenChanged(prevShowOnlyOpen);
                                }
                                // Clear snapshot
                                _savedSelectionBeforeFavorites = null;
                                _savedShowOnlyOpenBeforeFavorites = null;
                                // Disable favorites-only mode
                                widget.onFavoritesOnlyChanged(false);
                              }
                            },
                            onVenueTap: widget.onVenueTap,
                          );
                        }

                        // if (hasFriends && index == 1) { //TODO soon toggle friends on map and go to their logacion on press.
                        //   return VenueFilterExpandableTile(
                        //     label: 'Friends',
                        //     icon: Icons.all_inclusive_outlined,
                        //     isOn: allOn,
                        //     count: totalCount,
                        //     venues: allVenues,
                        //     userLocation: widget.userLocation,
                        //     favoriteVenueIds: widget.favoriteVenueIds,
                        //     showSwitch: true,
                        //     // active per venue if its type is selected
                        //     isVenueActive: (venue) {
                        //       final type = venue.type;
                        //       if (type == null) return false;
                        //       if (!_selected.contains(type)) return false;
                        //       if (widget.showOnlyOpen && !_isVenueOpenNow(venue)) return false;
                        //       return true;
                        //     },
                        //     onToggleChanged: (value) {
                        //       _updateSelection(() {
                        //         if (value) {
                        //           _selected
                        //             ..clear()
                        //             ..addAll(widget.allTypes);
                        //         } else {
                        //           _selected.clear();
                        //         }
                        //       });
                        //     },
                        //     onVenueTap: widget.onVenueTap,
                        //   );
                        // }


                        // "All" row (index 1 when we have favorites, otherwise 0)
                        if (index == allIndex) {
                          return VenueFilterExpandableTile(
                            label: 'All',
                            icon: Icons.all_inclusive_outlined,
                            isOn: allOn,
                            count: totalCount,
                            venues: allVenues,
                            userLocation: widget.userLocation,
                            favoriteVenueIds: widget.favoriteVenueIds,
                            showSwitch: true,
                            // active per venue if its type is selected
                            isVenueActive: (venue) {
                              final type = venue.type;
                              if (type == null) return false;
                              if (!_selected.contains(type)) return false;
                              if (widget.showOnlyOpen && !_isVenueOpenNow(venue)) return false;
                              return true;
                            },
                            onToggleChanged: (value) {
                              _updateSelection(() {
                                if (value) {
                                  _selected
                                    ..clear()
                                    ..addAll(widget.allTypes);
                                } else {
                                  _selected.clear();
                                }
                              });
                            },
                            onVenueTap: widget.onVenueTap,
                          );
                        }
                        // Other rows = each type
                        final t = visibleTypes[index - typeOffset];
                        final isOn = _selected.contains(t);
                        final count = effectiveCounts[t] ?? 0;
                        final venues = effectiveByType[t] ?? const <Venue>[];
                        return VenueFilterExpandableTile(
                          label: _labelFor(t) == 'Unknown' ? 'Other' : _labelFor(t),
                          icon: t.icon,
                          isOn: isOn,
                          count: count,
                          venues: venues,
                          userLocation: widget.userLocation,
                          favoriteVenueIds: widget.favoriteVenueIds,
                          showSwitch: true,
                          onToggleChanged: (value) {
                            _updateSelection(() {
                              if (value) {
                                _selected.add(t);
                              } else {
                                _selected.remove(t);
                              }
                            });
                          },
                          onVenueTap: widget.onVenueTap,
                        );
                      },
                    ),
                  ),
                ),
                const Divider(color: grey),
                // ===== FOOTER: Reset Filters (both sides) =================
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    horizontalSpacerDefault,
                    horizontalSpacerSmall,
                    horizontalSpacerDefault,
                    horizontalSpacerSmall,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton(
                        onPressed: () {
                          _resetFilters();
                        },
                        child: Text(
                          'Reset Filters',
                          style: Styles.smallText.copyWith(color: red),
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          _resetFilters();
                        },
                        child: Text(
                          'Reset Filters',
                          style: Styles.smallText.copyWith(color: red),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class VenueFilterExpandableTile extends StatefulWidget {
  const VenueFilterExpandableTile({
    required this.label,
    required this.icon,
    required this.isOn,
    required this.count,
    required this.venues,
    required this.userLocation,
    required this.onToggleChanged,
    required this.onVenueTap,
    required this.favoriteVenueIds,
    this.isVenueActive,
    this.showSwitch = true,
  });
  final String label;
  final IconData icon;
  final bool isOn;
  final int count;
  final List<Venue> venues;
  final LatLng? userLocation;
  final ValueChanged<bool> onToggleChanged;
  final Future<void> Function(Venue) onVenueTap;
  final Set<String> favoriteVenueIds;
  /// Optional per-venue active check (used by "All" and "Favorites" rows).
  /// If null, `isOn` is used for all venues in this tile.
  final bool Function(Venue v)? isVenueActive;
  /// Whether to show the filter switch in the header.
  /// For "Favorites" we hide it.
  final bool showSwitch;
  @override
  State<VenueFilterExpandableTile> createState() =>
      _VenueFilterExpandableTileState();
}

class _VenueFilterExpandableTileState extends State<VenueFilterExpandableTile> {
  bool _expanded = false;
  // Pagination: how many venues we currently show in this tile.
  static const int _pageSize = 48;
  int _visibleCount = _pageSize;
  // Scroll controller for the inner dropdown list
  late final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _toggleExpanded() {
    setState(() {
      _expanded = !_expanded;
      if (_expanded) {
        // Reset page + scroll back to top when opening
        _visibleCount = _pageSize;
        if (_scrollController.hasClients) {
          _scrollController.jumpTo(0);
        }
      }
    });
  }

  // Auto "show more" when scrolled to the bottom
  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final pos = _scrollController.position;
    // Small tolerance so it still triggers if you're *almost* at the bottom
    const double tolerance = 16.0;
    if (pos.pixels >= pos.maxScrollExtent - tolerance) {
      _maybeLoadMore();
    }
  }

  void _maybeLoadMore() {
    final total = widget.venues.length;
    if (_visibleCount >= total) return; // nothing more to load
    setState(() {
      _visibleCount = math.min(_visibleCount + _pageSize, total);
    });
  }

  /// Sort:
  /// 1) Favorites first (even if they are further away)
  /// 2) Within favorites / non-favorites, sort by distance (if userLocation is known)
  List<Venue> _sortedVenues() {
    final list = List<Venue>.from(widget.venues);
    final user = widget.userLocation;
    int favRank(Venue v) => widget.favoriteVenueIds.contains(v.id) ? 0 : 1;
    list.sort((a, b) {
      final fa = favRank(a);
      final fb = favRank(b);
      if (fa != fb) {
        return fa.compareTo(fb); // favorites (0) before non-favorites (1)
      }
      if (user == null) {
        // No distance info – keep original relative order between same favness
        return 0;
      }
      final da = Distance.metersLatLng(user, a.entry);
      final db = Distance.metersLatLng(user, b.entry);
      return da.compareTo(db);
    });
    return list;
  }

  String _fmtMeters(double meters) {
    final m = meters.round();
    // Under 1 km → show meters
    if (m < 1000) return '$m m';
    final km = meters / 1000.0;
    // Over 99 km → cap label
    if (km > 99) return '99+ km';
    // Otherwise: 0–9.9 → 1 decimal, 10–99 → no decimals
    return '${km.toStringAsFixed(km >= 10 ? 0 : 1)} km';
  }

  @override
  Widget build(BuildContext context) {
    final venues = _sortedVenues();
    final bool headerActive = widget.isOn;
    // Clamp visible count so we never go out of range.
    final int visible = math.min(_visibleCount, venues.length);
    final List<Venue> visibleVenues = venues.take(visible).toList();
    final int remaining = venues.length - visible; // still used for sizing
    final TextStyle headerLabelStyle = widget.icon == filledStarIcon ? Styles.basicText : headerActive
        ? Styles.basicText
        : Styles.basicText.copyWith(color: greyLighter);
    return Column(
      children: [
        // ===== HEADER ROW (ENTIRE ROW CLICKABLE) =======================
        InkWell(
          borderRadius: BorderRadius.circular(borderRadiusSmall),
          onTap: _toggleExpanded,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              children: [
                // Icon circle
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: widget.icon == filledStarIcon ? owlPurple.withOpacity(0.18): headerActive
                        ? owlPurple.withOpacity(0.18)
                        : white.withOpacity(0.04),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    widget.icon,
                    color: widget.icon == filledStarIcon ? owlPurple : headerActive ? owlPurple : greyLighter,
                    size: iconSizeSmall,
                  ),
                ),
                const SizedBox(width: 12),
                // Label
                Expanded(
                  child: Text(
                    widget.label,
                    style: headerLabelStyle,
                  ),
                ),
                // Count
                if (widget.count > 0) ...[
                  const SizedBox(width: 8),
                  Text(
                    '(${widget.count})',
                    style: Styles.smallText.copyWith(color: greyLighter),
                  ),
                ],
                const SizedBox(width: 8),
                if (widget.showSwitch) ...[
                  Switch.adaptive(
                    value: widget.isOn,
                    onChanged: widget.onToggleChanged,
                    activeColor: owlPurple,
                    activeTrackColor: owlPurple.withOpacity(0.4),
                    inactiveThumbColor: grey,
                    inactiveTrackColor: white.withOpacity(0.12),
                  ),
                  const SizedBox(width: 4),
                ],
                // Chevron (purely visual now – row InkWell handles tap)
                AnimatedRotation(
                  turns: _expanded ? 0.5 : 0.0,
                  duration: const Duration(milliseconds: 250),
                  child: Icon(
                    chevronUpIcon,
                    color: white,
                    size: iconSizeDefault,
                  ),
                ),
              ],
            ),
          ),
        ),
        // ===== EXPANDED CONTENT ========================================
        if (_expanded && venues.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 0),
            child: LayoutBuilder(
              builder: (context, constraints) {
                // Max height for the inner scroll area
                const double maxInnerHeight = 260.0;
                // Estimate a row height so the list doesn't get taller than needed
                const double rowHeight = 52.0;
                final int visible = visibleVenues.length;
                // We still use `remaining` only to approximate needed height,
                final double neededHeight =
                    visible * rowHeight + (remaining > 0 ? 8.0 : 0.0);
                final double height = math.min(
                  maxInnerHeight,
                  neededHeight,
                );
                return SizedBox(
                  height: height,
                  child: OwlScrollbar(
                    thickness: 1,
                    child: ListView.builder(
                      controller: _scrollController,
                      padding:
                      const EdgeInsets.only(right: 3), // space for scrollbar
                      itemCount: visibleVenues.length,
                      itemBuilder: (context, index) {
                        final v = visibleVenues[index];
                        return _buildVenueRow(context, v);
                      },
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildVenueRow(BuildContext context, Venue v) {
    final user = widget.userLocation;
    final now = DateTime.now();
    final rawName =
    v.displayName.isNotEmpty ? v.displayName : v.name;
    // Active under current filters? (used by "All" & "Favorites" tile)
    final bool venueActive =
        widget.isVenueActive?.call(v) ?? widget.isOn;
    // Is this venue one of my favorites?
    final bool isFavorite = widget.favoriteVenueIds.contains(v.id);
    // === NAME STYLE + STAR PREFIX =====================================
    TextStyle nameStyle;
    if (!venueActive) {
      // Dim everything that’s filtered out, even favorites
      nameStyle = Styles.basicText.copyWith(color: greyLighter);
    } else if (isFavorite) {
      // Highlight favorites in owlPurple
      nameStyle = Styles.basicText.copyWith(color: owlPurple);
    } else {
      nameStyle = Styles.basicText;
    }
    // Text-only star prefix for favorites
    final String name = isFavorite ? '★ $rawName' : rawName;
    final TextStyle walkStyle = Styles.smallText.copyWith(
      color: white, // walk text is white
      fontSize: fontSizeSmaller,
    );
    // Walking distance text like "🚶 5 min"
    final String walk = Distance.walkText(user, v);
    final String dist = Distance.normalDistanceText(user, v);
    final String? walkLabel =
    walk.isEmpty && dist.isEmpty ? null : '$walk - $dist';
    // Opening-hours display info (range + +1 flag)
    final OpeningDisplayRow opening =
    openingDisplayForVenue(v, now);
    // Age restriction, e.g. "21+"
    final String? ageLabel =
    ageRestrictionLabelFor(v, now);
    // Right side top: only the time range, or nothing.
    Widget openingTop;
    if (opening.showRange) {
      // Show "HH:mm - HH:mm" with "+1" as superscript when nextDay = true.
      // Always white text.
      final baseStyle = Styles.smallText.copyWith(
        color: white,
        fontSize: fontSizeSmaller,
      );
      final supStyle = Styles.smallText.copyWith(
        fontSize: 6,
      );
      openingTop = Align(
        alignment: Alignment.centerRight,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Text(
              '${opening.open} - ${opening.close}',
              style: baseStyle,
              overflow: TextOverflow.ellipsis,
            ),
            if (opening.nextDay)
              Positioned(
                right: -2,
                top: -5,
                child: Text(
                  '+1',
                  style: supStyle,
                ),
              ),
          ],
        ),
      );
    } else {
      // Closed today (or only opens tomorrow) → show nothing
      openingTop = const SizedBox.shrink();
    }
    return InkWell(
      onTap: () => widget.onVenueTap(v),
      borderRadius: BorderRadius.circular(borderRadiusSmall),
      child: Padding(
        // slightly larger vertically
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // ===== LEFT: logo ============================================
            VenueLogo(
              venue: v,
              size: iconSizeLarge + 4,
            ),
            const SizedBox(width: 8),
            // ===== CENTER: name (top) + walk text (bottom) ===============
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment:
                CrossAxisAlignment.start,
                children: [
                  // Name (one line, ellipsis)
                  Text(
                    name,
                    style: nameStyle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  // Walk text (white)
                  if (walkLabel != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        walkLabel,
                        style: walkStyle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // ===== RIGHT: opening hours (top) + age (bottom) =============
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Top: only "HH:mm - HH:mm (+1)" or nothing
                openingTop,
                const SizedBox(height: 4),
                // Bottom: age restriction e.g. "21+"
                if (ageLabel != null)
                  Text(
                    ageLabel,
                    style: Styles.smallText.copyWith(
                      color:
                      venueActive ? white : greyLighter,
                      fontSize: fontSizeSmaller,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Data needed to render the right-side opening-hours block.
class OpeningDisplayRow {
  final bool showRange; // true => show "HH:mm - HH:mm" (+1)
  final String open; // "HH:mm"
  final String close; // "HH:mm"
  final bool nextDay; // close is next day → show "+1"
  const OpeningDisplayRow({
    required this.showRange,
    required this.open,
    required this.close,
    required this.nextDay,
  });
}

/// Compute what to show on the right side: time range + "+1" flag.
///
/// Rules:
/// - If closed today → showRange = false (nothing rendered)
/// - If open now → show today's full hours
/// - If opens later today → show today's full hours
/// - No "open/close" words, only "HH:mm - HH:mm" (+1)
OpeningDisplayRow openingDisplayForVenue(Venue v, DateTime nowLocal) {
  final now = nowLocal.toLocal();
  // Structured status (open / opens later today / opens tomorrow / closed today)
  final status = v.openingHours.statusAt(now);
  // "Today" range (with overnight support + nextDay flag)
  // Uses your Venue extension from venue.dart
  final range = v.openingHoursToday(venueLocalNow: now);
  final bool hasRange = !range.isClosed;
  // Show times only when:
  // - currently open, OR
  // - it opens later today.
  //
  // If closed all day or only opens tomorrow → show nothing.
  final bool showRange =
      hasRange &&
          (status.phase == OpeningPhase.open ||
              status.phase == OpeningPhase.opensLaterToday);
  if (!showRange) {
    return const OpeningDisplayRow(
      showRange: false,
      open: '',
      close: '',
      nextDay: false,
    );
  }
  return OpeningDisplayRow(
    showRange: true,
    open: range.open,
    close: range.close,
    nextDay: range.nextDay,
  );
}

/// Age restriction label for *today/now*, e.g. "21+"
String? ageRestrictionLabelFor(Venue v, DateTime nowLocal) {
  final age = v.effectiveAgeRestriction(nowLocal.toLocal());
  if (age <= 0) return null;
  return '$age+';
}

/// Simple struct for an opening-hours label in the filter dropdown.
class _OpeningStatusInfo {
  final String text;
  final Color color;
  final bool shouldShow;
  _OpeningStatusInfo({
    required this.text,
    this.color = white,
    this.shouldShow = true,
  });
}

/// Compute a short opening-status label (open / opens soon / closes soon).
///
/// TODO: Wire this into your real opening-hours logic:
/// - is open now
/// - opens within 60 minutes
/// - closes within 60 minutes
_OpeningStatusInfo _openingStatusInfoFor(Venue v) {
  final now = DateTime.now(); // ideally venue-local
  final status = v.openingHours.statusAt(now);
  final label = status.label(localNow: now, soonThresholdMinutes: 60);
  // Only show something if:
  // - venue is open now
  // - OR opens soon
  // - OR closes soon
  final phase = status.phase;
  final bool isOpenNow = phase == OpeningPhase.open;
  // We can infer "soon" from the label we generated above:
  final bool isSoon =
      label.startsWith('Opens in') || label.startsWith('Closes in');
  final bool shouldShow = isOpenNow || isSoon;
  if (!shouldShow) {
    return _OpeningStatusInfo(
      text: '',
      color: grey,
    );
  }
  return _OpeningStatusInfo(
    text: label,
    color: label.startsWith('Closes in') ? orange : owlPurple,
    shouldShow: true,
  );
}

bool _isVenueOpenNow(Venue v) => v.isOpenNow(DateTime.now());