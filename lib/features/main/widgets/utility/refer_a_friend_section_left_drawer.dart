import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nightowlcode/core/platform_config.dart';
import 'package:nightowlcode/shared/constants/colors.dart';
import 'package:nightowlcode/shared/constants/styles.dart';
import 'package:nightowlcode/shared/constants/values.dart';

import '../../../../shared/constants/icons.dart';

/// Refer-a-friend section for the LEFT drawer
/// - Same header style (centered title + left icon)
/// - Shows a QR (easy in-person sharing) and a copyable link (easy remote sharing)
class ReferAFriendLeftDrawer extends StatelessWidget {
  const ReferAFriendLeftDrawer({
    super.key,
    required this.inviteCode,
    this.baseInviteUrl = 'https://owlnight.com/invite',
    this.qrSize = 0, //dynamic size that is as big as possible but fits.
  });

  final String inviteCode;
  final String baseInviteUrl;
  final double qrSize;

  String get _inviteLink {
    // simplest and human-friendly: https://owlnight.com/invite/ABC123
    final cleanBase = baseInviteUrl.endsWith('/')
      ? baseInviteUrl.substring(0, baseInviteUrl.length - 1)
      : baseInviteUrl;
    return '$cleanBase/$inviteCode';
  }

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
              child: Icon(qrCodeIcon, color: owlOrange, size: iconSizeDefault),
            ),
          ],
        ),

        const SizedBox(height: verticalSpacerSmall),

        // ---------- QR CODE (no extra packages: use a QR web service image) ---------- //TODO QR flutter.
        // For production, consider qr_flutter for offline generation.

        // QR: dynamically sized to the max possible that still fits
        ClipRRect(
          borderRadius: BorderRadius.circular(borderRadiusDefault),
          child: LayoutBuilder(
            builder: (context, constraints) {
              // We’re inside the drawer’s content width. Make a square QR that:
              // - uses (maxWidth - padding) so it never overflows horizontally
              // - leaves vertical space for buttons/text
              const double pad = allSidePaddingDefault * 2;
              final double maxSide = (constraints.maxWidth - pad).clamp(80.0, 2048.0);

              return Container(
                padding: const EdgeInsets.all(allSidePaddingDefault),
                decoration: BoxDecoration(
                  color: black,
                  borderRadius: BorderRadius.circular(borderRadiusDefault),
                ),
                child: Center(child:
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => _showQrFullscreen(context, _inviteLink),
                    child: Tooltip(
                      message: 'Tap to show full-screen QR',
                      child: SizedBox.square(
                        dimension: maxSide,
                        child: _QrFromNetwork(
                          data: _inviteLink,
                          size: maxSide,
                        ),
                      ),
                    ),
                  ),
                ),);
            },
          ),
        ),

        const SizedBox(height: verticalSpacerSmall),

        // ---------- ACTIONS ----------
        Wrap(
          alignment: WrapAlignment.center,
          children: [
            _SmallOutlinedButton(
              icon: fullScreenIcon,
              label: 'Show QR',
              onPressed: () => _showQrFullscreen(context, _inviteLink),
            ),

            _SmallOutlinedButton(
              icon: Icons.send,
              label: 'Send link',
              onPressed: () {
                //TODO messenger, messages, SOME
                // Clipboard.setData(ClipboardData(text: inviteCode));
                // ScaffoldMessenger.of(context).showSnackBar(
                //   SnackBar(
                //     content: const Text('Code copied'),
                //     backgroundColor: owlOrange.withOpacity(.9),
                //     behavior: SnackBarBehavior.floating,
                //   ),
                // );
              },
            ),

            _SmallOutlinedButton(
              icon: copyIcon,
              label: 'Copy Link',
              onPressed: () {
                Clipboard.setData(ClipboardData(text: _inviteLink));
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Link copied'),
                    backgroundColor: owlOrange.withOpacity(.9),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
            ),
          ],
        ),
      ],
    );
  }
  void _showQrFullscreen(BuildContext context, String link) {
    // Move UP by 12% of screen height (negative dy = up)
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
            padding: const EdgeInsets.all(allSidePaddingDefault*1.5),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Scan to join NightOwl', style: Styles.basicTextHeader.copyWith(fontSize: fontSizeMediumPlus)),
                const SizedBox(height: verticalSpacerSmall),
                Divider(color: grey,),
                const SizedBox(height: verticalSpacerSmall),
                SelectableText(
                  'Earn experience by referring your friends!',
                  style: Styles.basicTextHeader,
                  textAlign: TextAlign.center,
                ), _QrFromNetwork(
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

/// Minimal QR without packages via a public QR image API.
/// Replace with `qr_flutter` (QrImageView) for offline/branding needs.
class _QrFromNetwork extends StatelessWidget {
  const _QrFromNetwork({required this.data, required this.size});

  final String data;
  final double size;

  @override
  Widget build(BuildContext context) {
    final encoded = Uri.encodeComponent(data);
    // Using goqr.me (api.qrserver.com). You can switch to any QR service or self-host.
    final url = 'https://api.qrserver.com/v1/create-qr-code/?size=${size.toInt()}x${size.toInt()}&data=$encoded';

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
        child: const Text(
          'QR unavailable',
          style: TextStyle(color: white),
        ),
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
    return OutlinedButton.icon(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: white,
        // side: BorderSide(color: grey, width: 0.7), //TODO actually nice glow without
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(999),
        ),
        textStyle: Styles.boldText.copyWith(fontSize: fontSizeSmall),
      ),
      icon: Icon(icon, size: iconSizeDefault, color: owlOrange),
      label: Text(label),
    );
  }
}
