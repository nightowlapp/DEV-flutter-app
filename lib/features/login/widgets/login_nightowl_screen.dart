import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nightowlcode/data/providers/other_providers.dart';
import 'package:nightowlcode/navigation/nav_shortcuts.dart';
import 'package:nightowlcode/shared/constants/colors.dart';
import 'package:nightowlcode/shared/constants/enums.dart';
import 'package:nightowlcode/shared/constants/icons.dart';
import 'package:nightowlcode/shared/constants/styles.dart';
import 'package:nightowlcode/shared/constants/values.dart';
import 'package:nightowlcode/shared/reusable/sign_up_or_login/sign_up.dart';
import 'package:nightowlcode/shared/reusable/sign_up_or_login/simple_text_field.dart';
import 'package:nightowlcode/shared/reusable/ui/buttons.dart';
import 'package:nightowlcode/assets.dart';

import '../../../core/platform_config.dart';
import '../../../core/storage/app_storage.dart';
import '../../main/widgets/main_app_bar.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});
  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenUIState();
}

class _LoginScreenUIState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _mailPhoneInputController = TextEditingController();
  final _passwordInputController = TextEditingController();
  bool _stayLoggedIn = true;
  bool _canContinue = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _mailPhoneInputController.dispose();
    _passwordInputController.dispose();
    super.dispose();
  }

  // ✅ sync instance, async write
  Future<void> _saveStayLoggedIn() async {
    final prefs = ref.read(sharedPrefsProvider);
    await prefs.setBool('stayLoggedIn', _stayLoggedIn);
  }

  void _recomputeCanContinue() {
    setState(() {
      _canContinue = _mailPhoneInputController.text.isNotEmpty &&
          _mailPhoneInputController.text.length > 3 &&
          _passwordInputController.text.isNotEmpty &&
          _passwordInputController.text.length > 5;
    });
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate() || !_canContinue) return;
    setState(() => _isLoading = true);
    try {
      final authRepo = ref.read(authRepositoryProvider);
      await authRepo.signInWithEmailPassword(
        _mailPhoneInputController.text.trim(),
        _passwordInputController.text,
      );
      await _saveStayLoggedIn();
      if (mounted) context.goScreen(MainScreenName.explore);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Login failed: $e'),
              behavior: SnackBarBehavior.floating),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final horizontal = PlatformConfig.width(context) * 0.1;
    final vertical = PlatformConfig.height(context) * 0.02;

    return Scaffold(
      appBar: const MainAppBar(
        showBack: true,
        titleText: 'Login',
        actions: [
          CircleAvatar(
            backgroundImage: const AssetImage(ImagePaths.logoColored),
            radius: iconSizeDefault,
            backgroundColor: transparent,
          ),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: horizontal),
        child: SignUp(
          showProgressBar: false,
          formFields: [
            SizedBox(height: vertical),
            Form(
              key: _formKey,
              child: Column(
                children: [
                  SimpleTextField(
                    controller: _mailPhoneInputController,
                    hint: 'Email',
                    leadingIcon: mailIcon,
                    cursorColor: owlPurple,
                    onChanged: (_) => _recomputeCanContinue(),
                    validator: (v) =>
                        (v == null || v.isEmpty) ? 'Email is required' : null,
                  ),
                  SizedBox(height: verticalSpacerMedium),
                  SimpleTextField(
                    controller: _passwordInputController,
                    hint: 'Password',
                    leadingIcon: passwordIcon,
                    obscureText: true,
                    cursorColor: owlPurple,
                    onChanged: (_) => _recomputeCanContinue(),
                    validator: (v) => (v == null || v.isEmpty)
                        ? 'Password is required'
                        : null,
                  ),
                  SizedBox(height: verticalSpacerMedium),
                  Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        GestureDetector(
                          onTap: () {
                            setState(() => _stayLoggedIn = !_stayLoggedIn);
                            _saveStayLoggedIn();
                          },
                          child: Row(
                            children: [
                              Icon(
                                _stayLoggedIn
                                    ? checkBoxCheckedIcon
                                    : checkBoxUncheckedIcon,
                                color: owlPurple,
                              ),
                              const SizedBox(width: horizontalSpacerSmall),
                              Text(
                                'Stay logged in',
                                style: Styles.boldText
                                    .copyWith(fontSize: fontSizeMedium),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: verticalSpacerVeryBig),
                  OwlButton(
                    label: _isLoading ? 'Logging in...' : 'Login',
                    backgroundColor:
                        _canContinue && !_isLoading ? owlPurple : grey,
                    textColor: _canContinue && !_isLoading ? white : grey,
                    onPressed:
                        _canContinue && !_isLoading ? _handleLogin : null,
                  ),
                ],
              ),
            ),
            SizedBox(height: vertical),
          ],
        ),
      ),
    );
  }
}
