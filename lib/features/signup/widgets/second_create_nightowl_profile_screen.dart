import 'package:email_validator/email_validator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nightowlcode/navigation/nav_shortcuts.dart';
import 'package:nightowlcode/shared/reusable/ui/buttons.dart';

import '../../../core/platform_config.dart';
import '../../../data/providers/other_providers.dart';
import '../../../data/repositories/users/auth/auth_profile_mapper.dart';
import '../../../shared/constants/colors.dart';
import '../../../shared/constants/icons.dart';
import '../../../shared/constants/values.dart';
import '../../../shared/reusable/sign_up_or_login/sign_up.dart';
import '../../../shared/reusable/sign_up_or_login/simple_text_field.dart';
import '../../main/widgets/main_app_bar.dart';
import '../presentation/sign_up_draft_notifier.dart';
import 'package:nightowlcode/assets.dart';

class SecondCreateNightowlProfileScreen extends ConsumerStatefulWidget {
  const SecondCreateNightowlProfileScreen({super.key, this.emailController});
  final TextEditingController? emailController;

  @override
  ConsumerState<SecondCreateNightowlProfileScreen> createState() =>
      _SecondCreateNightowlProfileScreenState();
}

class _SecondCreateNightowlProfileScreenState
    extends ConsumerState<SecondCreateNightowlProfileScreen> {
  late final TextEditingController _email =
      widget.emailController ?? TextEditingController();

  bool _ownsController = false;
  bool _busy = false;

  bool _isValidEmail(String input) => EmailValidator.validate(input.trim());
  String _normalize(String input) => input.trim().toLowerCase();

  @override
  void initState() {
    super.initState();
    _ownsController = widget.emailController == null;

    // Prefill from draft
    final draft = ref.read(signUpDraftProvider);
    if (_email.text.trim().isEmpty && (draft.email ?? '').isNotEmpty) {
      _email.text = draft.email!;
    }

    // Persist email to draft on every change
    _email.addListener(() {
      setState(() {}); // update button state
      ref.read(signUpDraftProvider.notifier).setEmail(_normalize(_email.text));
    });
  }

  @override
  void dispose() {
    if (_ownsController) _email.dispose();
    super.dispose();
  }

  Future<void> _doGoogle() async {
    setState(() => _busy = true);
    try {
      final authRepo = ref.read(authRepositoryProvider);
      final user = await authRepo.signInWithGoogle();
      if (!mounted) return;
      if (user != null) {
        await prefillDraftFromFirebaseUser(ref, user);
        context.pushNamedPage('fourthCreateNightowlProfile'); // skip password
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sign-in cancelled')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Google sign-in failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _doApple() async {
    setState(() => _busy = true);
    try {
      final authRepo = ref.read(authRepositoryProvider);
      final user = await authRepo.signInWithApple();
      if (!mounted) return;
      if (user != null) {
        await prefillDraftFromFirebaseUser(ref, user);
        context.pushNamedPage('fourthCreateNightowlProfile'); // skip password
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sign-in cancelled')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Apple sign-in failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _continueWithEmail() {
    final email = _normalize(_email.text);
    if (!_isValidEmail(email)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid email address')),
      );
      return;
    }
    // Email already persisted by listener; just go to password
    context.pushNamedPage('thirdCreateNightowlProfile');
  }

  @override
  Widget build(BuildContext context) {
    final horizontal = PlatformConfig.width(context) * 0.1;
    final canTap = !_busy && _isValidEmail(_email.text);

    return Scaffold(
      appBar: const MainAppBar(
        showBack: true,
        titleText: 'Email',
        actions: [
          CircleAvatar(backgroundImage: AssetImage(ImagePaths.logo), radius: iconSizeDefault, backgroundColor: transparent,),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: horizontal),
        child: SignUp(
          useScaffold: false,
          showProgressBar: false,
          formFields: [
            SizedBox(height: PlatformConfig.height(context) * 0.02),
            PlatformConfig.isAndroid
                ? OwlButton(
                    icon: googleIcon,
                    label: _busy ? 'Signing in...' : 'Continue with Google',
                    backgroundColor: owlPurple,
                    onPressed: _busy ? null : _doGoogle,
                  )
                : OwlButton(
                    icon: appleIcon,
                    label: _busy ? 'Signing in...' : 'Continue with Apple',
                    backgroundColor: owlPurple,
                    onPressed: _busy ? null : _doApple,
                  ),
            SizedBox(height: PlatformConfig.height(context) * 0.01),
            const Divider(color: grey),
            SizedBox(height: PlatformConfig.height(context) * 0.01),
            SimpleTextField(
              hint: 'Email',
              leadingIcon: mailIcon,
              controller: _email,
            ),
            SizedBox(height: PlatformConfig.height(context) * 0.02),
            OwlButton(
              label: 'Continue',
              backgroundColor: canTap ? owlPurple : grey,
              textColor: canTap ? white : grey,
              onPressed: canTap ? _continueWithEmail : null,
            ),
          ],
        ),
      ),
    );
  }
}
