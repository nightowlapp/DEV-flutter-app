// lib/data/providers/venues/venue_status_color_provider.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nightowlcode/models/venues/venue.dart';
import 'package:nightowlcode/shared/constants/colors.dart';

final venueStatusColorProvider = Provider.family<Color, Venue>((ref, v) {
  final isOpen = v.isOpenNow(DateTime.now());
  return isOpen ? green : red;
});
