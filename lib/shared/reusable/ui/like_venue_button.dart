import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:nightowlcode/data/services/like_store.dart';
import 'package:nightowlcode/models/venues/venue.dart';
import 'package:nightowlcode/shared/constants/colors.dart';
import 'package:nightowlcode/shared/constants/icons.dart';
import 'package:nightowlcode/shared/constants/styles.dart';
import 'package:nightowlcode/shared/constants/values.dart';
import 'package:nightowlcode/shared/reusable/ui/buttons.dart';
import 'package:nightowlcode/shared/reusable/ui/popup_dialog_default.dart';
import 'package:nightowlcode/core/platform_config.dart';

class LikeVenueButton extends StatefulWidget {
  const LikeVenueButton({
    super.key,
    required this.store,
    required this.venue,
    this.padding = const EdgeInsets.all(0),
    this.size = iconSizeLarge,
    this.confirmOnUnlike = true,
    this.confirmTitle,
    this.confirmText,
    this.undoText = 'No',
    this.removeText = 'Remove',
    this.fullIcon = heartIcon,
    this.emptyIcon = emptyHeartIcon,
    this.fullColor = red,
    this.emptyColor = white,
  });

  final LikeStore store;
  final Venue venue;

  final EdgeInsets padding;
  final double size;

  final bool confirmOnUnlike;
  final String? confirmTitle;
  final String? confirmText;
  final String undoText;
  final String removeText;

  final IconData fullIcon;
  final IconData emptyIcon;
  final Color fullColor;
  final Color emptyColor;

  @override
  State<LikeVenueButton> createState() => _LikeVenueButtonState();
}

class _LikeVenueButtonState extends State<LikeVenueButton>
    with TickerProviderStateMixin {
  // Pulse when tapping (both like/unlike)
  late final AnimationController _pulseCtr =
  AnimationController(vsync: this, duration: const Duration(milliseconds: 180));
  late final Animation<double> _pulse =
  Tween(begin: 1.0, end: 1.15).chain(CurveTween(curve: Curves.easeOut)).animate(_pulseCtr);

  // Heart burst when switching to liked
  late final AnimationController _burstCtr =
  AnimationController(vsync: this, duration: const Duration(milliseconds: 2820));
  late final Animation<double> _burst =
  CurvedAnimation(parent: _burstCtr, curve: Curves.easeOutCubic);

  bool _showBurst = false;
  bool _prevLiked = false;

  @override
  void initState() {
    super.initState();
    _prevLiked = widget.store.isLiked;
    widget.store.addListener(_onStore);
    widget.store.init();
    _burstCtr.addStatusListener((s) {
      if (s == AnimationStatus.completed && mounted) {
        setState(() => _showBurst = false); // ensure hearts are gone after anim
      }
    });
  }

  @override
  void didUpdateWidget(covariant LikeVenueButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.store != widget.store) {
      oldWidget.store.removeListener(_onStore);
      _prevLiked = widget.store.isLiked;
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
    final liked = widget.store.isLiked;

    // Start burst only on false -> true transition
    if (liked && !_prevLiked) {
      setState(() {
        _showBurst = true;
      });
      _burstCtr.forward(from: 0);
      _pulseCtr.forward(from: 0).whenComplete(() => _pulseCtr.reverse());
    }

    // Small pulse on unlike too (no burst)
    if (!liked && _prevLiked) {
      _pulseCtr.forward(from: 0).whenComplete(() => _pulseCtr.reverse());
    }

    _prevLiked = liked;
  }

  String _venueLabel(Venue v) =>
      (v.displayName.isNotEmpty ? v.displayName : v.name).trim();

  Future<bool> _confirmRemove(BuildContext ctx) async {
    if (!widget.confirmOnUnlike) return true;

    bool doRemove = false;
    final label = _venueLabel(widget.venue);
    final title = widget.confirmTitle ?? 'Unlike $label';
    final text  = widget.confirmText  ?? 'Are you sure you want to unlike $label?';

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
                  height: PlatformConfig.height(context) * 0.04,
                  child: OwlButton(
                    label: widget.undoText,
                    onPressed: () {
                      doRemove = false;
                      Navigator.of(ctx).pop();
                    },
                    textColor: owlOrange,
                    borderColor: owlOrange, //TODO green instead?
                  ),
                ),
              ),
              SizedBox(width: PlatformConfig.width(context) * 0.1),
              Expanded(
                child: SizedBox(
                  height: PlatformConfig.height(context) * 0.04,
                  child: OwlButton(
                    label: widget.removeText,
                    onPressed: () {
                      doRemove = true;
                      Navigator.of(ctx).pop();
                    },
                    textColor: red,
                    borderColor: red,
                    borderRadius: borderRadiusSmall,
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

  Future<void> _onTap(BuildContext ctx) async {
    _pulseCtr.forward(from: 0).whenComplete(() => _pulseCtr.reverse()); // instant feedback

    await widget.store.init();

    if (widget.store.isLiked) {
      final ok = await _confirmRemove(ctx);
      if (!ok) return;
    }

    try {
      await widget.store.toggle();
    } on StateError catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(ctx).showSnackBar(
        const SnackBar(content: Text('Please sign in to like.'), behavior: SnackBarBehavior.floating),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(ctx).showSnackBar(
        const SnackBar(content: Text('Something went wrong. Please try again.'), behavior: SnackBarBehavior.floating),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final liked = widget.store.isLiked;

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
                  liked ? widget.fullIcon : widget.emptyIcon,
                  key: ValueKey<bool>(liked),
                  color: liked ? widget.fullColor : widget.emptyColor,
                  size: widget.size,
                ),
              ),
            ),

            // Heart burst (3 hearts) – only visible while the burst animation runs
            if (_showBurst) _HeartBurst(
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

/// Three-heart burst that flies upward & outward, then disappears.
/// Visible only while the animation controller is running.
class _HeartBurst extends StatelessWidget {
  const _HeartBurst({
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
    // Hearts: left, center, right with slight variations
    const offsets = [-1.0, 0.0, 1.0];

    return IgnorePointer(
      child: AnimatedBuilder(
        animation: t,
        builder: (_, __) {
          final v = t.value; // 0..1
          // opacity fades out; quick fade-in then out
          final opacity = (1.0 - v).clamp(0.0, 1.0);
          if (opacity <= 0) return const SizedBox.shrink();

          return Opacity(
            opacity: opacity,
            child: Stack(
              alignment: Alignment.center,
              children: List.generate(3, (i) {
                final side = offsets[i];

                // Horizontal spread grows with v using easeOut
                final spread = 20.0 * side * Curves.easeOut.transform(v);
                // Vertical rise
                final rise = -48.0 * Curves.easeOut.transform(v);
                // Size grows then shrinks slightly
                final size = baseSize * (0.6 + 0.4 * (1 - (v * 0.7)));
                // Rotation for a playful arc
                final rot = side * 0.6 * v; // radians

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
