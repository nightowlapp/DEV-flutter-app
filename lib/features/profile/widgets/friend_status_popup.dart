import 'package:flutter/material.dart';

import '../../../shared/constants/colors.dart';
import '../../../shared/constants/icons.dart';
import '../../../shared/constants/styles.dart';
import '../../../shared/constants/values.dart';

enum FriendStatusChoice { closeFriend, friend, unfriend }

class FriendStatusPopup extends StatelessWidget {
  final String userName;
  final bool isCloseFriend;

  const FriendStatusPopup({
    super.key,
    required this.userName,
    required this.isCloseFriend,
  });

  /// Bottom popup (modal sheet) styled similarly to OwlSnack.
  static Future<FriendStatusChoice?> show(
    BuildContext context, {
      required String userName,
      required bool isCloseFriend,
    }) {
    return showModalBottomSheet<FriendStatusChoice>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: false,
      builder: (ctx) => FriendStatusPopup(
        userName: userName,
        isCloseFriend: isCloseFriend,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        // Same outer margin style as OwlSnack
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        child: Container(
          decoration: BoxDecoration(
            color: black,
            borderRadius: BorderRadius.circular(borderRadiusDefault),
            border: Border.all(color: grey, width: 0.7),
          ),
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header row (matches OwlSnack style)
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Friend status',
                      style: Styles.popupHeader.copyWith(color: white),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(
                      closeIcon,
                      size: iconSizeDefault,
                    ),
                  ),
                ],
              ),
              const Divider(color: owlPurple),
              Align(
                alignment: Alignment.centerLeft,
                child: Row(
                  children: [
                    Text(
                      'Choose how you want to classify ',
                      style: Styles.popupText.copyWith(color: greyLighter),
                    ), Text(
                      userName,
                      style: Styles.popupText.copyWith(color: owlPurple),
                    ), Text(
                      '.',
                      style: Styles.popupText.copyWith(color: greyLighter),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Close friend
              _buildOption(
                context,
                label: 'Close friend',
                description:
                'Show more of $userName and enable close friend features.',
                selected: isCloseFriend,
                color: owlPurple,
                result: FriendStatusChoice.closeFriend,
              ),
              const SizedBox(height: 8),

              // Normal friend
              _buildOption(
                context,
                label: 'Friend',
                description: 'Keep $userName as a regular friend.',
                selected: !isCloseFriend,
                color: blue,
                result: FriendStatusChoice.friend,
              ),
              const SizedBox(height: 8),

              // Remove friend
              _buildOption(
                context,
                label: 'Remove friend',
                description: 'You will no longer be friends.',
                selected: false,
                color: red,
                result: FriendStatusChoice.unfriend,
              ),

              // _buildOption( //TODO make this friend never see me on map.
              //   context,
              //   selected: false,
              //   color: red,
              // ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOption(
    BuildContext context, {
      required String label,
      required String description,
      required bool selected,
      required Color color,
      required FriendStatusChoice result,
    }) {
    return InkWell(
      onTap: () => Navigator.of(context).pop(result),
      borderRadius: BorderRadius.circular(borderRadiusSmall),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon( // Todo icons star so on
            selected ? Icons.radio_button_checked : Icons.radio_button_off,
            color: selected ? color : greyLighter,
            size: iconSizeLarge,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Styles.basicText.copyWith(color: color),
                ),
                const SizedBox(height: 2),
                // Text(
                // description,
                // style: Styles.smallText.copyWith(color: greyLighter),
                // ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
