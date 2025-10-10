// lib/features/map/widgets/venue_popup.dart
import 'package:flutter/material.dart';
import 'package:nightowlcode/models/venues/venue.dart';
import 'package:nightowlcode/shared/constants/colors.dart';
import 'package:nightowlcode/shared/constants/enums.dart';

class VenuePopup extends StatelessWidget {
  const VenuePopup({
    super.key,
    required this.venue,
    required this.onClose,
    this.onOpenDetails,
    this.onGo,
  });

  final Venue venue;
  final VoidCallback onClose;
  final VoidCallback? onOpenDetails;
  final VoidCallback? onGo;

  Color _statusBorder(Venue v) =>
      v.isOpenNow(DateTime.now()) ? green : red;

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
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 32, height: 4, margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)),
              ),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(name, maxLines: 1, overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: Colors.white, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 4),
                        Row(children: [
                          if (typeLabel.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: Colors.white10, borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.white24),
                              ),
                              child: Text(typeLabel, style: const TextStyle(color: Colors.white70, fontSize: 12)),
                            ),
                          const SizedBox(width: 8),
                          const Icon(Icons.star_rounded, size: 16, color: Colors.amber),
                          Text(rating, style: const TextStyle(color: Colors.white70)),
                          const SizedBox(width: 8),
                          Row(children: [
                            Icon(Icons.circle, size: 8,
                                color: _statusBorder(venue) == green ? Colors.greenAccent : Colors.redAccent),
                            const SizedBox(width: 4),
                            Text(_statusBorder(venue) == green ? 'Open' : 'Closed',
                                style: const TextStyle(color: Colors.white70, fontSize: 12)),
                          ]),
                        ]),
                      ],
                    ),
                  ),
                  IconButton(onPressed: onClose, icon: const Icon(Icons.close, color: Colors.white70)),
                ],
              ),
              const SizedBox(height: 10),
              Row(children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: onOpenDetails,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white10, foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('Details'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: onGo,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white, foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('Go'),
                  ),
                ),
              ]),
            ],
          ),
        ),
      ),
    );
  }
}
