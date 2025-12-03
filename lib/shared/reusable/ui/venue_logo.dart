import 'package:flutter/material.dart';
import 'package:nightowlcode/models/venues/venue.dart';
import 'package:nightowlcode/data/services/media_existence.dart';
import 'package:nightowlcode/shared/constants/enums.dart';
import 'package:nightowlcode/shared/constants/values.dart';
import '../../../core/storage/storage_url.dart';
import '../../constants/colors.dart';

enum VenueLogoShape { circle, rounded }

/// Usage:
/// VenueLogo(venue: v, size: dim, showTypeIfNoLogo: true)
Widget VenueLogo({
  required Venue venue,
  VenueMediaHealth? media,
  String? logoUrlOverride,

  // visuals
  double size = 50,
  VenueLogoShape shape = VenueLogoShape.circle,
  double borderWidth = 1.5,
  Color borderColor = transparent, // used when autoBorderByOpen = false
  BorderRadius borderRadius =
      const BorderRadius.all(Radius.circular(borderRadiusMedium)),
  Color? backgroundColor, // <- allows a subtle bg
  EdgeInsetsGeometry padding = EdgeInsets.zero,

  // Fallback options
  bool showInitialFallback = true, // controls whether *any* fallback is shown
  bool showTypeIfNoLogo = true, // when true, use venue.type.icon instead of initials
  String? fallbackText,
  Color fallbackBgColor = const Color(0xFF222222),
  Color fallbackTextColor = white,
  FontWeight fallbackFontWeight = FontWeight.w700,
  bool hideIfNoImage = false,
  bool allowCoverOrMoodFallback = true,

  // Auto border based on "is open"
  bool autoBorderByOpen = true,
  Color openBorderColor = green,
  Color isSooColor = yellow,
  Color closedBorderColor = red,
  DateTime? nowForOpenCheck,

  // extras
  Object? heroTag,
  String? tooltip,
  VoidCallback? onTap,
  VoidCallback? onLongPress,
}) {
  final DateTime now = nowForOpenCheck ?? DateTime.now();

  final bool isOpen = venue.isOpenNow(now);
  final bool isSoon = venue.isOpeningOrClosingSoon(now); // opens OR closes within 60 min

  final Color effectiveBorder = !autoBorderByOpen
      ? borderColor
      : isSoon
      ? isSooColor          // opening OR closing soon  -> yellow
      : isOpen
      ? openBorderColor // open                     -> green
      : closedBorderColor; // closed, not soon      -> red



  Widget _fallbackBadge() {
    // Only use the type icon if we *want* to and the type isn't unknown
    final bool useTypeIcon = showTypeIfNoLogo;

    final label = (fallbackText ?? _initialOf(venue)).toUpperCase();

    final textStyle = TextStyle(
      color: fallbackTextColor,
      fontWeight: fallbackFontWeight,
      fontSize: size * 0.36,
      letterSpacing: 0.2,
      height: 1.0,
    );

    final decoration = shape == VenueLogoShape.circle
        ? BoxDecoration(
      shape: BoxShape.circle,
      color: backgroundColor ?? fallbackBgColor,
      border: Border.all(color: effectiveBorder, width: borderWidth),
    )
        : BoxDecoration(
      color: backgroundColor ?? fallbackBgColor,
      borderRadius: borderRadius,
      border: Border.all(color: effectiveBorder, width: borderWidth),
    );

    final child = useTypeIcon
        ? Icon(venue.type.icon, color: fallbackTextColor, size: size * 0.56)
        : FittedBox(
      fit: BoxFit.scaleDown,
      child: Text(label, style: textStyle),
    );

    return Container(
      width: size,
      height: size,
      decoration: decoration,
      alignment: Alignment.center,
      padding: padding,
      child: child,
    );
  }

  final url = _resolvePrimaryImageUrl(
    venue: venue,
    media: media,
    override: logoUrlOverride,
    allowCoverOrMoodFallback: allowCoverOrMoodFallback,
  );

  final hasRemoteImage =
      url != null && (url.startsWith('http://') || url.startsWith('https://'));
  final ImageProvider? provider = hasRemoteImage ? NetworkImage(url!) : null;

  if (!hasRemoteImage && hideIfNoImage) {
    return const SizedBox.shrink();
  }

  Widget core;
  if (provider == null) {
    core = showInitialFallback ? _fallbackBadge() : const SizedBox.shrink();
  } else {
    core = _LogoOnceLoaded(
      provider: provider,
      size: size,
      shape: shape,
      borderWidth: borderWidth,
      borderColor: effectiveBorder,
      borderRadius: borderRadius,
      backgroundColor: backgroundColor ?? Colors.black12,
      padding: padding,
      fallback:
          showInitialFallback ? _fallbackBadge() : const SizedBox.shrink(),
    );
  }

  if (heroTag != null) core = Hero(tag: heroTag!, child: core);
  if (tooltip != null) core = Tooltip(message: tooltip!, child: core);

  return Material(
    color: Colors.transparent,
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

String _initialOf(Venue venue) {
  final s =
      (venue.displayName.isNotEmpty ? venue.displayName : venue.name).trim();
  if (s.isEmpty) return '?';
  return String.fromCharCode(s.runes.first);
}

String? _resolvePrimaryImageUrl({
  required Venue venue,
  VenueMediaHealth? media,
  String? override,
  required bool allowCoverOrMoodFallback,
}) {
  final candidates = <String?>[
    override,
    if (media?.logoExists == true) media!.logoUrl,
    venue.logoUrl,
    if (allowCoverOrMoodFallback && media?.coverExists == true) media!.coverUrl,
    if (allowCoverOrMoodFallback) venue.coverImageUrl,
    if (allowCoverOrMoodFallback) ...venue.moodImageUrls,
  ];
  return _firstHttpUrl(candidates);
}

String? _firstHttpUrl(Iterable<String?> candidates) {
  for (final raw in candidates) {
    if (raw == null) continue;
    final normalized = StorageUrl.normalize(raw.trim());
    if (normalized.isEmpty) continue;
    if (normalized.startsWith('http://') || normalized.startsWith('https://')) {
      return normalized;
    }
  }
  return null;
}

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
    required this.fallback,
  });

  final ImageProvider provider;
  final double size;
  final VenueLogoShape shape;
  final double borderWidth;
  final Color borderColor;
  final BorderRadius borderRadius;
  final Color? backgroundColor;
  final EdgeInsetsGeometry padding;
  final Widget fallback;

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
    if (!_ok) return widget.fallback;

    final decoration = widget.shape == VenueLogoShape.circle
        ? BoxDecoration(
            shape: BoxShape.circle,
            color: widget.backgroundColor ?? Colors.transparent,
            border: Border.all(
                color: widget.borderColor, width: widget.borderWidth),
          )
        : BoxDecoration(
            color: widget.backgroundColor ?? Colors.transparent,
            borderRadius: widget.borderRadius,
            border: Border.all(
                color: widget.borderColor, width: widget.borderWidth),
          );

    final image = Image(image: widget.provider, fit: BoxFit.cover);

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
