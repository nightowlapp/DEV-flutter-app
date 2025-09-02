// lib/features/signup/screens/fourth_create_nightowl_profile_screen.dart
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nightowlcode/features/signup/widgets/utility/gender_selector.dart';
import 'package:nightowlcode/navigation/nav_shortcuts.dart';
import 'package:nightowlcode/shared/reusable/sign_up_or_login/sign_up.dart';

import '../../../core/app_config.dart';
import '../../../core/platform_config.dart';
import '../../../data/other_providers.dart';
import '../../../shared/constants/colors.dart';
import '../../../shared/constants/enums.dart';
import '../../../shared/reusable/sign_up_or_login/simple_text_field.dart';
import '../../../shared/reusable/ui/buttons.dart';
import '../../main/widgets/main_app_bar.dart';
import '../presentation/sign_up_draft_notifier.dart';
import '../presentation/password_provider.dart'; // <-- read the password here

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

    _username.addListener(() {
      setState(() {}); // update button
      ref.read(signUpDraftProvider.notifier).setUsername(_username.text);
    });
  }

  @override
  void dispose() {
    if (_ownsController) _username.dispose();
    super.dispose();
  }

  bool get _canContinue =>
      !_busy && _username.text.trim().isNotEmpty && _gender != null;

  Future<void> _createProfile() async {
    if (!_canContinue) return;
    setState(() => _busy = true);

    try {
      final draft = ref.read(signUpDraftProvider);
      final authRepo = ref.read(authRepositoryProvider);
      final userRepo = ref.read(userRepositoryProvider); // Add this to access UserRepository
      final finalize = ref.read(userFinalizeServiceProvider);

      // 1.0) Check username availability
      final userName = (draft.username!);
      final usernameAvail = await userRepo.usernameAvailable(userName);
      if (!usernameAvail) {
        throw Exception('Username already taken.');
      }


      // 1.1) Create auth user (fails if email exists)
      final email = (draft.email ?? '').trim().toLowerCase();
      final pwd = ref.read(passwordProvider);

      if (email.isEmpty || pwd.trim().length < 6) {
        throw StateError('Missing email or password.');
      }

      final au = await authRepo.signUpWithEmailPassword(email, pwd);
      if (au == null) throw StateError('Auth failed.');

      // 2) Create Firestore user doc (new only)
      final appV = await ref.read(appVersionProvider.future);
      await finalize.createFromDraft(  // Note: we'll add this method below
        draft: draft,
        appVersion: appV.label,
      );

      // 3) Clear local draft
      ref.read(signUpDraftProvider.notifier).clear();

      if (!mounted) return;
      context.pushNamedPage('chooseFavoriteVenues');
    } on fb.FirebaseAuthException catch (e) { //TODO remove firebase from here.
      final msg = e.code == 'email-already-in-use'
          ? 'Email already in use. Please sign in or use a different email.'
          : (e.code == 'weak-password'
          ? 'Please choose a stronger password.'
          : 'Auth error: ${e.message}');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not create profile: $e')));
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
        actions: [CircleAvatar(backgroundImage: AssetImage('assets/nightowl/logo.png'))],
      ),
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: horizontal),
        child: SignUp(
          showProgressBar: true,
          currentStep: 3,
          formFields: [
            SizedBox(height: PlatformConfig.height(context) * 0.02),
            SimpleTextField(hint: 'Username', controller: _username),
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
              backgroundColor: _canContinue ? owlOrange : grey,
              textColor: _canContinue ? white : grey,
              onPressed: _canContinue ? _createProfile : null,
            ),
          ],
        ),
      ),
    );
  }
}
