import 'package:flutter/material.dart';
import 'package:nightowlcode/core/platform_config.dart';
import 'package:nightowlcode/shared/constants/colors.dart';
import '../../../../shared/constants/styles.dart';
import '../../../../shared/constants/values.dart';

class CityNowSectionRightDrawer extends StatefulWidget {
  const CityNowSectionRightDrawer({super.key});

  @override
  State<CityNowSectionRightDrawer> createState() => _CityNowSectionRightDrawerState();
}

class _CityNowSectionRightDrawerState extends State<CityNowSectionRightDrawer> {
  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Stack(
            children: [
              SizedBox(width: PlatformConfig.width(context) * 0.25,
                child: Text('Copenhagen Now', style: Styles.boldText),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: Text("91002", style: Styles.basicText.copyWith(color: owlOrange),),
              )
            ],
          ),
          const SizedBox(height: verticalSpacerSmall),
          const Expanded(child: _CityList()),
        ],
      ),
    );
  }
}

class _CityList extends StatefulWidget {
  const _CityList();

  @override
  State<_CityList> createState() => _CityListState();
}

class _CityListState extends State<_CityList> {
  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        const SliverToBoxAdapter(child: SizedBox(height: verticalSpacerSmall)),
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, i) {
              if (i >= 39) return null;
              if (i.isOdd) return const SizedBox(height: verticalSpacerMedium);
              final itemIndex = i ~/ 2;
              return _ItemTile(index: itemIndex);
            },
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: verticalSpacerMedium)),
      ],
    );
  }
}

class _ItemTile extends StatefulWidget {
  const _ItemTile({required this.index});
  final int index;

  @override
  State<_ItemTile> createState() => _ItemTileState();
}

class _ItemTileState extends State<_ItemTile> {
  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: verticalSpacerMedium),
      child: ListTile(
        title: Text('Item #${widget.index + 1}'),
        subtitle: Text('This is a simple vertically scrolling list.', style: Styles.smallText),
        onTap: () {},
      ),
    );
  }
}
