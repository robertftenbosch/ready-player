import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'llm_state.dart';

class LlmService {
  static const _channel = MethodChannel('com.readyplayer/llm');

  LlmState _state = LlmState.uninitialized;
  LlmState get state => _state;

  Future<void> initialize() async {
    _state = LlmState.loading;
    try {
      await _channel.invokeMethod('initialize');
      _state = LlmState.ready;
    } catch (e) {
      _state = LlmState.error;
      rethrow;
    }
  }

  Future<String> generateResponse(String prompt, {Duration timeout = const Duration(seconds: 30)}) async {
    if (_state != LlmState.ready) {
      throw StateError('LLM not ready. Current state: $_state');
    }
    _state = LlmState.thinking;
    try {
      final result = await _channel.invokeMethod<String>(
        'generate',
        {'prompt': prompt},
      ).timeout(timeout);
      _state = LlmState.ready;
      return result ?? '';
    } catch (e) {
      _state = LlmState.ready;
      rethrow;
    }
  }

  Future<bool> isModelDownloaded() async {
    try {
      final result = await _channel.invokeMethod<bool>('isModelDownloaded');
      return result ?? false;
    } catch (_) {
      return false;
    }
  }

  Future<void> downloadModel() async {
    await _channel.invokeMethod('downloadModel');
  }
}

final llmServiceProvider = Provider<LlmService>((ref) => LlmService());

final llmReadyProvider = StateProvider<bool>((ref) => false);
