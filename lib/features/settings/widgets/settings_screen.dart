import 'package:flutter/material.dart';
import 'package:nightowlcode/shared/constants/colors.dart';

import '../../../shared/reusable/users/language_switcher.dart';

/// Standalone Settings screen widget with random default values.
/// Drop this into your app and navigate to `SettingsScreen()`.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}


//TODO When uploading images:
//
// // after picking file...
// final uid = ref.read(firebaseAuthProvider).currentUser!.uid;
// final file = File(pickedPath);
//
// // start immediately; don't block UI
// unawaited(() async {
// final url = await ref.read(storageRepositoryProvider)
//     .uploadUserProfilePicture(uid: uid, file: file);
// ref.read(signUpDraftProvider.notifier).setRemotePhoto(url);
// }());
//
// // store local path too (for quick previews)
// ref.read(signUpDraftProvider.notifier).setLocalPhoto(pickedPath);


/* ========================== THEME & TEXT ========================== */


const _kTextStyleH3 = TextStyle(
  fontSize: 18,
  fontWeight: FontWeight.w600,
  color: white,
);

const _kTextStyleH3ToP1 = TextStyle(
  fontSize: 14,
  fontWeight: FontWeight.w600,
  color: white,
);

const _kTextStyleP1 = TextStyle(
  fontSize: 14,
  fontWeight: FontWeight.w400,
  color: white,
);

class _SettingsScreenState extends State<SettingsScreen> {
  // Random default values
  String _email = 'alex.rivera@example.com';
  String _firstName = 'Alex';
  String _lastName = 'Rivera';
  DateTime? _birthday = DateTime(1997, 7, 14);
  String? _phone = '4512345678';
  String? _gender = 'm'; // 'm', 'f', 'o'
  bool _shareLocation = true;
  final List<String> _favoriteClubs = const [
    'Bassline',
    'Velvet Room',
    'Neon District',
    'The Observatory',
    'Club Mirage',
  ];

  IconData get _genderIcon {
    switch ((_gender ?? '').toLowerCase()) {
      case 'm':
        return Icons.male_rounded;
      case 'f':
        return Icons.female_rounded;
      default:
        return Icons.transgender_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final birthdayStr = _birthday == null
        ? ''
        : '${_two(_birthday!.day)}-${_two(_birthday!.month)}-${_birthday!.year}';

    return Scaffold(
        appBar: AppBar(
          backgroundColor: black,
          title: const Text('Settings'),
          centerTitle: true,
          actions: [
            const Padding(
              padding: EdgeInsets.only(right: 8),
              child: LanguageSwitcher(), // your widget
            ),
          ],
        ),

      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _sectionHeader("Personal"),
          _userTile(
            "Email",
            _email,
            onTap: () async {
              final updated = await _editTextField(
                context,
                fieldLabel: "Email",
                initial: _email,
                keyboardType: TextInputType.emailAddress,
              );
              if (updated != null) setState(() => _email = updated);
            },
          ),
          Row(
            children: [
              Expanded(
                child: _userTile(
                  "First Name",
                  _firstName,
                  onTap: () async {
                    final updated = await _editTextField(
                      context,
                      fieldLabel: "First Name",
                      initial: _firstName,
                    );
                    if (updated != null) setState(() => _firstName = updated);
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _userTile(
                  "Last Name",
                  _lastName,
                  onTap: () async {
                    final updated = await _editTextField(
                      context,
                      fieldLabel: "Last Name",
                      initial: _lastName,
                    );
                    if (updated != null) setState(() => _lastName = updated);
                  },
                ),
              ),
            ],
          ),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: _userTile(
                  "Birthday",
                  birthdayStr,
                  onTap: () async {
                    final picked = await _pickBirthday(context, _birthday);
                    if (picked != null) setState(() => _birthday = picked);
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: _userTile(
                  "Phone",
                  _formattedPhone(_phone),
                  onTap: () async {
                    final updated = await _editTextField(
                      context,
                      fieldLabel: "Phone",
                      initial: _phone ?? '',
                      keyboardType: TextInputType.phone,
                    );
                    if (updated != null) setState(() => _phone = updated);
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 1,
                child: _userTile(
                  "Gender",
                  _genderLabel(_gender),
                  icon: _genderIcon,
                  onTap: () async {
                    final g = await _pickGender(context, _gender);
                    if (g != null) setState(() => _gender = g);
                  },
                ),
              ),
            ],
          ),
          const Divider(color: white, thickness: 0.2, height: 30),
          _sectionHeader("Preferences"),
          SwitchListTile(
            value: _shareLocation,
            onChanged: (v) => setState(() => _shareLocation = v),
            title:
            const Text("Share location with friends", style: _kTextStyleP1),
            activeColor: owlOrange,
            inactiveThumbColor: grey,
            inactiveTrackColor: grey.withOpacity(0.3),
            contentPadding: const EdgeInsets.symmetric(horizontal: 0),

          ),
          const Text("ASBJØRN?!", style: _kTextStyleP1),
          const Text("Sms reklamer", style: _kTextStyleP1),
          const Text("email promovering.", style: _kTextStyleP1),
          const Text("log ud.", style: _kTextStyleP1),
          const Text("Delete user.", style: _kTextStyleP1),
          const Text("ToS.", style: _kTextStyleP1),

          const Divider(color: owlOrange),
          _sectionHeader("Notifications"),
          _favoriteClubsSection(_favoriteClubs),
          const SizedBox(height: 8),
          const Divider(color: owlOrange)        ],
      ),
    );
  }

  /* ========================== UI PARTS ========================== */

  Widget _sectionHeader(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Text(text, style: _kTextStyleH3.copyWith(color: owlOrange)),
  );

  Widget _userTile(
      String label,
      String value, {
        IconData? icon,
        required VoidCallback onTap,
      }) {
    final shown = value.trim().isEmpty ? 'Tap to set' : value.trim();
    final shownColor = value.trim().isEmpty ? grey : white;

    return ListTile(
      onTap: onTap,
      title: Text(label, style: _kTextStyleH3ToP1),
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
                style: _kTextStyleP1.copyWith(color: shownColor),
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
          style: _kTextStyleP1,
        ),
        const SizedBox(height: 8),
        ...sorted.map(
              (c) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Text("• $c", style: _kTextStyleP1.copyWith(color: white)),
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
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Save'),
          ),
        ],
      ),
    ) ??
        false;

    if (ok) {
      return controller.text.trim();
    }
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
              _genderTile(ctx, 'm', 'Male', Icons.male_rounded, sel),
              _divider(),
              _genderTile(ctx, 'f', 'Female', Icons.female_rounded, sel),
              _divider(),
              _genderTile(ctx, 'o', 'Other', Icons.transgender_rounded, sel),
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
      title: Text(label, style: _kTextStyleP1),
      trailing: isSelected
          ? const Icon(Icons.check_circle, color: owlOrange)
          : const SizedBox.shrink(),
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
}
