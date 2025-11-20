import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:nightowlcode/data/firestore_paths/firestore_collections%20.dart';
import 'package:nightowlcode/shared/constants/colors.dart';
import 'package:nightowlcode/shared/constants/enums.dart';
import 'package:nightowlcode/shared/constants/styles.dart';

import '../../../data/firestore_paths/user_paths.dart';

class TotalUsersSection extends StatelessWidget {
  const TotalUsersSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 0.0),
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection(FirestoreCollections.users).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const SizedBox();

          final docs = snapshot.data!.docs;
          final allUsers = docs.length;
          final femaleCount = docs
              .where((doc) =>
          (doc.data() as Map<String, dynamic>)[UserDocumentPaths.gender] == FirestoreFields.female)
              .length;
          final maleCount = docs
              .where((doc) =>
          (doc.data() as Map<String, dynamic>)[UserDocumentPaths.gender] == FirestoreFields.male)
              .length;
          final isAndroidUser = docs
              .where((doc) =>
          (doc.data() as Map<String, dynamic>)[UserDocumentPaths.platformType]
              ?.toLowerCase() ==
              PlatformType.android.name)
              .length;
          final isIOSUser = docs
              .where((doc) =>
          (doc.data() as Map<String, dynamic>)[UserDocumentPaths.platformType]
              ?.toLowerCase() ==
              PlatformType.ios.name)
              .length;

          return LayoutBuilder(
            builder: (context, constraints) {
              final screenWidth = constraints.maxWidth;
              final spacing = screenWidth * 0.10;

              return Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Text('Total Users',
                          style: Styles.basicText.copyWith(color: adminColor)),
                      Text('$allUsers',
                          style: Styles.basicText.copyWith(
                              decoration: TextDecoration.underline)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        children: [
                          Column(
                            children: [
                              Text('Female', style: Styles.basicText),
                              Text('$femaleCount',
                                  style: Styles.basicText.copyWith(
                                      fontWeight: FontWeight.bold,
                                      decoration: TextDecoration.underline)),
                            ],
                          ),
                          SizedBox(width: spacing),
                          Column(
                            children: [
                              Text('Male', style: Styles.basicText),
                              Text('$maleCount',
                                  style: Styles.basicText.copyWith(
                                      fontWeight: FontWeight.bold,
                                      decoration: TextDecoration.underline)),
                            ],
                          ),
                        ],
                      ),
                      Container(
                        height: 30,
                        width: 1,
                        color: adminColor,
                        margin: EdgeInsets.symmetric(horizontal: spacing),
                      ),
                      Row(
                        children: [
                          Column(
                            children: [
                              Text('Android', style: Styles.basicText),
                              Text('$isAndroidUser',
                                  style: Styles.basicText.copyWith(
                                      fontWeight: FontWeight.bold,
                                      decoration: TextDecoration.underline)),
                            ],
                          ),
                          SizedBox(width: spacing),
                          Column(
                            children: [
                              Text('iOS', style: Styles.basicText),
                              Text('$isIOSUser',
                                  style: Styles.basicText.copyWith(
                                      fontWeight: FontWeight.bold,
                                      decoration: TextDecoration.underline)),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}
