// lib/shared/reusable/ui/favorite_venue_button.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nightowlcode/data/providers/favorite_venues/favorite_limit_provider.dart';
import 'package:nightowlcode/data/services/favorite_store.dart';
import 'package:nightowlcode/models/venues/venue.dart';
import 'package:nightowlcode/shared/constants/colors.dart';
import 'package:nightowlcode/shared/constants/styles.dart';
import 'package:nightowlcode/shared/constants/values.dart';
import 'package:nightowlcode/shared/reusable/ui/popup_dialog_default.dart';
import 'package:nightowlcode/shared/reusable/ui/buttons.dart';
import 'package:nightowlcode/core/platform_config.dart';

import '../../../constants/enums.dart';
import '../../../constants/icons.dart';

class FavoriteVenueButton extends ConsumerStatefulWidget {
  const FavoriteVenueButton({
    super.key,
    required this.store,
    required this.venue,
    this.padding = const EdgeInsets.all(0),
    this.size = iconSizeLarge,
    this.confirmOnAdd = true,
    this.addTitle,
    this.addText,
    this.addDenyText = 'No',
    this.addConfirmText = 'Allow',
    this.confirmOnRemove = true,
    this.removeTitle,
    this.removeText,
    this.undoText = 'No',
    this.confirmRemoveText = 'Remove',
    this.fullIcon = filledStarIcon,
    this.emptyIcon = emptyStarIcon,
    this.fullColor = owlOrange,
    this.emptyColor = white,
  });

  final FavoriteStore store;
  final Venue venue;

  final EdgeInsets padding;
  final double size;

  final bool confirmOnAdd;
  final String? addTitle;
  final String? addText;
  final String addDenyText;
  final String addConfirmText;

  final bool confirmOnRemove;
  final String? removeTitle;
  final String? removeText;
  final String undoText;
  final String confirmRemoveText;

  final IconData fullIcon;
  final IconData emptyIcon;
  final Color fullColor;
  final Color emptyColor;

  @override
  ConsumerState<FavoriteVenueButton> createState() => _FavoriteVenueButtonState();
}

class _FavoriteVenueButtonState extends ConsumerState<FavoriteVenueButton>
    with TickerProviderStateMixin {
  // Pulse when tapping (both add/remove)
  late final AnimationController _pulseCtr =
  AnimationController(vsync: this, duration: const Duration(milliseconds: 180));
  late final Animation<double> _pulse =
  Tween(begin: 1.0, end: 1.15).chain(CurveTween(curve: Curves.easeOut)).animate(_pulseCtr);

  // Star burst when switching to favorite
  late final AnimationController _burstCtr =
  AnimationController(vsync: this, duration: const Duration(milliseconds: 2820));
  late final Animation<double> _burst =
  CurvedAnimation(parent: _burstCtr, curve: Curves.easeOutCubic);

  bool _showBurst = false;
  bool _prevFav = false;


  @override
  void initState() {
    super.initState();
    _prevFav = widget.store.isFavorite;
    widget.store.addListener(_onStore);
    widget.store.init();
    _burstCtr.addStatusListener((s) {
      if (s == AnimationStatus.completed && mounted) {
        setState(() => _showBurst = false); // make sure stars are gone after anim
      }
    });
  }

  @override
  void didUpdateWidget(covariant FavoriteVenueButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.store != widget.store) {
      oldWidget.store.removeListener(_onStore);
      _prevFav = widget.store.isFavorite;
      widget.store.addListener(_onStore);
      widget.store.init();
    }
  }

  @override
  void dispose() {
    widget.store.removeListener(_onStore);
    _pulseCtr.dispose();
    _burstCtr.dispose();
    super.dispose();
  }

  void _onStore() {
    final fav = widget.store.isFavorite;

    // Start burst only on false -> true transition
    if (fav && !_prevFav) {
      setState(() => _showBurst = true);
      _burstCtr.forward(from: 0);
      _pulseCtr.forward(from: 0).whenComplete(() => _pulseCtr.reverse());
    }

    // Small pulse on remove too (no burst)
    if (!fav && _prevFav) {
      _pulseCtr.forward(from: 0).whenComplete(() => _pulseCtr.reverse());
    }

    _prevFav = fav;
  }

  String _venueLabel(Venue v) =>
      (v.displayName.isNotEmpty ? v.displayName : v.name).trim();

  // Confirm when ADDING a favorite
  Future<bool> _confirmAdd(BuildContext ctx) async {
    if (!widget.confirmOnAdd) return true;

    bool doAdd = false;
    final label = _venueLabel(widget.venue);
    final title = widget.addTitle ?? 'Add $label to favorites';
    final text = widget.addText ??
        'By adding $label to favorites you allow $label to send you notifications.';

    await showDialog(
      context: ctx,
      barrierDismissible: true,
      builder: (_) => PopupDialogDefault(
        title: title,
        children: [
          Text(text, style: Styles.popupText),
          SizedBox(height: PlatformConfig.height(ctx) * 0.02),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: PlatformConfig.height(ctx) * 0.04,
                  child: OwlButton(
                    label: widget.addDenyText,
                    onPressed: () { doAdd = false; Navigator.of(ctx).pop(); },
                    textColor: red, borderColor: red,
                  ),
                ),
              ),
              SizedBox(width: PlatformConfig.width(ctx) * 0.1),
              Expanded(
                child: SizedBox(
                  height: PlatformConfig.height(ctx) * 0.04,
                  child: OwlButton(
                    label: widget.addConfirmText,
                    onPressed: () { doAdd = true; Navigator.of(ctx).pop(); },
                    textColor: owlOrange, borderColor: owlOrange,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );

    return doAdd;
  }

  Future<bool> _confirmRemove(BuildContext ctx) async {
    if (!widget.confirmOnRemove) return true;

    bool doRemove = false;
    final label = _venueLabel(widget.venue);
    final title = widget.removeTitle ?? 'Unfavorite $label';
    final text  = widget.removeText  ?? 'Are you sure you want to unfavorite $label?';

    await showDialog(
      context: ctx,
      barrierDismissible: true,
      builder: (_) => PopupDialogDefault(
        title: title,
        children: [
          Text(text, style: Styles.popupText),
          SizedBox(height: PlatformConfig.height(ctx) * 0.02),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: PlatformConfig.height(ctx) * 0.04,
                  child: OwlButton(
                    label: widget.undoText,
                    onPressed: () { doRemove = false; Navigator.of(ctx).pop(); },
                    textColor: owlOrange, borderColor: owlOrange, borderRadius: borderRadiusSmall,
                  ),
                ),
              ),
              SizedBox(width: PlatformConfig.width(ctx) * 0.1),
              Expanded(
                child: SizedBox(
                  height: PlatformConfig.height(ctx) * 0.04,
                  child: OwlButton(
                    label: widget.confirmRemoveText,
                    onPressed: () { doRemove = true; Navigator.of(ctx).pop(); },
                    textColor: red, borderColor: red, borderRadius: borderRadiusSmall,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );

    return doRemove;
  }


  Future<void> _showTooManyDialog(BuildContext ctx, int limit) async {
    // read the premium plan limit for the upsell line
    final premiumLimit = ref.read(planFavoriteLimitProvider(SubscriptionTypesUser.premium));

    await showDialog(
      context: ctx,
      barrierDismissible: true,
      builder: (_) => PopupDialogDefault(
        title: 'Too many favorites',
        children: [
          Text('You’ve hit your limit of $limit favorites. Upgrade to Premium to get notifications and special offers from your $premiumLimit favorites venues.',
              style: Styles.popupText),

          SizedBox(height: PlatformConfig.height(ctx) * 0.02),
          SizedBox(
            height: PlatformConfig.height(ctx) * 0.04,
            child: OwlButton(
              label: 'Upgrade To Premium',
              onPressed: () => Navigator.of(ctx).pop(),//TODO
              textColor: owlOrange, borderColor: owlOrange, borderRadius: borderRadiusSmall,
            ),
          ),

          SizedBox(height: PlatformConfig.height(ctx) * 0.02),

          SizedBox(
            height: PlatformConfig.height(ctx) * 0.04,
            child: OwlButton(
              label: 'OK',
              onPressed: () => Navigator.of(ctx).pop(),
              textColor: red, borderColor: red, borderRadius: borderRadiusSmall,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _onTap(BuildContext ctx) async {
    _pulseCtr.forward(from: 0).whenComplete(() => _pulseCtr.reverse());

    await widget.store.init();

    try {
      if (widget.store.isFavorite) {
        // Removing: confirm remove
        final ok = await _confirmRemove(ctx);
        if (!ok) return;
      } else {
        // Adding: pre-check the limit FIRST
        final canAdd = await widget.store.canAdd();
        if (!canAdd) {
          await _showTooManyDialog(ctx, widget.store.maxFavorites);
          return;
        }

        // Only show the consent if under the limit
        final ok = await _confirmAdd(ctx);
        if (!ok) return;
      }

      await widget.store.toggle();
    } on FavoriteLimitException catch (e) {
      // Fallback if the limit changed between precheck and toggle
      if (!mounted) return;
      await _showTooManyDialog(ctx, e.limit);
    } on StateError {
      if (!mounted) return;
      ScaffoldMessenger.of(ctx).showSnackBar(
        const SnackBar(
          content: Text('Please sign in to favorite.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(ctx).showSnackBar(
        const SnackBar(
          content: Text('Something went wrong. Please try again.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final fav = widget.store.isFavorite;

    return Padding(
      padding: widget.padding,
      child: GestureDetector(
        onTap: () => _onTap(context),
        child: Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            // Icon with pulse + smooth swap from outlined to filled
            ScaleTransition(
              scale: _pulse,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 140),
                switchInCurve: Curves.easeOut,
                switchOutCurve: Curves.easeIn,
                transitionBuilder: (child, anim) => FadeTransition(
                  opacity: anim,
                  child: ScaleTransition(
                    scale: Tween(begin: .9, end: 1.0).animate(anim),
                    child: child,
                  ),
                ),
                child: Icon(
                  fav ? widget.fullIcon : widget.emptyIcon,
                  key: ValueKey<bool>(fav),
                  color: fav ? widget.fullColor : widget.emptyColor,
                  size: widget.size,
                ),
              ),
            ),

            // Star burst – only visible while the burst animation runs
            if (_showBurst) _StarBurst(
              t: _burst,
              color: widget.fullColor,
              baseIcon: widget.fullIcon,
              baseSize: widget.size,
            ),
          ],
        ),
      ),
    );
  }
}

/// Three-star burst that flies upward & outward, then disappears.
/// Mirrors the Like button's _HeartBurst but uses stars.
class _StarBurst extends StatelessWidget {
  const _StarBurst({
    required this.t,
    required this.color,
    required this.baseIcon,
    required this.baseSize,
  });

  final Animation<double> t; // 0..1
  final Color color;
  final IconData baseIcon;
  final double baseSize;

  @override
  Widget build(BuildContext context) {
    const offsets = [-1.0, 0.0, 1.0];
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: t,
        builder: (_, __) {
          final v = t.value; // 0..1
          final opacity = (1.0 - v).clamp(0.0, 1.0);
          if (opacity <= 0) return const SizedBox.shrink();

          return Opacity(
            opacity: opacity,
            child: Stack(
              alignment: Alignment.center,
              children: List.generate(3, (i) {
                final side = offsets[i];

                final spread = 20.0 * side * Curves.easeOut.transform(v);
                final rise = -48.0 * Curves.easeOut.transform(v);
                final size = baseSize * (0.6 + 0.4 * (1 - (v * 0.7)));
                final rot = side * 0.6 * v;

                return Transform.translate(
                  offset: Offset(spread, rise - i * 2.0), // slight stagger
                  child: Transform.rotate(
                    angle: rot,
                    child: Icon(baseIcon, color: color, size: size),
                  ),
                );
              }),
            ),
          );
        },
      ),
    );
  }
}
