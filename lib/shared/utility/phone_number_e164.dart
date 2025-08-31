class PhoneNumberE164 {
  final String e164;           // "+4522334455"
  final String? countryIso2;   // "DK"
  const PhoneNumberE164({required this.e164, this.countryIso2});

  // E.164: "+" then digits; max 15 digits total, leading digit 1-9 (no leading 0 country code).
  static final RegExp _e164 = RegExp(r'^\+[1-9]\d{1,14}$');

  /// Normalize common separators, NBSP, full-width plus, and drop extensions.
  static String _normalizeToCandidate(String input) {
    // Convert full-width plus to ASCII; normalize NBSP to space.
    var s = input.replaceAll('＋', '+').replaceAll('\u00A0', ' ').trim();

    // Build a cleaned candidate: keep only digits and a single leading '+'.
    final out = StringBuffer();
    bool wrotePlus = false;
    for (var i = 0; i < s.length; i++) {
      final ch = s[i];

      // Stop at common extension markers like 'x', 'ext', or ';'
      if (ch == ';' || ch == ',' || ch.toLowerCase() == 'x') break;

      if (!wrotePlus && out.isEmpty && ch == '+') {
        out.write('+');
        wrotePlus = true;
      } else if (ch.codeUnitAt(0) >= 0x30 && ch.codeUnitAt(0) <= 0x39) {
        out.write(ch); // ASCII digits 0-9
      } else {
        // skip separators and other punctuation: spaces, dashes, dots, parentheses, etc.
      }
    }
    return out.toString();
  }

  static PhoneNumberE164? tryParse(String raw, {String? countryIso2}) {
    final candidate = _normalizeToCandidate(raw);
    if (_e164.hasMatch(candidate)) {
      return PhoneNumberE164(
        e164: candidate,
        countryIso2: countryIso2?.toUpperCase(),
      );
    }
    return null;
  }

  Map<String, dynamic> toMap() => {
    'e164': e164,
    if (countryIso2 != null) 'countryIso2': countryIso2,
  };

  factory PhoneNumberE164.fromMap(Map<String, dynamic> map) {
    return PhoneNumberE164(
      e164: map['e164'] as String,
      countryIso2: map['countryIso2'] as String?,
    );
  }
}
