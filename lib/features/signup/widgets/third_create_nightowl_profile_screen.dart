import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nightowlcode/navigation/nav_shortcuts.dart';
import 'package:nightowlcode/shared/constants/styles.dart';
import 'package:nightowlcode/assets.dart';

import '../../../core/platform_config.dart';
import '../../../shared/constants/colors.dart';
import '../../../shared/constants/icons.dart';
import '../../../shared/constants/values.dart';
import '../../../shared/reusable/sign_up_or_login/sign_up.dart';
import '../../../shared/reusable/sign_up_or_login/simple_text_field.dart';
import '../../../shared/reusable/ui/buttons.dart';
import '../../main/widgets/main_app_bar.dart';
import '../presentation/password_provider.dart';

class ThirdCreateNightowlProfileScreen extends ConsumerStatefulWidget {
  const ThirdCreateNightowlProfileScreen({super.key, this.passwordController});
  final TextEditingController? passwordController;
  @override
  ConsumerState<ThirdCreateNightowlProfileScreen> createState() =>
      _ThirdCreateNightowlProfileScreenState();
}

class _ThirdCreateNightowlProfileScreenState
    extends ConsumerState<ThirdCreateNightowlProfileScreen> {
  late final TextEditingController _password =
      widget.passwordController ?? TextEditingController();

  bool _ownsController = false;
  @override
  void initState() {
    super.initState();
    _ownsController = widget.passwordController == null;
    _password.text = ref.read(passwordProvider);
    _password.addListener(() {
      setState(() {}); // for button state
      ref.read(passwordProvider.notifier).state =
          _password.text; // in-memory only
    });
  }

  @override
  void dispose() {
    if (_ownsController) _password.dispose();
    super.dispose();
  }

  bool get _minOk => _password.text.trim().length >= 6;

  @override
  Widget build(BuildContext context) {
    final horizontal = PlatformConfig.width(context) * 0.1;
    final canContinue = _minOk;
    return Scaffold(
      appBar: const MainAppBar(showBack: true, titleText: 'Password', actions: [
        CircleAvatar(
          backgroundImage: AssetImage(ImagePaths.logoColored),
          radius: iconSizeDefault,
          backgroundColor: transparent,
        ),
      ]),
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: horizontal),
        child: SignUp(
          useScaffold: false,
          showProgressBar: true,
          currentStep: 2,
          formFields: [
            SizedBox(height: PlatformConfig.height(context) * 0.02),
            SimpleTextField(
              leadingIcon: passwordIcon,
              hint: 'Password (min 6 chars)',
              controller: _password,
              obscureText: true,
              // hintStyle:Styles.smallText, // smaller hint
            ),
            const SizedBox(height: 8),
            const Text('Tip: longer is stronger'),
            SizedBox(height: PlatformConfig.height(context) * 0.02),
            OwlButton(
              label: 'Continue',
              backgroundColor: canContinue ? owlPurple : grey,
              textColor: canContinue ? white : grey,
              onPressed: canContinue
                  ? () => context.pushNamedPage('fourthCreateNightowlProfile')
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
