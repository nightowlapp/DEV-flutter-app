import 'package:nightowlcode/shared/constants/enums.dart';

int partyPriority(PartyStatusTypes s) => const {
  PartyStatusTypes.out_tonight: 0,
  PartyStatusTypes.house_party: 1,
  PartyStatusTypes.pregame: 2,
  PartyStatusTypes.recovering: 3,
  PartyStatusTypes.still_planning: 4,
}[s] ?? 999;
