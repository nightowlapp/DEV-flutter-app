import 'package:flutter/material.dart';
import 'package:nightowlcode/models/venues/venue.dart';

class VenuePopup extends StatelessWidget {
  final Venue venue;
  const VenuePopup({super.key, required this.venue});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(centerTitle: true, title: Text(venue.displayName)),
      body: 
      Column(children:[
        Text(venue.displayName),
        Text(venue.openingHours.toString()),
        Text(venue.effectiveAgeRestriction(DateTime.now()).toString()),
        Text(venue.updatedAt.toString()),

        ]));
  }
}
