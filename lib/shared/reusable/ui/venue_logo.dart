// lib/shared/reusable/venues/venue_logo.dart
import 'package:flutter/material.dart';
import 'package:nightowlcode/models/venues/venue.dart';
import 'package:nightowlcode/data/services/media_existence.dart';
import 'package:nightowlcode/shared/constants/values.dart';

import '../../constants/colors.dart';

enum VenueLogoShape { circle, rounded }

/// Call this to get a widget. If no valid logo, it returns SizedBox.shrink().
Widget venueLogo({
  required Venue venue,
  VenueMediaHealth? media,
  String? logoUrlOverride,

  // visuals
  double size = 50,
  VenueLogoShape shape = VenueLogoShape.circle,
  double borderWidth = 1.5,
  Color borderColor = white,
  BorderRadius borderRadius = const BorderRadius.all(Radius.circular(borderRadiusMedium)),
  Color? backgroundColor,
  EdgeInsetsGeometry padding = EdgeInsets.zero,

  // extras
  Object? heroTag,
  String? tooltip,
  VoidCallback? onTap,
  VoidCallback? onLongPress,
}) {
  final url = _resolveLogoUrl(
    venue: venue,
    media: media,
    override: logoUrlOverride,
  );

  if (url == null || url.isEmpty) return const SizedBox.shrink();

  final isNetwork = url.startsWith('http://') || url.startsWith('https://');
  final ImageProvider provider = isNetwork ? NetworkImage(url) : AssetImage(url);

  Widget core = _LogoOnceLoaded(
    provider: provider,
    size: size,
    shape: shape,
    borderWidth: borderWidth,
    borderColor: borderColor,
    borderRadius: borderRadius,
    backgroundColor: backgroundColor,
    padding: padding,
  );

  if (heroTag != null) core = Hero(tag: heroTag!, child: core);
  if (tooltip != null) core = Tooltip(message: tooltip!, child: core);

  return Material(
    color: transparent,
    shape: shape == VenueLogoShape.circle
        ? const CircleBorder()
        : RoundedRectangleBorder(borderRadius: borderRadius),
    child: InkWell(
      customBorder: shape == VenueLogoShape.circle
          ? const CircleBorder()
          : RoundedRectangleBorder(borderRadius: borderRadius),
      onTap: onTap,
      onLongPress: onLongPress,
      child: core,
    ),
  );
}

String? _resolveLogoUrl({
  required Venue venue,
  VenueMediaHealth? media,
  String? override,
}) {
  if (override != null && override.trim().isNotEmpty) return override.trim();
  if (media != null && media.logoExists == true) {
    final u = media.logoUrl;
    if (u != null && u.trim().isNotEmpty) return u.trim();
  }
  // If your Venue model has a field for logo, add it here:
  try {
    final dynamic v = venue;
    final candidates = <String?>[
      (v as dynamic).logoUrl as String?,
      (v as dynamic).logo as String?,
      (v as dynamic).brandLogo as String?,
    ];
    for (final c in candidates) {
      if (c != null && c.trim().isNotEmpty) return c.trim();
    }
  } catch (_) {}
  return null;
}

/// Shows nothing until the image successfully resolves; hides on error.
/// This guarantees "only show if actual logo".
class _LogoOnceLoaded extends StatefulWidget {
  const _LogoOnceLoaded({
    required this.provider,
    required this.size,
    required this.shape,
    required this.borderWidth,
    required this.borderColor,
    required this.borderRadius,
    required this.backgroundColor,
    required this.padding,
  });

  final ImageProvider provider;
  final double size;
  final VenueLogoShape shape;
  final double borderWidth;
  final Color borderColor;
  final BorderRadius borderRadius;
  final Color? backgroundColor;
  final EdgeInsetsGeometry padding;

  @override
  State<_LogoOnceLoaded> createState() => _LogoOnceLoadedState();
}

class _LogoOnceLoadedState extends State<_LogoOnceLoaded> {
  ImageStream? _stream;
  ImageStreamListener? _listener;
  bool _ok = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _startListening();
  }

  @override
  void didUpdateWidget(covariant _LogoOnceLoaded oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.provider != widget.provider) {
      _stopListening();
      _ok = false;
      _startListening();
    }
  }

  void _startListening() {
    final config = createLocalImageConfiguration(context);
    _stream = widget.provider.resolve(config);
    _listener = ImageStreamListener(
          (ImageInfo _, bool __) {
        if (mounted) setState(() => _ok = true);
      },
      onError: (_, __) {
        if (mounted) setState(() => _ok = false);
      },
    );
    _stream!.addListener(_listener!);
  }

  void _stopListening() {
    if (_listener != null) {
      _stream?.removeListener(_listener!);
    }
  }

  @override
  void dispose() {
    _stopListening();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_ok) return const SizedBox.shrink();

    final decoration = widget.shape == VenueLogoShape.circle
        ? BoxDecoration(
      shape: BoxShape.circle,
      color: widget.backgroundColor ?? Colors.transparent,
      border: Border.all(color: widget.borderColor, width: widget.borderWidth),
    )
        : BoxDecoration(
      color: widget.backgroundColor ?? Colors.transparent,
      borderRadius: widget.borderRadius,
      border: Border.all(color: widget.borderColor, width: widget.borderWidth),
    );

    final clipper = widget.shape == VenueLogoShape.circle
        ? const ClipOval()
        : ClipRRect(borderRadius: widget.borderRadius);

    final image = Image(
      image: widget.provider,
      fit: BoxFit.contain, // logos keep proportions
    );

    return Container(
      width: widget.size,
      height: widget.size,
      decoration: decoration,
      padding: widget.padding,
      child: widget.shape == VenueLogoShape.circle
          ? ClipOval(child: image)
          : ClipRRect(borderRadius: widget.borderRadius, child: image),
    );
  }
}
