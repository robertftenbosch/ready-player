import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/retro_colors.dart';
import '../../settings/settings_provider.dart';
import 'scanline_overlay.dart';

class RetroScaffold extends ConsumerWidget {
  final String title;
  final Widget body;
  final List<Widget>? actions;
  final bool showBackButton;

  const RetroScaffold({
    super.key,
    required this.title,
    required this.body,
    this.actions,
    this.showBackButton = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scanlineEnabled = ref.watch(
      settingsProvider.select((s) => s.scanlineEffect),
    );

    Widget scaffold = Scaffold(
      appBar: AppBar(
        title: Text(title),
        leading: showBackButton
            ? IconButton(
                icon: const Icon(Icons.arrow_back, color: RetroColors.primary),
                onPressed: () => Navigator.of(context).pop(),
              )
            : null,
        automaticallyImplyLeading: false,
        actions: actions,
      ),
      body: body,
    );

    if (scanlineEnabled) {
      scaffold = ScanlineOverlay(child: scaffold);
    }

    return scaffold;
  }
}
