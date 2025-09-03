// lib/shared/reusable/ui/venue_logo.dart
import 'package:flutter/material.dart';
import 'package:nightowlcode/models/venues/venue.dart';
import 'package:nightowlcode/data/services/media_existence.dart';
import 'package:nightowlcode/shared/constants/values.dart';
import '../../../core/storage/storage_url.dart';
import '../../constants/colors.dart';

//TODO call customnetworkimage.

enum VenueLogoShape { circle, rounded }

/// Call this to get a widget. If no valid logo, it shows a local fallback with the venue initial.
/// New:
/// - `hideIfNoImage`: when true, return nothing if no logo/cover/mood is available.
/// - `allowCoverOrMoodFallback`: when false, only try logo (don’t use cover/mood in the circle).
Widget venueLogo({
required Venue venue,
VenueMediaHealth? media,
String? logoUrlOverride,

// visuals
double size = 50,
VenueLogoShape shape = VenueLogoShape.circle,
double borderWidth = 1.5,
Color borderColor = white, // used when autoBorderByOpen = false
BorderRadius borderRadius = const BorderRadius.all(Radius.circular(borderRadiusMedium)),
Color? backgroundColor,
EdgeInsetsGeometry padding = EdgeInsets.zero,

// Fallback options
bool showInitialFallback = true,
String? fallbackText,                 // default: first letter of displayName/name
Color fallbackBgColor = const Color(0xFF222222),
Color fallbackTextColor = white,
FontWeight fallbackFontWeight = FontWeight.w700,

// NEW: hide the whole thing if there’s no image at all (logo/cover/mood)
bool hideIfNoImage = false,

// NEW: if false, do NOT fall back to cover/mood inside the logo circle
bool allowCoverOrMoodFallback = true,

// Auto border based on "is open" (keeps callers dumb)
bool autoBorderByOpen = true,
Color openBorderColor = green,
Color closedBorderColor = red,
DateTime? nowForOpenCheck, // for tests/overrides

// extras
Object? heroTag,
String? tooltip,
VoidCallback? onTap,
VoidCallback? onLongPress,
}) {
// Pick border color automatically if enabled
final DateTime _now = nowForOpenCheck ?? DateTime.now();
final Color _effectiveBorder = autoBorderByOpen
? (venue.isOpenNow(_now) ? openBorderColor : closedBorderColor)
    : borderColor;

// Local fallback badge (single letter)
Widget _fallbackBadge() {
final label = (fallbackText ?? _initialOf(venue)).toUpperCase();
final textStyle = TextStyle(
color: fallbackTextColor,
fontWeight: fallbackFontWeight,
fontSize: size * 0.3, // scales with size nicely
letterSpacing: 0.5,
height: 1.0,
);

final decoration = shape == VenueLogoShape.circle
? BoxDecoration(
shape: BoxShape.circle,
color: fallbackBgColor,
border: Border.all(color: _effectiveBorder, width: borderWidth),
)
    : BoxDecoration(
color: fallbackBgColor,
borderRadius: borderRadius,
border: Border.all(color: _effectiveBorder, width: borderWidth),
);

return Container(
width: size,
height: size,
decoration: decoration,
alignment: Alignment.center,
padding: padding,
child: FittedBox(
fit: BoxFit.scaleDown,
child: Text(label, style: textStyle),
),
);
}

// Resolve which image to show (logo → cover → mood) unless restricted
final url = _resolvePrimaryImageUrl(
venue: venue,
media: media,
override: logoUrlOverride,
allowCoverOrMoodFallback: allowCoverOrMoodFallback,
);

final hasRemoteImage = url != null && (url.startsWith('http://') || url.startsWith('https://'));
final ImageProvider? provider = hasRemoteImage ? NetworkImage(url!) : null;

// If caller wants nothing when there’s no image at all
if (!hasRemoteImage && hideIfNoImage) {
return const SizedBox.shrink();
}

// Core visual (image or fallback)
Widget core;
if (provider == null) {
// No usable URL → show fallback or nothing
core = showInitialFallback ? _fallbackBadge() : const SizedBox.shrink();
} else {
// Try load image; if it fails, use fallback
core = _LogoOnceLoaded(
provider: provider,
size: size,
shape: shape,
borderWidth: borderWidth,
borderColor: _effectiveBorder,
borderRadius: borderRadius,
backgroundColor: backgroundColor,
padding: padding,
fallback: showInitialFallback ? _fallbackBadge() : const SizedBox.shrink(),
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
final s = (venue.displayName.isNotEmpty ? venue.displayName : venue.name).trim();
if (s.isEmpty) return '?';
// Safely take first visible char
return String.fromCharCode(s.runes.first);
}

String? _resolvePrimaryImageUrl({
required Venue venue,
VenueMediaHealth? media,
String? override,
required bool allowCoverOrMoodFallback, // NEW
}) {
// Order: explicit override → media.logo → venue.logo → (optional cover/mood)
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
final normalized = StorageUrl.normalize(raw.trim()); // handles gs:// & storage paths
if (normalized.isEmpty) continue;
if (normalized.startsWith('http://') || normalized.startsWith('https://')) {
return normalized;
}
}
return null;
}

/// Shows image once it loads; otherwise shows provided fallback.
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
if (!_ok) return widget.fallback; // fallback until image is actually ready

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

final image = Image(image: widget.provider, fit: BoxFit.contain);

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
