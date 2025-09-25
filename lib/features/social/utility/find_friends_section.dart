// lib/features/social/widgets/find_friends_section.dart
import 'package:flutter/material.dart';
import 'package:nightowlcode/core/platform_config.dart';
import 'package:nightowlcode/shared/constants/colors.dart';
import 'package:nightowlcode/shared/constants/styles.dart';
import 'package:nightowlcode/shared/reusable/ui/loading_indicator.dart';
import 'package:nightowlcode/shared/reusable/users/profile_picture_avatar.dart';

import '../../../shared/constants/icons.dart';

class FindFriendsSection extends StatefulWidget {
  const FindFriendsSection({super.key});

  @override
  State<FindFriendsSection> createState() => _FindFriendsSectionState();
}

class _FindFriendsSectionState extends State<FindFriendsSection> {
  final _scroll = ScrollController();

  // ---- mock data (no providers) ----
  late final List<_FriendCandidate> _allCandidates = List.generate(
    120,
        (i) => _FriendCandidate(
      id: 'u$i',
      firstName: 'User',
      lastName: '#$i',
    ),
  );

  final int _pageSize = 20;
  String _query = '';
  bool _loadingMore = false;

  // visible list
  final List<_FriendCandidate> _visible = [];

  @override
  void initState() {
    super.initState();
    _loadInitial();

    _scroll.addListener(() {
      if (_scroll.position.pixels >= _scroll.position.maxScrollExtent - 24) {
        _loadMore();
      }
    });
  }

  void _loadInitial() {
    _visible
      ..clear()
      ..addAll(_filtered().take(_pageSize));
    setState(() {});
  }

  void _onSearch(String q) {
    _query = q.trim();
    _loadInitial();
  }

  Iterable<_FriendCandidate> _filtered() {
    if (_query.isEmpty) return _allCandidates;
    final q = _query.toLowerCase();
    return _allCandidates.where((u) =>
    u.firstName.toLowerCase().contains(q) ||
        u.lastName.toLowerCase().contains(q));
  }

  Future<void> _loadMore() async {
    if (_loadingMore) return;
    final src = _filtered().toList();
    if (_visible.length >= src.length) return;

    setState(() => _loadingMore = true);
    await Future.delayed(const Duration(milliseconds: 250)); // small UX delay

    final next = src.skip(_visible.length).take(_pageSize);
    _visible.addAll(next);
    setState(() => _loadingMore = false);
  }

  void _sendFriendRequest(_FriendCandidate u) {
    // hook up to your backend later; for now show feedback + remove
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Friend request sent to ${u.firstName} ${u.lastName}'),
        behavior: SnackBarBehavior.floating,
      ),
    );
    _visible.removeWhere((e) => e.id == u.id);
    setState(() {});
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final h = PlatformConfig.height(context);
    final w = PlatformConfig.width(context);

    final hasMore = _visible.length < _filtered().length;

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
          Text('Find Friends', style: Styles.basicTextHeader),
            Spacer(),
            Text('237 Nearby')
          ],),
          SizedBox(height: h * 0.02,),


          // search
          Container(
            decoration: BoxDecoration(
              color: black,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: white, width: 1),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                Icon(exploreIcon, color: white),
                const SizedBox(width: 6),
                Expanded(
                  child: TextField(
                    style: const TextStyle(color: white),
                    cursorColor: white,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      hintText: 'Enter Username',
                      hintStyle: TextStyle(color: grey),
                    ),
                    onChanged: _onSearch,
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: h * 0.02,),


          // vertical list (downwards). Give it finite height to embed cleanly.
          SizedBox(
            height: h * 0.45,
            child: _visible.isEmpty
                ? _EmptyState(query: _query)
                : ListView.separated(
              controller: _scroll,
              padding: EdgeInsets.zero,
              itemCount: _visible.length + (hasMore ? 1 : 0),
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                if (index >= _visible.length) {
                  // loader row
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: _loadingMore
                          ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: LoadingIndicator(),
                      )
                          : const SizedBox.shrink(),
                    ),
                  );
                }

                final u = _visible[index];

                return InkWell(
                  onTap: () {
                    // TODO: navigate to profile
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Ink(
                    decoration: BoxDecoration(
                      color: black,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: white, width: 1),
                    ),
                    child: ListTile(
                      contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      leading: ProfilePictureAvatar(
                        size: w * 0.14,
                        showOnlyInitials: true,

                      ),
                      title: Text(
                        '${u.firstName} ${u.lastName}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: white, fontWeight: FontWeight.w600),
                      ),
                      subtitle: const Text(
                        'Suggested • Nearby • Verified',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.person_add_alt_1_outlined, color: owlPurple),
                        onPressed: () => _sendFriendRequest(u),
                        tooltip: 'Add friend',
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _FriendCandidate {
  final String id;
  final String firstName;
  final String lastName;
  const _FriendCandidate({
    required this.id,
    required this.firstName,
    required this.lastName,
  });
}

class _EmptyState extends StatelessWidget {
  final String query;
  const _EmptyState({required this.query});

  @override
  Widget build(BuildContext context) {
    final msg = query.isEmpty ? 'No suggestions yet' : 'No results for “$query”';
    return Center(
      child: Text(
        msg,
        style: const TextStyle(color: Colors.white70),
      ),
    );
  }
}
