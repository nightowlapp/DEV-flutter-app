import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../features/signup/presentation/sign_up_draft_notifier.dart';

/// Call this right after a successful Firebase sign-in to prefill the local draft.
Future<void> prefillDraftFromFirebaseUser(WidgetRef ref, fb.User u) async {
  ref.read(signUpDraftProvider.notifier).mergeExternalProfile(
    displayName: u.displayName,
    email: u.email,
    photoUrl: u.photoURL,
  );
}
