import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nightowlcode/shared/constants/colors.dart';
import 'package:nightowlcode/shared/constants/styles.dart';
import 'package:nightowlcode/shared/constants/values.dart';
import 'package:nightowlcode/shared/reusable/ui/owl_snack.dart';

import '../../../../data/repositories/users/referral_repository.dart';

class RedeemReferralSheet extends ConsumerStatefulWidget {
  const RedeemReferralSheet({super.key});

  @override
  ConsumerState<RedeemReferralSheet> createState() =>
      _RedeemReferralSheetState();
}

class _RedeemReferralSheetState extends ConsumerState<RedeemReferralSheet> {
  final _ctrl = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final repo = ref.watch(referralRepositoryProvider);

    return Padding(
      padding: const EdgeInsets.all(allSidePaddingDefault * 1.2),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Have a code?', style: Styles.basicTextHeader),
          const SizedBox(height: verticalSpacerSmall),
          TextField(
            controller: _ctrl,
            textCapitalization: TextCapitalization.characters,
            decoration: const InputDecoration(
              hintText: 'ENTER CODE (e.g. 9F7KQZ)',
              filled: true,
            ),
          ),
          const SizedBox(height: verticalSpacerSmall),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _busy
                  ? null
                  : () async {
                      final code = _ctrl.text.trim();
                      if (code.isEmpty) {
                        OwlSnack.show(context,
                            title: 'Missing code',
                            message: 'Please enter a referral code.');
                        return;
                      }
                      setState(() => _busy = true);
                      try {
                        final res = await repo.redeemCode(code);
                        if (mounted) {
                          OwlSnack.show(
                            context,
                            title: 'Referral applied!',
                            message:
                                'You earned +${res.awardedInvitee} EXP. Your friend earned +${res.awardedInviter} EXP.',
                            variant: OwlSnackVariant.success,
                          );
                          Navigator.of(context).maybePop();
                        }
                      } catch (e) {
                        if (mounted) {
                          OwlSnack.show(
                            context,
                            title: 'Could not redeem',
                            message: '$e',
                            variant: OwlSnackVariant.error,
                          );
                        }
                      } finally {
                        if (mounted) setState(() => _busy = false);
                      }
                    },
              child: _busy
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Redeem'),
            ),
          ),
        ],
      ),
    );
  }
}

class ExpBadge extends ConsumerWidget {
  const ExpBadge({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final exp = ref.watch(myXpProvider).maybeWhen(
          data: (v) => v,
          orElse: () => 0,
        );
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: black,
        border: Border.all(color: grey.withOpacity(.6)),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.bolt, color: Colors.amber, size: 18),
          const SizedBox(width: 6),
          Text('$exp EXP', style: Styles.boldText),
        ],
      ),
    );
  }
}
