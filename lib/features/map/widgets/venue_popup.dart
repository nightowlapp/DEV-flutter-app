import 'package:flutter/material.dart';

class VenuePopup extends StatelessWidget {
  final String id;
  const VenuePopup({required this.id});
  @override
  Widget build(BuildContext context) {
    return Scaffold(appBar: AppBar(centerTitle: true, title: Text('Venue $id')), body: Center(child: Text('Details for $id')));
  }
}
