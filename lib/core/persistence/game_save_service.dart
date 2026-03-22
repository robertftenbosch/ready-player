import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../chess/models/chess_game_state.dart';
import '../../checkers/models/checkers_game_state.dart';
import '../../ballerburg/models/ballerburg_game_state.dart';

class GameSaveService {
  static const _chessKey = 'saved_chess_game';
  static const _checkersKey = 'saved_checkers_game';
  static const _ballerburgKey = 'saved_ballerburg_game';

  // ── Chess ─────────────────────────────────────────────────────────

  Future<void> saveChessGame(ChessGameState state) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_chessKey, jsonEncode(state.toJson()));
    } catch (_) {}
  }

  Future<ChessGameState?> loadChessGame() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = prefs.getString(_chessKey);
      if (json == null) return null;
      return ChessGameState.fromJson(
          jsonDecode(json) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  Future<void> deleteChessGame() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_chessKey);
    } catch (_) {}
  }

  Future<bool> hasChessGameSave() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.containsKey(_chessKey);
    } catch (_) {
      return false;
    }
  }

  // ── Checkers ──────────────────────────────────────────────────────

  Future<void> saveCheckersGame(CheckersGameState state) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_checkersKey, jsonEncode(state.toJson()));
    } catch (_) {}
  }

  Future<CheckersGameState?> loadCheckersGame() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = prefs.getString(_checkersKey);
      if (json == null) return null;
      return CheckersGameState.fromJson(
          jsonDecode(json) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  Future<void> deleteCheckersGame() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_checkersKey);
    } catch (_) {}
  }

  Future<bool> hasCheckersGameSave() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.containsKey(_checkersKey);
    } catch (_) {
      return false;
    }
  }

  // ── Ballerburg ────────────────────────────────────────────────────

  Future<void> saveBallerburgGame(BallerburgGameState state) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_ballerburgKey, jsonEncode(state.toJson()));
    } catch (_) {}
  }

  Future<BallerburgGameState?> loadBallerburgGame() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = prefs.getString(_ballerburgKey);
      if (json == null) return null;
      return BallerburgGameState.fromJson(
          jsonDecode(json) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  Future<void> deleteBallerburgGame() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_ballerburgKey);
    } catch (_) {}
  }

  Future<bool> hasBallerburgGameSave() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.containsKey(_ballerburgKey);
    } catch (_) {
      return false;
    }
  }
}

final gameSaveServiceProvider =
    Provider<GameSaveService>((ref) => GameSaveService());
