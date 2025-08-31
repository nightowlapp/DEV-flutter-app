import 'package:geolocator/geolocator.dart';

class Visit{ // as well as another class called location? NEed to track amount of times a plac.e as well as current location.
  final String userid;
  final String? venueid; // maybe in Position??

  final Position position;
  final DateTime createdAt;

  Visit({required this.userid, this.venueid, required this.position, required this.createdAt});
}