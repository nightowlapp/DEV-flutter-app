// lib/shared/reusable/ui/edit_badge.dart

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:nightowlcode/shared/constants/colors.dart';
import 'package:nightowlcode/shared/constants/icons.dart';
import 'package:nightowlcode/shared/constants/styles.dart';
import 'package:nightowlcode/shared/constants/values.dart';
import 'package:nightowlcode/shared/constants/enums.dart'; // VenueType, DressCodeType
import 'package:nightowlcode/shared/reusable/ui/owl_popup.dart';

import '../../../data/providers/other_providers.dart';
import '../../../data/repositories/users/feedback_repository.dart';
import '../../../data/repositories/users/role_repository.dart';
import '../../../models/venues/venue.dart';
import '../../utility/tag_actions.dart';
import '../../utility/utility.dart';
import 'owl_snack.dart';

/// Simple ISO date: 2025-01-02
String _formatDateIso(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-'
        '${d.month.toString().padLeft(2, '0')}-'
        '${d.day.toString().padLeft(2, '0')}';

InputDecoration _editFieldDecoration({
  required String label,
  String? hint,
  bool multiline = false,
}) {
  final baseBorder = OutlineInputBorder(
    borderRadius: BorderRadius.circular(borderRadiusSmall),
    borderSide: const BorderSide(color: grey, width: 0.6),
  );

  return InputDecoration(
    labelText: label,
    hintText: hint,
    labelStyle: Styles.mediumSmallText,
    hintStyle: Styles.greyedOutPopupText,
    isDense: true,
    filled: true,
    fillColor: black,
    enabledBorder: baseBorder,
    focusedBorder: baseBorder.copyWith(
      borderSide: const BorderSide(color: owlPurple, width: 0.9),
    ),
    contentPadding: multiline
        ? const EdgeInsets.symmetric(horizontal: 8, vertical: 8)
        : const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
  );
}

/// Same visual style as your VenueSearchBar / tag picker optional message
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

class EditBadge extends ConsumerWidget {
  const EditBadge({
    super.key,
    required this.venue,
  });

  final Venue venue;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () => _showEditDialog(context, ref),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        decoration: BoxDecoration(
          color: black,
          borderRadius: BorderRadius.circular(borderRadiusSmall),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(editIcon, color: greyLighter, size: iconSizeDefault),
            Text(
              'Edit',
              style: Styles.smallText.copyWith(
                fontSize: 6,
                color: greyLighter,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => OwlPopup(
        title: 'Suggest an edit',
        children: [
          _EditOption(
            label: 'Age restriction',
            icon: Icons.child_friendly_outlined,
            onTap: () => _handleOptionTap(context, ref, 'age_restriction'),
          ),
          _EditOption(
            label: 'Venue type',
            icon: venuesIcon,
            onTap: () => _handleOptionTap(context, ref, 'venue_type'),
          ),
          _EditOption(
            label: 'Tags',
            icon: Icons.tag_outlined,
            onTap: () async {
              // Close the "Suggest an edit" popup
              Navigator.of(context, rootNavigator: true).pop();

              // Open the tag picker flow
              await handleAddTagPressed(context, ref, venue);
            },
          ),
          _EditOption(
            label: 'Opening hours',
            icon: Icons.schedule_outlined,
            onTap: () => _handleOptionTap(context, ref, 'opening_hours'),
          ),
          _EditOption(
            label: 'Entry price',
            icon: Icons.attach_money_outlined,
            onTap: () => _handleOptionTap(context, ref, 'entry_price'),
          ),
          _EditOption(
            label: 'Dress code',
            icon: Icons.checkroom_outlined,
            onTap: () => _handleOptionTap(context, ref, 'dress_code'),
          ),
          _EditOption(
            label: 'Offers',
            icon: Icons.local_offer_outlined,
            onTap: () => _handleOptionTap(context, ref, 'offers'),
          ),
          _EditOption(
            label: 'Name',
            icon: Icons.signpost_outlined,
            onTap: () => _handleOptionTap(context, ref, 'name'),
          ),
          _EditOption(
            label: 'Location',
            icon: Icons.place_outlined,
            onTap: () => _handleOptionTap(context, ref, 'location'),
          ),
        ],
      ),
    );
  }

  /// 1) Close the list dialog
  /// 2) Create a stub feedback doc (ONE per suggestion)
  /// 3) Optionally show a follow-up dialog that updates the same doc
  Future<void> _handleOptionTap(
      BuildContext context,
      WidgetRef ref,
      String category,
      ) async {
    Navigator.of(context, rootNavigator: true).pop(); // close first popup

    // Step 1: create stub & get its id
    final feedbackId = await _submitQuick(context, ref, category);
    if (feedbackId == null) return;

    // Step 2: show optional follow-up UI (day-specific)
    await _showFollowUpDialog(context, category, feedbackId: feedbackId);
  }

  /// Creates the stub doc and shows the first snack.
  /// Returns docId or null on error.
  Future<String?> _submitQuick(
      BuildContext context,
      WidgetRef ref,
      String category,
      ) async {
    try {
      final now = DateTime.now(); // later: convert to venue-local using timeZoneId
      final weekdayIndex =
          (now.weekday + 6) % 7; // 0=Mon, 1=Tue, ..., 6=Sun – matches OpeningHours

      // Extra fields for specific categories
      final extra = <String, dynamic>{};

      if (category == 'age_restriction' || category == 'opening_hours' || category == 'entry_price' ||
          category == 'dress_code') {
        extra['weekday'] = weekdayIndex; // 🔹 important for later migration
      }

      final feedbackId = await FeedbackRepository.createVenueFeedbackStub(
        venueId: venue.id,
        category: category,
        extraFields: extra.isEmpty ? null : extra,
      );

      // 🔥 LOCAL ROLE CHECK – *before* hitting Firestore
      final authUserAsync = ref.read(authUserProvider);
      final user = authUserAsync.asData?.value;
      if (user != null) {
        final roles = user.roles ?? const <UserRole>{};

        await addReviewerRoleToUserIfMissing(
          userId: user.id, // or user.uid, depending on your model
          localRoles: roles,
        );
      }

      OwlSnack.show(
        context,
        title: 'Hoot hoot! Edit sent 🦉',
        message:
        'Thanks for looking out for the NightOwl community! We\'ll review your ${Utility.formatString(category)} suggestion soon.',
        variant: OwlSnackVariant.success,
        duration: const Duration(seconds: 10),
      );

      return feedbackId;
    } catch (e) {
      OwlSnack.show(
        context,
        title: 'Could not send suggestion',
        message: e.toString(),
        variant: OwlSnackVariant.error,
      );
      return null;
    }
  }

  Future<void> _showFollowUpDialog(
      BuildContext context,
      String category, {
        required String feedbackId,
      }) async {
    final prettyCategory = Utility.formatString(category);

    // Use "now" as venue-local time; if you later wire timeZoneId into a
    // timezone library, replace this with venue-local DateTime.

    String _formatDateWithWeekday(DateTime d) {
      const weekdayNames = <String>[
        'Monday',
        'Tuesday',
        'Wednesday',
        'Thursday',
        'Friday',
        'Saturday',
        'Sunday',
      ];

      final weekday = weekdayNames[d.weekday - 1]; // DateTime.weekday: 1 = Monday
      final iso = _formatDateIso(d);
      return weekday;
      // ' $iso';
    }

    final now = DateTime.now();
    final dateStr = _formatDateWithWeekday(now);

    // Day-specific *effective* values (week schedule + exceptions + defaults)
    final todayAge = venue.effectiveAgeRestriction(now);
    final todayPrice = venue.effectiveEntryPrice(now);
    final todayDressCode = venue.effectiveDressCode(now);
    final todayHoursLabel = venue.openingHoursTodayLabel(venueLocalNow: now);
    String? offerPhotoPath; // local file path
    final picker = ImagePicker();

    await showDialog(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        final TextEditingController mainController = TextEditingController();

        // Prefill for some categories (not used for age anymore)
        if (category == 'entry_price' && todayPrice > 0) {
          mainController.text = todayPrice
              .toStringAsFixed(
            todayPrice.truncateToDouble() == todayPrice ? 0 : 2,
          );
        } else if (category == 'name') {
          final display = (venue.displayName.isNotEmpty
              ? venue.displayName
              : venue.name)
              .trim();
          mainController.text = display;
        }

        // Enums that may vary day-by-day
        VenueType? selectedVenueType =
        venue.type == VenueType.unknown ? null : venue.type;
        DressCodeType? selectedDressCode = todayDressCode;

        // Age restriction dropdown: 18–25
        int? selectedAge;
        if (category == 'age_restriction' &&
            todayAge >= 18 &&
            todayAge <= 25) {
          selectedAge = todayAge;
        }
        // For opening_hours UI: prefill from today's range
        final todayRange = venue.todayRangeParts24h(venueLocalNow: now);
        bool openingIsClosed = todayRange.isClosed;

        int? openHour;
        int? openMinute;
        int? closeHour;
        int? closeMinute;

        if (!todayRange.isClosed &&
            todayRange.open.isNotEmpty &&
            todayRange.close.isNotEmpty) {
          // parse "HH:mm"
          final openParts = todayRange.open.split(':');
          final closeParts = todayRange.close.split(':');

          if (openParts.length == 2) {
            openHour = int.tryParse(openParts[0]);
            openMinute = int.tryParse(openParts[1]);
          }
          if (closeParts.length == 2) {
            closeHour = int.tryParse(closeParts[0]);
            closeMinute = int.tryParse(closeParts[1]);
          }
        }

        // Optional free message text (same for all categories)
        String freeMessage = '';

        return StatefulBuilder(
          builder: (ctx, setState) {
            List<Widget> body = [];

            switch (category) {
            // 🔹 age restriction dropdown 18–25, no free text value
              case 'age_restriction':
                body = [
                  Text(
                    'What is the correct age restriction for ${venue.displayName} today ($dateStr)?',
                    style: Styles.smallText,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<int>(
                    value: selectedAge,
                    dropdownColor: black,
                    iconEnabledColor: white,
                    decoration: _editFieldDecoration(
                      label: 'Correct age',
                    ),
                    items: List<int>.generate(25 - 18 + 1, (i) => 18 + i) //TODO soft code so age cannot be the same as age today/now.
                        .map(
                          (age) => DropdownMenuItem<int>(
                        value: age,
                        child: Text(
                          '$age+',
                          style: Styles.basicText,
                        ),
                      ),
                    )
                        .toList(),
                    onChanged: (age) {
                      setState(() {
                        selectedAge = age;
                      });
                    },
                  ),
                ];
                break;

              case 'venue_type':
                body = [
                  Text(
                    'Which type of venue is ${venue.displayName}?',
                    style: Styles.smallText,
                  ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 260),
                      child: DropdownButtonFormField<VenueType>(
                        value: selectedVenueType,
                        dropdownColor: black,
                        iconEnabledColor: white,
                        items: VenueType.values
                            .map(
                              (v) => DropdownMenuItem<VenueType>(
                            value: v,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  v.icon,
                                  color: white,
                                  size: 18,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  v.name == 'unknown'
                                      ? 'Other'
                                      : Utility.formatString(v.name),
                                  style: Styles.smallText.copyWith(
                                    color: white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                            .toList(),
                        onChanged: (v) {
                          setState(() {
                            selectedVenueType = v;
                          });
                        },
                      ),
                    ),
                  ),
                ];
                break;

              case 'entry_price':
                body = [
                  Text(
                    'What is the correct entry price for ${venue.displayName} today ($dateStr)?',
                    style: Styles.smallText,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: mainController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    style: Styles.smallText,
                    decoration: _editFieldDecoration(
                      label: 'Correct entry price (€)',
                    ),
                  ),
                ];
                break;

              case 'dress_code':
                body = [
                  Text(
                    'What is the correct dress code for ${venue.displayName} today ($dateStr)?',
                    style: Styles.smallText,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<DressCodeType>(
                    value: selectedDressCode,
                    dropdownColor: black,
                    iconEnabledColor: white,
                    decoration: _editFieldDecoration(
                      label: 'Correct dress code',
                    ),
                    items: DressCodeType.values
                        .map(
                          (d) => DropdownMenuItem<DressCodeType>(
                        value: d,
                        child: Text(
                          Utility.formatString(d.name),
                          style: Styles.smallText.copyWith(color: white),
                        ),
                      ),
                    )
                        .toList(),
                    onChanged: (d) {
                      setState(() {
                        selectedDressCode = d;
                      });
                    },
                  ),
                ];
                break;

              case 'opening_hours':
                body = [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 🟣 Left: question text, wraps nicely
                      Expanded(
                        child: Text(
                          'What are the correct opening hours for ${venue.displayName} today ($dateStr)?',
                          style: Styles.smallText,
                        ),
                      ),
                      const SizedBox(width: 8),

                      // 🟣 Right: switch + label, no overflow
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Switch(
                            value: openingIsClosed,
                            activeColor: owlPurple,
                            onChanged: (v) {
                              setState(() {
                                openingIsClosed = v;
                              });
                            },
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Closed today',
                            style: Styles.smallText,
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (!openingIsClosed) ...[
                    _TimeRow(
                      label: 'Opens',
                      initialHour: openHour,
                      initialMinute: openMinute,
                      onChanged: (h, m) {
                        setState(() {
                          openHour = h;
                          openMinute = m;
                        });
                      },
                    ),
                    const SizedBox(height: 8),
                    _TimeRow(
                      label: 'Closes',
                      initialHour: closeHour,
                      initialMinute: closeMinute,
                      onChanged: (h, m) {
                        setState(() {
                          closeHour = h;
                          closeMinute = m;
                        });
                      },
                    ),
                  ],
                ];
                break;

              case 'offers':
                body = [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 🟣 Left: text box
                      Expanded(
                        child: TextField(
                          controller: mainController,
                          maxLines: 4,
                          style: Styles.smallText.copyWith(color: white),
                          decoration: _editFieldDecoration(
                            label:
                            'What are the correct offers for ${venue.displayName} today ($dateStr)?',
                            multiline: true,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),

                      // 🟣 Right: photo picker / preview
                      GestureDetector(
                        onTap: () async {
                          // Use root navigator so the sheet appears above the popup
                          final rootCtx = Navigator.of(ctx, rootNavigator: true).context;

                          final src = await _chooseOfferImageSource(rootCtx);
                          if (src == null) return;

                          final picked = await picker.pickImage(
                            source: src,
                            maxWidth: 1600,
                            maxHeight: 1600,
                            imageQuality: 80,
                          );
                          if (picked == null) return;

                          setState(() {
                            offerPhotoPath = picked.path;
                          });
                        },
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 64,
                              height: 64,
                              decoration: BoxDecoration(
                                color: black,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: offerPhotoPath == null
                                  ? const Icon(
                                Icons.camera_alt_outlined,
                                color: white,
                                size: iconSizeDefault,
                              )
                                  : ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.file(
                                  File(offerPhotoPath!),
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ];
                break;


              case 'location':
                body = [
                  Text(
                    'What is the correct location for ${venue.displayName}?',
                    style: Styles.smallText,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: mainController,
                    maxLines: 4,
                    style: Styles.smallText,
                    decoration: _editFieldDecoration(
                      label: 'Correct location',
                      multiline: true,
                    ),
                  ),
                ];
                break;

              default:
                body = [
                  Text(
                    'What is the correct name of ${venue.displayName}?',
                    style: Styles.smallText,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: mainController,
                    maxLines: 3,
                    style: Styles.smallText.copyWith(color: white),
                    decoration: _editFieldDecoration(
                      label: '',
                      multiline: true,
                    ),
                  ),
                ];
            }

            // 🔹 Add optional free-text message for ALL categories
            body = [
              ...body,
              const SizedBox(height: 8),
              TextField(
                maxLines: 3,
                style: Styles.smallText,
                decoration: _searchBarDecoration(
                  hint: 'Optional message',
                  prefixIcon: Icons.chat_bubble_outline,
                  multiline: true,
                ),
                onChanged: (value) {
                  setState(() => freeMessage = value);
                },
              ),
            ];

            return OwlPopup(
              title: '$prettyCategory correction',
              children: [
                ...body,
                const SizedBox(height: verticalSpacerSmall),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Skip: keep only the stub doc
                    TextButton(
                      onPressed: () {
                        Navigator.of(ctx, rootNavigator: true).pop();
                      },
                      child: Text(
                        'Skip',
                        style: Styles.smallText.copyWith(color: greyLighter),
                      ),
                    ),
                    TextButton(
                      onPressed: () async {
                        final trimmedMessage = freeMessage.trim();
                        int? suggestedAge;
                        final extraFields = <String, dynamic>{};

                        switch (category) {
                          case 'age_restriction':
                            if (selectedAge != null) {
                              suggestedAge = selectedAge;
                              // structured in suggested_age; message stays user text
                            }
                            break;

                          case 'venue_type':
                            if (selectedVenueType != null &&
                                selectedVenueType != VenueType.unknown) {
                              extraFields['suggested_venue_type'] =
                                  selectedVenueType!.name;
                            }
                            break;

                          case 'entry_price':
                            final v = mainController.text.trim();
                            if (v.isNotEmpty) {
                              final parsed =
                              double.tryParse(v.replaceAll(',', '.'));
                              if (parsed != null) {
                                extraFields['suggested_entry_price'] = parsed;
                              } else {
                                extraFields['suggested_entry_price_raw'] = v;
                              }
                            }
                            break;

                          case 'dress_code':
                            if (selectedDressCode != null) {
                              extraFields['suggested_dress_code'] =
                                  selectedDressCode!.name;
                            }
                            break;

                          case 'opening_hours':
                          // If marked closed
                            if (openingIsClosed) {
                              extraFields['suggested_is_closed'] = true;
                            } else {
                              // Need valid times
                              if (openHour != null &&
                                  openMinute != null &&
                                  closeHour != null &&
                                  closeMinute != null) {
                                final openM = openHour! * 60 + openMinute!;
                                final closeM =
                                    closeHour! * 60 + closeMinute!;
                                // 0..1439, DaySchedule handles overnight when close <= open
                                extraFields['suggested_is_closed'] = false;
                                extraFields['suggested_open'] = openM;
                                extraFields['suggested_close'] = closeM;
                              }
                            }
                            break;

                          case 'tags':
                            final v = mainController.text.trim();
                            if (v.isNotEmpty) {
                              extraFields['suggested_tags'] = v;
                            }
                            break;

                          case 'offers':
                            final v = mainController.text.trim();
                            if (v.isNotEmpty) {
                              extraFields['suggested_offers'] = v;
                            }

                            if (offerPhotoPath != null) {
                              final file = File(offerPhotoPath!);
                              final url = await FeedbackRepository.uploadOfferImage(
                                venueId: venue.id,
                                feedbackId: feedbackId,
                                file: file,
                              );
                              extraFields['offer_photo_url'] = url;
                            }
                            break;


                          case 'name':
                            final v = mainController.text.trim();
                            if (v.isNotEmpty) {
                              extraFields['suggested_name'] = v;
                            }
                            break;

                          case 'location':
                            final v = mainController.text.trim();
                            if (v.isNotEmpty) {
                              extraFields['suggested_location'] = v;
                            }
                            break;

                          default:
                            final v = mainController.text.trim();
                            if (v.isNotEmpty) {
                              extraFields['suggested_value'] = v;
                            }
                        }

                        final hasStructured =
                            suggestedAge != null || extraFields.isNotEmpty;
                        final hasMessage = trimmedMessage.isNotEmpty;

                        if (!hasStructured && !hasMessage) {
                          // Nothing extra → just close, keep stub
                          Navigator.of(ctx, rootNavigator: true).pop();
                          return;
                        }

                        try {
                          await FeedbackRepository.updateVenueFeedbackDetails(
                            venueId: venue.id,
                            category: category,
                            feedbackId: feedbackId,
                            message: hasMessage
                                ? trimmedMessage
                                : null, // pure user text
                            suggestedAge: suggestedAge,
                            extraFields:
                            extraFields.isEmpty ? null : extraFields,
                          );

                          Navigator.of(ctx, rootNavigator: true).pop();
                          OwlSnack.show(
                            context,
                            title: 'Details added',
                            message:
                            'Hoot hoot! Your $prettyCategory suggestion just joined the NightOwl flock! We’ll give it a loving look soon 🦉💜',
                            variant: OwlSnackVariant.success,
                            duration: const Duration(seconds: 5),
                          );
                        } catch (e) {
                          Navigator.of(ctx, rootNavigator: true).pop();
                          OwlSnack.show(
                            context,
                            title: 'Could not send details',
                            message: e.toString(),
                            variant: OwlSnackVariant.error,
                          );
                        }
                      },
                      child: Text(
                        'Send details',
                        style: Styles.smallText.copyWith(color: owlPurple),
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        );
      },
    );
  }
  Future<ImageSource?> _chooseOfferImageSource(BuildContext context) {
    return showModalBottomSheet<ImageSource>(
      context: context,
      useRootNavigator: true,
      backgroundColor: black,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(
                cameraIcon,
                size: iconSizeDefault,
                color: owlPurple,
              ),
              title: Text('Take photo', style: Styles.basicText),
              onTap: () => Navigator.of(ctx, rootNavigator: true)
                  .pop(ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(
                photoLibraryIcon,
                size: iconSizeDefault,
                color: owlPurple,
              ),
              title: Text('Choose from gallery', style: Styles.basicText),
              onTap: () => Navigator.of(ctx, rootNavigator: true)
                  .pop(ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
  }

}

class _TimeRow extends StatelessWidget {
  const _TimeRow({
    required this.label,
    required this.initialHour,
    required this.initialMinute,
    required this.onChanged,
  });

  final String label;
  final int? initialHour;
  final int? initialMinute;
  final void Function(int hour, int minute) onChanged;

  @override
  Widget build(BuildContext context) {
    final hours = List<int>.generate(24, (i) => i); // 00–23
    final minutes = const <int>[0, 15, 30, 45]; // quarter-hour steps

    int? selectedHour = initialHour;
    int? selectedMinute = initialMinute;

    return Row(
      children: [
        SizedBox(
          width: 30,
          child: Text(
            label,
            style: Styles.smallText.copyWith(color: greyLighter),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Row(
            children: [
              // Hour dropdown
              Expanded(
                child: DropdownButtonFormField<int>(
                  value: selectedHour,
                  dropdownColor: black,
                  iconEnabledColor: white,
                  decoration: _editFieldDecoration(
                    label: 'HH',
                  ),
                  items: hours
                      .map(
                        (h) => DropdownMenuItem<int>(
                      value: h,
                      child: Text(
                        h.toString().padLeft(2, '0'),
                        style:
                        Styles.smallText.copyWith(color: white),
                      ),
                    ),
                  )
                      .toList(),
                  onChanged: (h) {
                    selectedHour = h;
                    if (selectedMinute == null) {
                      selectedMinute = 0;
                    }
                    onChanged(selectedHour!, selectedMinute!);
                  },
                ),
              ),
              const SizedBox(width: 8),
              // Minute dropdown
              Expanded(
                child: DropdownButtonFormField<int>(
                  value: selectedMinute,
                  dropdownColor: black,
                  iconEnabledColor: white,
                  decoration: _editFieldDecoration(
                    label: 'MM',
                  ),
                  items: minutes
                      .map(
                        (m) => DropdownMenuItem<int>(
                      value: m,
                      child: Text(
                        m.toString().padLeft(2, '0'),
                        style:
                        Styles.smallText.copyWith(color: white),
                      ),
                    ),
                  )
                      .toList(),
                  onChanged: (m) {
                    selectedMinute = m;
                    if (selectedHour == null) {
                      selectedHour = 0;
                    }
                    onChanged(selectedHour!, selectedMinute!);
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Simple row item used inside the dialog
class _EditOption extends StatelessWidget {
  const _EditOption({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      splashColor: owlPurple.withOpacity(0.15),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: grey, width: 0.35)),
        ),
        child: Row(
          children: [
            Icon(icon, color: white, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: Styles.popupText.copyWith(color: white),
              ),
            ),
            const Icon(Icons.chevron_right, color: grey),
          ],
        ),
      ),
    );
  }
}
