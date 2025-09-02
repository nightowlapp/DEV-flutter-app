//
// Column(
// crossAxisAlignment: CrossAxisAlignment.start,
// children: [
// Row(
// mainAxisAlignment: MainAxisAlignment.spaceBetween,
// children: [
// Text(
// 'Reviews',
// style: Styles.basicTextHeader,
// ),
// // AddRatingButton(
// // clubId: widget.club.id,
// // onRatingSubmitted: () {
// // Navigator.push;
// // },
// // ),
// ],
// ),
// ]),
// // Row(
// // crossAxisAlignment: CrossAxisAlignment.start,
// // children: [Column(
// // mainAxisAlignment: MainAxisAlignment.start,
// // crossAxisAlignment: CrossAxisAlignment.center,
// // children: [
// // Text(
// // venue.rating!.toStringAsFixed(1),
// // style: Styles.basicText.copyWith(fontSize: 28),
// // ),
// // const SizedBox(height: 4),
// // Row(
// // children: List.generate(5, (index) {
// // final double rating = venue.rating!;
// // if (rating >= index + 1) {
// // return const Icon(Icons.star,
// // color: owlOrange, size: 14);
// // }
// // else if (rating > index) {
// // return const Icon(Icons.star_half,
// // color: owlOrange, size: 14);
// // }
// // else {
// // return const Icon(Icons.star_border,
// // color: owlOrange, size: 14);
// // }
// // }
// // ),
// // ),
// // const SizedBox(height: 4),
// // // FutureBuilder<String>(
// // //   future: fetchRatingCount(widget.club.id),
// // //   builder: (context, snapshot) {
// // //     if (snapshot.connectionState ==
// // //         ConnectionState.waiting) {
// // //       return const SizedBox.shrink();
// // //     }
// // //     final ratingText = snapshot.data ?? '';
// // //     return Text(
// // //       ratingText,
// // //       style: const TextStyle(
// // //           color: white, fontSize: 10),
// // //       textAlign: TextAlign.center,
// // //     );
// // //   },
// // // ),
// // const SizedBox(height: 15),
// // Row(
// // crossAxisAlignment: CrossAxisAlignment.center,
// // children: [
// // CircleAvatar(
// // radius: 15,
// // backgroundColor: purple,
// // child: CircleAvatar(
// // radius: 13,
// // //   backgroundImage: context
// // //       .watch<GlobalProvider>()
// // //       .profilePicture,
// // ),
// // ),
// // const SizedBox(width: 8),
// // // RateVenue(venueid: venue.id),
// // ],
// // ),
// // const Spacer(),
// // // FutureBuilder<QuerySnapshot>(
// // //   future: FirebaseFirestore.instance
// // //     .collection('club_data')
// // //     .doc(widget.club.id)
// // //     .collection('ratings')
// // //     .get(),
// // //   builder: (context, snapshot) {
// // //     if (snapshot.connectionState ==
// // //       ConnectionState.waiting) {
// // //       return const SizedBox.shrink();
// // //     }
// // //     if (!snapshot.hasData ||
// // //       snapshot.data!.docs.isEmpty) {
// // //       return const SizedBox.shrink();
// // //     }
// //
// // // final ratings = snapshot.data!.docs
// // //   .map((doc) => (doc['rating'] as num).toInt())
// // //   .toList();
// //
// // final counts = [0, 0, 0, 0, 0];
// // for (var rating in ratings) {
// // if (rating >= 1 && rating <= 5) {
// // counts[5 - rating]++;
// // }
// // }
// // final totalCount = ratings.length;
// //
// // return Column(
// // crossAxisAlignment: CrossAxisAlignment.start,
// // children: List.generate(5, (index) {
// // final count = counts[index];
// // final ratingValue = 5 - index;
// // final showLabel =
// // [5, 3, 1].contains(ratingValue);
// //
// // return Padding(
// // padding: const EdgeInsets.only(bottom: 12.0),
// // child: Row(
// // crossAxisAlignment:
// // CrossAxisAlignment.center,
// // children: [
// // SizedBox(
// // width: 10,
// // child: showLabel
// // ? Text(
// // ratingValue.toString(),
// // style: const TextStyle(
// // color: white,
// // fontSize: 12,
// // ),
// // textAlign: TextAlign.right,
// // )
// //     : const SizedBox.shrink(),
// // ),
// // const SizedBox(width: 4),
// // SizedBox(
// // width: 200,
// // child: LinearProgressIndicator(
// // value: totalCount > 0
// // ? count / totalCount
// //     : 0,
// // backgroundColor: grey,
// // color: primaryColor,
// // minHeight: 8,
// // borderRadius:
// // BorderRadius.circular(22),
// // ),
// // ),
// // ],
// // ),
// // );
// // }
// // ),
// // );
// // },
// // ),
// // ],
// // ),
// // ],
// // ),