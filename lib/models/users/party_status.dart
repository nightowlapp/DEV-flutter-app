import 'package:geolocator/geolocator.dart';
import 'package:nightowlcode/shared/constants/enums.dart';

class PartyStatus{ //TODO maybe more fields needed.
  PartyStatus(this.venueid,{required this.userid, required this.createdAt,
    required this.partyStatus, required this.partyStatusChange,required this.position,});
// What is the point of this?? TODO
  final String userid;
  final String? venueid; // maybe in Position??

  final PartyStatusTypes partyStatus;
  final PartyStatusChange partyStatusChange;

  final DateTime createdAt;
  final Position position;

}