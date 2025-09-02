import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nightowlcode/core/platform_config.dart';
import 'package:nightowlcode/data/other_providers.dart'; // has authStateProvider & sharedPrefsFutureProvider
import 'package:nightowlcode/navigation/nav_shortcuts.dart';
import 'package:nightowlcode/shared/constants/colors.dart';
import 'package:nightowlcode/shared/constants/enums.dart';
import 'package:nightowlcode/shared/constants/styles.dart';
import 'package:nightowlcode/shared/reusable/ui/buttons.dart';
import 'package:nightowlcode/shared/reusable/users/language_switcher.dart';

import '../../../core/storage/app_storage.dart';
import '../../main/widgets/main_app_bar.dart';

enum StartDecision { loading, showLogin, goExplore }

/// Reads SharedPreferences once and exposes the stayLoggedIn flag.
final stayLoggedInProvider = FutureProvider<bool>((ref) async {
  final prefs = await ref.watch(sharedPrefsFutureProvider.future);
  return
    // prefs.getBool('stayLoggedIn') ?? true;
    true; // TODO TESTING.
});

/// Combines auth + stayLoggedIn to decide what to render.
final startDecisionProvider = Provider<StartDecision>((ref) {
  final auth = ref.watch(authStateProvider);           // AsyncValue<User?>
  final stay = ref.watch(stayLoggedInProvider);        // AsyncValue<bool>

  if (auth.isLoading || stay.isLoading) return StartDecision.loading;

  // If anything errors out, degrade gracefully to login screen (no flash).
  if (auth.hasError || stay.hasError) return StartDecision.showLogin;

  final user = auth.value;
  final s = stay.value ?? true;

  if (user != null && s) return StartDecision.goExplore;
  return StartDecision.showLogin;
});

class LoginOrCreateAccountScreen extends ConsumerWidget {
  const LoginOrCreateAccountScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Side-effect: navigate once the decision flips to goExplore.
    ref.listen<StartDecision>(startDecisionProvider, (prev, next) {
      if (next == StartDecision.goExplore) {
        context.goScreen(MainScreenName.explore);
      }
    });

    final decision = ref.watch(startDecisionProvider);

    // While deciding OR right before navigating, show loading (no login flash).
    if (decision == StartDecision.loading || decision == StartDecision.goExplore) {
      return const _LoadingScaffold();
    }

    // Decided to show login/signup.
    return const _LoginBody();
  }
}

/// Minimal branded loading screen.
class _LoadingScaffold extends StatelessWidget {
  const _LoadingScaffold();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
                'assets/nightowl/logo.png',
                height: PlatformConfig.height(context) * 0.18,
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
              ),
              const SizedBox(height: 24),
              const CircularProgressIndicator(color: owlOrange),
            ],
          ),
        ),
      ),
    );
  }
}

/// Your existing login/create UI, untouched.
class _LoginBody extends StatelessWidget {
  const _LoginBody();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const MainAppBar(leading: LanguageSwitcher(), actions: []),
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                SizedBox(
                  height: PlatformConfig.height(context) * 0.5,
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Image.asset(
                          'assets/nightowl/logo.png',
                          height: PlatformConfig.height(context) * 0.30,
                          errorBuilder: (context, _, __) => const SizedBox.shrink(),
                        ),
                        Styles.logoCrazy('Claim the Night'),
                      ],
                    ),
                  ),
                ),
                const Spacer(),
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: PlatformConfig.width(context) * 0.1,
                  ),
                  child: Column(
                    children: [
                      OwlButton(
                        label: "Create Account",
                        backgroundColor: owlOrange,
                        onPressed: () => context.pushNamedPage('firstCreateNightowlProfile'),
                      ),
                      SizedBox(height: PlatformConfig.height(context) * 0.01),
                      const Divider(color: grey),
                      SizedBox(height: PlatformConfig.height(context) * 0.01),
                      OwlButton(
                        label: "Login",
                        textColor: owlOrange,
                        onPressed: () => context.pushNamedPage('login'),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: PlatformConfig.height(context) * 0.02),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
