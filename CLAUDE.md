# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build & Development Commands

```bash
flutter pub get          # Install dependencies
flutter run              # Run on connected Android device/emulator
flutter analyze          # Lint and static analysis
flutter test             # Run all tests
flutter test test/widget_test.dart  # Run single test file
flutter build apk        # Build release APK
```

Min SDK is 24 (Android 7.0). The project targets Android only.

## Architecture

Three games (Chess, Checkers/Dammen, Ballerburg) share identical layered architecture:

```
models/     → Immutable state classes with copyWith() and toJson()/fromJson()
logic/      → Pure game rules, move generation, physics (no Flutter dependencies)
providers/  → Riverpod Notifier<GameState> managing game loop, undo/redo, LLM calls
llm/        → Prompt builders that format game state for LLM consumption
widgets/    → Board rendering, piece widgets, input controls
screens/    → ConsumerStatefulWidget assembling widgets and wiring providers
```

Shared code lives in `lib/core/`: theme, retro widgets, LLM service, audio, persistence.

### State Management

**Riverpod Notifier pattern** (not StateNotifier, not code-gen):
```dart
class ChessGameNotifier extends Notifier<ChessGameState> {
  final List<ChessGameState> _history = [];
  final List<ChessGameState> _redoStack = [];
  // ...
}
final chessGameProvider = NotifierProvider<ChessGameNotifier, ChessGameState>(...);
```

Each provider manages: game phases (`playerTurn`/`llmThinking`/`gameOver`), undo/redo stacks, auto-save after moves, and sound effect triggers.

### LLM Integration

Flutter ↔ Kotlin via MethodChannel `com.readyplayer/llm`. Kotlin wraps MediaPipe's `LlmInference` API for Gemma 2B.

**Critical pattern**: Every LLM response is validated against the legal move list. Invalid responses retry up to 2 times, then fall back to a random legal move. Games never deadlock.

Prompt builders (`chess_prompt_builder.dart`, etc.) include the full game state + complete list of legal moves, requesting a single move in a rigid parseable format.

### Game Mode

`GameMode.vsAi` (human vs LLM) and `GameMode.vsPlayer` (local multiplayer). In vsPlayer mode: board auto-flips, both colors are tappable, undo takes 1 step instead of 2.

### Rendering

Chess/Checkers: widget tree with `GridView`-like layout, `AnimationController` for piece movement (250ms). Ballerburg: full `CustomPainter` with layered renderers (sky, mountain, castles, projectile, explosion), `Timer.periodic` for projectile animation.

### Persistence

`shared_preferences` with JSON. All models have `toJson()`/`fromJson()`. Animation state (projectile, explosion) is not serialized. GameSaveService manages one save slot per game type.

## Key Conventions

- **No external game engines** — all chess rules, checkers rules, and physics are implemented from scratch
- **No Freezed/code-gen** — plain Dart classes with manual `copyWith()`
- **Retro UI** — `PressStart2P` font, `RetroColors` palette, `Paint()..isAntiAlias = false` for pixel art
- **Audio safety** — all sound plays wrapped in try/catch, controlled by `settingsProvider.soundEnabled`
- **Enum serialization** — use `.name` to serialize, `.byName()` to deserialize
- **Board indexing** — Chess: 0-63 flat array (0=a1, 63=h8). Checkers: 1-50 standard international numbering
