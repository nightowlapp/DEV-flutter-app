// lib/features/map/widgets/share_location_popup.dart
import 'package:flutter/material.dart';
import 'package:nightowlcode/models/users/location_audience.dart';
import 'package:nightowlcode/shared/constants/colors.dart';
import 'package:nightowlcode/shared/constants/styles.dart';
import 'package:nightowlcode/shared/constants/values.dart';
import 'package:nightowlcode/shared/reusable/ui/owl_popup.dart';

/// Call this to show the popup. Returns the selected audience (or null on dismiss).
Future<LocationAudience?> showShareLocationPopup(
BuildContext context, {
required LocationAudience initial,
int friendsCount = 0,
int closeFriendsCount = 0,
}){
  return showDialog<LocationAudience>(
    context: context,
    barrierDismissible: true,
    builder: (_) => _ShareLocationPopup(
      initial: initial,
      friendsCount: friendsCount,
      closeFriendsCount: closeFriendsCount,
    ),
  );
}

class _ShareLocationPopup extends StatefulWidget {
  const _ShareLocationPopup({
    required this.initial,
    required this.friendsCount,
    required this.closeFriendsCount,
  });

  final LocationAudience initial;
  final int friendsCount;
  final int closeFriendsCount;

  @override
  State<_ShareLocationPopup> createState() => _ShareLocationPopupState();
}

class _ShareLocationPopupState extends State<_ShareLocationPopup> {
  late LocationAudience _selected = widget.initial;

  @override
  Widget build(BuildContext context) {
    final captionStyle = Styles.smallText.copyWith(
      color: greyLighter,
      height: 1.35,
      fontSize: fontSizeSmaller,
    );
    final friends = widget.friendsCount == 1 ? 'person' : 'people';
    final closeFriends = widget.closeFriendsCount == 1 ? 'person' : 'people';

    final buttonLabel = () {
      if (_selected == LocationAudience.none) {
        return 'Do not share location';
      }
      if (_selected == LocationAudience.friends) {
        return 'Share location with ${widget.friendsCount} $friends';
      }
      if (_selected == LocationAudience.closeFriends) {
        return 'Share location with ${widget.closeFriendsCount} $closeFriends';
      }
      return 'Share location';
    }();

    return OwlPopup(
      title: 'Share Location',
      maxWidth: 520,
      maxHeightFraction: 0.86,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton(
            onPressed: () {}, // TODO: open info page
            style: TextButton.styleFrom(
              foregroundColor: owlPurple,
              padding: EdgeInsets.zero,
              minimumSize: const Size(0, 0),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text('Learn more'),
          ),
        ),
        const SizedBox(height: 6),

        _ChoiceTile(
          title: 'Friends',
          subtitle: '${widget.friendsCount} $friends',
          icon: Icons.group_rounded,
          value: LocationAudience.friends,
          groupValue: _selected,
          onChanged: (v) => setState(() => _selected = v),
        ),
        _ChoiceTile(
          title: 'Close Friends',
          subtitle:  '${widget.closeFriendsCount} $closeFriends',
          icon: Icons.star_rounded,
          value: LocationAudience.closeFriends,
          groupValue: _selected,
          onChanged: (v) => setState(() => _selected = v),
        ),
        _ChoiceTile(
          title: 'No one',
          subtitle: "Don't share location",
          icon: Icons.flight_rounded,
          value: LocationAudience.none,
          groupValue: _selected,
          onChanged: (v) => setState(() => _selected = v),
        ),

        const SizedBox(height: 18),

        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () => Navigator.of(context).pop(_selected),
            style: ElevatedButton.styleFrom(
              backgroundColor: owlPurple,
              foregroundColor: white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(borderRadiusDefault),
              ),
            ),

            child: Text(
              buttonLabel,
              style: Styles.basicText,
            ),
          ),
        ),
      ],
    );
  }
}

class _ChoiceTile extends StatelessWidget {
  const _ChoiceTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.value,
    required this.groupValue,
    required this.onChanged,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final LocationAudience value;
  final LocationAudience groupValue;
  final ValueChanged<LocationAudience> onChanged;

  @override
  Widget build(BuildContext context) {
    final selected = value == groupValue;

    return InkWell(
      onTap: () => onChanged(value),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: selected ? owlPurple.withOpacity(0.18) : Colors.white10,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Icon(
                icon,
                color: selected ? owlPurple : white,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Styles.basicText),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: Styles.smallText.copyWith(
                      color: greyLighter,
                      fontSize: fontSizeSmaller,
                    ),
                  ),
                ],
              ),
            ),
            Radio<LocationAudience>(
              value: value,
              groupValue: groupValue,
              onChanged: (v) => onChanged(v!),
              activeColor: owlPurple,
              fillColor: MaterialStateProperty.resolveWith(
                    (states) =>
                states.contains(MaterialState.selected) ? owlPurple : grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
