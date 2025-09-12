import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/platform_config.dart';

class FindFriends extends ConsumerStatefulWidget {
  const FindFriends({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _FindFriendsState();
}

class _FindFriendsState extends ConsumerState<FindFriends> {
  @override
  Widget build(BuildContext context) {
    final h = PlatformConfig.height(context);
    final w = PlatformConfig.width(context);
    // final state = ref.watch(findFriendsControllerProvider);
    // final ctrl = ref.read(findFriendsControllerProvider.notifier);

    return Scaffold(
      body: SafeArea(
        child: Padding(padding: EdgeInsets.symmetric(horizontal: w * 0.05),
          child: Column(
            children: [
              Text('Find Friends'),

              SingleChildScrollView(
                child: Column(
                  children: [

                    //TODO show users that could be friends. Show closest first. Then show people out. Prioritise verified + people with images.

                  ],
                ),
              )
            ],
          ),    
        )
      ),
    );
  }

}
