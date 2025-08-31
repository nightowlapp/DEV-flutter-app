import 'package:flutter/material.dart';
import 'package:nightowlcode/features/main/widgets/main_app_bar.dart';
import 'package:nightowlcode/navigation/nav_shortcuts.dart';
import 'package:nightowlcode/shared/constants/enums.dart';

import '../../../core/platform_config.dart';
import '../../../shared/constants/colors.dart';
import '../../../shared/reusable/ui/buttons.dart';
import '../../../shared/reusable/ui/progress_bar.dart';

class ChooseFavoriteVenuesScreen extends StatefulWidget {
  const ChooseFavoriteVenuesScreen({super.key});

  @override
  State<ChooseFavoriteVenuesScreen> createState() =>
      _ChooseFavoriteVenuesScreenState();
}

class _ChooseFavoriteVenuesScreenState
    extends State<ChooseFavoriteVenuesScreen> {
  final TextEditingController _searchController = TextEditingController();
  final int _maxSelection = 5;

  late final List<ClubData> _allClubs;
  final Map<String, bool> _selectedMap = {};
  List<String> _filteredIds = [];

  @override
  void initState() {
    super.initState();
    _allClubs = _mockClubs;
    for (final c in _allClubs) {
      _selectedMap[c.id] = false;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterClubs(String query) {
    setState(() {
      _filteredIds = _allClubs
          .where((c) => c.name.toLowerCase().contains(query.toLowerCase().trim()))
          .map((c) => c.id)
          .toList();
    });
  }

  void _toggle(String clubId) {
    final selectedCount = _selectedMap.values.where((v) => v).length;
    final isSelected = _selectedMap[clubId] ?? false;

    if (selectedCount >= _maxSelection && !isSelected) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          backgroundColor: const Color(0xFF121212),
          content: Text(
            'You can only pick $_maxSelection favorite clubs.',
            style: const TextStyle(color: Colors.redAccent),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('OK', style: TextStyle(color: owlOrange)),
            ),
          ],
        ),
      );
      return;
    }

    setState(() {
      _selectedMap[clubId] = !isSelected;
    });
  }

  Color _counterColor(int selectedCount) {
    if (selectedCount < 3) return Colors.red;
    if (selectedCount < _maxSelection) return Colors.orange;
    return owlOrange;
  }

  @override
  Widget build(BuildContext context) {
    final selectedCount = _selectedMap.values.where((v) => v).length;

    final displayClubs = _filteredIds.isNotEmpty
        ? _filteredIds
        .map((id) => _allClubs.firstWhere((c) => c.id == id))
        .toList()
        : _allClubs;

    final selected = displayClubs.where((c) => _selectedMap[c.id] ?? false).toList();
    final unselected =
    displayClubs.where((c) => !(_selectedMap[c.id] ?? false)).toList();

    final screenWidth = MediaQuery.of(context).size.width;
    const itemWidth = 60.0;
    const paddingTotal = 40.0;
    const spacingTotal = 8.0;
    final totalWidth = 5 * itemWidth + spacingTotal + paddingTotal;
    final useTwoRows = selected.length == 5 && totalWidth > screenWidth;

    return Scaffold(
      appBar: const MainAppBar(
        titleText: 'Favorite Venues',
        leading: SizedBox.shrink(),
        actions: [
          CircleAvatar(backgroundImage: AssetImage('assets/nightowl/logo.png')),
        ],
      ),
      body: SafeArea(
        child: Stack(
          children: [

            // Content
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Search + counter
                  Row(
                    children: [
                      // TODO Make seperate search bar
                      // Expanded(
                      //   flex: 8,
                      //   child: TextField(
                      //     controller: _searchController,
                      //     onChanged: _filterClubs,
                      //     decoration: InputDecoration(
                      //       hintText: 'Search Venues',
                      //       hintStyle: TextStyle(color: Colors.grey.shade400),
                      //       filled: true,
                      //       fillColor: const Color(0xFF1E1E1E),
                      //       prefixIcon: Icon(Icons.search, color: owlOrange),
                      //       contentPadding: const EdgeInsets.symmetric(vertical: 14),
                      //       border: OutlineInputBorder(
                      //         borderRadius: BorderRadius.circular(12),
                      //         borderSide: BorderSide.none,
                      //       ),
                      //     ),
                      //     style: const TextStyle(color: Colors.white),
                      //   ),
                      // ),
                      const SizedBox(width: 10),
                      Expanded(
                        flex: 2,
                        child: RichText(
                          textAlign: TextAlign.center,
                          text: TextSpan(
                            children: [
                              TextSpan(
                                text: '$selectedCount',
                                style: TextStyle(
                                  color: _counterColor(selectedCount),
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const TextSpan(
                                text: '/',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              TextSpan(
                                text: '$_maxSelection',
                                style: TextStyle(
                                  color: owlOrange,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Selected strip
                  if (selected.isNotEmpty) ...[
                    SizedBox(
                      height: 90,
                      child: useTwoRows
                          ? Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 5,
                        runSpacing: 5,
                        children: selected
                            .map((c) => Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 5),
                          child: _ClubItem(
                            club: c,
                            isSelected: true,
                            onTap: () => _toggle(c.id),
                          ),
                        ))
                            .toList(),
                      )
                          : SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: selected
                              .map((c) => Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 2),
                            child: _ClubItem(
                              club: c,
                              isSelected: true,
                              onTap: () => _toggle(c.id),
                            ),
                          ))
                              .toList(),
                        ),
                      ),
                    ),
                    const Text(
                      'Tap again to unselect',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 10, color: Colors.white70),
                    ),
                    Container(
                      height: 2,
                      color: _AppColors.secondaryColor,
                      margin: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ],

                  // Grid
                  Expanded(
                    child: Scrollbar(
                      child: GridView.builder(
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: 6,
                          mainAxisSpacing: 6,
                        ),
                        itemCount: unselected.length,
                        itemBuilder: (_, i) => _ClubItem(
                          club: unselected[i],
                          isSelected: false,
                          onTap: () => _toggle(unselected[i].id),
                        ),
                      ),
                    ),
                  ),

                  // Bottom buttons
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 16),
                    child: Row(
                      children: [
                        Expanded(
                          child: OwlButton(
                            label: 'Skip',
                            textColor: white,
                            onPressed: () {
                              context.goScreen(MainScreenName.explore);
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: OwlButton(
                            label: 'Save & Continue',
                            textColor: grey,
                            onPressed: selectedCount > 0
                                ? () {
                              context.goScreen(MainScreenName.explore);
                              // save for upload
                            }
                                : null,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: PlatformConfig.height(context) *0.02),
                ],
              ),
            ),
            // Padding(padding: EdgeInsets.only(bottom: 20),child: TODO Maybe?
            // ProgressBar(currentStep: 1, totalSteps: 2),
            // ),
      ],
        ),
      ),
    );
  }
}

/* ---------------------------- UI Building Blocks --------------------------- */

class _ClubItem extends StatelessWidget {
  const _ClubItem({
    required this.club,
    required this.isSelected,
    required this.onTap,
  });

  final ClubData club;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    const baseImage = 50.0;
    const selectedImage = 55.0;

    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          SizedBox(
            width: 60,
            child: Text(
              club.name,
              maxLines: 1,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 10,
                color: isSelected ? owlOrange : Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Container(
            width: isSelected ? selectedImage : baseImage,
            height: isSelected ? selectedImage : baseImage,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: isSelected
                  ? Border.all(color: owlOrange, width: 3)
                  : null,
            ),
            child: ClipOval(
              child: Image.network(
                club.logo,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: const Color(0xFF222222),
                  child: const Icon(Icons.local_bar, color: Colors.white70),
                ),
                loadingBuilder: (context, child, progress) {
                  if (progress == null) return child;
                  return Container(
                    color: const Color(0xFF1A1A1A),
                    alignment: Alignment.center,
                    child: SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor:
                        AlwaysStoppedAnimation(_AppColors.secondaryColor),
                        value: progress.expectedTotalBytes != null
                            ? progress.cumulativeBytesLoaded /
                            (progress.expectedTotalBytes ?? 1)
                            : null,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton._({
    required this.label,
    required this.onPressed,
    required this.background,
    required this.foreground,
    required this.outlined,
  });

  factory _ActionButton.filled({
    required String label,
    required VoidCallback? onPressed,
  }) =>
      _ActionButton._(
        label: label,
        onPressed: onPressed,
        background: owlOrange,
        foreground: Colors.black,
        outlined: false,
      );

  factory _ActionButton.ghost({
    required String label,
    required VoidCallback onPressed,
  }) =>
      _ActionButton._(
        label: label,
        onPressed: onPressed,
        background: Colors.transparent,
        foreground: Colors.white,
        outlined: true,
      );

  final String label;
  final VoidCallback? onPressed;
  final Color background;
  final Color foreground;
  final bool outlined;

  @override
  Widget build(BuildContext context) {
    final shape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(14));
    final style = outlined
        ? OutlinedButton.styleFrom(
      foregroundColor: foreground,
      side: BorderSide(color: Colors.white.withOpacity(0.25)),
      shape: shape,
      padding: const EdgeInsets.symmetric(vertical: 14),
    )
        : FilledButton.styleFrom(
      backgroundColor: background,
      foregroundColor: foreground,
      shape: shape,
      padding: const EdgeInsets.symmetric(vertical: 14),
      disabledBackgroundColor: Colors.white12,
      disabledForegroundColor: Colors.white38,
    );

    return outlined
        ? OutlinedButton(onPressed: onPressed, style: style, child: Text(label))
        : FilledButton(onPressed: onPressed, style: style, child: Text(label));
  }
}

class _ProgressBar extends StatelessWidget {
  const _ProgressBar({required this.currentStep, required this.totalSteps});

  final int currentStep;
  final int totalSteps;

  @override
  Widget build(BuildContext context) {
    final segments = List.generate(totalSteps, (i) => i + 1);
    return Row(
      children: segments
          .map(
            (i) => Expanded(
          child: Container(
            height: 6,
            margin: EdgeInsets.only(
              right: i == segments.length ? 0 : 6,
            ),
            decoration: BoxDecoration(
              color: i <= currentStep
                  ? owlOrange
                  : Colors.white12,
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      )
          .toList(),
    );
  }
}

/* ---------------------------------- Data ---------------------------------- */

class ClubData {
  final String id;
  final String name;
  final String logo;
  final String typeOfClub;

  ClubData({
    required this.id,
    required this.name,
    required this.logo,
    required this.typeOfClub,
  });
}

final List<ClubData> _mockClubs = List.generate(18, (i) {
  final n = i + 1;
  return ClubData(
    id: 'club_$n',
    name: [
      'Aurora',
      'Nebula',
      'Pulse',
      'Velvet',
      'Eclipse',
      'Mirage',
      'Noir',
      'Voltage',
      'Lunar',
      'Prism',
      'Afterglow',
      'Monarch',
      'Opal',
      'Cascade',
      'Zenith',
      'Harbor',
      'Vortex',
      'Echo'
    ][i],
    // picsum seed keeps images stable between runs
    logo: 'https://picsum.photos/seed/club$n/200',
    typeOfClub: ['bar', 'club', 'lounge', 'disco'][i % 4],
  );
});

/* --------------------------------- Styling -------------------------------- */

class _AppColors {
  static Color get secondaryColor => const Color(0xFF10D7A8);
}
