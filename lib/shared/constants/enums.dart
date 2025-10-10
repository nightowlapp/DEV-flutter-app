import 'package:flutter/material.dart';
import 'package:nightowlcode/shared/constants/icons.dart';

enum MainScreenName {
  explore(showNav: true),
  map(showNav: true),

  calender(showNav: false),
  // cupons(showNav: false),

  social(showNav: true),
  profile(showNav: true),

  venues(showNav: true),
  admin(showNav: true);

  final bool showNav;
  const MainScreenName({required this.showNav});
}

extension ScreenNameX on MainScreenName {
  String get label => switch (this) {
        MainScreenName.explore => 'Explore',
        MainScreenName.map => 'Map',
        MainScreenName.calender => 'Calender',
        MainScreenName.social => 'Social',
        MainScreenName.profile => 'Profile',
        // MainScreenName.cupons => 'Cupons', //TODO
        MainScreenName.venues => 'Venues',
        MainScreenName.admin => 'Admin',
      };

  IconData get icon => switch (this) {
        MainScreenName.explore => exploreIcon,
        MainScreenName.map => mapIcon,
        MainScreenName.calender => calenderIcon,
        MainScreenName.social => socialIcon,
        MainScreenName.profile => profileIcon,
        MainScreenName.venues => venuesIcon,
        MainScreenName.admin => adminIcon,
      };

  // simple gating flags (so bottom bar logic stays tiny)
  bool get requiresAdmin => this == MainScreenName.admin;
  bool get requiresOwner => this == MainScreenName.venues;
  bool get isProfile => this == MainScreenName.profile;
}

// TODO Put (almost) all enums in database for runtime changes.

//Venues

enum VenueType {
  //database format
  unknown,
  club,
  bar,
  pub,
  beer_bar,
  cocktail_bar,
  gay_bar,
  wine_bar,
  sports_bar,
  karaoke_bar,
  // Thrown out: bar_club, bodega, live_music_bar, jazz_bar ,
}

extension VenueTypeIconX on VenueType {
  IconData get icon {
    switch (this) {
      case VenueType.wine_bar:
        return wineBarIcon;
      case VenueType.cocktail_bar:
        return cocktailBarIcon;
      case VenueType.beer_bar:
        return beerBarIcon;
      case VenueType.karaoke_bar:
        return karaokeBarIcon;
      case VenueType.sports_bar:
        return sportsBarIcon; // per your mapping
      case VenueType.gay_bar:
        return gayBarIcon;
      case VenueType.pub:
        return pubIcon;
      case VenueType.bar:
        return barIcon;
      case VenueType.club:
        return clubIcon; // note: correct spelling
      case VenueType.unknown:
        return unknowBarIcon;
      default:
        return unknowBarIcon;
    }
  }
}

enum DressCodeType {
  //database format
  none, // Come as you are
  casual, // Tees/jeans OK
  smart_casual, // Neat shirt/blouse, tidy denim/chinos
  business_casual, // Office-lite, no tie needed
  business, // Suit or equivalent
  formal, // Dark suit / dressy attire

  upscale,
  streetwear, // Fashion sneakers, hoodies, caps (style-forward)
  rave, // Neon/UV, eccentric, functional party wear
  theme,
  outdoor,
}

enum SubscriptionTypesVenue {
  free,
  trial,
  premium,
}

// Users

enum PlatformType { android, ios, web }

enum UserRole { admin, user, tester, reviewer }

enum SubscriptionTypesUser {
  free,
  premium,
  // admin,
}

enum FriendRequestStatus {
  pending,
  accepted,
  rejected,
}

enum Gender { male, female, other }

//TODO dispaly partystatus with a "wheel" and turn to select the mood. Maybe find more?
enum PartyStatusTypes {
  out_tonight,
  house_party,
  pregame,
  recovering,
  still_planning,
  // , , heading_home,not_tonight,
}

enum PartyStatusChange { automatic, manual }
