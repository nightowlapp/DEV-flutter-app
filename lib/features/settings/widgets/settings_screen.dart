import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:go_router/go_router.dart';

import 'package:nightowlcode/shared/constants/colors.dart';
import 'package:nightowlcode/shared/constants/values.dart';
import 'package:nightowlcode/shared/reusable/ui/owl_snack.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/platform_config.dart';
import '../../../data/repositories/users/settings/personal_settings_repository.dart';
import '../../../data/repositories/users/settings/preferences_repository.dart';
import '../../../data/services/location/location_service.dart';
import '../../../models/users/phone_number.dart' as phone;
import '../../../shared/constants/country_code.dart';
import '../../../shared/constants/enums.dart';
import '../../../shared/constants/icons.dart';
import '../../../shared/constants/styles.dart';
import '../../../shared/reusable/ui/buttons.dart';
import '../../../shared/reusable/ui/location_indicator.dart';
import '../../../shared/reusable/ui/owl_popup.dart';
import '../../../shared/reusable/users/language_switcher.dart';

// providers & model
import '../../../data/providers/other_providers.dart';
import 'package:nightowlcode/models/users/user.dart' as model;

import '../../../shared/utility/european_location_mapper.dart';
import '../../../shared/utility/phone_country_code.dart';
import '../../../shared/utility/utility.dart';
import '../../signup/widgets/favorite_venues_section.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});
  static const routeName = 'settingsScreen';

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  // Local editable fields (UI-only for now)
  String _email = '';
  String _firstName = '';
  String _middleName = '';
  String _lastName = '';
  String _userName = '';

  DateTime? _birthday;
  phone.PhoneNumber? _phoneObj;
  String? _gender; // 'm' | 'f' | 'o'

  // bool _shareLocation = true;
  bool _hydrated = false;

  static const double _minKm = 5;
  static const double _maxKm = 150;

  // Use enums.* for venue types
  Set<VenueType> _prefTypes = <VenueType>{};
  double _maxDistanceKm = 50;

  List<VenueType> get _allVenueTypes =>
  VenueType.values.where((t) => t != VenueType.unknown).toList();

  final _mapper = EuropeanLocationMapper();
  // final Map<String, dynamic>? phoneMap = (json['phone'] ?? json['phone_number']) as Map<String, dynamic>?;


  void _kickoffBestEffortHomeAutofill(model.User? appUser) {
    if (appUser == null) return;
    final hasCountry = (appUser.homeCountryCode?.trim().isNotEmpty ?? false);
    final hasTown = (appUser.homeTown?.trim().isNotEmpty ?? false);
    if (hasCountry && hasTown) return;
    if (appUser.homeLocationLocked) return; // never override manual

    // Run after first layout; do NOT await -> won't block UI
    SchedulerBinding.instance.addPostFrameCallback((_) {
        _bestEffortHomeAutofill(); // intentionally not awaited
      }
    );
  }

  Future<void> _bestEffortHomeAutofill() async {
    try {
      final uid = ref.read(firebaseAuthProvider).currentUser?.uid;
      if (uid == null) return;

      final loc = await LocationService().lastKnownOrCurrent();
      if (loc == null) return;

      final r = _mapper.resolve(
        lat: loc.lat,
        lon: loc.lng,
        maxCityFallbackKm: double.infinity,
      );
      if (r == null || r.countryCode == null || r.cityName == null) return;

      await ref.read(personalSettingsRepositoryProvider).setHomeLocation(
        uid: uid,
        countryIso2: r.countryCode!,            // <— was countryIso2
        town: r.cityName!.toLowerCase(),
        locked: false,
        lastLat: loc.lat,                       // gets written to locations/{uid}
        lastLon: loc.lng,
      );

      // Refresh local state from DB if still mounted
      if (mounted) ref.invalidate(authUserProvider);
    }
    catch (_) {
      // silent best-effort
    }
  }

  String _prefTypesSummary() {
    final total = _allVenueTypes.length;
    final selected = _prefTypes.length;
    return (selected == total) ? 'All' : '$selected';
  }
  // Hydrate once from providers
  void _maybeHydrate(model.User? appUser, fb.User? fbUser) {
    if (_hydrated) return;
    if (appUser == null && fbUser == null) return;
    phone.PhoneNumber? phoneObj = appUser?.phoneNumber;

    SchedulerBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;

        // locals
        String email = '';
        String userName = '';
        String first = '';
        String middle = '';
        String last = '';
        DateTime? birth;
        String? phoneStr;
        String? genderLetter;

        if (phoneObj == null) {
          final e164 = fbUser?.phoneNumber;
          if (e164 != null && e164.trim().isNotEmpty) {
            phoneObj = _fromE164(e164, iso2Hint: appUser?.homeCountryCode);
          }
        }

        // Preferred types & distance (from appUser if present)
        _prefTypes = {
          if (appUser != null)
          ...appUser.preferredVenueTypes.where((t) => t != VenueType.unknown),
        };
        if (_prefTypes.isEmpty) _prefTypes = {..._allVenueTypes};

        _maxDistanceKm = (appUser?.maxDistanceKm ?? 50).clamp(_minKm, _maxKm).toDouble();

        if (appUser != null) {
          email = appUser.email;
          userName = appUser.userName;

          first = (appUser.firstName ?? '').trim();
          middle = (appUser.middleName ?? '').trim();
          last = (appUser.lastName ?? '').trim();

          birth = appUser.birthDate;
          _phoneObj = appUser.phoneNumber;
          phoneStr = _phoneObj?.e164;

          genderLetter = _genderLetterFromEnum(appUser.gender);

          if (first.isEmpty && last.isEmpty) {
            final dn = appUser.displayFullName.trim();
            if (dn.isNotEmpty) {
              final parts = dn.split(RegExp(r'\s+'));
              first = parts.isNotEmpty ? parts.first : '';
              last = parts.length > 1 ? parts.sublist(1).join(' ') : '';
            }
          }
        }

        // Fallbacks from Firebase Auth
        email = _firstNonEmpty(email, fbUser?.email, _email);
// phoneNumber =
        // If phone still empty, try FB user
        if ((phoneStr ?? '').trim().isEmpty) {
          phoneStr = fbUser?.phoneNumber ?? _phoneObj?.e164;
        }

        // If still no names, try FB displayName
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
            _middleName = middle;
            _lastName = last;
            _birthday = birth;
            _phoneObj = phoneObj;
            _gender = genderLetter;
            _hydrated = true;
          }
        );
      }
    );

    _kickoffBestEffortHomeAutofill(appUser);
  }

  @override
  Widget build(BuildContext context) {
    final appUser = ref.watch(authUserProvider).valueOrNull; // model.User?
    final fbUser = ref.watch(firebaseAuthProvider).currentUser; // Firebase user
    _maybeHydrate(appUser, fbUser);
    final g = _gender.asGender;

    final birthdayStr = _birthday == null
      ? ''
      : '${_two(_birthday!.day)}-${_two(_birthday!.month)}-${_birthday!.year}';

    final countryName = _mapper.countries[(appUser?.homeCountryCode ?? '').toUpperCase()]?.name ?? '';

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
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          // ---------------- PERSONAL ----------------
          Row(
            children: [
              Text('Personal', style: Styles.basicTextHeader),
              const Spacer(),
              // LocationIndicator(
              //   enabledByUser: _shareLocation,
              //   onToggleRequested: () => setState(() => _shareLocation = !_shareLocation),
              // ),
            ],
          ),

          if (appUser?.isVerified == true)
          _kv('Verified', 'Yes'),

          if(appUser!.roles.length > 1 || !appUser.roles.contains(UserRole.user))
          _kv('Roles', appUser.roles.map((e) => e.name).join(', ')),

          if(appUser?.subscriptionType.name != SubscriptionTypesUser.free.name)
          _kv('Subscription', appUser?.subscriptionType.name ?? ''),

          if(appUser?.isVerified == true)
          _kv('Verified', (appUser?.isVerified ?? false).toString()),

          _userTile("Username", _userName, onTap: () async {
              final v = await _editUsernameSheet(context, _userName);
              if (v != null) await _onEditUsernameWithValue(v);
            }
          ),

          _userTile("Email", _email, onTap: () async {
              final v = await _editTextSheet(
                context,
                title: "Email",
                initial: _email,
                keyboardType: TextInputType.emailAddress,
                validator: _emailValidator,
              );
              if (v != null) await _saveEmail(v);   // 👈 persist
            }
          ),

          _userTile("First Name", _firstName, onTap: () async {
              final v = await _editTextSheet(context, title: "First Name", initial: _firstName, validator: _nonEmpty);
              if (v != null) await _saveNames(first: v);
            }
          ),

          _userTile("Middle Name", _middleName, onTap: () async {
              final v = await _editTextSheet(context, title: "Middle Name", initial: _middleName);
              if (v != null) await _saveNames(middle: v);
            }
          ),

          _userTile("Last Name", _lastName, onTap: () async {
              final v = await _editTextSheet(context, title: "Last Name", initial: _lastName, validator: _nonEmpty);
              if (v != null) await _saveNames(last: v);
            }
          ),

          _userTile(
            "Phone",
            _phoneObj?.nsn ?? '',
            valueLeading: _phoneValueLeading(_phoneObj), // 👈 flag + +code
            onTap: () async {
              final picked = await _editPhoneSheet(context, _phoneObj);
              if (picked == null) return;
              final uid = ref.read(firebaseAuthProvider).currentUser?.uid;
              if (uid == null) return;
              await ref.read(userRepositoryProvider).updateNamesAndPhone(uid: uid, phone: picked);
              if (!mounted) return;
              setState(() => _phoneObj = picked);
              OwlSnack.show(context, title: 'Phone saved', variant: OwlSnackVariant.success);
            },
          ),

          _userTile("Birthday", birthdayStr, enabled: false),

          _userTile(
            "Gender",
            g.label,                    // from your GenderX extension
            valueIcon: g.icon,          // from your GenderX extension
            enabled: false,
          ),

          _kvClickable(
            'Home country',
            countryName.isEmpty ? 'Set' : '$countryName',
            // | ${(appUser!.homeCountryCode ?? '').toUpperCase()}',
            onTap: () async {
              final picked = await _pickHomeLocationBottomSheet(appUser);
              if (picked == true && mounted) {
                OwlSnack.show(context, title: 'Home location saved', variant: OwlSnackVariant.success);
                ref.invalidate(authUserProvider);
              }
            },
          ),
          _kvClickable(
            'Home town',
            (appUser?.homeTown ?? '').trim().isEmpty
              ? 'Set'
              : Utility.formatString(appUser!.homeTown!),
            onTap: () async {
              final picked = await _pickHomeLocationBottomSheet(appUser);
              if (picked == true && mounted) {
                OwlSnack.show(context, title: 'Home location saved', variant: OwlSnackVariant.success);
                ref.invalidate(authUserProvider);
              }
            },
          ),

          const Divider(color: owlPurple, height: 30),

          // ---------------- PREFERENCES ----------------
          _sectionHeader("Preferences"),

          // Text('Explore', style: Styles.basicTextHeader.copyWith(fontWeight: FontWeight.w600),), // Todo activate when needed.
          // SwitchListTile(
          //   value: _shareLocation,
          //   onChanged: (v) => setState(() => _shareLocation = v),
          //   title: Text("Share location with friends", style: Styles.basicText),
          //   activeColor: owlPurple,
          //   inactiveThumbColor: grey,
          //   inactiveTrackColor: grey.withOpacity(0.3),
          //   contentPadding: const EdgeInsets.symmetric(horizontal: 0),
          // ),
          // Show a few preference fields from model
          if (appUser != null) ...[
            _kvClickable(
              'Preferred venue types',
              _prefTypesSummary(),
              onTap: () async {
                final picked = await _pickPreferredTypes(context, _prefTypes);
                if (picked != null) {
                  setState(() => _prefTypes = picked);
                  await _persistPreferredTypes(picked);
                }
              },
            ),

            _kvClickable(
              'Max venue distance (km)',
              _maxDistanceKm.toStringAsFixed(0),
              onTap: () async {
                final picked = await _pickMaxDistance(context, _maxDistanceKm);
                if (picked != null) {
                  setState(() => _maxDistanceKm = picked);
                  await _persistMaxDistance(picked);
                }
              },
            ),

            // Text('Map', style: Styles.basicTextHeader.copyWith(fontWeight: FontWeight.w600),),

            // Text('Social', style: Styles.basicTextHeader.copyWith(fontWeight: FontWeight.w600),),


            // Text('Profile', style: Styles.basicTextHeader.copyWith(fontWeight: FontWeight.w600),),

          ],

          const Divider(color: owlPurple, height: 30),

          // ---------------- NOTIFICATIONS ----------------
          _sectionHeader("Notifications"),
          const FavoriteVenuesSection(),

          const Divider(color: owlPurple, height: 30),

          // ---------------- APP DATA ----------------
          _sectionHeader("Account Data"),
          _kv('App version', appUser?.appVersion ?? ''),
          _kv('Account Creation', _dateS(appUser?.createdAt)),

          const Divider(color: owlPurple, height: 30),

          // ---------------- OTHER (BOTTOM-LEFT) ----------------
          // _sectionHeader("Other"),
          const _SettingsActionsRow(
            onOpenTos: _openTermsOfServiceStatic,
            onLogout: _onLogoutStatic,
            onDeleteAccount: _onDeleteAccountStatic,
          ),
        ],
      ),
    );
  }

  /* ---------- Small UI helpers ---------- */

  String? _emailValidator(String v) {
    final ok = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(v);
    return ok ? null : 'Enter a valid email';
  }
  String? _nonEmpty(String v) => v.trim().isEmpty ? 'Required' : null;

  Widget _sectionHeader(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 8, top: 0),
    child: Text(text, style: Styles.basicTextHeader),
  );

  Widget _kv(String k, String v) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(flex: 4, child: Text(k, style: Styles.basicText)),
          const SizedBox(width: 8),
          Expanded(
            flex: 6,
            child: Text(
              v,
              style: Styles.basicText,
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  Widget _userTile(
    String label,
    String value, {
      IconData? icon,
      IconData? valueIcon,
      Color? valueIconColor,
      bool valueIconOnRight = false,
      Widget? valueLeading,           // 👈 NEW
      VoidCallback? onTap,
      bool enabled = true,
    }) {
    final shown = value.trim().isEmpty ? 'Tap to set' : value.trim();
    final textColor = enabled ? white : greyLighter;

    Widget valueIconWidget() => Icon(
      valueIcon,
      size: 16,
      color: (valueIconColor ?? textColor).withOpacity(enabled ? 1 : 0.7),
    );

    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 16, color: enabled ? white : grey),
                  const SizedBox(width: 6),
                ],
                Text(label, style: Styles.basicText),
                if (!enabled) ...[
                  const SizedBox(width: 8),
                  const Icon(Icons.lock, size: 14, color: grey),
                ],
                const Spacer(),
              ],
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: enabled ? grey : grey.withOpacity(0.5),
                  width: 0.8,
                ),
              ),
              child: Row(
                children: [
                  if (valueLeading != null) ...[
                    valueLeading,
                    const SizedBox(width: 8),
                  ],
                  if (valueIcon != null && !valueIconOnRight) ...[
                    valueIconWidget(),
                    const SizedBox(width: 8),
                  ],
                  Expanded(
                    child: Text(
                      shown,
                      style: Styles.basicText.copyWith(color: textColor),
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                  if (valueIcon != null && valueIconOnRight) ...[
                    const SizedBox(width: 8),
                    valueIconWidget(),
                  ],
                  const SizedBox(width: 8),
                  Icon(
                    onTap != null && enabled
                      ? Icons.chevron_right
                      : Icons.do_not_disturb_on_outlined,
                    size: 18,
                    color: enabled ? grey : grey.withOpacity(0.6),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  CountryCode? _countryFromIso2(String? iso2) {
    if (iso2 == null || iso2.trim().isEmpty) return null;
    final lower = iso2.trim().toLowerCase();
    for (final c in CountryCode.values) {
      if (c.name.toLowerCase() == lower) return c;
    }
    return null;
  }

  Widget? _phoneValueLeading(phone.PhoneNumber? pn) {
    final code = _countryFromIso2(pn?.iso2);
    if (code == null) return null;
    final info = PhoneCountryCode(code);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (info.flagImage != null)
        SizedBox(width: 22, height: 16, child: FittedBox(fit: BoxFit.cover, child: info.flagImage)),
        if (info.flagImage != null) const SizedBox(width: 6),

        // +45 (for example)
        Text(info.phoneCode ?? '', style: Styles.basicText),

        const SizedBox(width: 6),

        // (DK) on the right side of +code
        Text(
          '(${code.name.toUpperCase()})',
          style: Styles.basicText.copyWith(color: greyLighter),
        ),
      ],
    );
  }

  /* ---------- Dialogs & pickers ---------- */

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
          decoration: const InputDecoration(border: OutlineInputBorder()),
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

    if (ok) return controller.text.trim();
    return null;
  }

  Future<String?> _editTextSheet(
    BuildContext context, {
      required String title,
      required String initial,
      String? hint,
      TextInputType keyboardType = TextInputType.text,
      String? Function(String value)? validator,
      int? maxLength,
    }) async {
    final controller = TextEditingController(text: initial);
    String error = '';
    bool changed = false;

    bool validNow(String v) {
      final msg = validator?.call(v) ?? '';
      error = msg ?? '';
      return (msg ?? '').isEmpty;
    }

    return await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1C1C1E),
      builder: (ctx) {
        return StatefulBuilder(builder: (ctx, setSt) {
            final bottom = MediaQuery.of(ctx).viewInsets.bottom;
            final v = controller.text.trim();
            final isValid = validNow(v);

            return AnimatedPadding(
              padding: EdgeInsets.only(bottom: bottom),
              duration: const Duration(milliseconds: 180),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Text(title, style: Styles.basicTextHeader),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.close, color: grey),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: controller,
                      maxLength: maxLength,
                      keyboardType: keyboardType,
                      decoration: InputDecoration(
                        hintText: hint,
                        counterText: '',
                        border: const OutlineInputBorder(),
                        errorText: (changed && !isValid) ? (error.isEmpty ? 'Invalid' : error) : null,
                      ),
                      onChanged: (_) => setSt(() => changed = true),
                      autofocus: true,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OwlButton(
                            label: 'Cancel',
                            onPressed: () => Navigator.pop(ctx),
                            backgroundColor: transparent,
                            textColor: grey,
                            borderColor: grey,
                            borderRadius: borderRadiusSmall,
                            fullWidth: true,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: OwlButton(
                            label: 'Save',
                            onPressed: (!changed || !isValid) ? null : () {
                                Navigator.pop(ctx, controller.text.trim());
                              },
                            backgroundColor: owlPurple,
                            textColor: white,
                            borderColor: transparent,
                            borderRadius: borderRadiusSmall,
                            fullWidth: true,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }
        );
      },
    );
  }

  /* ---------- Helpers ---------- */

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

  static String _firstNonEmpty(String a, String? b, String? c) {
    if (a.trim().isNotEmpty) return a;
    if ((b ?? '').trim().isNotEmpty) return b!.trim();
    if ((c ?? '').trim().isNotEmpty) return c!.trim();
    return '';
  }

  static String _genderLetterFromEnum(Gender g) {
    switch (g) {
      case Gender.male:
        return 'm';
      case Gender.female:
        return 'f';
      default:
      return 'o';
    }
  }

  static String _dateS(DateTime? d) {
    if (d == null) return '';
    return '${_two(d.day)}-${_two(d.month)}-${d.year} ${_two(d.hour)}:${_two(d.minute)}';
  }

  /* ---------- Actions ---------- */

  Future<void> _confirmAndLogout() async {
    final ok = await _confirmLogoutDialog();
    if (!ok) return;
    await _onLogout();
  }

  Future<void> _confirmAndDeleteAccount() async {
    final ok = await _confirmDeleteDialog();
    if (!ok) return;
    await _onDeleteAccount();
  }

  Future<void> _onLogout() async {
    final rootCtx = Navigator.of(context, rootNavigator: true).context;
    try {
      await ref.read(firebaseAuthProvider).signOut();
      if (!mounted) return;
      OwlSnack.show(rootCtx, title: 'Successfully logged out', variant: OwlSnackVariant.success);
      context.goNamed('loginOrCreate');
    }
    catch (e) {
      if (!mounted) return;
      OwlSnack.show(rootCtx, title: 'Log out failed', variant: OwlSnackVariant.warning);
    }
  }

  Future<void> _onDeleteAccount() async {
    final user = ref.read(firebaseAuthProvider).currentUser;
    if (user == null) {
      if (!mounted) return;
      OwlSnack.show(context, title: 'No user to delete', variant: OwlSnackVariant.warning);
      return;
    }

    try {
      await user.delete(); // may require recent login
      // Also sign out to fully clear local state
      await ref.read(firebaseAuthProvider).signOut();

      if (!mounted) return;
      OwlSnack.show(context, title: 'Account deleted', variant: OwlSnackVariant.success);
      context.goNamed('loginOrCreate');
    }
    on fb.FirebaseAuthException catch (e) {
      if (!mounted) return;
      final msg = e.code == 'requires-recent-login'
        ? 'Please reauthenticate and try again.'
        : (e.message ?? 'Delete failed');
      OwlSnack.show(context, title: msg, variant: OwlSnackVariant.error);
    }
    catch (e) {
      if (!mounted) return;
      OwlSnack.show(context, title: 'Delete failed: $e', variant: OwlSnackVariant.error);
    }
  }

  Future<void> _openTermsOfService() async {
    if (!mounted) return;
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1C1C1E),
        title: const Text('Terms of Service'),
        content: const Text(
          'Your ToS content or navigation goes here.\n'
          'Replace this dialog with a route to your ToS screen if you have one.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  // Static proxies for the bottom widget (so it stays const-constructible)
  static void _openTermsOfServiceStatic(BuildContext context) {
    final state = context.findAncestorStateOfType<_SettingsScreenState>();
    state?._openTermsOfService();
  }

  static void _onLogoutStatic(BuildContext context) {
    final state = context.findAncestorStateOfType<_SettingsScreenState>();
    state?._confirmAndLogout();
  }

  static void _onDeleteAccountStatic(BuildContext context) {
    final state = context.findAncestorStateOfType<_SettingsScreenState>();
    state?._confirmAndDeleteAccount();
  }

  Future<bool> _confirmLogoutDialog() async {
    return await showDialog<bool>(
      context: context,
      barrierDismissible: true, // tap outside == cancel
      builder: (ctx) => OwlPopup( //TODO when loggin out it needs to delete all cached stuff.
        title: 'Log out?',
        children: [
          Text('You will be returned to the start screen.', style: Styles.popupText),
          SizedBox(height: PlatformConfig.height(ctx) * 0.02),
          Row(
            children: [
              // Cancel (purple outline)
              Expanded(
                child: SizedBox(
                  height: PlatformConfig.height(ctx) * 0.04,
                  child: OwlButton(
                    label: 'Cancel',
                    onPressed: () => Navigator.of(ctx).pop(false),
                    backgroundColor: transparent,
                    textColor: owlPurple,
                    borderColor: owlPurple,
                    borderRadius: borderRadiusSmall,
                    fullWidth: true,
                  ),
                ),
              ),
              SizedBox(width: PlatformConfig.width(ctx) * 0.1),
              // Confirm (red outline)
              Expanded(
                child: SizedBox(
                  height: PlatformConfig.height(ctx) * 0.04,
                  child: OwlButton(
                    label: 'Log out',
                    onPressed: () => Navigator.of(ctx).pop(true),
                    backgroundColor: transparent,
                    textColor: red,
                    borderColor: red,
                    borderRadius: borderRadiusSmall,
                    fullWidth: true,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    ) ?? false; // outside tap returns null -> treat as cancel
  }

  Future<bool> _confirmDeleteDialog() async {
    return await showDialog<bool>(
      context: context,
      barrierDismissible: true, // tap outside == cancel
      builder: (ctx) => OwlPopup(
        title: 'Delete account?',
        children: [
          Text('This action is permanent and cannot be undone.', style: Styles.popupText),
          SizedBox(height: PlatformConfig.height(ctx) * 0.02),
          Row(
            children: [
              // Cancel (purple outline)
              Expanded(
                child: SizedBox(
                  height: PlatformConfig.height(ctx) * 0.04,
                  child: OwlButton(
                    label: 'Cancel',
                    onPressed: () => Navigator.of(ctx).pop(false),
                    backgroundColor: transparent,
                    textColor: owlPurple,
                    borderColor: owlPurple,
                    borderRadius: borderRadiusSmall,
                    fullWidth: true,
                  ),
                ),
              ),
              SizedBox(width: PlatformConfig.width(ctx) * 0.1),
              // Confirm (red outline)
              Expanded(
                child: SizedBox(
                  height: PlatformConfig.height(ctx) * 0.04,
                  child: OwlButton(
                    label: 'Delete',
                    onPressed: () => Navigator.of(ctx).pop(true),
                    backgroundColor: transparent,
                    textColor: red,
                    borderColor: red,
                    borderRadius: borderRadiusSmall,
                    fullWidth: true,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    ) ?? false; // outside tap returns null -> treat as cancel
  }

  Future<Set<VenueType>?> _pickPreferredTypes(
    BuildContext context,
    Set<VenueType> current,
  ) async {
    return await showDialog<Set<VenueType>>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) {
        Set<VenueType> sel = {...current};
        final all = _allVenueTypes;

        void toggle(VenueType t, void Function(void Function()) setSt) {
          setSt(() {
              if (sel.contains(t)) {
                // prevent removing the last remaining selection
                if (sel.length == 1) return;
                sel.remove(t);
              }
              else {
                sel.add(t);
              }
            }
          );
        }

        return StatefulBuilder(
          builder: (ctx, setSt) => OwlPopup(
            title: 'Preferred venue types',
            children: [
              Row(
                children: [
                  TextButton(
                    onPressed: () => setSt(() => sel = {...all}),
                    child: const Text('Select all'),
                  ),
                  const SizedBox(width: 8),
                  // "Clear" disabled if it would go to 0
                  TextButton(
                    onPressed: sel.length <= 1 ? null : () => setSt(() => sel = {sel.first}),
                    child: const Text('Clear'),
                  ),
                  const Spacer(),
                  Text(sel.length == all.length ? 'All' : '${sel.length}', style: Styles.popupText),
                ],
              ),
              const SizedBox(height: 6),

              ConstrainedBox(
                constraints: BoxConstraints(maxHeight: MediaQuery.of(ctx).size.height * 0.45),
                child: SingleChildScrollView(
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: [
                      for (final t in all) ...[
                          ListTile(
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                            leading: Icon(t.icon, color: white),
                            title: Text(Utility.formatString(t.name), style: Styles.basicText),
                            trailing: sel.contains(t)
                              ? const Icon(Icons.check_circle, color: owlPurple)
                              : const SizedBox.shrink(),
                            onTap: () => toggle(t, setSt),
                          ),
                          const Divider(color: owlPurple, height: 0.3),
                        ],
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: OwlButton(
                      label: 'Cancel',
                      onPressed: () => Navigator.of(ctx).pop(null),
                      backgroundColor: transparent,
                      textColor: owlPurple,
                      borderColor: owlPurple,
                      borderRadius: borderRadiusSmall,
                    ),
                  ),
                  SizedBox(width: PlatformConfig.width(ctx) * 0.1),
                  Expanded(
                    child: OwlButton(
                      label: 'Save',
                      onPressed: () => Navigator.of(ctx).pop(sel),
                      backgroundColor: transparent,
                      textColor: owlPurple,
                      borderColor: owlPurple,
                      borderRadius: borderRadiusSmall,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Future<double?> _pickMaxDistance(BuildContext context, double currentKm) async {
    return await showDialog<double>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) {
        double tempKm = currentKm.clamp(_minKm, _maxKm).toDouble();
        final controller = TextEditingController(text: tempKm.toStringAsFixed(0));

        void _syncFromText(void Function(void Function()) setSt) {
          final v = double.tryParse(controller.text);
          if (v == null) return;
          setSt(() => tempKm = v.clamp(_minKm, _maxKm).toDouble());
        }

        return StatefulBuilder(
          builder: (ctx, setSt) => OwlPopup(
            title: 'Max venue distance (km)',
            children: [
              Row(
                children: [
                  Expanded(
                    child: Slider(
                      min: _minKm,
                      max: _maxKm,
                      divisions: (_maxKm - _minKm).round(),
                      value: tempKm,
                      label: tempKm.toStringAsFixed(0),
                      onChanged: (v) {
                        setSt(() => tempKm = v);
                        controller.text = v.toStringAsFixed(0);
                      },
                      activeColor: owlPurple,
                      inactiveColor: grey,
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 72,
                    child: TextField(
                      controller: controller,
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      decoration: const InputDecoration(
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (_) => _syncFromText(setSt),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: OwlButton(
                      label: 'Cancel',
                      onPressed: () => Navigator.of(ctx).pop(null),
                      backgroundColor: transparent,
                      textColor: owlPurple,
                      borderColor: owlPurple,
                      borderRadius: borderRadiusSmall,
                    ),
                  ),
                  SizedBox(width: PlatformConfig.width(ctx) * 0.1),
                  Expanded(
                    child: OwlButton(
                      label: 'Save',
                      onPressed: () => Navigator.of(ctx).pop(double.parse(tempKm.toStringAsFixed(0))),
                      backgroundColor: transparent,
                      textColor: owlPurple,
                      borderColor: owlPurple,
                      borderRadius: borderRadiusSmall,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _persistPreferredTypes(Set<VenueType> sel) async {
    final uid = ref.read(firebaseAuthProvider).currentUser?.uid;
    if (uid == null) return;

    try {
      await ref.read(preferencesRepositoryProvider).updatePreferredVenueTypes(
        uid: uid,
        types: sel,
      );

      // Local cache
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('pref_venue_types', sel.map((e) => e.name).toList());

      ref.invalidate(authUserProvider);
      OwlSnack.show(context, title: 'Preferences updated', variant: OwlSnackVariant.success);
    }
    catch (e) {
      OwlSnack.show(context, title: 'Failed to save: $e', variant: OwlSnackVariant.error);
    }
  }

  Future<void> _persistMaxDistance(double km) async {
    final uid = ref.read(firebaseAuthProvider).currentUser?.uid;
    if (uid == null) return;

    final clamped = km.clamp(_minKm, _maxKm).toDouble();
    try {
      await ref.read(preferencesRepositoryProvider).updateMaxDistanceKm(
        uid: uid,
        km: clamped,
      );

      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble('pref_max_distance_km', clamped);

      ref.invalidate(authUserProvider);
      OwlSnack.show(context, title: 'Max distance saved', variant: OwlSnackVariant.success);
    }
    catch (e) {
      OwlSnack.show(context, title: 'Failed to save: $e', variant: OwlSnackVariant.error);
    }
  }

  Future<bool?> _pickHomeLocation(model.User? appUser) async {
    final uid = ref.read(firebaseAuthProvider).currentUser?.uid;
    if (uid == null) return false;

    String selIso2 = (appUser?.homeCountryCode ?? '').toUpperCase();
    if (selIso2.isEmpty) selIso2 = 'DK'; // default

    String? selCity = appUser?.homeTown;

    final countries = _mapper.countries;          // Map<String, CountryInfo>
    final countryCodes = countries.keys.toList()..sort();
    final cityListFor = (String iso2) => _mapper.citiesInCountry(iso2); // List<CityInfo>

    String filter = '';

    return showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) {
        return StatefulBuilder(builder: (ctx, setSt) {
            final cities = cityListFor(selIso2)
              .where((c) => c.name.toLowerCase().contains(filter.toLowerCase()))
              .toList()
            ..sort((a, b) => a.name.compareTo(b.name));

            return OwlPopup(
              title: 'Choose home location',
              children: [
                // Country dropdown
                DropdownButtonFormField<String>(
                  value: selIso2,
                  items: countryCodes.map((code) {
                      final name = countries[code]!.name;
                      return DropdownMenuItem(value: code, child: Text('$name ($code)'));
                    }
                  ).toList(),
                  onChanged: (v) => setSt(() { selIso2 = v!;
                      selCity = null;
                    }
                  ),
                ),
                const SizedBox(height: 12),
                // City filter
                TextField(
                  decoration: const InputDecoration(
                    hintText: 'Filter cities',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  onChanged: (v) => setSt(() => filter = v),
                ),
                const SizedBox(height: 8),
                // City list
                ConstrainedBox(
                  constraints: BoxConstraints(maxHeight: MediaQuery.of(ctx).size.height * 0.45),
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: cities.length,
                    separatorBuilder: (_, __) => const Divider(color: owlPurple, height: 0.3),
                    itemBuilder: (_, i) {
                      final c = cities[i];
                      final selected = selCity?.toLowerCase() == c.name.toLowerCase();
                      return ListTile(
                        dense: true,
                        title: Text(c.name),
                        trailing: selected ? const Icon(Icons.check_circle, color: owlPurple) : null,
                        onTap: () => setSt(() => selCity = c.name.toLowerCase()),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: OwlButton(
                        label: 'Cancel',
                        onPressed: () => Navigator.of(ctx).pop(false),
                        backgroundColor: transparent,
                        textColor: owlPurple,
                        borderColor: owlPurple,
                        borderRadius: borderRadiusSmall,
                      ),
                    ),
                    SizedBox(width: PlatformConfig.width(ctx) * 0.1),
                    Expanded(
                      child: OwlButton(
                        label: 'Save',
                        onPressed: (selCity == null)
                          ? null
                          : () async {
                            await ref.read(personalSettingsRepositoryProvider).setHomeLocation(
                              uid: uid,
                              countryIso2: selIso2,
                              town: selCity!,
                              locked: true, // MANUAL -> lock forever
                            );
                            if (ctx.mounted) Navigator.of(ctx).pop(true);
                          },
                        backgroundColor: transparent,
                        textColor: owlPurple,
                        borderColor: owlPurple,
                        borderRadius: borderRadiusSmall,
                      ),
                    ),
                  ],
                ),
              ],
            );
          }
        );
      },
    );
  }

  Future<bool?> _pickHomeLocationBottomSheet(model.User? appUser) async {
    final uid = ref.read(firebaseAuthProvider).currentUser?.uid;
    if (uid == null) return false;

    // Build once: only countries that have ≥1 city + their city counts
    final countryOptions = _mapper.countries.entries
      .map((e) => (
        code: e.key,
        name: e.value.name,
        count: _mapper.citiesInCountry(e.key).length,
        ))
      .where((x) => x.count > 0)
      .toList()
    ..sort((a, b) => a.name.compareTo(b.name));

    if (countryOptions.isEmpty) return false;

    String selIso2 = (appUser?.homeCountryCode ?? '').toUpperCase();
    if (!countryOptions.any((x) => x.code == selIso2)) {
      selIso2 = countryOptions.first.code; // fallback
    }
    String? selCity = appUser?.homeTown;
    String filter = '';

    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: const Color(0xFF1C1C1E),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSt) {
            final bottomInset = MediaQuery.viewInsetsOf(ctx).bottom;

            final cities = _mapper
              .citiesInCountry(selIso2)
              .where((c) => c.name.toLowerCase().contains(filter.toLowerCase()))
              .toList()
            ..sort((a, b) => a.name.compareTo(b.name));

            final selCountry = countryOptions.firstWhere((x) => x.code == selIso2);

            return AnimatedPadding(
              padding: EdgeInsets.only(bottom: bottomInset),
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
              child: FractionallySizedBox(
                heightFactor: 0.8,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Header
                      Row(
                        children: [
                          Text('Select home location', style: Styles.basicTextHeader),
                          const Spacer(),
                          IconButton(
                            icon: const Icon(Icons.close, color: grey),
                            onPressed: () => Navigator.of(ctx).pop(false),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Country dropdown (with correct per-country city count)
                      DropdownButtonFormField<String>(
                        value: selIso2,
                        dropdownColor: const Color(0xFF1C1C1E),
                        menuMaxHeight: 350,
                        items: [
                          for (final c in countryOptions)
                            DropdownMenuItem<String>(
                              value: c.code,
                              child: Text(
                                '(${c.code}) ${c.name} | ${c.count} ${c.count == 1 ? 'city' : 'cities'}',
                                style: Styles.basicText.copyWith(letterSpacing: 1.5, wordSpacing: 1.5),
                              ),
                            ),
                        ],
                        onChanged: (v) => setSt(() {
                            selIso2 = v!;
                            selCity = null;
                            filter = '';
                          }
                        ),
                        style: Styles.basicText,
                        decoration: const InputDecoration(isDense: true, border: OutlineInputBorder()),
                      ),
                      const SizedBox(height: 12),

                      // City filter
                      TextField(
                        decoration: const InputDecoration(
                          hintText: 'Search City', border: OutlineInputBorder(), isDense: true,
                        ),
                        onChanged: (v) => setSt(() => filter = v),
                      ),
                      const SizedBox(height: 8),

                      // Cities
                      Expanded(
                        child: cities.isEmpty
                          ? Center(
                            child: Text(
                              'No cities in ${selCountry.name} match "$filter"',
                              style: Styles.basicText,
                              textAlign: TextAlign.center,
                            ),
                          )
                          : ListView.separated(
                            key: ValueKey('${selIso2}_$filter'),
                            addSemanticIndexes: false,
                            primary: false,
                            physics: const ClampingScrollPhysics(),
                            itemCount: cities.length,
                            separatorBuilder: (_, __) =>
                            const Divider(color: owlPurple, height: 0.3),
                            itemBuilder: (_, i) {
                              final c = cities[i];
                              final selected = selCity?.toLowerCase() == c.name.toLowerCase();
                              return ListTile(
                                dense: true,
                                title: Text(c.name, style: Styles.basicText),
                                trailing: selected
                                  ? const Icon(Icons.check_circle, color: owlPurple)
                                  : null,
                                onTap: () => setSt(() => selCity = c.name.toLowerCase()),
                              );
                            },
                          ),
                      ),
                      const SizedBox(height: 12),

                      // Actions
                      Row(
                        children: [
                          Expanded(
                            child: OwlButton(
                              label: 'Cancel',
                              onPressed: () {
                                FocusScope.of(ctx).unfocus();
                                Navigator.of(ctx).pop(false);
                              },
                              backgroundColor: transparent,
                              textColor: white,
                              borderColor: grey,
                              borderRadius: borderRadiusSmall,
                              fullWidth: true,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: OwlButton(
                              label: 'Save',
                              onPressed: (selCity == null)
                                ? null
                                : () async {
                                  FocusScope.of(ctx).unfocus();
                                  await ref
                                    .read(personalSettingsRepositoryProvider)
                                    .setHomeLocation(
                                      uid: uid,
                                      countryIso2: selIso2,
                                      town: selCity!,
                                      locked: true,
                                    );
                                  if (ctx.mounted) Navigator.of(ctx).pop(true);
                                },
                              backgroundColor: owlPurple,
                              textColor: white,
                              borderColor: transparent,
                              borderRadius: borderRadiusSmall,
                              fullWidth: true,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _saveNames({String? first, String? middle, String? last}) async {
    final uid = ref.read(firebaseAuthProvider).currentUser?.uid;
    if (uid == null) return;
    try {
      await ref.read(userRepositoryProvider).updateNamesAndPhone(
        uid: uid,
        firstName: first ?? _firstName,
        middleName: middle ?? _middleName,
        lastName: last ?? _lastName,
      );
      if (!mounted) return;
      setState(() {
          if (first != null) _firstName = first;
          if (middle != null) _middleName = middle;
          if (last != null) _lastName = last;
        }
      );
      OwlSnack.show(context, title: 'Name saved', variant: OwlSnackVariant.success);
      ref.invalidate(authUserProvider);
    }
    catch (e) {
      if (!mounted) return;
      OwlSnack.show(context, title: 'Save failed: $e', variant: OwlSnackVariant.error);
    }
  }

  Future<phone.PhoneNumber?> _editPhoneSheet(
    BuildContext context,
    phone.PhoneNumber? current,
  ) async {
    // Try to preselect from current phone, else from user's home country, else DK
    final appUser = ref.read(authUserProvider).valueOrNull;
    final iso2Guess = (current?.iso2 ?? appUser?.homeCountryCode ?? 'DK').toUpperCase();

    CountryCode selCountry =
      _countryFromIso2(iso2Guess) ?? CountryCode.dk; // fallback
    // inside _editPhoneSheet before computing selCountry:
    if ((current?.iso2 ?? appUser?.homeCountryCode) == null) {
      final loc = await LocationService().lastKnownOrCurrent();
      if (loc != null) {
        final r = _mapper.resolve(lat: loc.lat, lon: loc.lng);
        final iso = r.countryCode;
        final c = _countryFromIso2(iso);
        if (c != null) selCountry = c;
      }
    }

    // Split current E.164 into +code + local digits (best-effort)
    String initialLocalDigits = '';
    if (current?.e164 != null && current!.e164.startsWith('+')) {
      final withoutPlus = current.e164.substring(1); // "4512345678"
      // pick the longest matching calling code
      int bestLen = 0;
      for (final c in PhoneCountryCode.availableCountries) {
        final cc = (PhoneCountryCode(c).phoneCode ?? '+').replaceAll('+', '');
        if (cc.isEmpty) continue;
        if (withoutPlus.startsWith(cc) && cc.length > bestLen) {
          bestLen = cc.length;
          selCountry = c;
        }
      }
      if (bestLen > 0) {
        initialLocalDigits = withoutPlus.substring(bestLen);
      }
      else {
        // fallback: keep everything after '+'
        initialLocalDigits = withoutPlus;
      }
    }

    final localCtl = TextEditingController(text: initialLocalDigits);
    bool changed = false;

    phone.PhoneNumber? buildCandidate() {
      final info = PhoneCountryCode(selCountry);
      final cc = (info.phoneCode ?? '').trim();          // like "+45"
      final nationalDigits = localCtl.text.replaceAll(RegExp(r'\D'), '');
      if (cc.isEmpty || nationalDigits.isEmpty) return null;

      final e164 = '$cc$nationalDigits';                 // "+45" + "12345678"
      final iso2 = selCountry.name.toUpperCase();
      final ccDigits = cc.replaceAll('+', '');           // "45"

      final minLen = info.minimumPhoneNumberLength ?? 6; // basic sanity
      if (nationalDigits.length < minLen) return null;

      // Try your domain model’s parser
      return phone.PhoneNumber.tryParse(
        e164,
        iso2: iso2,
        callingCode: ccDigits,
      );
    }

    return showModalBottomSheet<phone.PhoneNumber>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1C1C1E),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSt) {
            final bottom = MediaQuery.of(ctx).viewInsets.bottom;
            final info = PhoneCountryCode(selCountry);
            final candidate = buildCandidate();
            final valid = candidate != null;

            // Build dropdown menu items (flag + +code), sorted numerically by code
            List<DropdownMenuItem<CountryCode>> items() {
              final list = PhoneCountryCode.availableCountries
                .map((c) {
                    final p = PhoneCountryCode(c);
                    return DropdownMenuItem<CountryCode>(
                      value: c,
                      child: SizedBox(
                        height: 26,
                        child: Row(
                          children: [
                            if (p.flagImage != null)
                            SizedBox(width: 24, height: 16, child: FittedBox(fit: BoxFit.cover, child: p.flagImage)),
                            if (p.flagImage != null) const SizedBox(width: 8),
                            Text(p.phoneCode ?? '', style: Styles.basicText),
                          ],
                        ),
                      ),
                    );
                  }
                )
                .toList();

              int parseCode(String? s) =>
              int.tryParse((s ?? '').replaceAll('+', '')) ?? 99999;

              list.sort((a, b) =>
                parseCode(PhoneCountryCode(a.value!).phoneCode)
                  .compareTo(parseCode(PhoneCountryCode(b.value!).phoneCode)));

              return list;
            }

            return AnimatedPadding(
              padding: EdgeInsets.only(bottom: bottom),
              duration: const Duration(milliseconds: 180),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Text('Edit phone', style: Styles.basicTextHeader),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.close, color: grey),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),

                    // Row: [Dropdown (flag + +code)] [Local number]
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        DropdownButtonFormField<CountryCode>(
                          dropdownColor: const Color(0xFF1C1C1E),
                          decoration: const InputDecoration(
                            labelText: 'Country / Code',
                            isDense: true,
                            border: OutlineInputBorder(),
                          ),
                          value: selCountry,
                          items: items(),
                          onChanged: (v) => setSt(() {
                              if (v == null) return;
                              selCountry = v;
                              changed = true;
                            }
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: localCtl,
                          keyboardType: TextInputType.phone,
                          decoration: InputDecoration(
                            hintText: 'Phone number',
                            border: const OutlineInputBorder(),
                            isDense: true,
                            prefixIcon: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                              child: Row(
                                mainAxisSize: MainAxisSize.min, // compact prefix
                                children: [
                                  if (info.flagImage != null)
                                  SizedBox(width: 22, height: 16, child: FittedBox(fit: BoxFit.cover, child: info.flagImage)),
                                  if (info.flagImage != null) const SizedBox(width: 6),

                                  // +code
                                  Text(info.phoneCode ?? '', style: Styles.basicText),

                                  const SizedBox(width: 6),

                                  // (ISO2) to the right of the code
                                  Text(
                                    '(${selCountry.name.toUpperCase()})',
                                    style: Styles.basicText.copyWith(color: greyLighter),
                                  ),

                                  const SizedBox(width: 6),
                                  Container(width: 1, height: 18, color: grey.withOpacity(0.35)),
                                  const SizedBox(width: 6),
                                ],
                              ),
                            ),
                            prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
                          ),
                          onChanged: (_) => setSt(() => changed = true),
                        ),

                      ],
                    ),

                    // Live E.164 preview + validity

                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: OwlButton(
                            label: 'Cancel',
                            onPressed: () => Navigator.pop(ctx),
                            backgroundColor: transparent,
                            textColor: grey,
                            borderColor: grey,
                            borderRadius: borderRadiusSmall,
                            fullWidth: true,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: OwlButton(
                            label: 'Save',
                            onPressed: (!changed && current != null)
                              ? () => Navigator.pop(ctx, current)
                              : (valid ? () => Navigator.pop(ctx, candidate) : null),
                            backgroundColor: owlPurple,
                            textColor: white,
                            borderColor: transparent,
                            borderRadius: borderRadiusSmall,
                            fullWidth: true,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<String?> _editUsernameSheet(BuildContext context, String current) async {
    final ctl = TextEditingController(text: current);
    bool checking = false;
    bool? available; // null = unknown
    Timer? debouncer;

    Future<void> _check(String name, void Function(void Function()) setSt) async {
      final v = name.trim();
      if (v.isEmpty || v.toLowerCase() == current.trim().toLowerCase()) {
        setSt(() { available = null;
            checking = false;
          }
        );
        return;
      }
      setSt(() { checking = true;
          available = null;
        }
      );
      try {
        final repo = ref.read(userRepositoryProvider);
        bool ok;
        try {
          ok = await repo.usernameAvailableFast(v); // if you implemented it
        }
        catch (_) {
          ok = await repo.usernameAvailableFast(v);     // fallback to the basic one
        }
        setSt(() { available = ok;
            checking = false;
          }
        );
      }
      catch (_) {
        setSt(() { available = null;
            checking = false;
          }
        );
      }
    }

    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1C1C1E),
      builder: (ctx) {
        return StatefulBuilder(builder: (ctx, setSt) {
            final bottom = MediaQuery.of(ctx).viewInsets.bottom;
            final v = ctl.text.trim();
            final changed = v != current.trim();
            final basicValid = RegExp(r'^[a-zA-Z0-9_\.]{3,20}$').hasMatch(v);

            return AnimatedPadding(
              padding: EdgeInsets.only(bottom: bottom),
              duration: const Duration(milliseconds: 180),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Text('Edit Username', style: Styles.basicTextHeader),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.close, color: grey),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: ctl,
                      maxLength: 20,
                      decoration: InputDecoration(
                        counterText: '',
                        border: const OutlineInputBorder(),
                        suffixIcon: checking
                          ? const Padding(
                            padding: EdgeInsets.all(10),
                            child: SizedBox(
                              width: 18, height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          )
                          : (available == true
                            ? const Icon(Icons.check_circle, color: Colors.green)
                            : (available == false
                              ? const Icon(Icons.error, color: Colors.red)
                              : null)),
                      ),
                      onChanged: (s) {
                        debouncer?.cancel();
                        debouncer = Timer(const Duration(milliseconds: 150), () {
                            _check(s, setSt);
                          }
                        );
                      },
                      autofocus: true,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OwlButton(
                            label: 'Cancel',
                            onPressed: () => Navigator.pop(ctx),
                            backgroundColor: transparent,
                            textColor: grey,
                            borderColor: grey,
                            borderRadius: borderRadiusSmall,
                            fullWidth: true,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: OwlButton(
                            label: 'Save',
                            onPressed: (!changed || !basicValid || available == false)
                              ? null
                              : () => Navigator.pop(ctx, v),
                            backgroundColor: owlPurple,
                            textColor: white,
                            borderColor: transparent,
                            borderRadius: borderRadiusSmall,
                            fullWidth: true,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }
        );
      },
    ).whenComplete(() => debouncer?.cancel());
  }

  Future<void> _onEditUsernameWithValue(String v) async {
    final uid = ref.read(firebaseAuthProvider).currentUser?.uid;
    if (uid == null) return;

    final repo = ref.read(userRepositoryProvider);
    final desired = v.trim();
    try {
      // Quick pre-check (not strictly required because tx also checks)
      final free = await repo.usernameAvailableFast(desired);
      if (!free && desired.toLowerCase() != _userName.trim().toLowerCase() || repo.resemblesNightOwl(desired) != false) {
        OwlSnack.show(context, title: 'Username already taken', variant: OwlSnackVariant.error);
        return;
      }

      await repo.renameUsername(uid: uid, newUserName: desired);

      if (!mounted) return;
      setState(() => _userName = desired);
      OwlSnack.show(context, title: 'Username updated', variant: OwlSnackVariant.success);
      ref.invalidate(authUserProvider);
    } catch (e) {
      if (!mounted) return;
      final msg = e.toString().contains('taken') ? 'Username already taken' : 'Update failed: $e';
      OwlSnack.show(context, title: msg, variant: OwlSnackVariant.error);
    }
  }

  phone.PhoneNumber? _fromE164(String e164, {String? iso2Hint}) {
    final raw = e164.trim();
    if (!raw.startsWith('+')) return null;

    final digits = raw.substring(1); // without '+'
    CountryCode? bestCountry;
    String bestCode = '';

    for (final c in PhoneCountryCode.availableCountries) {
      final code = (PhoneCountryCode(c).phoneCode ?? '').replaceAll('+', '');
      if (code.isEmpty) continue;
      if (digits.startsWith(code) && code.length > bestCode.length) {
        bestCode = code;
        bestCountry = c;
      }
    }

    // If multiple countries share the same code (e.g. +1), prefer the hint
    if (bestCountry != null && iso2Hint != null) {
      final hint = _countryFromIso2(iso2Hint);
      if (hint != null &&
          (PhoneCountryCode(hint).phoneCode ?? '').replaceAll('+', '') == bestCode) {
        bestCountry = hint;
      }
    }

    if (bestCountry == null || bestCode.isEmpty) return null;

    return phone.PhoneNumber.tryParse(
      raw,
      iso2: bestCountry.name.toUpperCase(),
      callingCode: bestCode,
    );
  }

  Future<void> _saveEmail(String v) async {
    final fb.User? user = ref.read(firebaseAuthProvider).currentUser; // <-- typed
    final String? uid = user?.uid;
    if (uid == null) return;

    try {
      // Update Firebase Auth email (may require recent login)
      if ((user!.email ?? '').toLowerCase() != v.trim().toLowerCase()) {
        await user.verifyBeforeUpdateEmail(v.trim());
        // or: await user.verifyBeforeUpdateEmail(v.trim());  // if you prefer the verified flow
      }

      // Mirror to Firestore
      await ref.read(userRepositoryProvider).setEmail(uid: uid, email: v.trim());

      if (!mounted) return;
      setState(() => _email = v.trim());
      OwlSnack.show(context, title: 'Email saved', variant: OwlSnackVariant.success);
    } on fb.FirebaseAuthException catch (e) {
      final msg = e.code == 'requires-recent-login'
          ? 'Please reauthenticate and try again.'
          : (e.message ?? 'Could not update email');
      if (mounted) {
        OwlSnack.show(context, title: msg, variant: OwlSnackVariant.error);
      }
    } catch (e) {
      if (mounted) {
        OwlSnack.show(context, title: 'Email save failed: $e', variant: OwlSnackVariant.error);
      }
    }
  }

}


Widget _kvClickable(
  String label,
  String value, {
    required VoidCallback onTap,
    IconData? leading,
  }) {
  return InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(12),
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          if (leading != null) ...[
            Icon(leading, size: 18, color: white),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: Text(label, style: Styles.basicText),
          ),
          // right-aligned summary
          Text(
            value,
            style: Styles.basicText, // tweak color if you want it dimmer
            textAlign: TextAlign.right,
          ),
          const SizedBox(width: 6),
          const Icon(Icons.chevron_right, size: 18, color: grey),
        ],
      ),
    ),
  );
}


/* ---------- Bottom actions (left-aligned column) ---------- */

class _SettingsActionsRow extends StatelessWidget {
  const _SettingsActionsRow({
    required this.onOpenTos,
    required this.onLogout,
    required this.onDeleteAccount,
  });

  final void Function(BuildContext) onOpenTos;
  final void Function(BuildContext) onLogout;
  final void Function(BuildContext) onDeleteAccount;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start, // left like the rest
      children: [
        _pillButton(
          context: context,
          icon: Icons.description,
          label: 'Terms of Service',
          onTap: onOpenTos,
        ),
        _pillButton(
          context: context,
          icon: Icons.logout,
          label: 'Log out',
          onTap: onLogout,
          color: grey,
          danger: true
        ),
        _pillButton(
          context: context,
          icon: profileIcon,
          label: 'Delete user',
          onTap: onDeleteAccount,
          danger: true,
        ),
      ],
    );
  }

  Widget _pillButton({
    required BuildContext context,
    required IconData icon,
    required String label,
    required void Function(BuildContext) onTap,
    Color? color,
    bool danger = false,
  }) {
    return Container(
      child: TextButton.icon(
        onPressed: () => onTap(context),
        icon: Icon(
          icon,
          size: iconSizeDefault,
          color: color ?? (danger ? red : white),
        ),
        label: Text(label, style: Styles.basicText.copyWith(color: danger ? red : white)),
      ),
    );
  }


}
