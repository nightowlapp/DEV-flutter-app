// lib/shared/reusable/ui/owl_app_bar.dart
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:nightowlcode/shared/constants/colors.dart';
import 'package:nightowlcode/shared/constants/enums.dart';
import 'package:nightowlcode/shared/constants/icons.dart';
import 'package:nightowlcode/shared/constants/styles.dart';
import 'package:nightowlcode/shared/constants/values.dart';
import 'package:nightowlcode/shared/reusable/users/profile_picture_avatar.dart';

class MainAppBar extends StatelessWidget implements PreferredSizeWidget {
  const MainAppBar({
    super.key,
    this.titleText,
    this.title,
    this.centerTitle = true,
    this.backgroundColor,            // defaults to transparent
    this.leading,                    // defaults to NightOwl logo
    this.showBack = false,           // if true & canPop, shows back instead of logo
    this.onBack,
    this.actions,
    this.action,
    this.logoImage,
    this.onTapSettings,              // optional handler; defaults to /settings
  });

  // Title (defaults to "NightOwl" with gradient style)
  final String? titleText;
  final Widget? title;
  final bool centerTitle;

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
  final bool showSettingsButton = MainScreenName.profile == true;
  final VoidCallback? onTapSettings;

  static const _kHeight = 44.0;

  @override
  Size get preferredSize => const Size.fromHeight(_kHeight);

  void _defaultBack(BuildContext context) {
    final router = GoRouter.of(context);
    if (router.canPop()) {
      router.pop();
    } else {
      Navigator.of(context).maybePop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final canPop = Navigator.of(context).canPop();

    // Default leading: fixed-radius logo
    final Widget defaultLeading = Builder(
      builder: (ctx) => IconButton(
        tooltip: MaterialLocalizations.of(ctx).openAppDrawerTooltip,
        padding: EdgeInsets.zero,
        onPressed: () => Scaffold.maybeOf(ctx)?.openDrawer(),
        icon: CircleAvatar(
          radius: borderRadiusDefault,
          backgroundImage:
          logoImage ?? const AssetImage('assets/nightowl/logo.png'),
          backgroundColor: Colors.transparent,
        ),
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
    if (showSettingsButton) {
      defaultActions.add(
        IconButton(
          icon: const Icon(CupertinoIcons.settings),
          onPressed: onTapSettings ?? () => context.push('/settings'),
          tooltip: 'Settings',
        ),
      );
    }

    defaultActions.addAll([
      Builder(
        builder: (ctx) => GestureDetector(
          onTap: () => Scaffold.maybeOf(ctx)?.openEndDrawer(),
          child: const ProfilePictureAvatar(),
        ),
      ),
      const SizedBox(width: 8),
    ]);

    final List<Widget> resolvedActions =
        actions ?? (action != null ? <Widget>[action!] : defaultActions);
    final Widget resolvedTitle = title ??
        Text(
          titleText ?? 'NightOwl',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Styles.logoTextGradient,
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
