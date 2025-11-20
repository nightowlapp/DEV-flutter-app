import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:nightowlcode/shared/constants/colors.dart';
import 'package:nightowlcode/shared/constants/styles.dart';

import '../../../shared/utility/utility.dart';

class ClubFavoritesSection extends StatefulWidget {
  @override
  _ClubFavoritesSectionState createState() => _ClubFavoritesSectionState();
}

class _ClubFavoritesSectionState extends State<ClubFavoritesSection> {
  int _limit = 5;
  double containerHeight = 100;

  void _loadMore() {
    setState(() {
        _limit += 15;
        containerHeight = 200;
      }
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header Row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Most Favorited Venues',
              style: Styles.basicText.copyWith(color: adminColor),
            ),
            Text(
              "(Top $_limit)",
              style: Styles.basicText.copyWith(color: adminColor),
            ),
            TextButton(
              onPressed: _loadMore,
              style: TextButton.styleFrom(
                padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 0),
                backgroundColor: adminColor,
              ),
              child: Text('Load More', style: Styles.basicText
              ),
            ),
          ],
        ),

        // 🔸 Column Labels
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4.0),
          child: Row(
            children: [
              Expanded(
                flex: 2,
                child: Text('Name',               style: Styles.basicText.copyWith(color: adminColor),
                ),
              ),
              Expanded(
                flex: 2,
                child: Center(
                  child: Text('Amount',               style: Styles.basicText.copyWith(color: adminColor),
                  ),
                ),
              ),
              Expanded(
                flex: 1,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Location',               style: Styles.basicText.copyWith(color: adminColor),
                  ),
                ),
              ),
            ],
          ),
        ),

        // Clubs Scrollable List
        StreamBuilder<QuerySnapshot>(
          stream:
          FirebaseFirestore.instance.collection('club_data').snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (!snapshot.hasData || snapshot.hasError) {
              return Text(
                'Error loading clubs: ${snapshot.error}',
                style: const TextStyle(color: white),
              );
            }

            final docs = snapshot.data!.docs;
            final sorted = docs.map((doc) {
                final name = Utility.formatString(doc['name']) ?? 'Unnamed';
                final favorites = (doc['favorites'] as List?) ?? [];
                final locationLat = doc['lat'];
                final locationLon = doc['lon'];
                // final location =
                //   ClubDataLocationFormatting.determineLocationFromCoordinates(
                //     locationLat, locationLon);
                return {
                  'name': name,
                  'followers': favorites.length,
                  // 'location': location,
                };
              }
            ).toList()
            ..sort((a, b) => ((b['followers'] ?? 0) as int)
                .compareTo((a['followers'] ?? 0) as int));

            final limited = sorted.take(_limit).toList();

            return Container(
              height: containerHeight,
              padding: const EdgeInsets.only(right: 0.0),
              child: Scrollbar(
                thumbVisibility: true,
                thickness: 1,
                radius: const Radius.circular(22),
                child: SingleChildScrollView(
                  child: Column(
                    children: limited.map((club) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2.0),
                          child: Row(
                            children: [
                              Expanded(
                                flex: 2,
                                child: Text(
                                  club['name'].toString(),
                                  style: Styles.basicText.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Center(
                                  child: Text(
                                    '${club['followers']}',
                                    style: Styles.basicText.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: adminColor,
                                    ),
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 1,
                                child: Align(
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    club['location'].toString(),
                                    style: Styles.basicText.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: adminColor,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }
                    ).toList(),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
