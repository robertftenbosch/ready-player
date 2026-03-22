import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme/retro_colors.dart';
import '../core/models/game_mode.dart';
import '../core/widgets/scanline_overlay.dart';
import '../core/widgets/mode_selection_dialog.dart';
import '../core/widgets/pixel_border.dart';
import '../core/persistence/game_save_service.dart';
import '../settings/settings_provider.dart';
import '../settings/settings_screen.dart';
import 'widgets/game_card.dart';
import '../chess/screens/chess_screen.dart';
import '../chess/providers/chess_provider.dart';
import '../checkers/screens/checkers_screen.dart';
import '../checkers/providers/checkers_provider.dart';
import '../ballerburg/screens/ballerburg_screen.dart';
import '../ballerburg/providers/ballerburg_provider.dart';

/// Provides a combined future that checks all three save slots.
final _savedGamesProvider = FutureProvider<({bool chess, bool checkers, bool ballerburg})>((ref) async {
  final service = ref.read(gameSaveServiceProvider);
  final results = await Future.wait([
    service.hasChessGameSave(),
    service.hasCheckersGameSave(),
    service.hasBallerburgGameSave(),
  ]);
  return (chess: results[0], checkers: results[1], ballerburg: results[2]);
});

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final savedGames = ref.watch(_savedGamesProvider);

    final hasChessSave = savedGames.valueOrNull?.chess ?? false;
    final hasCheckersSave = savedGames.valueOrNull?.checkers ?? false;
    final hasBallerburgSave = savedGames.valueOrNull?.ballerburg ?? false;

    Widget content = Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 24),
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.only(right: 16),
                child: IconButton(
                  icon: const Icon(
                    Icons.settings,
                    color: RetroColors.textMuted,
                    size: 20,
                  ),
                  onPressed: () => _navigateTo(context, const SettingsScreen()),
                ),
              ),
            ),
            const Text(
              'READY\nPLAYER',
              style: TextStyle(
                fontFamily: 'PressStart2P',
                fontSize: 24,
                color: RetroColors.primary,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'GAMES',
              style: TextStyle(
                fontFamily: 'PressStart2P',
                fontSize: 10,
                color: RetroColors.secondary,
              ),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: ListView(
                  children: [
                    GameCard(
                      title: 'CHESS',
                      subtitle: hasChessSave
                          ? 'Continue saved game'
                          : 'Classic strategy',
                      icon: Icons.grid_on,
                      color: RetroColors.primary,
                      onTap: () => hasChessSave
                          ? _showContinueDialog(
                              context,
                              ref,
                              'CHESS',
                              onContinue: () async {
                                final loaded = await ref
                                    .read(chessGameProvider.notifier)
                                    .loadGame();
                                if (loaded && context.mounted) {
                                  _navigateAndRefresh(
                                    context,
                                    ref,
                                    ChessScreen(
                                      gameMode: ref
                                          .read(chessGameProvider)
                                          .gameMode,
                                      loadedFromSave: true,
                                    ),
                                  );
                                }
                              },
                              onNewGame: () async {
                                await ref
                                    .read(chessGameProvider.notifier)
                                    .deleteSave();
                                ref.invalidate(_savedGamesProvider);
                                if (context.mounted) {
                                  _selectModeAndNavigate(
                                    context,
                                    'CHESS',
                                    (mode) => ChessScreen(gameMode: mode),
                                    ref: ref,
                                  );
                                }
                              },
                            )
                          : _selectModeAndNavigate(
                              context,
                              'CHESS',
                              (mode) => ChessScreen(gameMode: mode),
                              ref: ref,
                            ),
                    ),
                    const SizedBox(height: 16),
                    GameCard(
                      title: 'DAMMEN',
                      subtitle: hasCheckersSave
                          ? 'Continue saved game'
                          : 'International 10x10',
                      icon: Icons.circle_outlined,
                      color: RetroColors.secondary,
                      onTap: () => hasCheckersSave
                          ? _showContinueDialog(
                              context,
                              ref,
                              'DAMMEN',
                              onContinue: () async {
                                final loaded = await ref
                                    .read(checkersGameProvider.notifier)
                                    .loadGame();
                                if (loaded && context.mounted) {
                                  _navigateAndRefresh(
                                    context,
                                    ref,
                                    CheckersScreen(
                                      gameMode: ref
                                          .read(checkersGameProvider)
                                          .gameMode,
                                      loadedFromSave: true,
                                    ),
                                  );
                                }
                              },
                              onNewGame: () async {
                                await ref
                                    .read(checkersGameProvider.notifier)
                                    .deleteSave();
                                ref.invalidate(_savedGamesProvider);
                                if (context.mounted) {
                                  _selectModeAndNavigate(
                                    context,
                                    'DAMMEN',
                                    (mode) => CheckersScreen(gameMode: mode),
                                    ref: ref,
                                  );
                                }
                              },
                            )
                          : _selectModeAndNavigate(
                              context,
                              'DAMMEN',
                              (mode) => CheckersScreen(gameMode: mode),
                              ref: ref,
                            ),
                    ),
                    const SizedBox(height: 16),
                    GameCard(
                      title: 'BALLERBURG',
                      subtitle: hasBallerburgSave
                          ? 'Continue saved game'
                          : 'Artillery warfare',
                      icon: Icons.castle,
                      color: RetroColors.accent,
                      onTap: () => hasBallerburgSave
                          ? _showContinueDialog(
                              context,
                              ref,
                              'BALLERBURG',
                              onContinue: () async {
                                final loaded = await ref
                                    .read(ballerburgGameProvider.notifier)
                                    .loadGame();
                                if (loaded && context.mounted) {
                                  _navigateAndRefresh(
                                    context,
                                    ref,
                                    BallerburgScreen(
                                      gameMode: ref
                                          .read(ballerburgGameProvider)
                                          .gameMode,
                                      loadedFromSave: true,
                                    ),
                                  );
                                }
                              },
                              onNewGame: () async {
                                await ref
                                    .read(ballerburgGameProvider.notifier)
                                    .deleteSave();
                                ref.invalidate(_savedGamesProvider);
                                if (context.mounted) {
                                  _selectModeAndNavigate(
                                    context,
                                    'BALLERBURG',
                                    (mode) =>
                                        BallerburgScreen(gameMode: mode),
                                    ref: ref,
                                  );
                                }
                              },
                            )
                          : _selectModeAndNavigate(
                              context,
                              'BALLERBURG',
                              (mode) => BallerburgScreen(gameMode: mode),
                              ref: ref,
                            ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );

    if (settings.scanlineEffect) {
      content = ScanlineOverlay(child: content);
    }

    return content;
  }

  Future<void> _showContinueDialog(
    BuildContext context,
    WidgetRef ref,
    String gameTitle, {
    required Future<void> Function() onContinue,
    required Future<void> Function() onNewGame,
  }) async {
    final choice = await showDialog<String>(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: PixelBorder(
          color: RetroColors.primary,
          padding: const EdgeInsets.all(24),
          child: Container(
            color: RetroColors.background,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  gameTitle,
                  style: const TextStyle(
                    fontFamily: 'PressStart2P',
                    fontSize: 12,
                    color: RetroColors.primary,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'SAVED GAME FOUND',
                  style: TextStyle(
                    fontFamily: 'PressStart2P',
                    fontSize: 7,
                    color: RetroColors.textMuted,
                  ),
                ),
                const SizedBox(height: 16),
                _DialogButton(
                  label: 'CONTINUE',
                  color: RetroColors.primary,
                  onTap: () => Navigator.of(context).pop('continue'),
                ),
                const SizedBox(height: 12),
                _DialogButton(
                  label: 'NEW GAME',
                  color: RetroColors.secondary,
                  onTap: () => Navigator.of(context).pop('new'),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (choice == 'continue') {
      await onContinue();
    } else if (choice == 'new') {
      await onNewGame();
    }
  }

  Future<void> _selectModeAndNavigate(
    BuildContext context,
    String gameTitle,
    Widget Function(GameMode mode) screenBuilder, {
    WidgetRef? ref,
  }) async {
    final mode = await ModeSelectionDialog.show(context, gameTitle: gameTitle);
    if (mode == null || !context.mounted) return;
    if (ref != null) {
      _navigateAndRefresh(context, ref, screenBuilder(mode));
    } else {
      _navigateTo(context, screenBuilder(mode));
    }
  }

  void _navigateTo(BuildContext context, Widget screen) {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => screen,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }

  /// Navigates and refreshes saved game status when returning.
  void _navigateAndRefresh(BuildContext context, WidgetRef ref, Widget screen) {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => screen,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 300),
      ),
    ).then((_) {
      ref.invalidate(_savedGamesProvider);
    });
  }
}

class _DialogButton extends StatefulWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _DialogButton({
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  State<_DialogButton> createState() => _DialogButtonState();
}

class _DialogButtonState extends State<_DialogButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: Transform.translate(
        offset: _pressed ? const Offset(2, 2) : Offset.zero,
        child: PixelBorder(
          color: widget.color,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: Text(
            widget.label,
            style: TextStyle(
              fontFamily: 'PressStart2P',
              fontSize: 10,
              color: widget.color,
            ),
          ),
        ),
      ),
    );
  }
}
