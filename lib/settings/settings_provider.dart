import 'package:flutter_riverpod/flutter_riverpod.dart';

class AppSettings {
  final double llmTemperature;
  final bool scanlineEffect;
  final bool soundEnabled;

  const AppSettings({
    this.llmTemperature = 0.7,
    this.scanlineEffect = true,
    this.soundEnabled = true,
  });

  AppSettings copyWith({
    double? llmTemperature,
    bool? scanlineEffect,
    bool? soundEnabled,
  }) {
    return AppSettings(
      llmTemperature: llmTemperature ?? this.llmTemperature,
      scanlineEffect: scanlineEffect ?? this.scanlineEffect,
      soundEnabled: soundEnabled ?? this.soundEnabled,
    );
  }
}

class SettingsNotifier extends Notifier<AppSettings> {
  @override
  AppSettings build() => const AppSettings();

  void setLlmTemperature(double value) {
    state = state.copyWith(llmTemperature: value.clamp(0.1, 1.5));
  }

  void toggleScanlineEffect() {
    state = state.copyWith(scanlineEffect: !state.scanlineEffect);
  }

  void toggleSound() {
    state = state.copyWith(soundEnabled: !state.soundEnabled);
  }
}

final settingsProvider =
    NotifierProvider<SettingsNotifier, AppSettings>(SettingsNotifier.new);
