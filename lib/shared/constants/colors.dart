
import 'package:flutter/material.dart';

//Core
const owlOrange = Color(0xFFE87701);
const black = Colors.black;
const white = Colors.white;
const grey = Color.fromRGBO(66, 66, 66, 1);
const transparent = Colors.transparent;

const adminColor = Color(0xFF0137E8);

// Status colors
const green = Colors.green;
const blue = Colors.blue;
const purple = Colors.purple;
const red = Colors.red; // accent? confuse wiht orange? TODO
const yellow = Colors.yellow;
const greyLighter = Colors.grey;

const TEST = Colors.pink;

// Map colors
const lightOrange = Color(0xFF78350F);
const darkOrange = Color(0xFF33130A);

const mapGrey555 = Color(0xFF555555);            // #555555
const onHoldBg = Color(0xFF2E1A09);
const degradedBg = Color(0xFF3A1D0F);
const mapOpenGreen = Color(0xFF2ECC71);          // #2ECC71
const mapClosedRed = Color(0xFFE74C3C);          // #E74C3C
const technoBg = Color(0xFF0F1029);
const friendTeal = Colors.teal;                  // #009688

// const lighterBlack = Color.fromARGB(221, 184, 178, 178);
// const owlOrange = Colors.deepOrangeAccent;
// const grey = Colors.blueGrey;
// const owlPurple = Colors.deepPurple;
const owlOrangeDark = Color(0x0AE87701); // owlOrange.opacity(0.04)


// Core semantics
const successBg = Color(0xFF064E3B);
const successFg = Color(0xFF34D399);

const infoBg = Color(0xFF1E3A8A);
const infoFg = Color(0xFF60A5FA);

const noticeBg = Color(0xFF0F172A);
const noticeFg = Color(0xFF94A3B8);

const warningFg = Color(0xFFFBBF24);

const errorBg = Color(0xFF7F1D1D);
const errorFg = Color(0xFFF87171);

const criticalBg = Color(0xFF450A0A);
const criticalFg = Color(0xFFFCA5A5);

const neutralBg = Color(0xFF111827);
const neutralFg = Color(0xFFD1D5DB);

const disabledBg = Color(0xFF0B1220);
const disabledFg = Color(0xFF6B7280);

// Workflow states
const pendingBg = Color(0xFF1F2937);
const pendingFg = Color(0xFFE5E7EB);

const queuedBg = Color(0xFF0B1020);
const queuedFg = Color(0xFFA5B4FC);

const pausedBg = Color(0xFF3F1D2B);
const pausedFg = Color(0xFFF472B6);

const inProgressBg = Color(0xFF0C4A6E);
const inProgressFg = Color(0xFF38BDF8);

const syncingBg = Color(0xFF052E3B);
const syncingFg = Color(0xFF67E8F9);

const scheduledBg = Color(0xFF1F2A19);
const scheduledFg = Color(0xFFA3E635);

const completedBg = Color(0xFF052E16);
const completedFg = Color(0xFF22C55E);

const cancelledBg = Color(0xFF3A0D0D);
const cancelledFg = Color(0xFFFB7185);

const blockedBg = Color(0xFF3B0A0A);
const blockedFg = Color(0xFFFCA5A5);

const onHoldFg = Color(0xFFFDBA74);

const reopenedBg = Color(0xFF0B2A1F);
const reopenedFg = Color(0xFF5EEAD4);

// Presence / venue states
const liveNowBg = Color(0xFF3F0A3F);
const liveNowFg = Color(0xFFE879F9);

const activeBg = Color(0xFF1B4332);
const activeFg = Color(0xFF86EFAC);

const busyBg = Color(0xFF3B2C0A);
const busyFg = Color(0xFFFDE047);

const calmBg = Color(0xFF0A263B);
const calmFg = Color(0xFF93C5FD);

const upcomingBg = Color(0xFF1B2A3B);
const upcomingFg = Color(0xFFA5B4FC);

const soldOutBg = Color(0xFF331010);
const soldOutFg = Color(0xFFFCA5A5);

const vipBg = Color(0xFF2A1A0A);
const vipFg = Color(0xFFFBBF24);

const promoFg = Color(0xFFFB923C);

const maintenanceBg = Color(0xFF1F2937);
const maintenanceFg = Color(0xFF93A3B8);

const degradedFg = Color(0xFFF59E0B);

const offlineBg = Color(0xFF0C0F14);
const offlineFg = Color(0xFF6B7280);

const geofencedBg = Color(0xFF102A12);
const geofencedFg = Color(0xFF4ADE80);

const locationLostBg = Color(0xFF0A1F2E);
const locationLostFg = Color(0xFF60A5FA);

// Nightlife accents (tags)

const technoFg = Color(0xFF818CF8);

const houseBg = Color(0xFF0F1A2A);
const houseFg = Color(0xFF38BDF8);

const hiphopBg = Color(0xFF140A1A);
const hiphopFg = Color(0xFFF472B6);

const jazzBg = Color(0xFF0F1A14);
const jazzFg = Color(0xFF34D399);

const cocktailsBg = Color(0xFF1A0F14);
const cocktailsFg = Color(0xFFFB7185);



extension ColorHex on Color {
  /// '#RRGGBB' or '#RRGGBBAA' (alpha at the end = RGBA)
  String toHex({bool includeAlpha = false, bool leadingHashSign = true}) {
    final r = this.red.toRadixString(16).padLeft(2, '0');
    final g = this.green.toRadixString(16).padLeft(2, '0');
    final b = this.blue.toRadixString(16).padLeft(2, '0');
    final a = this.alpha.toRadixString(16).padLeft(2, '0');
    final body = includeAlpha ? '$r$g$b$a' : '$r$g$b';
    return '${leadingHashSign ? '#' : ''}${body.toUpperCase()}';
  }
}

