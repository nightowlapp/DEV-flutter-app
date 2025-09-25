import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nightowlcode/core/platform_config.dart';
import 'package:nightowlcode/features/main/widgets/utility/redeem_referral_sheet.dart';
import 'package:nightowlcode/shared/constants/colors.dart';
import 'package:nightowlcode/shared/constants/styles.dart';
import 'package:nightowlcode/shared/constants/values.dart';
import 'package:nightowlcode/shared/reusable/ui/owl_snack.dart';
import 'package:share_plus/share_plus.dart';

import 'package:nightowlcode/shared/constants/icons.dart';

import '../../../../data/repositories/users/referral_repository.dart';

// ---------- Connected wrapper: fetches inviteCode & inviteLink ----------
class ReferAFriendLeftDrawerConnected extends ConsumerWidget {
  const ReferAFriendLeftDrawerConnected({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final codeAsync = ref.watch(inviteCodeProvider);
    final linkAsync = ref.watch(inviteLinkProvider);

    return codeAsync.when(
      data: (code) {
        final link = linkAsync.maybeWhen(data: (l) => l, orElse: () => '');
        return ReferAFriendLeftDrawer(inviteCode: code, inviteLink: link);
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Referral unavailable: $e')),
    );
  }
}

/// Refer-a-friend section for the LEFT drawer.
class ReferAFriendLeftDrawer extends StatelessWidget {
  const ReferAFriendLeftDrawer({
    super.key,
    required this.inviteCode,
    required this.inviteLink,
  });

  final String inviteCode;
  final String inviteLink;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(borderRadiusDefault * 1.2);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Stack(
          children: [
            Center(child: Text('Refer a Friend', style: Styles.boldText)),
             Align(
              alignment: Alignment.centerLeft,
              child: Icon(qrCodeIcon, color: owlPurple),
            ),
          ],
        ),
        const SizedBox(height: verticalSpacerSmall),

        // ---------- QR ----------
        ClipRRect(
          borderRadius: radius,
          child: LayoutBuilder(
            builder: (context, constraints) {
              const pad = allSidePaddingDefault * 2;
              final double maxSide = (constraints.maxWidth - pad)
                  .clamp(80.0, 2048.0) / 2;

              return Container(
                padding: const EdgeInsets.all(allSidePaddingDefault),
                decoration: BoxDecoration(
                  color: black,
                  borderRadius: BorderRadius.circular(borderRadiusDefault),
                ),
                child: Center(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => _showQrFullscreen(context, inviteLink),
                    child: Tooltip(
                      message: 'Tap to show full-screen QR',
                      child: SizedBox.square(
                        dimension: maxSide,
                        child: _QrFromNetwork(
                          data: inviteLink,
                          size: maxSide,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),

        const SizedBox(height: verticalSpacerSmall),

        // ---------- ACTIONS ----------
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 8,
          runSpacing: 8,
          children: [
            _SmallOutlinedButton(
              icon: fullScreenIcon,
              label: 'Show QR',
              onPressed: () => _showQrFullscreen(context, inviteLink),
            ),
            _SmallOutlinedButton(
              icon: Icons.ios_share,
              label: 'Share link',
              onPressed: () => Share.share(inviteLink, subject: 'Join me on NightOwl'),
            ),
            _SmallOutlinedButton(
              icon: copyIcon,
              label: 'Copy link',
              onPressed: () {
                Clipboard.setData(ClipboardData(text: inviteLink));
                OwlSnack.show(
                  context,
                  title: 'Link Copied',
                  message: '$inviteLink copied to clipboard.',
                  variant: OwlSnackVariant.success,
                  duration: const Duration(seconds: 4),
                );
              },
            ),
            _SmallOutlinedButton(
              icon: Icons.key,
              label: 'Redeem code',
              onPressed: () => showModalBottomSheet(
                context: context,
                backgroundColor: black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(borderRadiusDefault),
                ),
                builder: (_) => const RedeemReferralSheet(),
              ),
            ),
          ],
        ),

        const SizedBox(height: verticalSpacerSmall),
        Center(child: Text('Your code: $inviteCode', style: Styles.basicTextHeader)),
      ],
    );
  }

  void _showQrFullscreen(BuildContext context, String link) {
    final double dy = -PlatformConfig.height(context) * 0.14;
    showDialog(
      context: context,
      builder: (_) => Transform.translate(
        offset: Offset(0, dy),
        child: Dialog(
          backgroundColor: black,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadiusDefault),
            side: const BorderSide(color: grey, width: 0.7),
          ),
          child: Padding(
            padding: const EdgeInsets.all(allSidePaddingDefault * 1.5),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Scan to join NightOwl',
                    style: Styles.basicTextHeader.copyWith(fontSize: 18)),
                const SizedBox(height: verticalSpacerSmall),
                const Divider(color: grey),
                const SizedBox(height: verticalSpacerSmall),
                SelectableText(
                  'Earn experience by referring your friends!',
                  style: Styles.basicTextHeader,
                  textAlign: TextAlign.center,
                ),
                _QrFromNetwork(
                  data: link,
                  size: PlatformConfig.width(context) * 0.85,
                ),
                SelectableText(
                  link,
                  style: Styles.boldText,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _QrFromNetwork extends StatelessWidget {
  const _QrFromNetwork({required this.data, required this.size});
  final String data;
  final double size;

  @override
  Widget build(BuildContext context) {
    final encoded = Uri.encodeComponent(data);
    final url =
        'https://api.qrserver.com/v1/create-qr-code/?size=${size.toInt()}x${size.toInt()}&data=$encoded';

    return Image.network(
      url,
      width: size,
      height: size,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.medium,
      errorBuilder: (_, __, ___) => Container(
        width: size,
        height: size,
        color: Colors.black,
        alignment: Alignment.center,
        child: const Text('QR unavailable', style: TextStyle(color: white)),
      ),
    );
  }
}

class _SmallOutlinedButton extends StatelessWidget {
  const _SmallOutlinedButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: PlatformConfig.width(context) * 0.35,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(999),
          ),
          textStyle: Styles.boldText.copyWith(fontSize: fontSizeSmall),
        ),
        icon: Icon(icon, color: owlPurple),
        label: Text(label),
      ),
    );
  }
}
