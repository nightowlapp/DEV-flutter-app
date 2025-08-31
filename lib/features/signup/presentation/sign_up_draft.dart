import 'package:nightowlcode/shared/constants/enums.dart';

class SignUpDraft { // TODO Photo is only if login with google (maybe apple?)
  final DateTime? birthdate;
  final String? username;
  final Gender? gender;
  final String? email;
  final String? localPhotoPath;
  final String? remotePhotoUrl;
  final bool acceptedTos;

  const SignUpDraft({
    this.birthdate,
    this.username,
    this.gender,
    this.email,
    this.localPhotoPath,
    this.remotePhotoUrl,
    this.acceptedTos = false,
  });

  bool get hasRemotePhoto => (remotePhotoUrl ?? '').isNotEmpty;

  SignUpDraft copyWith({
    DateTime? birthdate,
    String? username,
    Gender? gender,
    String? email,
    String? localPhotoPath,
    String? remotePhotoUrl,
    bool? acceptedTos,
  }) {
    return SignUpDraft(
      birthdate: birthdate ?? this.birthdate,
      username: username ?? this.username,
      gender: gender ?? this.gender,
      email: email ?? this.email,
      localPhotoPath: localPhotoPath ?? this.localPhotoPath,
      remotePhotoUrl: remotePhotoUrl ?? this.remotePhotoUrl,
      acceptedTos: acceptedTos ?? this.acceptedTos,
    );
  }

  Map<String, dynamic> toJson() => {
    'birthdate': birthdate?.toIso8601String(),
    'username': username,
    'gender': gender?.name,
    'email': email,
    'localPhotoPath': localPhotoPath,
    'remotePhotoUrl': remotePhotoUrl,
    'acceptedTos': acceptedTos,
  }..removeWhere((_, v) => v == null);

  factory SignUpDraft.fromJson(Map<String, dynamic> j) => SignUpDraft(
    birthdate: (j['birthdate'] as String?) != null
        ? DateTime.tryParse(j['birthdate'] as String)
        : null,
    username: j['username'] as String?,
    gender: j['gender'] != null
        ? Gender.values.firstWhere(
          (g) => g.name == j['gender'],
      orElse: () => Gender.other,
    )
        : null,
    email: j['email'] as String?,
    localPhotoPath: j['localPhotoPath'] as String?,
    remotePhotoUrl: j['remotePhotoUrl'] as String?,
    acceptedTos: (j['acceptedTos'] as bool?) ?? false,
  );
}
