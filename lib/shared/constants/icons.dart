import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:nightowlcode/shared/constants/colors.dart';

//TODO find cool
// Navbar
final exploreIcon = Icons.search;
final mapIcon = Icons.map_outlined;
final calenderIcon = Icons.calendar_today;
final socialIcon = Icons.group;
final profileIcon = Icons.person_4_rounded; // TODO rename all like this.
final venuesIcon = Icons.nightlife_outlined;
final adminIcon = Icons.shield ?? FontAwesomeIcons.personBreastfeeding;

// Platform
final appleIcon = FontAwesomeIcons.apple;
final googleIcon = FontAwesomeIcons.google;

// Genders
final IconData maleIcon = Icons.male;
final IconData femaleIcon = Icons.female;
final IconData otherGenderIcon = Icons.transgender;

// UI
final partyStatusIcon = Icons.my_location;
final locationIcon = Icons.my_location;

const filledStarIcon = Icons.star;
const halfFilledStarIcon = Icons.star_half;
const emptyStarIcon = Icons.star_border;

final locationPinIcon = Icons.location_pin;

final euroIcon = Icons.euro;
final freeIcon = Icons.money_off;

final dressCodeIcon = FontAwesomeIcons.vest;

const heartIcon = Icons.favorite;
const emptyHeartIcon = Icons.favorite_border;

const cameraIcon = Icons.photo_camera_outlined;
const photoLibraryIcon = Icons.photo_library_outlined;

// Utility
final burgerMenu = Icons.menu_outlined;
final checkIcon = Icons.check;
final checkCircleIcon = Icons.check_circle_outline;
final tuneIcon = Icons.tune;
final checkBoxCheckedIcon = Icons.check_box;
final checkBoxUncheckedIcon = Icons.check_box_outline_blank;
final invisible = Icons.visibility_off;
final visible = Icons.visibility;
final mailIcon = Icons.mail_outline;
final passwordIcon = Icons.lock_outline;
final globeIcon = Icons.public;
final qrCodeIcon = Icons.qr_code_2;
final feedback = Icons.feedback_outlined;
final fullScreenIcon = Icons.fullscreen;
final copyIcon = Icons.copy;
final shieldIcon = Icons.shield_moon;
final infoIcon = Icons.info_outline;
final IconData distanceIcon = Icons.near_me;
final IconData distanceDisabledIcon = Icons.near_me_disabled_outlined;
final closeIcon = Icons.close_sharp;
final editIcon = Icons.edit_outlined;

final settingsIcon = Icons.settings;
final errorIcon = Icons.error_outline;

// Navigation chevrons
final chevronUpIcon = CupertinoIcons.chevron_up;
final chevronDownIcon = CupertinoIcons.chevron_down;
final chevronLeftIcon = CupertinoIcons.chevron_left;
final chevronRightIcon = CupertinoIcons.chevron_right;

// const defaultGooglePlusIcon = FontAwesomeIcons.googlePlusG;
// const defaultGooglePlayIcon = FontAwesomeIcons.googlePlay;
// const defaultAppStoreIcon = FontAwesomeIcons.appStore;
// // REDDIT YT ....

// Venue
final wineBarIcon = Icons.wine_bar;
final cocktailBarIcon = Icons.local_bar;
final beerBarIcon = Icons.sports_bar;
final karaokeBarIcon = Icons.mic_none;
final sportsBarIcon = Icons.sports_soccer;
final gayBarIcon = Icons.transgender;
final pubIcon = Icons.local_drink;
final unknowBarIcon = Icons.nightlife_outlined;
final barIcon = Icons.table_bar;
final clubIcon = Icons.flourescent;

// const defaultLocationDot = FontAwesomeIcons.locationDot;
// const defaultLocationDotLocked = FontAwesomeIcons.locationPinLock;
// const defaultCompassIcon = FontAwesomeIcons.compass;
// final defaultCompassIcon12 = MdiIcons.compass;

// Utility
// const defaultDownArrow = FontAwesomeIcons.chevronDown;
// const defaultUpArrow = FontAwesomeIcons.chevronUp;
// const defaultGoBackIcon = FontAwesomeIcons.arrowLeft;
// const ChevronGoBackIcon = FontAwesomeIcons.chevronLeft;
// const defaultPlusIcon = FontAwesomeIcons.plus;
//
// // Locations
// const defaultEmptyHeartIcon = FontAwesomeIcons.heart;
// const defaultFullHeartIcon = FontAwesomeIcons.solidHeart;
// const defaultEmptyStarIcon = FontAwesomeIcons.star;
// const defaultFullStarIcon = FontAwesomeIcons.solidStar;
// const defaultCommentIcon = FontAwesomeIcons.comment;
//

//

//
// const defaultGearIcon = FontAwesomeIcons.gear;
// const defaultPercentIcon = FontAwesomeIcons.percent;
// ScreenName.venues => Icons.wine_bar,
// ScreenName.venues => Icons.local_bar,

// // const defaultSize = 20.0;
// const defaultSettingIcon = Icon(
//   Icons.tune,
//   color: defaultColor,
//   // size: defaultSize,
// );

// const defaultProfileIcon = FontAwesomeIcons.person;

// const defaultLocationDot = FontAwesomeIcons.mapLocationDot;
// const defaultLocationDot = FontAwesomeIcons.locationCrosshairs;
// const defaultLocationDot = FontAwesomeIcons.mapLocation;
// const defaultLocationDot = FontAwesomeIcons.magnifyingGlassLocation; Okay
// const defaultLocationDot = FontAwesomeIcons.locationArrow;
