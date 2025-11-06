import 'package:flutter/material.dart';
import 'package:nightowlcode/data/repositories/users/feedback_repository.dart';
import 'package:nightowlcode/shared/constants/colors.dart';
import 'package:nightowlcode/shared/constants/icons.dart';
import 'package:nightowlcode/shared/constants/styles.dart';
import 'package:nightowlcode/shared/constants/values.dart';
import 'package:nightowlcode/shared/reusable/ui/buttons.dart';
import 'package:nightowlcode/shared/reusable/ui/popup_dialog_default.dart';

import '../../../../shared/reusable/ui/owl_snack.dart';

class FeedbackButton extends StatefulWidget {
  const FeedbackButton({super.key});

  @override
  State<FeedbackButton> createState() => _FeedbackButtonState();
}

class _FeedbackButtonState extends State<FeedbackButton> {
  final Map<String, String> categoryLabels = {
    'suggestion': 'General Suggestion',
    'bug': 'Something Broken (bug)',
    'missing_feature': 'Missing Feature',
    'confusing': 'Hard to Understand (confusion)',
  };

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showFeedbackDialog(context),
      child: Column(
        children: [
          const SizedBox(height: verticalSpacerSmall),
          Row(
            children: [
              Icon(
                feedback,
                color: owlPurple,
                size: iconSizeDefault,
              ),
              const SizedBox(width: 12),
              Text(
                'Give Feedback',
                style: Styles.boldText,
              ),
            ],
          ),
          const SizedBox(height: verticalSpacerMedium),
          const Divider(color: owlPurple, thickness: 0.5),
          const SizedBox(height: verticalSpacerMedium),
        ],
      ),
    );
  }
  Future<void> _showFeedbackDialog(BuildContext context) async {
    final controller = TextEditingController();
    String selectedCategory = 'suggestion';

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return PopupDialogDefault(
              title: 'Send Feedback',
              children: [
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: categoryLabels.entries.map((entry) {
                      final isSelected = selectedCategory == entry.key;
                      return ChoiceChip(
                        label: Text(
                          entry.value,
                          style: Styles.smallText.copyWith(
                            color: isSelected ? owlPurple : white,
                          ),
                        ),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        selected: isSelected,
                        selectedColor: owlPurple.withOpacity(0.2),
                        backgroundColor: black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: BorderSide(color: isSelected ? owlPurple : grey),
                        ),
                        onSelected: (_) {
                          setModalState(() {
                              selectedCategory = entry.key;
                            }
                          );
                        },
                      );
                    }
                  ).toList(),
                ),

                const SizedBox(height: verticalSpacerMedium),

                TextField(
                  controller: controller,
                  maxLines: 10,
                  style: Styles.basicText,
                  decoration: const InputDecoration(
                    hintText: "Type your feedback here.",
                    hintStyle: TextStyle(color: Colors.grey, fontSize: 8),
                    border: OutlineInputBorder(),
                  ),
                ),

                const SizedBox(height: verticalSpacerMedium),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    OwlButton(
                      label: "Cancel",
                      onPressed: () => Navigator.pop(context),
                      backgroundColor: red,
                      borderColor: black,
                      textColor: white,
                      fullWidth: false,
                    ),


                    OwlButton(
                      label: "Submit",
                      onPressed: () async {
                        final text = controller.text.trim();
                        if (text.isEmpty) return;

                        await FeedbackRepository.submitAppFeedback(
                          text: text,
                          category: selectedCategory,
                        );

                        Navigator.pop(context);

                        OwlSnack.show(
                          context,
                          title: "Feedback sent",
                          message: "Thanks for helping improve NightOwl!",
                          variant: OwlSnackVariant.success,
                        );
                      },
                      backgroundColor: owlPurple,
                      textColor: white,
                      borderColor: transparent,
                      fullWidth: false,
                    ),
                  ],
                ),
              ],
            );
          },
        );
      },
    );
  }

}
