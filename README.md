# Ready Player

A retro-styled Flutter app where you play classic board and artillery games against an on-device LLM (Gemma 2B via MediaPipe) or against a friend on the same device.

## Games

### Chess
Full chess implementation with all rules: castling, en passant, pawn promotion, check/checkmate/stalemate detection, and 50-move draw rule. Play as White against the LLM or take turns in local multiplayer.

### Dammen (International Draughts)
10x10 international draughts with flying kings, mandatory captures, and the maximum capture rule. Complete DFS-based capture sequence generation ensures all rules are enforced correctly.

### Ballerburg
Turn-based artillery game inspired by the 1987 Atari ST classic by Eckhard Kruse. Two castles separated by a procedurally generated mountain. Set your cannon angle and gunpowder amount, account for wind, and try to destroy your opponent's castle. Features physics simulation, collision detection, and destructible castle blocks rendered with CustomPainter.

## Features

- **VS AI** - Play against Gemma 2B running on-device via MediaPipe LLM Inference API
- **VS Player** - Local multiplayer on the same device with automatic board flip
- **Undo/Redo** - Take back moves in all three games
- **Piece Animations** - Smooth 250ms movement animations for chess and checkers
- **8-bit Sound Effects** - Retro sounds for moves, captures, cannon fire, and explosions
- **Save/Load** - Auto-saves after each move, continue where you left off
- **Retro Pixel Art UI** - PressStart2P font, terminal green theme, CRT scanline overlay

## Tech Stack

- **Flutter** (Android)
- **Riverpod** for state management
- **MediaPipe LLM Inference API** for on-device Gemma 2B
- **CustomPainter** for Ballerburg rendering
- **audioplayers** for 8-bit sound effects
- **shared_preferences** for game persistence
- No external chess/checkers/game engine packages - all game logic built from scratch

## Getting Started

### Prerequisites

- Flutter 3.x
- Android SDK
- An Android device or emulator (minSdk 24)

### Run

```bash
flutter pub get
flutter run
```

### LLM Setup (Optional)

The games work without the LLM model - they fall back to random legal moves. To enable AI:

1. Download the Gemma 2B IT int4 model (`gemma-2b-it-gpu-int4.bin`, ~1.4 GB)
2. Push to device:
   ```bash
   adb push gemma-2b-it-gpu-int4.bin /data/data/com.readyplayer.ready_player/files/
   ```
3. Initialize the model from the app's Settings screen

## Project Structure

```
lib/
  core/           # Theme, widgets, LLM service, audio, persistence
  home/           # Game selection screen
  chess/          # Chess models, rules engine, FEN parser, UI
  checkers/       # International draughts models, rules, UI
  ballerburg/     # Artillery models, physics, rendering, UI
  settings/       # App settings
android/
  .../llm/        # Kotlin MediaPipe integration
assets/
  fonts/          # PressStart2P retro font
  audio/          # Generated 8-bit WAV sound effects
```

## LLM Strategy

Each game provides the LLM with a structured prompt containing the full game state and a complete list of legal moves. The LLM's response is parsed, validated against legal moves, and retried up to 2 times before falling back to a random legal move. This ensures games never deadlock regardless of LLM output quality.

## License

MIT
