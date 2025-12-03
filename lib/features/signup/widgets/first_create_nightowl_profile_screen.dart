// lib/features/signup/screens/first_create_nightowl_profile_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nightowlcode/features/signup/widgets/utility/date_picker.dart';
import 'package:nightowlcode/navigation/nav_shortcuts.dart';
import 'package:nightowlcode/shared/reusable/sign_up_or_login/sign_up.dart';

import '../../../core/platform_config.dart';
import '../../../shared/constants/colors.dart';
import '../../../shared/constants/icons.dart';
import '../../../shared/constants/styles.dart';
import '../../../shared/constants/values.dart';
import '../../../shared/legal/terms_of_service.dart';
import '../../../shared/reusable/ui/buttons.dart';
import '../../main/widgets/main_app_bar.dart';
import '../presentation/sign_up_draft_notifier.dart'; // <-- signUpDraftProvider + selectors
import 'package:nightowlcode/assets.dart';

class FirstCreateNightowlProfileScreen extends ConsumerWidget {
  const FirstCreateNightowlProfileScreen({super.key});

  Future<void> _showTOS(BuildContext context) async {
    final h = MediaQuery.of(context).size.height;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return SafeArea(
          top: false,
          child: Container(
            decoration: const BoxDecoration(
              color: black,
              borderRadius: BorderRadius.vertical(
                  top: Radius.circular(borderRadiusDefault)),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(2)),
                  ),
                  Row(
                    children: [
                      const Text('Terms of Service',
                          style: TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 18)),
                      const Spacer(),
                      IconButton(
                          icon: const Icon(Icons.close, color: white),
                          onPressed: () => Navigator.of(ctx).pop()),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: h * 0.6,
                    child: SingleChildScrollView(
                      child: Text(
                        TermsOfService.tosText,
                        style:
                            Styles.basicText.copyWith(fontSize: fontSizeMedium),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final draft = ref.watch(signUpDraftProvider);
    final ageOk = ref.watch(ageOkProvider);
    final canContinue = ref.watch(canContinueFirstStepProvider);

    final horizontal = PlatformConfig.width(context) * 0.1;

    return Scaffold(
      appBar: const MainAppBar(
        showBack: true,
        titleText: 'Birthdate',
        actions: [
          CircleAvatar(
            backgroundImage: const AssetImage(ImagePaths.logo),
            radius: iconSizeDefault,
            backgroundColor: transparent,
          ),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: horizontal),
        child: SignUp(
          showProgressBar: false,
          formFields: <Widget>[
            SizedBox(height: PlatformConfig.height(context) * 0.02),
            DatePicker(
              initialDate: draft.birthdate,
              legalAge: 18,
              onChanged: (d) =>
                  ref.read(signUpDraftProvider.notifier).setBirthdate(d),
            ),
            if (draft.birthdate != null && !ageOk) ...[
              const SizedBox(height: 8),
              const Text(
                'You must be at least 18 years old to continue.',
                style: TextStyle(color: red, fontWeight: FontWeight.w600),
              ),
            ],
            SizedBox(height: PlatformConfig.height(context) * 0.01),

            // ToS row
            Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GestureDetector(
                    onTap: () => ref
                        .read(signUpDraftProvider.notifier)
                        .setAcceptedTos(!draft.acceptedTos),
                    child: Icon(
                        draft.acceptedTos
                            ? checkBoxCheckedIcon
                            : checkBoxUncheckedIcon,
                        color: owlPurple),
                  ),
                  const SizedBox(width: horizontalSpacerSmall),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Accept ',
                          style: Styles.boldText
                              .copyWith(fontSize: fontSizeMedium)),
                      GestureDetector(
                        onTap: () => _showTOS(context),
                        child: Text(
                          'Terms of Service',
                          style: Styles.boldText.copyWith(
                            fontSize: fontSizeMedium,
                            color: owlPurple,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            SizedBox(height: PlatformConfig.height(context) * 0.02),
            OwlButton(
              label: 'Continue',
              backgroundColor: canContinue ? owlPurple : grey,
              textColor: canContinue ? white : grey,
              onPressed: canContinue
                  ? () => context.pushNamedPage('secondCreateNightowlProfile')
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
