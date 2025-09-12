import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;

import 'package:nightowlcode/shared/constants/colors.dart';
import '../../../shared/constants/enums.dart' as model;
import '../../../shared/constants/icons.dart';
import '../../../shared/constants/styles.dart';
import '../../../shared/reusable/users/language_switcher.dart';

// providers & model
import '../../../data/other_providers.dart';
import 'package:nightowlcode/models/users/user.dart' as model;

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});
  static const routeName = 'settingsScreen';

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  // Local editable fields (default to empty; we hydrate once)
  String _email = '';
  String _firstName = '';
  String _lastName = '';
  String _userName = '';
  DateTime? _birthday;
  String? _phone = '';
  String? _gender; // 'm' | 'f' | 'o'
  bool _shareLocation = true;

  final List<String> _favoriteClubs = const[
    'Bassline',
    'Velvet Room',
    'Neon District',
    'The Observatory',
    'Club Mirage',
  ];

  bool _hydrated = false;

  // ---- HYDRATE FROM PROVIDERS (one-time) ----
  void _maybeHydrate(model.User? appUser, fb.User? fbUser) {
    if (_hydrated) return;
    if (appUser == null && fbUser == null) return;

    SchedulerBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;

        String email = '';
        String userName = '';
        String first = '';
        String last = '';
        DateTime? birth;
        String? phone;
        String? genderLetter;

        double maxDistanceKm;

        if (appUser != null) {
          email = appUser.email;
          userName = appUser.userName;
          first = (appUser.firstName ?? '').trim();
          last = (appUser.lastName ?? '').trim();

          // If no first/last but display name exists, split it
          if (first.isEmpty && last.isEmpty) {
            final dn = appUser.displayFullName.trim();
            if (dn.isNotEmpty) {
              final parts = dn.split(RegExp(r'\s+'));
              first = parts.isNotEmpty ? parts.first : '';
              last = parts.length > 1 ? parts.sublist(1).join(' ') : '';
            }
          }

          birth = appUser.birthDate;
          phone = appUser.phoneNumber?.toString(); // generic string form
          genderLetter = _genderLetterFromEnum(appUser.gender);
          maxDistanceKm = appUser.maxDistanceKm;
          userName = appUser.userName;
        }

        // Fallbacks from Firebase if missing
        email = _firstNonEmpty(email, fbUser?.email, _email);
        if (phone == null || phone.trim().isEmpty) {
          phone = fbUser?.phoneNumber ?? _phone;
        }
        if ((first + last).trim().isEmpty) {
          final dn = (fbUser?.displayName ?? '').trim();
          if (dn.isNotEmpty) {
            final parts = dn.split(RegExp(r'\s+'));
            first = parts.isNotEmpty ? parts.first : '';
            last = parts.length > 1 ? parts.sublist(1).join(' ') : '';
          }
        }

        setState(() {
            _email = email;
            _userName = userName;
            _firstName = first;
            _lastName = last;
            _birthday = birth;
            _phone = phone;
            _gender = genderLetter; // 'm' | 'f' | 'o'
            _hydrated = true;
          }
        );
      }
    );
  }

  // ===== UI =====
  @override
  Widget build(BuildContext context) {
    final appUser = ref.watch(authUserProvider).valueOrNull; // model.User?
    final fbUser = ref.watch(firebaseAuthProvider).currentUser; // Firebase user
    _maybeHydrate(appUser, fbUser);

    final birthdayStr = _birthday == null
      ? ''
      : '${_two(_birthday!.day)}-${_two(_birthday!.month)}-${_birthday!.year}';

    return Scaffold(
      appBar: AppBar(
        backgroundColor: black,
        title: const Text('Settings'),
        centerTitle: true,
        actions: const[
          Padding(
            padding: EdgeInsets.only(right: 8),
            child: LanguageSwitcher(),
          ),
        ],
      ),
      body:
      ListView(children: [
          Column(children: [

            Image.asset('assets/nightowl/logo.png'),
            Image.asset('assets/nightowl/logo2.png'),
              // Image.asset('assets/nightowl/logo3.png'),

            Text('NightOwl', style: Styles.gradientLogo,),
            Text('NightOwl', style: Styles.logoTextGradient,),
            Text('NightOwl', style: Styles.sloganTextGradient,),
            Text('NightOwl', style: Styles.slogan,),
            Text('NightOwl', style: Styles.popShadowLogo,),

            Text('NightOwl', style: Styles.test1,),
            Text('NightOwl', style: Styles.test2,),
            Text('NightOwl', style: Styles.test3,),
            Text('NightOwl', style: Styles.test4,),
            Text('NightOwl', style: Styles.test5,),

            Styles.logoCrazy('NightOwl'),
            Styles.nameOrangeAttemptUpgrade(),
            Styles.nameWhite(),
            Styles.nameOrange(),
            Styles.nameOrange(),



            SizedBox(height: 100,)

            ],)
        ],)

    // ListView(
    //   padding: const EdgeInsets.all(16.0),
    //   children: [
    //     _sectionHeader("Personal"),
    //     _userTile("Username", _userName, onTap: () async {
    //         final updated = await _editTextField(
    //           context,
    //           fieldLabel: "Username",
    //           initial: _userName,
    //         );
    //         if (updated != null) setState(() => _userName = updated);
    //       }
    //     ),
    //     _userTile("Email", _email, onTap: () async {
    //         final updated = await _editTextField(
    //           context,
    //           fieldLabel: "Email",
    //           initial: _email,
    //           keyboardType: TextInputType.emailAddress,
    //         );
    //         if (updated != null) setState(() => _email = updated);
    //       }
    //     ),
    //
    //     Row(
    //       children: [
    //         Expanded(
    //           child: _userTile("First Name", _firstName, onTap: () async {
    //               final updated = await _editTextField(
    //                 context,
    //                 fieldLabel: "First Name",
    //                 initial: _firstName,
    //               );
    //               if (updated != null) setState(() => _firstName = updated);
    //             }
    //           ),
    //         ),
    //         const SizedBox(width: 16),
    //         Expanded(
    //           child: _userTile("Last Name", _lastName, onTap: () async {
    //               final updated = await _editTextField(
    //                 context,
    //                 fieldLabel: "Last Name",
    //                 initial: _lastName,
    //               );
    //               if (updated != null) setState(() => _lastName = updated);
    //             }
    //           ),
    //         ),
    //       ],
    //     ),
    //     Row(
    //       children: [
    //         Expanded(
    //           flex: 2,
    //           child: _userTile("Birthday", birthdayStr, onTap: () async {
    //               final picked = await _pickBirthday(context, _birthday);
    //               if (picked != null) setState(() => _birthday = picked);
    //             }
    //           ),
    //         ),
    //         const SizedBox(width: 10),
    //         Expanded(
    //           flex: 2,
    //           child: _userTile("Phone", _formattedPhone(_phone), onTap: () async {
    //               final updated = await _editTextField(
    //                 context,
    //                 fieldLabel: "Phone",
    //                 initial: _phone ?? '',
    //                 keyboardType: TextInputType.phone,
    //               );
    //               if (updated != null) setState(() => _phone = updated);
    //             }
    //           ),
    //         ),
    //         const SizedBox(width: 10),
    //         Expanded(
    //           flex: 1,
    //           child: _userTile(
    //             "Gender",
    //             _genderLabel(_gender),
    //             icon: maleIcon,
    //             onTap: () async {
    //               final g = await _pickGender(context, _gender);
    //               if (g != null) setState(() => _gender = g);
    //             },
    //           ),
    //         ),
    //       ],
    //     ),
    //     const Divider(color: white, thickness: 0.2, height: 30),
    //
    //     _sectionHeader("Preferences"),
    //     SwitchListTile(
    //       value: _shareLocation,
    //       onChanged: (v) => setState(() => _shareLocation = v),
    //       title: Text("Share location with friends", style: Styles.basicText),
    //       activeColor: owlOrange,
    //       inactiveThumbColor: grey,
    //       inactiveTrackColor: grey.withOpacity(0.3),
    //       contentPadding: const EdgeInsets.symmetric(horizontal: 0),
    //     ),
    //
    //     // ---- your "lonely texts" (left intact) ----
    //     Text("ASBJØRN?!", style: Styles.basicText),
    //     Text("Sms reklamer", style: Styles.basicText),
    //     Text("email promoting.", style: Styles.basicText),
    //     Text("log ud.", style: Styles.basicText),
    //     Text("Delete user.", style: Styles.basicText),
    //     Text("ToS.", style: Styles.basicText),
    //
    //     const Divider(color: owlOrange),
    //
    //     _sectionHeader("Notifications"),
    //     _favoriteClubsSection(_favoriteClubs),
    //
    //     const SizedBox(height: 8),
    //     const Divider(color: owlOrange),
    //
    //     // -------- ALL AVAILABLE DATA (read-only) --------
    //     _sectionHeader("All account data"),
    //     ..._allDataTiles(appUser, fbUser),
    //   ],
    // ),
    );
  }

  /* ========================== READ-ONLY “ALL DATA” ========================== */
  List<Widget> _allDataTiles(model.User? u, fb.User? fbu) {
    String s(Object? v) => v == null ? '' : v.toString();
    String enumS(Enum? e) => e == null ? '' : e.name;
    String dateS(DateTime? d) =>
    d == null ? '' : '${_two(d.day)}-${_two(d.month)}-${d.year} ${_two(d.hour)}:${_two(d.minute)}';
    String setS(Set? set) =>
    set == null || set.isEmpty ? '' : set.map((e) => (e is Enum) ? e.name : e.toString()).join(', ');
    String listS(List? list) =>
    list == null || list.isEmpty ? '' : list.map((e) => e.toString()).join(', ');

    final tiles = <Widget>[];

    // Model.User
    tiles.addAll([
        _kv('id', s(u?.id)),
        _kv('email', s(u?.email)),
        _kv('userName', s(u?.userName)),
        _kv('firstName', s(u?.firstName)),
        _kv('middleName', s(u?.middleName)),
        _kv('lastName', s(u?.lastName)),
        _kv('displayFullName', s(u?.displayFullName)),
        _kv('birthDate', dateS(u?.birthDate)),
        _kv('age', u == null ? '' : u.age.toString()),
        _kv('gender', enumS(u?.gender)),
        _kv('phoneNumber', s(u?.phoneNumber)),
        _kv('biography', s(u?.biography)),
        _kv('profilePictureUrl', s(u?.profilePictureUrl)),
        _kv('homeCountry', s(u?.homeCountry)),
        _kv('homeTown', s(u?.homeTown)),
        _kv('appVersion', s(u?.appVersion)),
        _kv('isVerified', u == null ? '' : u.isVerified.toString()),
        _kv('level', u == null ? '' : u.level.toString()),
        _kv('xp', u == null ? '' : u.xp.toStringAsFixed(0)),
        _kv('preferredVenueTypes', setS(u?.preferredVenueTypes)),
        _kv('maxDistanceKm', u == null ? '' : u.maxDistanceKm.toStringAsFixed(1)),
        _kv('roles', setS(u?.roles)),
        _kv('subscriptionType', enumS(u?.subscriptionType)),
        _kv('platformType', enumS(u?.platformType)),
        _kv('currentPartyStatus', enumS(u?.currentPartyStatus)),
        _kv('createdAt', dateS(u?.createdAt)),
        _kv('updatedAt', dateS(u?.updatedAt)),
      ]);

    // Firebase user (extra diagnostics)
    tiles.addAll([
        const SizedBox(height: 12),
        _sectionHeader('Firebase'),
        _kv('uid', s(fbu?.uid)),
        _kv('email', s(fbu?.email)),
        _kv('emailVerified', fbu == null ? '' : fbu.emailVerified.toString()),
        _kv('phoneNumber', s(fbu?.phoneNumber)),
        _kv('displayName', s(fbu?.displayName)),
        _kv('tenantId', s(fbu?.tenantId)),
        _kv('providerIds', fbu == null ? '' : listS(fbu.providerData.map((p) => p.providerId).toList())),
        _kv('creationTime', dateS(fbu?.metadata.creationTime)),
        _kv('lastSignInTime', dateS(fbu?.metadata.lastSignInTime)),
      ]);

    return tiles;
  }

  Widget _kv(String k, String v) {
    // Show "" literally as empty string (no "Tap to set")
    final shown = v; // already "" if missing
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(flex: 4, child: Text(k, style: Styles.basicText)),
          const SizedBox(width: 8),
          Expanded(flex: 6, child: Text(shown, style: Styles.basicText, textAlign: TextAlign.right)),
        ],
      ),
    );
  }

  /* ========================== UI PARTS ========================== */

  Widget _sectionHeader(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 10, top: 6),
    child: Text(text, style: Styles.basicTextHeader),
  );

  Widget _userTile(
    String label,
    String value, {
      IconData? icon,
      required VoidCallback onTap,
    }) {
    // Show actual or "" (no placeholder text)
    final shown = value.trim();
    return ListTile(
      onTap: onTap,
      title: Text(label, style: Styles.basicText),
      subtitle: Container(
        margin: const EdgeInsets.only(top: 8),
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        decoration: BoxDecoration(
          border: Border.all(color: grey, width: 0.7),
          borderRadius: BorderRadius.circular(22),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null)
            Padding(
              padding: const EdgeInsets.only(right: 6),
              child: Icon(icon, size: 16, color: white),
            ),
            Flexible(
              child: Text(
                shown,
                style: Styles.basicText,
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                softWrap: false,
              ),
            ),
          ],
        ),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 0),
    );
  }

  Widget _favoriteClubsSection(List<String> clubs) {
    final sorted = [...clubs]..sort((a, b) => a.length.compareTo(b.length));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "You are receiving notifications from these ${sorted.length} venue${sorted.length == 1 ? '' : 's'}",
          style: Styles.basicText,
        ),
        const SizedBox(height: 8),
        ...sorted.map(
          (c) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Text("• $c", style: Styles.basicText),
          ),
        ),
      ],
    );
  }

  /* ========================== DIALOGS & PICKERS ========================== */

  Future<String?> _editTextField(
    BuildContext context, {
      required String fieldLabel,
      required String initial,
      TextInputType keyboardType = TextInputType.text,
    }) async {
    final controller = TextEditingController(text: initial);
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1C1C1E),
        title: Text('Edit $fieldLabel'),
        content: TextField(
          controller: controller,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            hintText: fieldLabel,
            border: const OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Save')),
        ],
      ),
    ) ??
      false;

    if (ok) return controller.text.trim();
    return null;
  }

  Future<DateTime?> _pickBirthday(BuildContext context, DateTime? current) async {
    final now = DateTime.now();
    final initial = current ?? DateTime(now.year - 21, now.month, now.day);
    final first = DateTime(1900, 1, 1);
    final last = now;

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: first,
      lastDate: last,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: owlOrange,
              surface: black,
              onSurface: white,
            ),
          ),
          child: child!,
        );
      },
    );
    return picked;
  }

  Future<String?> _pickGender(BuildContext context, String? current) async {
    String sel = (current ?? '').isEmpty ? 'm' : current!;
    return showModalBottomSheet<String>(
      context: context,
      backgroundColor: const Color(0xFF1C1C1E),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _genderTile(ctx, 'm', 'Male', maleIcon, sel),
              _divider(),
              _genderTile(ctx, 'f', 'Female', femaleIcon, sel),
              _divider(),
              _genderTile(ctx, 'o', 'Other', otherGenderIcon, sel),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  Widget _genderTile(
    BuildContext ctx,
    String value,
    String label,
    IconData icon,
    String selected,
  ) {
    final isSelected = value == selected;
    return ListTile(
      leading: Icon(icon, color: white),
      title: Text(label, style: Styles.basicText),
      trailing: isSelected ? const Icon(Icons.check_circle, color: owlOrange) : const SizedBox.shrink(),
      onTap: () => Navigator.pop(ctx, value),
    );
  }

  Widget _divider() => const Divider(color: grey, height: 0);

  /* ========================== HELPERS ========================== */

  static String _two(int v) => v.toString().padLeft(2, '0');

  static String _formattedPhone(String? phone) {
    if (phone == null || phone.trim().isEmpty) return '';
    final p = phone.replaceAll(RegExp(r'\s+'), '');
    if (p.length <= 3) return p;
    final head = p.substring(0, 3);
    final rest = p.substring(3);
    return '$head ${_pairify(rest)}';
  }

  static String _pairify(String s) {
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i != 0 && i % 2 == 0) buf.write(' ');
      buf.write(s[i]);
    }
    return buf.toString();
  }

  static String _genderLabel(String? g) {
    switch ((g ?? '').toLowerCase()) {
      case 'm':
        return 'Male';
      case 'f':
        return 'Female';
      case 'o':
        return 'Other';
      default:
      return '';
    }
  }
  static IconData? _genderIcon(model.Gender g) {
    switch (g){
      case model.Gender.female: return femaleIcon;
      case model.Gender.male: return maleIcon;
      case model.Gender.other: return otherGenderIcon;
    }
  }

  static String _firstNonEmpty(String a, String? b, String? c) {
    if (a.trim().isNotEmpty) return a;
    if ((b ?? '').trim().isNotEmpty) return b!.trim();
    if ((c ?? '').trim().isNotEmpty) return c!.trim();
    return '';
  }

  static String _genderLetterFromEnum(model.Gender g) {
    switch (g) {
      case model.Gender.male:
        return 'm';
      case model.Gender.female:
        return 'f';
      default:
      return 'o';
    }
  }
}
