// lib/shared/utility/tag_actions.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:nightowlcode/data/repositories/users/feedback_repository.dart';
import 'package:nightowlcode/data/repositories/users/role_repository.dart';
import 'package:nightowlcode/data/services/tags/tags_sso.dart';
import 'package:nightowlcode/data/services/tags/tag_helpers.dart';

import 'package:nightowlcode/models/venues/tag.dart';
import 'package:nightowlcode/models/venues/venue.dart';

import 'package:nightowlcode/shared/constants/colors.dart';
import 'package:nightowlcode/shared/constants/styles.dart';
import 'package:nightowlcode/shared/constants/values.dart';
import 'package:nightowlcode/shared/reusable/ui/owl_popup.dart';
import 'package:nightowlcode/shared/reusable/ui/buttons.dart';
import 'package:nightowlcode/shared/reusable/ui/owl_snack.dart';

InputDecoration _searchBarDecoration({
  required String hint,
  IconData? prefixIcon,
  bool multiline = false,
}) {
  final baseBorder = OutlineInputBorder(
    borderRadius: BorderRadius.circular(borderRadiusDefault),
    borderSide: const BorderSide(color: grey, width: 0.7),
  );

  return InputDecoration(
    suffixStyle: Styles.smallText,
    hintText: hint,
    hintStyle: Styles.greyedOutPopupText,
    isDense: true,
    filled: true,
    fillColor: owlPurple.withOpacity(0.03),
    border: baseBorder,
    enabledBorder: baseBorder,
    focusedBorder: baseBorder.copyWith(
      borderSide: const BorderSide(color: owlPurple, width: 0.9),
    ),
    prefixIcon: prefixIcon == null
        ? null
        : Icon(prefixIcon, color: white, size: 20),
    contentPadding: multiline
        ? const EdgeInsets.symmetric(horizontal: 8, vertical: 8)
        : const EdgeInsets.symmetric(vertical: 0),
  );
}

/// Result from the tag picker: chosen tags + optional message.
class TagPickerResult {
  final List<String> tagIds;
  final String? message;

  TagPickerResult({
    required this.tagIds,
    this.message,
  });
}

/// Called from VenueTagsGrid.onAddTag
Future<void> handleAddTagPressed(
    BuildContext context,
    WidgetRef ref,
    Venue venue,
    ) async {
  // ✅ Correct: bool, derived from userRolesProvider
  final bool isAdmin = ref.read(currentUserIsAdminProvider);

  // Show tag picker dialog (multi-select) using OwlPopup
  final result = await showTagPickerDialog(
    context,
    ref,
    venue: venue,
    isAdmin: isAdmin,
  );

  if (result == null || result.tagIds.isEmpty) return;

  final message = (result.message ?? '').trim().isEmpty
      ? null
      : result.message!.trim();

  // We need tag metadata to enforce exclusives on write for admins
  final tagsAsync = ref.read(tagsSsoProvider);
  final Map<String, Tag> allTagMap = tagsAsync.value ?? const {};

  const exclusiveTypeNames = <String>{
    'venue_type',
    'entry_price',
    'age_restriction',
    'smoking_policy',
  };

  List<String> conflictingTagIdsFor(String newTagId) {
    final newTag = allTagMap[newTagId];
    if (newTag == null) return const [];

    if (!exclusiveTypeNames.contains(newTag.type.name)) {
      // Only care about exclusives here
      return const [];
    }

    final conflicts = <String>[];
    for (final rawId in venue.tagids) {
      final existingId = rawId.trim();
      if (existingId.isEmpty || existingId == newTagId) continue;

      final existingTag = allTagMap[existingId];
      if (existingTag != null && existingTag.type == newTag.type) {
        conflicts.add(existingId);
      }
    }
    return conflicts;
  }

  // Submit each suggestion / auto-apply for admins
  for (final tagId in result.tagIds) {
    final conflicts =
    isAdmin ? conflictingTagIdsFor(tagId) : const <String>[];

    await FeedbackRepository.submitVenueTagSuggestion(
      venueId: venue.id,
      tagId: tagId,
      isAdmin: isAdmin,
      message: message,
      conflictingTagIds: conflicts, // 🔹 NEW
    );
  }

  if (!context.mounted) return;

  final count = result.tagIds.length;
  final plural = count == 1 ? '' : 's';

  OwlSnack.show(
    context,
    title: isAdmin ? 'Tag$plural added' : 'Tag$plural suggested',
    message: isAdmin
        ? 'Added $count tag$plural to '
        '${venue.displayName.isNotEmpty ? venue.displayName : venue.name}.'
        : 'Sent $count tag suggestion$plural.',
    variant: OwlSnackVariant.success,
  );
}

/// OwlPopup-based tag picker dialog, grouped by TagType with collapsible sections.
/// Enforces the same business logic as the JS TagsPicker:
/// - exclusiveTypes: at most 1
/// - maxByType: optional caps beyond exclusives
Future<TagPickerResult?> showTagPickerDialog(
    BuildContext context,
    WidgetRef ref, {
      required Venue venue,
      required bool isAdmin,
    }) async {
  // All cached tags from SSO
  final asyncTags = ref.read(tagsSsoProvider);
  final Map<String, Tag> allTagMap = asyncTags.value ?? const {};

  // Exclude tags the venue already has
  final existingIds = venue.tagids
      .map((e) => e.trim())
      .where((e) => e.isNotEmpty)
      .toSet();

  final List<Tag> allTags =
  allTagMap.values.where((t) => !existingIds.contains(t.id)).toList();

  if (allTags.isEmpty) {
    OwlSnack.show(
      context,
      title: 'No tags available',
      message: 'All tags are already added to this venue.',
    );
    return null;
  }

  // Sort by tag type order, then A–Z by name
  final typeOrder = ref.read(tagTypeOrderProvider);

  int rank(TagType t) {
    final i = typeOrder.indexOf(t);
    return i == -1 ? 9999 : i;
  }

  allTags.sort((a, b) {
    final r = rank(a.type).compareTo(rank(b.type));
    if (r != 0) return r;
    return a.name.toLowerCase().compareTo(b.name.toLowerCase());
  });

  // 🔹 Business rules mirrored from JS
  // 1) Exclusive types: at most one selected
  const exclusiveTypeNames = <String>{
    'venue_type',
    'entry_price',
    'age_restriction',
    'smoking_policy',
  };

  bool isExclusive(TagType t) => exclusiveTypeNames.contains(t.name);

  // 2) Optional caps per type (beyond exclusives).
  //    JS example was: { music: 2, vibe: 2 }, but it was never actually enabled.
  //    To *activate* them, just add entries here.
  const Map<String, int> maxByTypeName = {
    // 'music': 2,
    // 'vibe': 2,
  };

  int maxFor(TagType t) => maxByTypeName[t.name] ?? 9999;

  // Treat "max 1" as: exclusive OR explicitly capped at 1
  bool isMaxOneType(TagType t) => isExclusive(t) || maxFor(t) == 1;

  // Map of all tags by id for quick lookup
  final Map<String, Tag> tagsById = {
    for (final t in allTags) t.id: t,
  };


  List<Tag> selectedOfType(
      TagType type,
      Set<String> selectedIds,
      ) {
    return selectedIds
        .map((id) => tagsById[id])
        .whereType<Tag>()
        .where((t) => t.type == type)
        .toList();
  }

  return showDialog<TagPickerResult?>(
    context: context,
    barrierDismissible: true,
    builder: (dialogContext) {
      String query = '';
      String message = '';

      // used to force-rebuild TextFields when we clear with the "X" button
      int queryResetTick = 0;
      int messageResetTick = 0;

      final Set<String> selectedIds = <String>{};
      final Map<TagType, bool> expanded = <TagType, bool>{};

      return StatefulBuilder(
        builder: (ctx, setState) {
          final q = query.trim().toLowerCase();

          // Filter tags by search
          final List<Tag> filtered = q.isEmpty
              ? allTags
              : allTags.where((t) {
            final name = t.name.toLowerCase();
            final typeLabel = t.type.name.toLowerCase();
            final id = t.id.toLowerCase();
            return name.contains(q) ||
                typeLabel.contains(q) ||
                id.contains(q);
          }).toList();

          // Group by TagType
          final Map<TagType, List<Tag>> grouped = <TagType, List<Tag>>{};
          for (final t in filtered) {
            grouped.putIfAbsent(t.type, () => <Tag>[]).add(t);
          }

// Ensure each type has an expansion state:
// - max-one types (exclusive or max==1) → expanded by default
// - others → collapsed by default
          for (final type in grouped.keys) {
            expanded.putIfAbsent(type, () => isMaxOneType(type));
          }



// Order sections:
// 1) all max-one types first
// 2) then the rest, both groups using your rank() order internally
          final List<TagType> orderedTypes = grouped.keys.toList()
            ..sort((a, b) {
              final aMaxOne = isMaxOneType(a);
              final bMaxOne = isMaxOneType(b);

              if (aMaxOne != bMaxOne) {
                return aMaxOne ? -1 : 1; // max-one types first
              }
              return rank(a).compareTo(rank(b));
            });


          void toggleTag(Tag tag) {
            setState(() {
              final type = tag.type;
              final exclusive = isExclusive(type);
              final max = maxFor(type);
              final ofType = selectedOfType(type, selectedIds);

              if (exclusive) {
                // Remove all other tags of this type
                for (final t in ofType) {
                  if (t.id != tag.id) {
                    selectedIds.remove(t.id);
                  }
                }
                // Toggle this one
                if (selectedIds.contains(tag.id)) {
                  selectedIds.remove(tag.id);
                } else {
                  selectedIds.add(tag.id);
                }
              } else {
                // Non-exclusive: optional max
                if (selectedIds.contains(tag.id)) {
                  selectedIds.remove(tag.id);
                } else {
                  if (ofType.length >= max) {
                    // Drop the "oldest" of this type (first in list)
                    selectedIds.remove(ofType.first.id);
                  }
                  selectedIds.add(tag.id);
                }
              }
            });
          }

          Widget buildTypeHeader(TagType type, int count) {
            final isExpanded = expanded[type] ?? false;

            final typeLabel =
            type.name.replaceAll('_', ' '); // nice human label

            return InkWell(
              onTap: () {
                setState(() {
                  expanded[type] = !isExpanded;
                });
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    Icon(
                      isExpanded
                          ? Icons.keyboard_arrow_down
                          : Icons.keyboard_arrow_right,
                      color: greyLighter,
                      size: 18,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        typeLabel,
                        style: Styles.smallText
                            .copyWith(color: greyLighter, fontSize: 10),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: grey.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        '$count',
                        style: Styles.smallText.copyWith(
                          fontSize: 9,
                          color: white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          Widget buildTagChip(Tag t) {
            final selected = selectedIds.contains(t.id);
            final type = t.type;
            final exclusive = isExclusive(type);
            final max = maxFor(type);
            final ofType = selectedOfType(type, selectedIds);
            final atMax = ofType.length >= max;

            bool disabled = false;
            if (exclusive) {
              // If any tag of this type is selected, all *other* ones are disabled
              final chosenDifferent =
                  ofType.isNotEmpty && !selected; // not this one
              disabled = chosenDifferent;
            } else if (atMax && !selected) {
              // At cap, and this chip isn't currently selected
              disabled = true;
            }

            final emoji = t.emoji;
            final label = t.name;

            return FilterChip(
              selected: selected,
              onSelected: disabled ? null : (_) => toggleTag(t),
              label: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (emoji.isNotEmpty) ...[
                    Text(
                      emoji,
                      style: Styles.smallText,
                    ),
                    const SizedBox(width: 2),
                  ],
                  Flexible(
                    child: Text(
                      label,
                      overflow: TextOverflow.ellipsis,
                      style: Styles.smallText.copyWith(
                        color: disabled
                            ? grey
                            : (selected ? owlPurple : white),
                      ),
                    ),
                  ),
                ],
              ),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              padding:
              const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              selectedColor: owlPurple.withOpacity(0.3),
              backgroundColor: disabled ? black.withOpacity(0.5) : black,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(
                  color: disabled
                      ? grey.withOpacity(0.6)
                      : (selected ? owlPurple : grey),
                ),
              ),
            );
          }

          return OwlPopup(
            title: 'Suggest tags to',
            children: [
              // Venue name
              const SizedBox(height: verticalSpacerSmall),
              // Info line
              Text(
                isAdmin
                    ? 'As admin, selected tags will be added immediately to ${venue.displayName}.'
                    : 'Selected tags will be suggestions for ${venue.displayName}.',
                style: Styles.smallText.copyWith(color: greyLighter),
              ),
              const SizedBox(height: verticalSpacerSmall),

              // Search field
              // Search field – same visual style as VenueSearchBar
              // Search field – same visual style as VenueSearchBar, with clear "X"
              TextField(
                key: ValueKey('tag_search_$queryResetTick'),
                style: Styles.smallText,
                decoration: _searchBarDecoration(
                  hint: 'Search tags…',
                  prefixIcon: Icons.search,
                ).copyWith(
                  suffixIcon: query.trim().isEmpty
                      ? null
                      : IconButton(
                    icon: const Icon(
                      Icons.close,
                      size: 16,
                      color: grey,
                    ),
                    splashRadius: 16,
                    onPressed: () {
                      setState(() {
                        query = '';
                        queryResetTick++; // force a new TextField instance → clears text
                      });
                    },
                  ),
                ),
                onChanged: (value) {
                  setState(() => query = value);
                },
              ),


              const SizedBox(height: verticalSpacerSmall),

              // Optional message – multi-line, same visual style
              TextField(
                maxLines: 3,
                style: Styles.smallText,
                decoration: _searchBarDecoration(
                  hint: 'Optional message',
                  prefixIcon: Icons.chat_bubble_outline,
                  multiline: true,
                ),
                onChanged: (value) {
                  setState(() => message = value);
                },
              ),

              const SizedBox(height: verticalSpacerSmall),

              // Actions row – same vibe as feedback popup
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  OwlButton(
                    textStyle: Styles.smallText,
                    label: 'Cancel',
                    onPressed: () =>
                        Navigator.of(ctx).pop<TagPickerResult?>(null),
                    backgroundColor: red,
                    borderColor: transparent,
                    textColor: white,
                    fullWidth: false,
                  ),
                  OwlButton(
                    textStyle: Styles.smallText,
                    label: selectedIds.isEmpty
                        ? 'Suggest'
                        : 'Suggest ${selectedIds.length} tags',
                    onPressed: () {
                      if (selectedIds.isEmpty) return;
                      Navigator.of(ctx).pop<TagPickerResult>(
                        TagPickerResult(
                          tagIds: selectedIds.toList(),
                          message: message.trim().isEmpty
                              ? null
                              : message.trim(),
                        ),
                      );
                    },
                    backgroundColor: owlPurple,
                    borderColor: transparent,
                    textColor: white,
                    fullWidth: false,
                  ),
                ],
              ),

              if (filtered.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: verticalSpacerSmall,
                    ),
                    child: Text(
                      'No tags match your search',
                      style: Styles.smallText.copyWith(color: grey),
                    ),
                  ),
                )
              else
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final type in orderedTypes) ...[
                      buildTypeHeader(type, grouped[type]!.length),
                      if (expanded[type] ?? false)

                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: grouped[type]!
                                .map((t) => buildTagChip(t))
                                .toList(),
                          ),
                        ),
                    ],
                  ],
                ),





            ],
          );
        },
      );
    },
  );
}


