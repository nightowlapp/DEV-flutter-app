import 'dart:async';

import 'package:animated_list_plus/animated_list_plus.dart';
import 'package:animated_list_plus/transitions.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nightowlcode/data/providers/party_status/party_status_provider.dart';
import 'package:nightowlcode/navigation/nav_shortcuts.dart';
import 'package:nightowlcode/shared/constants/colors.dart';
import 'package:nightowlcode/shared/constants/styles.dart';
import 'package:nightowlcode/shared/constants/values.dart';
import 'package:nightowlcode/shared/reusable/ui/loading/error_screen.dart';
import 'package:nightowlcode/shared/reusable/ui/loading_indicator.dart';
import 'package:nightowlcode/shared/reusable/users/profile_picture_avatar.dart';
import 'package:nightowlcode/shared/utility/utility.dart';
import '../../../data/providers/users/friends/friend_request_provider.dart';
import '../../../data/providers/users/friends/friend_suggestions_provider.dart';
import '../../../models/users/user.dart' as model;
import '../../../data/repositories/users/friend_requests_repository.dart';
import '../../../shared/constants/enums.dart';

class FindFriendsSection extends ConsumerStatefulWidget {
  const FindFriendsSection({super.key});

  @override
  ConsumerState<FindFriendsSection> createState() => _FindFriendsSectionState();
}

class _FindFriendsSectionState extends ConsumerState<FindFriendsSection> {
  @override
  Widget build(BuildContext context) {
    final q = ref.watch(userSearchQueryProvider);
    final usersAv = ref.watch(suggestedUsersProvider);

    // Only pending outgoing
    final outgoing = ref.watch(outgoingFriendRequestsProvider).maybeWhen(
          data: (l) => l
              .where((r) => r.status == FriendRequestStatus.pending)
              .map((e) => e.toUid)
              .toSet(),
          orElse: () => <String>{},
        );

    // 👇 New: how many suggestions / matches we currently have
    final int? matchCount = usersAv.asData?.value.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Find Friends', style: Styles.basicTextHeader),
        const SizedBox(height: 8),
        _SearchField(
          initial: q,
          onChanged: (v) =>
              ref.read(userSearchQueryProvider.notifier).state = v,
          matchCount: matchCount, // 👈 pass down
        ),
        const SizedBox(height: 8),
        usersAv.when(
          loading: () => const SizedBox(
            height: 80,
            child: Center(child: LoadingIndicator()),
          ),
          error: (e, _) => const ErrorScreen(),
          data: (list) {
            if (list.isEmpty) {
              return Text(
                q.trim().isEmpty ? '' : 'No results for “$q”',
                style: Styles.smallText,
              );
            }

            return ImplicitlyAnimatedList<model.User>(
              items: list,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              areItemsTheSame: (a, b) => a.id == b.id,
              insertDuration: const Duration(milliseconds: 300),
              removeDuration: const Duration(milliseconds: 300),
              updateDuration: const Duration(milliseconds: 250),
              itemBuilder: (context, animation, u, index) {
                return SizeFadeTransition(
                  animation: animation,
                  curve: Curves.easeInOut,
                  child: _UserRow(
                    user: u,
                    alreadyPending: outgoing.contains(u.id),
                  ),
                );
              },
              removeItemBuilder: (context, animation, oldItem) {
                return SizeFadeTransition(
                  animation: animation,
                  curve: Curves.easeInOut,
                  child: _UserRow(
                    user: oldItem,
                    alreadyPending: outgoing.contains(oldItem.id),
                  ),
                );
              },
              updateItemBuilder: (context, animation, item) {
                return FadeTransition(
                  opacity: animation.drive(Tween(begin: 0.6, end: 1.5)),
                  child: _UserRow(
                    user: item,
                    alreadyPending: outgoing.contains(item.id),
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }
}

class _UserRow extends ConsumerStatefulWidget {
  const _UserRow({required this.user, required this.alreadyPending});
  final model.User user;
  final bool alreadyPending;

  @override
  ConsumerState<_UserRow> createState() => _UserRowState();
}

class _UserRowState extends ConsumerState<_UserRow> {
  bool _sending = false;

  @override
  Widget build(BuildContext context) {
    final repo = ref.read(friendRequestsRepositoryProvider);

    final borderColor = ref.read(
      partyStatusColorForProvider(widget.user.currentPartyStatus),
    );

    final trailing = switch ((widget.alreadyPending, _sending)) {
      (true, _) => _RequestedChip(),
      (false, true) => const SizedBox(
          width: 24,
          height: 24,
          child: LoadingIndicator(),
        ),
      (false, false) => IconButton(
          tooltip: 'Add friend',
          icon: const Icon(Icons.person_add_alt_1_outlined, color: white),
          onPressed: () async {
            setState(() => _sending = true);
            final res = await repo.send(toUid: widget.user.id);
            if (!mounted) return;
            setState(() => _sending = false);

            final (msg, isOk) = _msgForResult(res, widget.user.userName);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(msg),
                backgroundColor:
                    isOk ? Colors.green.shade700 : Colors.red.shade700,
                behavior: SnackBarBehavior.floating,
              ),
            );
          },
        ),
    };

    return InkWell(
      borderRadius: BorderRadius.circular(borderRadiusDefault),
      onTap: () {
        context.pushNamedPage(
          'otherProfile',
          extra: widget.user.id,
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: black,
          borderRadius: BorderRadius.circular(borderRadiusDefault),
          border: Border.all(
            color: borderColor,
            width: 0.5,
          ),
        ),
        child: Row(
          children: [
            ProfilePictureAvatar(
              borderColor: borderColor,
              imageUrl: widget.user.profilePictureUrl,
              onTap: () {
                context.pushNamedPage(
                  'otherProfile',
                  extra: widget.user.id,
                );
              },
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AutoSizeText(
                    Utility.formatString(widget.user.userName),
                    maxLines: 1,
                  ),
                  widget.user.displayFullName.isNotEmpty
                      ? Text(
                          Utility.formatString(widget.user.displayFullName),
                          style: Styles.smallText,
                        )
                      : const SizedBox.shrink(),
                ],
              ),
            ),
            trailing,
          ],
        ),
      ),
    );
  }

  (String, bool) _msgForResult(FriendRequestSendResult r, String name) {
    switch (r) {
      case FriendRequestSendResult.sent:
        return ('Friend request sent to $name', true);
      case FriendRequestSendResult.notAuthenticated:
        return ('You need to sign in first.', false);
      case FriendRequestSendResult.selfRequest:
        return ('You cannot add yourself.', false);
      case FriendRequestSendResult.alreadyFriends:
        return ('You are already friends.', false);
      case FriendRequestSendResult.alreadyPending:
        return ('Request already pending.', false);
      case FriendRequestSendResult.error:
      default:
        return ('Could not send request. Try again.', false);
    }
  }
}

class _RequestedChip extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white10,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: owlPurple, width: 1),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check, color: owlPurple, size: 16),
          SizedBox(width: 6),
          Text('Requested', style: TextStyle(color: owlPurple)),
        ],
      ),
    );
  }
}

class _SearchField extends StatefulWidget {
  const _SearchField({
    required this.initial,
    required this.onChanged,
    required this.matchCount,
  });
  final String initial;
  final ValueChanged<String> onChanged;
  final int? matchCount;

  @override
  State<_SearchField> createState() => _SearchFieldState();
}

class _SearchFieldState extends State<_SearchField> {
  late final TextEditingController _c;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _c = TextEditingController(text: widget.initial);
  }

  @override
  void didUpdateWidget(covariant _SearchField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initial != widget.initial && _c.text != widget.initial) {
      _c.text = widget.initial;
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _c.dispose();
    super.dispose();
  }

  void _onChangedDebounced(String v) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      widget.onChanged(v);
    });
  }

  @override
  Widget build(BuildContext context) {
    final hasText = _c.text.trim().isNotEmpty;
    final count = widget.matchCount;

    // decide label: matches when searching, nearby when idle
    final label = hasText ? ' matches' : ' nearby';
    final semantics = hasText ? 'Friend matches' : 'Nearby friends';

    return TextField(
      controller: _c,
      style: const TextStyle(color: white),
      cursorColor: white,
      decoration: InputDecoration(
        hintText: 'Search username or name',
        hintStyle: Styles.smallText.copyWith(color: greyLighter),
        isDense: true,
        filled: true,
        fillColor: owlPurple.withOpacity(0.03),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadiusDefault),
          borderSide: const BorderSide(color: white, width: 0.7),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadiusDefault),
          borderSide: const BorderSide(color: white, width: 0.7),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadiusDefault),
          borderSide: const BorderSide(color: white, width: 0.9),
        ),
        prefixIcon: const Icon(Icons.search, color: white),

        // 👇 NEW: "x nearby / matches" + clear button like VenueSearchBar
        suffixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
        suffixIcon: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: EdgeInsets.only(
                right: label.trim() == 'nearby' ? 16 : 6,
              ),
              child: _FriendCountText(
                count: count,
                label: label,
                semanticsLabelWhenUnknown: semantics,
              ),
            ),
            if (hasText)
              IconButton(
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(horizontal: 0),
                constraints: const BoxConstraints(),
                icon: const Icon(Icons.clear, color: white),
                onPressed: () {
                  _c.clear();
                  _onChangedDebounced('');
                  setState(() {});
                },
              ),
          ],
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 0),
      ),
      onChanged: (v) {
        _onChangedDebounced(v);
        setState(() {}); // update suffix (hasText + label)
      },
    );
  }
}

class _FriendCountText extends StatelessWidget {
  const _FriendCountText({
    required this.count,
    required this.label,
    required this.semanticsLabelWhenUnknown,
  });

  final int? count;
  final String label; // ' nearby' or ' matches'
  final String semanticsLabelWhenUnknown;

  @override
  Widget build(BuildContext context) {
    Widget child;

    if (count == null) {
      // nothing yet (e.g. loading) but keep semantics if you want SRs to read something
      child = Semantics(
        key: const ValueKey('friend_count_empty'),
        label: semanticsLabelWhenUnknown,
        child: const SizedBox.shrink(),
      );
    } else {
      final isMatchesLabel =
          label.trim() == 'matches' || label.contains('matches');
      final plural = isMatchesLabel
          ? (count == 1 ? ' match' : ' matches')
          : label; // e.g. ' nearby'
      final numColor = (count == 0) ? red : owlPurple;

      child = Semantics(
        key: ValueKey('friend_count_${label}_$count'),
        label: '$count$plural',
        child: Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: '$count',
                style: TextStyle(
                  color: numColor,
                  fontWeight: FontWeight.w700,
                  fontSize: fontSizeSmall,
                ),
              ),
              TextSpan(
                text: plural,
                style: Styles.basicText,
              ),
            ],
          ),
        ),
      );
    }

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      switchInCurve: Curves.easeOut,
      switchOutCurve: Curves.easeIn,
      child: child,
    );
  }
}
