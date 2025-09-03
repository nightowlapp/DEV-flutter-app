import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nightowlcode/shared/constants/colors.dart';
import 'package:nightowlcode/shared/constants/icons.dart';
import 'package:nightowlcode/shared/constants/values.dart';
import 'package:nightowlcode/shared/reusable/ui/popup_dialog_default.dart';
import 'package:nightowlcode/shared/constants/enums.dart';
import 'package:nightowlcode/shared/utility/utility.dart';

import '../../../data/providers/party_status/party_status_provider.dart';
import '../../constants/styles.dart'; // PartyStatusTypes
import '../../party_status_store.dart';

class PartyStatusIndicator extends ConsumerStatefulWidget {
  const PartyStatusIndicator({super.key});

  @override
  ConsumerState<PartyStatusIndicator> createState() => _PartyStatusIndicatorState();
}

class _PartyStatusIndicatorState extends ConsumerState<PartyStatusIndicator> {
  PartyStatusTypes _status = PartyStatusTypes.still_planning;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    final store = ref.read(partyStatusStoreProvider);
    final persisted = await store.loadStatus();
    if (!mounted) return;
    setState(() {
      _status = persisted ?? _status;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final store = ref.watch(partyStatusStoreProvider);

    return GestureDetector(
      onTap: () async {
        HapticFeedback.selectionClick();
        final picked = await _showStatusDialog(context, initial: _status);
        if (picked == null) return;

        // // Simulate a tiny DB write TODO DB
        // await Future.delayed(const Duration(milliseconds: 250));
        // if (!mounted) return;

        setState(() => _status = picked);
        await store.saveStatus(picked); // keep last selected for "whenever it is shown"
        ref.invalidate(partyStatusColorProvider);
        HapticFeedback.mediumImpact(); //TODO Use a lot more many places.

      },
      child: CircleAvatar(
        backgroundColor: transparent, // Todo if not responed to day flash "normal color/null (orange)
        radius: iconSizeDefault, // same size always
        child: _loading
            ? SizedBox(
          width: iconSizeDefault,
          height: iconSizeDefault,
          child: CircularProgressIndicator(strokeWidth: 2, color: greyLighter),
        )
            : Icon(
          partyStatusIcon ,
          size: iconSizeMedium,
          color: _statusColor(_status), // color reflects status
        ),
      ),
    );
  }
}

/* ---------- Popup content (same shell as LanguageSwitcher) ---------- */

Future<PartyStatusTypes?> _showStatusDialog(
    BuildContext context, {
      required PartyStatusTypes initial,
    }) {
  PartyStatusTypes selected = initial;

  return showDialog<PartyStatusTypes>(
    context: context,
    builder: (dialogCtx) => PopupDialogDefault(
      title: 'Select Status',
      children: [
        for (final it in PartyStatusTypes.values)
          ListTile(
            // highlight what is chosen right now
            selected: it == initial,
            selectedTileColor: _statusBg(it),
            leading: _StatusIcon(
              icon: _statusIcon(it),
              color: _statusColor(it),
            ),
            title: Text(Utility.formatString(it.name), style: Styles.popupText,),
            onTap: () {
              HapticFeedback.selectionClick();
              selected = it;
              Navigator.of(dialogCtx).pop<PartyStatusTypes>(it);
            },
          ),
      ],
    ),
  );
}

/* ---------- Small helpers ---------- */

class _StatusIcon extends StatelessWidget {
  const _StatusIcon({
    required this.icon,
    required this.color,
  });

  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: iconSizeDefault,
      height: iconSizeDefault,
      child: Icon(
        icon,
        color: color,
        size: iconSizeDefault,
      ),
    );
  }
}

IconData _statusIcon(PartyStatusTypes s) {
  switch (s) {
    // case PartyStatusTypes.out_tonight:
    //   return myLocation;
  // Icons.local_bar; // TODO Icons when going out?
  //   case PartyStatusTypes.not_tonight:
  //     return myLocation;
  //   case PartyStatusTypes.still_planning:
  //     return myLocation;
    default:return partyStatusIcon;
  }
}

Color _statusColor(PartyStatusTypes s) {
  switch (s) {
    case PartyStatusTypes.out_tonight:
      return green;
    case PartyStatusTypes.house_party:
      return purple;
    case PartyStatusTypes.pregame:
      return yellow;
    case PartyStatusTypes.recovering:
      // return blue;
    // case PartyStatusTypes.not_tonight:
      return red;
    case PartyStatusTypes.still_planning:
      return greyLighter;
    default:
      return greyLighter;
  }
}

// subtle background derived from the status color (keeps it DRY and scalable)
Color _statusBg(PartyStatusTypes s) => _statusColor(s).withOpacity(0.14);
