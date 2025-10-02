// lib/shared/reusable/ui/owl_app_bar.dart
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:nightowlcode/features/settings/widgets/settings_screen.dart';
import 'package:nightowlcode/navigation/nav_shortcuts.dart';
import 'package:nightowlcode/shared/constants/colors.dart';
import 'package:nightowlcode/shared/constants/enums.dart';
import 'package:nightowlcode/shared/constants/icons.dart';
import 'package:nightowlcode/shared/constants/styles.dart';
import 'package:nightowlcode/shared/constants/values.dart';
import 'package:nightowlcode/shared/reusable/ui/loading_indicator.dart';
import 'package:nightowlcode/shared/reusable/users/profile_picture_avatar.dart';

import '../../../data/providers/other_providers.dart';
import '../../../shared/reusable/ui/verified_badge.dart';

class MainAppBar extends StatelessWidget implements PreferredSizeWidget {
  const MainAppBar({
    super.key,
    this.titleText,
    this.title,
    this.titleColor,
    this.centerTitle = true,
    this.backgroundColor,            // defaults to transparent
    this.leading,                    // defaults to NightOwl logo
    this.showBack = false,           // if true & canPop, shows back instead of logo
    this.onBack,
    this.actions,
    this.action,
    this.logoImage,
    this.onTapSettings,              // optional handler; defaults to /settings
    this.screen,
    this.verifiedVenue = false,
  });

  final MainScreenName? screen;

  // Title (defaults to "NightOwl" with gradient style)
  final String? titleText;
  final Widget? title;
  final Color? titleColor;
  final bool centerTitle;
  final bool verifiedVenue;

  // Colors (defaults to transparent)
  final Color? backgroundColor;

  // Leading (defaults to logo; replaced by back button if showBack && canPop)
  final Widget? leading;
  final bool showBack;
  final VoidCallback? onBack;

  // Actions
  final Widget? action;
  final List<Widget>? actions; // full override if provided

  // Optional logo override
  final ImageProvider? logoImage;

  // Profile settings toggle
  final VoidCallback? onTapSettings;

  static const _kHeight = 44.0;

  @override
  Size get preferredSize => const Size.fromHeight(_kHeight);

  TextStyle get _resolvedTitleStyle {
    // default = gradient
    if (titleColor == null) return Styles.logoTextGradient;
    // when a solid color is requested, remove the gradient foreground first
    return Styles.logoTextGradient.copyWith( //TODO not working.
      color: titleColor,
    );
  }

  void _defaultBack(BuildContext context) {
    final router = GoRouter.of(context);
    if (router.canPop()) {
      router.pop();
    }
    else {
      Navigator.of(context).maybePop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final canPop = Navigator.of(context).canPop();

    final bool showSettingsButton = screen == MainScreenName.profile;

    // Default leading: fixed-radius logo
    final Widget defaultLeading = Builder(
      builder: (ctx) => IconButton(
        tooltip: MaterialLocalizations.of(ctx).openAppDrawerTooltip,
        padding: EdgeInsets.zero,
        onPressed: () => Scaffold.maybeOf(ctx)?.openDrawer(),
        icon: logoImage != null
          ? CircleAvatar(
            radius: borderRadiusDefault,
            backgroundImage:
            logoImage,
            backgroundColor: Colors.transparent,
          )
          :
          Icon(burgerMenu),

      ),
    );

    final Widget? resolvedLeading = leading ??
      (showBack && canPop
        ? IconButton(
          icon: Icon(chevronLeftIcon),
          onPressed: onBack ?? () => _defaultBack(context),
        )
        : defaultLeading);

    // Build default trailing (settings? + end-drawer avatar)

    final List<Widget> defaultActions = [];
    if (verifiedVenue) {
      defaultActions.add(const VerifiedBadge());
    }

    if (showSettingsButton) {
      defaultActions.add(
        IconButton(
          icon: Icon(settingsIcon),
          onPressed: () => context.pushNamedPage(SettingsScreen.routeName,),
        ),
      );
    }
    else {
      defaultActions.add(
        ProfilePictureAvatar(
          onTap: () => Scaffold.maybeOf(context)?.openEndDrawer(),
        )
      );
    }

    final List<Widget> resolvedActions =
      actions ?? (action != null ? <Widget>[action!] : defaultActions);
    final Widget resolvedTitle = title ??
      Text(
        titleText ?? 'NightOwl',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: _resolvedTitleStyle,
      );

    return AppBar(
      elevation: 0,
      toolbarHeight: _kHeight,                         // always 44
      backgroundColor: backgroundColor ?? transparent, // transparent by default
      automaticallyImplyLeading: false,
      leading: resolvedLeading,
      centerTitle: centerTitle,
      title: resolvedTitle,
      actions: resolvedActions,
    );
  }
}
