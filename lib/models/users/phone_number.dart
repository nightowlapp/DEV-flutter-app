import 'package:flutter/foundation.dart';

@immutable
class PhoneNumber {
  final String e164; // "+4522334455"
  final String? iso2; // "DK"
  final String? callingCode; // "45"

  const PhoneNumber({required this.e164, this.iso2, this.callingCode});

  static final RegExp _e164 = RegExp(r'^\+[1-9]\d{6,14}$');

  static PhoneNumber? tryParse(String raw,
      {String? iso2, String? callingCode}) {
    final s = raw.replaceAll(' ', '');
    if (!_e164.hasMatch(s)) return null;
    return PhoneNumber(
        e164: s, iso2: iso2?.toUpperCase(), callingCode: callingCode);
  }

  Map<String, dynamic> toJson() => {
        'e164': e164,
        if (iso2 != null) 'iso2': iso2,
        if (callingCode != null) 'calling_code': callingCode,
      };

  factory PhoneNumber.fromJson(Map<String, dynamic>? json) {
    if (json == null || json['e164'] == null) {
      return const PhoneNumber(e164: '+1000000');
    }
    return PhoneNumber(
      e164: (json['e164'] as String).trim(),
      iso2: (json['iso2'] as String?)?.toUpperCase(),
      callingCode: json['calling_code'] as String?,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PhoneNumber &&
          e164 == other.e164 &&
          iso2 == other.iso2 &&
          callingCode == other.callingCode;

  @override
  int get hashCode => Object.hash(e164, iso2, callingCode);
}
