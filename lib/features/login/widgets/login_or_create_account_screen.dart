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

// ✅ sync prefs read
final stayLoggedInProvider = Provider<bool>((ref) {
  final prefs = ref.watch(sharedPrefsProvider);
  return prefs.getBool('stayLoggedIn') ?? true;
});

// ✅ combine auth (async) + stayLoggedIn (sync)
final startDecisionProvider = Provider<StartDecision>((ref) {
  final auth = ref.watch(authStateProvider); // AsyncValue<User?>
  final stay = ref.watch(stayLoggedInProvider); // bool

  if (auth.isLoading) return StartDecision.loading;
  if (auth.hasError)  return StartDecision.showLogin;

  final user = auth.value;
  if (user != null && stay) return StartDecision.goExplore;
  return StartDecision.showLogin;
});

class LoginOrCreateAccountScreen extends ConsumerWidget {
  const LoginOrCreateAccountScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen<StartDecision>(startDecisionProvider, (prev, next) {
      if (next == StartDecision.goExplore) {
        context.goScreen(MainScreenName.explore);
      }
    });

    final decision = ref.watch(startDecisionProvider);

    if (decision == StartDecision.loading || decision == StartDecision.goExplore) {
      return const _LoadingScaffold();
    }
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
              const CircularProgressIndicator(color: owlPurple),
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
                  height: PlatformConfig.height(context) * 0.35,
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Image.asset(
                          'assets/nightowl/logo.png',
                          height: PlatformConfig.height(context) * 0.3,
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
                        backgroundColor: owlPurple,
                        onPressed: () => context.pushNamedPage('firstCreateNightowlProfile'),
                      ),
                      SizedBox(height: PlatformConfig.height(context) * 0.01),
                      const Divider(color: grey),
                      SizedBox(height: PlatformConfig.height(context) * 0.01),
                      OwlButton(
                        label: "Login",
                        textColor: owlPurple,
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
