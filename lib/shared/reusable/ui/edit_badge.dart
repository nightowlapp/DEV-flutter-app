import 'package:flutter/material.dart';
import 'package:nightowlcode/shared/constants/colors.dart';
import 'package:nightowlcode/shared/constants/icons.dart';
import 'package:nightowlcode/shared/constants/styles.dart';
import 'package:nightowlcode/shared/constants/values.dart';
import 'package:nightowlcode/shared/reusable/ui/popup_dialog_default.dart';

import '../../../data/repositories/users/feedback_repository.dart';
import '../../../models/venues/venue.dart';
import '../../utility/utility.dart';
import 'owl_snack.dart';

class EditBadge extends StatelessWidget {
  const EditBadge({
    super.key,
    required this.venue,
  });

  final Venue venue;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showEditDialog(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        decoration: BoxDecoration(
          color: black,
          borderRadius: BorderRadius.circular(borderRadiusSmall),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(editIcon, color: greyLighter, size: iconSizeDefault),
            Text('Edit', style: Styles.smallText.copyWith(fontSize: 6, color: greyLighter)),
          ],
        ),
      ),
    );
  }

  void _showEditDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => PopupDialogDefault(
        title: 'Suggest an edit',
        children: [
          _EditOption(
            label: 'Wrong age restriction',
            icon: Icons.child_friendly_outlined,
            onTap: () => _submit(context, 'wrong_age_restriction'),
          ),
          _EditOption(
            label: 'Wrong venue type',
            icon: venuesIcon,
            onTap: () => _submit(context, 'wrong_type'),
          ),
          _EditOption(
            label: 'Wrong tags',
            icon: Icons.tag_outlined,
            onTap: () => _submit(context, 'wrong_tags'),
          ),
          _EditOption(
            label: 'Wrong opening hours',
            icon: Icons.schedule_outlined,
            onTap: () => _submit(context, 'wrong_opening_hours'),
          ),
          _EditOption(
            label: 'Wrong entry price',
            icon: Icons.attach_money_outlined,
            onTap: () => _submit(context, 'wrong_entry_price'),
          ),
          _EditOption(
            label: 'Wrong dress code',
            icon: Icons.checkroom_outlined,
            onTap: () => _submit(context, 'wrong_dress_code'),
          ),
          _EditOption(
            label: 'Wrong offer(s)',
            icon: Icons.local_offer_outlined,
            onTap: () => _submit(context, 'wrong_offers'),
          ),
          _EditOption(
            label: 'Wrong name',
            icon: Icons.signpost_outlined,
            onTap: () => _submit(context, 'wrong_name'),
          ),
          _EditOption(
            label: 'Wrong location',
            icon: Icons.place_outlined,
            onTap: () => _submit(context, 'wrong_location'),
          ),
        ],
      ),
    );
  }

  Future<void> _submit(BuildContext context, String category) async {
    Navigator.of(context, rootNavigator: true).pop(); // close dialog first
    try {
      await FeedbackRepository.submitVenueFeedback(
        venueId: venue.id,
        category: category,
        message: '', // simple for now; no extra prompt
      );
      OwlSnack.show(
        context,
        title: 'Edit suggestion sent',
        message: 'Category: ${Utility.formatString(category)}',
        variant: OwlSnackVariant.success,
      );
    } catch (e) {
      OwlSnack.show(
        context,
        title: 'Could not send suggestion',
        message: e.toString(),
        variant: OwlSnackVariant.error,
      );
    }
  }
}

/// Simple row item used inside the dialog
class _EditOption extends StatelessWidget {
  const _EditOption({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      splashColor: owlPurple.withOpacity(0.15),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: grey, width: 0.35)),
        ),
        child: Row(
          children: [
            Icon(icon, color: white, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: Styles.popupText.copyWith(color: white),
              ),
            ),
            const Icon(Icons.chevron_right, color: grey),
          ],
        ),
      ),
    );
  }
}
