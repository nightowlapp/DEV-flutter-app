// lib/features/signup/screens/fourth_create_nightowl_profile_screen.dart
import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nightowlcode/features/signup/widgets/utility/gender_selector.dart';
import 'package:nightowlcode/navigation/nav_shortcuts.dart';
import 'package:nightowlcode/shared/reusable/sign_up_or_login/sign_up.dart';

import '../../../core/app_config.dart';
import '../../../core/platform_config.dart';
import '../../../data/providers/other_providers.dart';
import '../../../shared/constants/colors.dart';
import '../../../shared/constants/enums.dart';
import '../../../shared/constants/values.dart';
import '../../../shared/reusable/sign_up_or_login/simple_text_field.dart';
import '../../../shared/reusable/ui/buttons.dart';
import '../../main/widgets/main_app_bar.dart';
import '../presentation/sign_up_draft_notifier.dart';
import '../presentation/password_provider.dart'; // <-- read the password here
import 'package:nightowlcode/assets.dart';

class FourthCreateNightowlProfileScreen extends ConsumerStatefulWidget {
  const FourthCreateNightowlProfileScreen({super.key, this.usernameController});
  final TextEditingController? usernameController;

  @override
  ConsumerState<FourthCreateNightowlProfileScreen> createState() =>
      _FourthCreateNightowlProfileScreenState();
}

class _FourthCreateNightowlProfileScreenState
    extends ConsumerState<FourthCreateNightowlProfileScreen> {
  late final TextEditingController _username =
      widget.usernameController ?? TextEditingController();

  bool _ownsController = false;
  bool _busy = false;
  Gender? _gender;

  // --- Username validation state ---
  bool _checkingUname = false; // in-flight check
  bool? _unameOk;              // null = unknown, true = ok, false = bad
  String? _unameMsg;           // message for bad/other states
  Timer? _unameDebounce;

  @override
  void initState() {
    super.initState();
    _ownsController = widget.usernameController == null;

    // Prefill from draft
    final draft = ref.read(signUpDraftProvider);
    if ((_username.text).trim().isEmpty && (draft.username ?? '').isNotEmpty) {
      _username.text = draft.username!;
    }
    _gender = draft.gender;

    // Listen + debounce validate
    _username.addListener(() {
      ref.read(signUpDraftProvider.notifier).setUsername(_username.text);
      _queueUsernameCheck();
      setState(() {}); // update button state
    });

    // Run initial check if prefilled
    if (_username.text.trim().isNotEmpty) {
      _queueUsernameCheck();
    }
  }

  @override
  void dispose() {
    _unameDebounce?.cancel();
    if (_ownsController) _username.dispose();
    super.dispose();
  }

  bool get _canContinue =>
      !_busy && _gender != null && (_unameOk ?? false);

  void _queueUsernameCheck() {
    final name = _username.text.trim();
    _unameDebounce?.cancel();

    if (name.isEmpty) {
      setState(() {
        _checkingUname = false;
        _unameOk = null;
        _unameMsg = null;
      });
      return;
    }

    _unameDebounce = Timer(const Duration(milliseconds: 250), () async {
      setState(() {
        _checkingUname = true;
        _unameOk = null;
        _unameMsg = null;
      });

      try {
        final repo = ref.read(userRepositoryProvider);

        // Disallow names resembling "nightowl" (requires admin to claim)
        if (repo.resemblesNightOwl(name)) {
          setState(() {
            _checkingUname = false;
            _unameOk = false;
            _unameMsg = 'This username is reserved';
          });
          return;
        }

        // Fast availability (case-insensitive via /usernames/<lowercase>) with fallback
        bool ok;

          ok = await repo.usernameAvailableFast(name);

        setState(() {
          _checkingUname = false;
          _unameOk = ok;
          _unameMsg = ok ? null : 'Username already taken';
        });
      } catch (_) {
        setState(() {
          _checkingUname = false;
          _unameOk = false;
          _unameMsg = 'Could not validate username';
        });
      }
    });
  }

  // Small status row under the username field with green check / red error
  Widget _usernameStatus() {
    final hasText = _username.text.trim().isNotEmpty;
    if (!hasText) return const SizedBox.shrink();

    if (_checkingUname) {
      return const Row(
        children: [
          SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
          SizedBox(width: 8),
          Text('Checking Username…'),
        ],
      );
    }

    if (_unameOk == true) {
      return const Row(
        children: [
          Icon(Icons.check_circle, color: Colors.green, size: 16),
          SizedBox(width: 8),
          Text('Unique Username!'),
        ],
      );
    }

    if (_unameOk == false) {
      return Row(
        children: [
          const Icon(Icons.error, color: Colors.red, size: 16),
          const SizedBox(width: 8),
          Text(_unameMsg ?? 'Not available'),
        ],
      );
    }

    return const SizedBox.shrink();
  }

  Future<void> _createProfile() async {
    if (!_canContinue) return;
    setState(() => _busy = true);

    try {
      final draft = ref.read(signUpDraftProvider);
      final authRepo = ref.read(authRepositoryProvider);
      final userRepo = ref.read(userRepositoryProvider);
      final finalize = ref.read(userFinalizeServiceProvider);

      // Guard again on reserved names and availability (defensive)
      final userName = (draft.username ?? '').trim();
      if (userName.isEmpty) throw StateError('Username required.');
      if (userRepo.resemblesNightOwl(userName)) {
        throw Exception('This username is reserved.');
      }
      final usernameAvail = await userRepo.usernameAvailableFast(userName);
      if (!usernameAvail) throw Exception('Username already taken.');

      // Create auth user (fails if email exists)
      final email = (draft.email ?? '').trim().toLowerCase();
      final pwd = ref.read(passwordProvider);

      if (email.isEmpty || pwd.trim().length < 6) {
        throw StateError('Missing email or password.');
      }

      final au = await authRepo.signUpWithEmailPassword(email, pwd);
      if (au == null) throw StateError('Auth failed.');

      // Create Firestore user doc (new only)
      final appV = await ref.read(appVersionProvider.future);
      await finalize.createFromDraft(
        draft: draft,
        appVersion: appV.label,
      );

      // Clear local draft
      ref.read(signUpDraftProvider.notifier).clear();

      if (!mounted) return;
      context.pushNamedPage('chooseFavoriteVenues');
    } on fb.FirebaseAuthException catch (e) {
      final msg = e.code == 'email-already-in-use'
          ? 'Email already in use. Please sign in or use a different email.'
          : (e.code == 'weak-password'
          ? 'Please choose a stronger password.'
          : 'Auth error: ${e.message}');
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(msg)));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Could not create profile: $e')));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final horizontal = PlatformConfig.width(context) * 0.1;

    return Scaffold(
      appBar: const MainAppBar(
        showBack: true,
        titleText: 'Final Details',
        actions: [
          CircleAvatar(backgroundImage: AssetImage(ImagePaths.logo), radius: iconSizeDefault, backgroundColor: transparent,),

        ],
      ),
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: horizontal),
        child: SignUp(
          showProgressBar: true,
          currentStep: 3,
          formFields: [
            SizedBox(height: PlatformConfig.height(context) * 0.02),
            SimpleTextField(hint: 'Username', controller: _username),
            const SizedBox(height: 6),
            _usernameStatus(), // green check / red error / spinner
            SizedBox(height: PlatformConfig.height(context) * 0.01),
            GenderSelector(
              value: _gender,
              onChanged: (g) {
                setState(() => _gender = g);
                ref.read(signUpDraftProvider.notifier).setGender(g);
              },
            ),
            SizedBox(height: PlatformConfig.height(context) * 0.02),
            OwlButton(
              label: _busy ? 'Saving…' : 'Create Profile',
              backgroundColor: _canContinue ? owlPurple : grey,
              textColor: _canContinue ? white : grey,
              onPressed: _canContinue ? _createProfile : null,
            ),
          ],
        ),
      ),
    );
  }
}
