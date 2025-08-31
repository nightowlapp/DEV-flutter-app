class JsonUtility {
  static T? asNum<T>(dynamic value, T Function(num) converter) {
    if (value == null) return null;
    final str = value.toString().trim();
    if (str.isEmpty) return null;
    final numVal = value is num ? value : num.tryParse(str);
    return numVal != null ? converter(numVal) : null;
  }

  static String? nullIfEmpty(String? value) =>
      (value?.trim().isEmpty ?? true) ? null : value;

  static List<String> listStrings(dynamic input) {
    final list = input as List?;
    return list?.whereType<String>().toList() ?? [];
  }

  static Map<String, String> mapStringString(dynamic input) {
    final map = input as Map?;
    if (map == null) return {};
    final result = <String, String>{};
    map.forEach((key, val) {
      if (key is String && val is String) {
        result[key] = val;
      }
    });
    return result;
  }

}