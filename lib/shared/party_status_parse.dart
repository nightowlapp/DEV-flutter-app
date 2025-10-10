// lib/shared/party_status_parse.dart
import 'package:nightowlcode/shared/constants/enums.dart';

PartyStatusTypes parsePartyStatus(String? value) {
  switch ((value ?? '').trim()) {
    case 'out_tonight':
      return PartyStatusTypes.out_tonight;
    case 'house_party':
      return PartyStatusTypes.house_party;
    case 'pregame':
      return PartyStatusTypes.pregame;
    case 'recovering':
      return PartyStatusTypes.recovering;
    case 'still_planning':
    default:
      return PartyStatusTypes.still_planning;
  }
}

String partyStatusToString(PartyStatusTypes s) {
  switch (s) {
    case PartyStatusTypes.out_tonight:
      return 'out_tonight';
    case PartyStatusTypes.house_party:
      return 'house_party';
    case PartyStatusTypes.pregame:
      return 'pregame';
    case PartyStatusTypes.recovering:
      return 'recovering';
    case PartyStatusTypes.still_planning:
    default:
      return 'still_planning';
  }
}
