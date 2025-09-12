// models/users/user.dart
import 'package:flutter/foundation.dart'
    show immutable, defaultTargetPlatform, kIsWeb, TargetPlatform;
import 'package:nightowlcode/shared/constants/enums.dart';
import 'package:nightowlcode/models/users/phone_number.dart';

T _enumFromString<T extends Enum>(String? s, List<T> values, T fallback) {
  final v = (s ?? '').trim().toLowerCase();
  for (final e in values) {
    if (e.name.toLowerCase() == v) return e;
  }
  return fallback;
}

String _enumToString(Enum e) => e.name;

PlatformType _detectPlatformType() {
  if (kIsWeb) return PlatformType.web;
  switch (defaultTargetPlatform) {
    case TargetPlatform.android:
      return PlatformType.android;
    case TargetPlatform.iOS:
      return PlatformType.ios;
    default:
      return PlatformType.android;
  }
}

@immutable
class User {
  // ---- Required ---- (kept in Dart only; not stored to Firestore)
  final String id;
  final String email;
  final String userName;
  final DateTime birthDate;
  final Gender gender;

  // Auditing
  final DateTime createdAt;
  final DateTime updatedAt;

  // ---- Optional ----
  final PhoneNumber? phoneNumber;
  final String? profilePictureUrl;

  final String? firstName;
  final String? middleName;
  final String? lastName;
  final String? biography;

  final String? homeCountry; // iso2 lowercase
  final String? homeTown;    // lowercase

  // ---- Defaults / flags ----
  final String? appVersion;
  final bool isVerified;

  // TODO achievementCount to quickly display amount of achievemnts.
  final int level;
  final double xp;
  final PartyStatusTypes currentPartyStatus;

  final Set<VenueType> preferredVenueTypes;
  final double maxDistanceKm;

  final Set<UserRole> roles;
  final SubscriptionTypesUser subscriptionType;
  final PlatformType platformType;

  User({
    // Required
    required this.id,
    required this.email,
    required this.userName,
    required this.birthDate,
    required this.gender,

    // Optional
    this.firstName,
    this.middleName,
    this.lastName,
    this.phoneNumber,
    this.biography,
    this.profilePictureUrl,
    this.homeCountry,
    this.homeTown,
    this.appVersion,

    // Defaults / flags
    this.isVerified = false,
    this.level = 0,
    this.xp = 0.0,

    // Preferences
    Set<VenueType>? preferredVenueTypes,
    this.maxDistanceKm = 50.0,

    // Roles & Account
    Set<UserRole>? roles,
    this.subscriptionType = SubscriptionTypesUser.free,
    PlatformType? platformType,

    // Presence
    this.currentPartyStatus = PartyStatusTypes.still_planning,

    // Auditing
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : preferredVenueTypes = preferredVenueTypes ?? allVenueTypes(),
        roles = roles ?? const {UserRole.user},
        platformType = platformType ?? _detectPlatformType(),
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  String get displayFullName {
    final parts = <String>[
      if ((firstName ?? '').trim().isNotEmpty) firstName!.trim(),
      if ((middleName ?? '').trim().isNotEmpty) middleName!.trim(),
      if ((lastName ?? '').trim().isNotEmpty) lastName!.trim(),
    ];
    return parts.isEmpty ? '' : parts.join(' ');
  }

  int get age {
    final now = DateTime.now();
    int a = now.year - birthDate.year;
    final hadBirthday = (now.month > birthDate.month) ||
        (now.month == birthDate.month && now.day >= birthDate.day);
    return hadBirthday ? a : a - 1;
  }

  bool get isAdult => age >= 18;
  bool get isAdmin => roles.contains(UserRole.admin);

  User copyWith({
    String? id,
    String? email,
    String? userName,
    DateTime? birthDate,
    Gender? gender,
    String? firstName,
    String? middleName,
    String? lastName,
    PhoneNumber? phoneNumber,
    String? biography,
    String? profilePictureUrl,
    String? homeCountry,
    String? homeTown,
    String? appVersion,
    bool? isVerified,
    int? level,
    double? xp,
    Set<VenueType>? preferredVenueTypes,
    double? maxDistanceKm,
    Set<UserRole>? roles,
    SubscriptionTypesUser? subscriptionType,
    PlatformType? platformType,
    PartyStatusTypes? currentPartyStatus,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      userName: userName ?? this.userName,
      birthDate: birthDate ?? this.birthDate,
      gender: gender ?? this.gender,
      firstName: firstName ?? this.firstName,
      middleName: middleName ?? this.middleName,
      lastName: lastName ?? this.lastName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      biography: biography ?? this.biography,
      profilePictureUrl: profilePictureUrl ?? this.profilePictureUrl,
      homeCountry: homeCountry ?? this.homeCountry,
      homeTown: homeTown ?? this.homeTown,
      appVersion: appVersion ?? this.appVersion,
      isVerified: isVerified ?? this.isVerified,
      level: level ?? this.level,
      xp: xp ?? this.xp,
      preferredVenueTypes: preferredVenueTypes ?? this.preferredVenueTypes,
      maxDistanceKm: maxDistanceKm ?? this.maxDistanceKm,
      roles: roles ?? this.roles,
      subscriptionType: subscriptionType ?? this.subscriptionType,
      platformType: platformType ?? this.platformType,
      currentPartyStatus: currentPartyStatus ?? this.currentPartyStatus,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    // NOTE: 'id' is intentionally NOT included here; repo injects it on read only
    'email': email,
    'user_name': userName,
    'birth_date': birthDate.toIso8601String(),
    'gender': _enumToString(gender),
    'first_name': firstName,
    'middle_name': middleName,
    'last_name': lastName,
    'phone': phoneNumber?.toJson(),
    'biography': biography,
    'profile_picture_url': profilePictureUrl,
    'home_country': homeCountry,
    'home_town': homeTown,
    'app_version': appVersion,
    'is_verified': isVerified,
    'level': level,
    'xp': xp,
    'preferred_venue_types': preferredVenueTypes.map(_enumToString).toList(),
    'max_distance_km': maxDistanceKm,
    'roles': roles.map(_enumToString).toList(),
    'subscription_type': _enumToString(subscriptionType),
    'platform_type': _enumToString(platformType),
    'current_party_status': _enumToString(currentPartyStatus),
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
  }..removeWhere((_, v) => v == null);

  factory User.fromJson(Map<String, dynamic> json) {
    dynamic _v(String k1, [String? k2]) => json[k1] ?? (k2 != null ? json[k2] : null);
    DateTime _asDate(dynamic v, {DateTime? fallback}) {
      if (v == null) return fallback ?? DateTime.now();
      if (v is DateTime) return v;
      final tsType = v.runtimeType.toString();
      if (tsType == 'Timestamp') return (v as dynamic).toDate() as DateTime;
      if (v is int) return DateTime.fromMillisecondsSinceEpoch(v);
      if (v is String) return DateTime.tryParse(v) ?? (fallback ?? DateTime.now());
      return fallback ?? DateTime.now();
    }

    String? _s(String k1, [String? k2]) => _v(k1, k2) as String?;
    List<dynamic>? _l(String k1, [String? k2]) => _v(k1, k2) as List<dynamic>?;

    final rolesList = (_l('roles') ?? const []).cast<String>();
    final venueTypesList = (_l('preferred_venue_types') ?? const []).cast<String>();

    return User(
      id: _s('id') ?? '',
      email: (_s('email') ?? '').trim(),
      userName: _s('user_name', 'userName') ?? '',
      birthDate: _asDate(_v('birth_date')),
      gender: _enumFromString(_s('gender'), Gender.values, Gender.other),

      firstName: _s('first_name', 'firstName'),
      middleName: _s('middle_name', 'middleName'),
      lastName: _s('last_name', 'lastName'),
      phoneNumber: json['phone'] is Map<String, dynamic>
          ? PhoneNumber.fromJson(json['phone'] as Map<String, dynamic>)
          : null,
      biography: _s('biography'),
      profilePictureUrl: _s('profile_picture_url'),
      homeCountry: _s('home_country')?.toLowerCase(),
      homeTown: _s('home_town')?.toLowerCase(),
      appVersion: _s('app_version'),

      isVerified: (json['is_verified'] as bool?) ?? false,
      level: (json['level'] as num?)?.toInt() ?? 0,
      xp: ((json['xp'] as num?) ?? 0).toDouble(),
      preferredVenueTypes: venueTypesList.isEmpty
          ? allVenueTypes()
          : venueTypesList
          .map((s) => _enumFromString<VenueType>(s, VenueType.values, VenueType.unknown))
          .toSet(),
      maxDistanceKm: ((json['max_distance_km'] as num?) ?? 50).toDouble(),
      roles: rolesList.isEmpty
          ? const {UserRole.user}
          : rolesList
          .map((s) => _enumFromString<UserRole>(s, UserRole.values, UserRole.user))
          .toSet(),
      subscriptionType: _enumFromString(
          _s('subscription_type'), SubscriptionTypesUser.values, SubscriptionTypesUser.free),
      platformType:
      _enumFromString(_s('platform_type'), PlatformType.values, _detectPlatformType()),
      currentPartyStatus: _enumFromString(
          _s('current_party_status'), PartyStatusTypes.values, PartyStatusTypes.still_planning),
      createdAt: _asDate(_v('created_at')),
      updatedAt: _asDate(_v('updated_at')),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is User &&
        other.id == id &&
        other.email == email &&
        other.userName == userName &&
        other.birthDate == birthDate &&
        other.gender == gender &&
        other.firstName == firstName &&
        other.middleName == middleName &&
        other.lastName == lastName &&
        _phoneEq(other.phoneNumber, phoneNumber) &&
        other.biography == biography &&
        other.profilePictureUrl == profilePictureUrl &&
        other.homeCountry == homeCountry &&
        other.homeTown == homeTown &&
        other.appVersion == appVersion &&
        other.isVerified == isVerified &&
        other.level == level &&
        other.xp == xp &&
        _setEq(other.preferredVenueTypes, preferredVenueTypes) &&
        other.maxDistanceKm == maxDistanceKm &&
        _setEq(other.roles, roles) &&
        other.subscriptionType == subscriptionType &&
        other.platformType == platformType &&
        other.currentPartyStatus == currentPartyStatus &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt;
  }

  @override
  int get hashCode =>
      id.hashCode ^
      email.hashCode ^
      userName.hashCode ^
      birthDate.hashCode ^
      gender.hashCode ^
      (firstName?.hashCode ?? 0) ^
      (middleName?.hashCode ?? 0) ^
      (lastName?.hashCode ?? 0) ^
      (phoneNumber?.hashCode ?? 0) ^
      (biography?.hashCode ?? 0) ^
      (profilePictureUrl?.hashCode ?? 0) ^
      (homeCountry?.hashCode ?? 0) ^
      (homeTown?.hashCode ?? 0) ^
      (appVersion?.hashCode ?? 0) ^
      isVerified.hashCode ^
      level.hashCode ^
      xp.hashCode ^
      preferredVenueTypes.fold(0, (p, e) => p ^ e.hashCode) ^
      roles.fold(0, (p, e) => p ^ e.hashCode) ^
      subscriptionType.hashCode ^
      platformType.hashCode ^
      currentPartyStatus.hashCode ^
      createdAt.hashCode ^
      updatedAt.hashCode;

  static Set<VenueType> allVenueTypes() => VenueType.values.toSet();

  static bool _setEq(Set a, Set b) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    for (final v in a) {
      if (!b.contains(v)) return false;
    }
    return true;
  }

  static bool _phoneEq(PhoneNumber? a, PhoneNumber? b) {
    if (identical(a, b)) return true;
    if (a == null && b == null) return true;
    if (a == null || b == null) return false;
    return a == b;
  }
}

extension UserX on User {
  bool get hasProfilePicture => (profilePictureUrl?.trim().isNotEmpty ?? false);
}
