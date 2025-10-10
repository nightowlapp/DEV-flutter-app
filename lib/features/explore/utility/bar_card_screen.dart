// lib/features/bar_card/bar_card_screen.dart
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:pdfx/pdfx.dart';

import 'package:nightowlcode/core/storage/storage_url.dart';
import 'package:nightowlcode/data/providers/venues/venue_media_providers.dart';
import 'package:nightowlcode/features/main/widgets/main_app_bar.dart';
import 'package:nightowlcode/shared/reusable/ui/loading_indicator.dart';
import 'package:nightowlcode/shared/reusable/ui/loading_screen.dart';
import 'package:nightowlcode/shared/constants/colors.dart';

class BarCardArgs {
  final String venueId;
  final String venueName;
  const BarCardArgs({
    required this.venueId,
    required this.venueName,
  });
}

class BarCardScreen extends ConsumerWidget {
  const BarCardScreen({super.key, required this.args});
  static const routeName = 'barCard';
  final BarCardArgs args;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(venueMediaBundleProvider(args.venueId));

    return Scaffold(
      appBar: MainAppBar(
          showBack: true,
          titleText: "${args.venueName}'s Bar Card",
          actions: const []),
      body: async.when(
        loading: () => const Center(child: LoadingIndicator()),
        error: (e, _) => Center(
            child: Text('Error: $e', style: const TextStyle(color: white))),
        data: (bundle) {
          final raw = bundle.barCardPdfUrl;
          if (raw == null || raw.isEmpty) {
            return const Center(
                child: Text('No bar card available',
                    style: TextStyle(color: red)));
          }
          final url = StorageUrl.normalize(raw);

          return FutureBuilder<Uint8List>(
            future: DefaultCacheManager()
                .getSingleFile(url)
                .then((f) => f.readAsBytes()),
            builder: (ctx, snap) {
              if (snap.connectionState != ConnectionState.done) {
                return const Center(child: LoadingScreen());
              }
              if (snap.hasError || !snap.hasData) {
                return const Center(
                    child: Text('Failed to load PDF',
                        style: TextStyle(color: red)));
              }

              try {
                final controller = PdfControllerPinch(
                    document: PdfDocument.openData(snap.data!));
                return PdfViewPinch(
                  controller: controller,
                  backgroundDecoration: const BoxDecoration(color: black),
                );
              } on PlatformException catch (e) {
                // Graceful fallback—show URL so the user can open externally
                return _PdfErrorFallback(
                    url: url, message: '${e.code}: ${e.message}');
              }
            },
          );
        },
      ),
    );
  }
}

class _PdfErrorFallback extends StatelessWidget {
  const _PdfErrorFallback({required this.url, required this.message});
  final String url;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Text('Couldn’t open PDF\n$message',
            textAlign: TextAlign.center, style: const TextStyle(color: red)),
        const SizedBox(height: 12),
        TextButton(
          onPressed: () {
            Clipboard.setData(ClipboardData(text: url));
            ScaffoldMessenger.of(context)
                .showSnackBar(const SnackBar(content: Text('PDF URL copied')));
          },
          child: const Text('Copy PDF URL'),
        ),
      ]),
    );
  }
}
