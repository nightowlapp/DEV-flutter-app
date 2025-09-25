// lib/features/map/widgets/venue_sticky_sheet.dart
import 'package:flutter/material.dart';
import 'package:nightowlcode/models/venues/venue.dart';
import 'package:nightowlcode/shared/constants/colors.dart';
import 'package:nightowlcode/shared/constants/enums.dart';
import '../../../shared/reusable/venue_avatar.dart';

class VenuePopup extends StatelessWidget {
  const VenuePopup({
    super.key,
    required this.venue,
    required this.onClose,
    this.onOpenDetails,
  });

  final Venue venue;
  final VoidCallback onClose;
  final VoidCallback? onOpenDetails;

  ImageProvider<Object>? _imageOf(Venue v) {
    // Try logo first, else a type placeholder. Null falls back to errorChild.
    final url = (v.logoUrl ?? '').trim();
    if (url.isNotEmpty) return NetworkImage(url);
    // final typeImg = (v.typeOfClubImg ?? '').trim(); // if you have this
    // if (typeImg.isNotEmpty) return NetworkImage(typeImg);
    return null;
  }

  Color? _statusBorder(Venue v) {
    try {
      final open = v.isOpenNow(DateTime.now());
      return open ? green : red;
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final name = venue.displayName.isNotEmpty ? venue.displayName : venue.name;
    final rating = venue.rating?.toStringAsFixed(1) ?? '—';
    final typeLabel = venue.type == VenueType.unknown ? '' : venue.type.name.replaceAll('_', ' ');

    return SafeArea(
      top: false,
      child: Material(
        elevation: 12,
        color: Colors.black.withOpacity(0.86),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 96, maxHeight: 220),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Grab handle
                Container(
                  width: 32,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Row(
                  children: [
                    // Avatar
                    VenueAvatar<Venue>(
                      items: [venue],
                      imageOf: _imageOf,
                      // borderColorOf: _statusBorder,
                      radius: 22,
                      borderWidth: 2,
                      emptyText: '',
                    ),
                    const SizedBox(width: 12),
                    // Title + meta
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              )),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              if (typeLabel.isNotEmpty)
                                _Chip(typeLabel),
                              const SizedBox(width: 8),
                              _Star(rating),
                              const SizedBox(width: 8),
                              _OpenDot(isOpen: _statusBorder(venue) == green),
                            ],
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: 'Close',
                      onPressed: onClose,
                      icon: const Icon(Icons.close, color: Colors.white70),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                // Actions
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: onOpenDetails,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white10,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: const Text('Details'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: onOpenDetails, // or navigate / go
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: const Text('Go'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip(this.text);
  final String text;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.white10,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white24),
      ),
      child: Text(text, style: const TextStyle(color: Colors.white70, fontSize: 12)),
    );
  }
}

class _Star extends StatelessWidget {
  const _Star(this.rating);
  final String rating;
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.star_rounded, size: 16, color: Colors.amber),
        Text(rating, style: const TextStyle(color: Colors.white70)),
      ],
    );
  }
}

class _OpenDot extends StatelessWidget {
  const _OpenDot({required this.isOpen});
  final bool isOpen;
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(Icons.circle, size: 8, color: isOpen ? Colors.greenAccent : Colors.redAccent),
        const SizedBox(width: 4),
        Text(isOpen ? 'Open' : 'Closed', style: const TextStyle(color: Colors.white70, fontSize: 12)),
      ],
    );
  }
}
