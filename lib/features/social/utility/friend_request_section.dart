// lib/features/social/widgets/find_friends_section.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nightowlcode/shared/constants/colors.dart';
import 'package:nightowlcode/shared/constants/styles.dart';
import 'package:nightowlcode/shared/constants/values.dart';
import 'package:nightowlcode/shared/reusable/ui/loading_indicator.dart';
import '../../../data/providers/users/friend_request_provider.dart';
import '../../../data/providers/users/friend_suggestions_provider.dart';
import '../../../models/users/user.dart' as model;
import '../../../data/repositories/users/friend_requests_repository.dart';

class FindFriendsSection extends ConsumerWidget {
  const FindFriendsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final q = ref.watch(userSearchQueryProvider);
    final users = ref.watch(suggestedUsersProvider);
    final outgoing = ref.watch(outgoingFriendRequestsProvider).maybeWhen(
      data: (l) => l.map((e) => e.toUid).toSet(),
      orElse: () => <String>{},
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Find Friends', style: Styles.basicTextHeader),
        const SizedBox(height: 10),
        _SearchField(
          initial: q,
          onChanged: (v) => ref.read(userSearchQueryProvider.notifier).state = v,
        ),
        const SizedBox(height: 10),
        users.when(
          loading: () => const SizedBox(height: 80, child: Center(child: LoadingIndicator())),
          error: (e, _) => Text('Error: $e', style: Styles.smallText),
          data: (list) {
            if (list.isEmpty) {
              return Text(
                q.trim().isEmpty ? '' : 'No results for “$q”',
                style: Styles.smallText,
              );
            }
            return Column(
              children: [
                for (final u in list)
                  _UserRow(user: u, alreadyPending: outgoing.contains(u.id)),
              ],
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

    final trailing = switch ((widget.alreadyPending, _sending)) {
      (true, _) => _RequestedChip(),
      (false, true) => const SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(strokeWidth: 2, color: owlPurple),
      ),
      (false, false) => IconButton(
        tooltip: 'Add friend',
        icon: const Icon(Icons.person_add_alt_1_outlined, color: owlPurple),
        onPressed: () async {
          setState(() => _sending = true);
          final res = await repo.send(toUid: widget.user.id);
          if (!mounted) return;
          setState(() => _sending = false);

          final (msg, isOk) = _msgForResult(res, widget.user.userName);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(msg),
              backgroundColor: isOk ? Colors.green.shade700 : Colors.red.shade700,
              behavior: SnackBarBehavior.floating,
            ),
          );
          // No extra UI tweaks needed: once the outgoing stream sees the doc,
          // this user disappears from suggestions automatically.
        },
      ),
    };

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: black,
        borderRadius: BorderRadius.circular(borderRadiusDefault),
        border: Border.all(color: white, width: 1),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              widget.user.displayFullName.isEmpty
                  ? widget.user.userName
                  : widget.user.displayFullName,
              style: Styles.basicText,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          trailing,
        ],
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
  const _SearchField({required this.initial, required this.onChanged});
  final String initial;
  final ValueChanged<String> onChanged;

  @override
  State<_SearchField> createState() => _SearchFieldState();
}

class _SearchFieldState extends State<_SearchField> {
  late final TextEditingController _c;

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
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _c,
      style: const TextStyle(color: white),
      cursorColor: white,
      decoration: const InputDecoration(
        hintText: 'Search username',
        hintStyle: TextStyle(color: greyLighter),
        border: OutlineInputBorder(),
      ),
      onChanged: widget.onChanged,
    );
  }
}
