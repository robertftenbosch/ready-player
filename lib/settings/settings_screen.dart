import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme/retro_colors.dart';
import '../core/widgets/retro_scaffold.dart';
import '../core/widgets/pixel_border.dart';
import '../core/widgets/pixel_button.dart';
import '../core/widgets/pixel_loading_indicator.dart';
import '../core/llm/llm_service.dart';
import 'settings_provider.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool? _modelDownloaded;
  bool _initializing = false;
  String? _initError;

  @override
  void initState() {
    super.initState();
    _checkModelStatus();
  }

  Future<void> _checkModelStatus() async {
    final llmService = ref.read(llmServiceProvider);
    final downloaded = await llmService.isModelDownloaded();
    if (mounted) {
      setState(() => _modelDownloaded = downloaded);
    }
  }

  Future<void> _initializeModel() async {
    setState(() {
      _initializing = true;
      _initError = null;
    });
    final llmService = ref.read(llmServiceProvider);
    try {
      await llmService.initialize();
      ref.read(llmReadyProvider.notifier).state = true;
      if (mounted) {
        setState(() => _initializing = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _initializing = false;
          _initError = e.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);
    final llmReady = ref.watch(llmReadyProvider);

    return RetroScaffold(
      title: 'SETTINGS',
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _SectionHeader(title: 'LLM MODEL'),
          const SizedBox(height: 12),
          PixelBorder(
            color: RetroColors.primaryDim,
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text(
                      'STATUS: ',
                      style: TextStyle(
                        fontFamily: 'PressStart2P',
                        fontSize: 7,
                        color: RetroColors.textSecondary,
                      ),
                    ),
                    Text(
                      _modelDownloaded == null
                          ? 'CHECKING...'
                          : _modelDownloaded!
                              ? (llmReady ? 'READY' : 'DOWNLOADED')
                              : 'NOT FOUND',
                      style: TextStyle(
                        fontFamily: 'PressStart2P',
                        fontSize: 7,
                        color: _modelDownloaded == true
                            ? RetroColors.primary
                            : RetroColors.accent,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'gemma-2b-it-gpu-int4.bin',
                  style: TextStyle(
                    fontFamily: 'PressStart2P',
                    fontSize: 5,
                    color: RetroColors.textMuted,
                  ),
                ),
                const SizedBox(height: 12),
                if (_modelDownloaded == true && !llmReady) ...[
                  if (_initializing)
                    const Center(child: PixelLoadingIndicator())
                  else
                    PixelButton(
                      text: 'INITIALIZE',
                      color: RetroColors.primary,
                      fontSize: 7,
                      onPressed: _initializeModel,
                    ),
                  if (_initError != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      _initError!,
                      style: const TextStyle(
                        fontFamily: 'PressStart2P',
                        fontSize: 5,
                        color: RetroColors.accent,
                        height: 1.8,
                      ),
                    ),
                  ],
                ] else if (_modelDownloaded == false)
                  const Text(
                    'Place model file via:\nadb push gemma-2b-it-gpu-int4.bin\n/data/data/com.readyplayer\n.ready_player/files/',
                    style: TextStyle(
                      fontFamily: 'PressStart2P',
                      fontSize: 5,
                      color: RetroColors.textMuted,
                      height: 1.8,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _SectionHeader(title: 'LLM'),
          const SizedBox(height: 12),
          PixelBorder(
            color: RetroColors.primaryDim,
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'TEMPERATURE',
                  style: TextStyle(
                    fontFamily: 'PressStart2P',
                    fontSize: 7,
                    color: RetroColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text(
                      settings.llmTemperature.toStringAsFixed(1),
                      style: const TextStyle(
                        fontFamily: 'PressStart2P',
                        fontSize: 10,
                        color: RetroColors.primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: SliderTheme(
                        data: SliderThemeData(
                          activeTrackColor: RetroColors.primary,
                          inactiveTrackColor: RetroColors.primaryDim,
                          thumbColor: RetroColors.primary,
                          overlayColor: RetroColors.primaryGlow,
                          trackHeight: 4,
                          thumbShape: const RoundSliderThumbShape(
                            enabledThumbRadius: 6,
                          ),
                        ),
                        child: Slider(
                          value: settings.llmTemperature,
                          min: 0.1,
                          max: 1.5,
                          divisions: 14,
                          onChanged: (v) => notifier.setLlmTemperature(v),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Lower = more predictable, Higher = more creative',
                  style: TextStyle(
                    fontFamily: 'PressStart2P',
                    fontSize: 5,
                    color: RetroColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _SectionHeader(title: 'DISPLAY'),
          const SizedBox(height: 12),
          _ToggleTile(
            label: 'CRT SCANLINES',
            value: settings.scanlineEffect,
            onToggle: () => notifier.toggleScanlineEffect(),
          ),
          const SizedBox(height: 20),
          _SectionHeader(title: 'AUDIO'),
          const SizedBox(height: 12),
          _ToggleTile(
            label: 'SOUND EFFECTS',
            value: settings.soundEnabled,
            onToggle: () => notifier.toggleSound(),
          ),
          const SizedBox(height: 32),
          _SectionHeader(title: 'ABOUT'),
          const SizedBox(height: 12),
          PixelBorder(
            color: RetroColors.primaryDim,
            padding: const EdgeInsets.all(12),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'READY PLAYER v1.0',
                  style: TextStyle(
                    fontFamily: 'PressStart2P',
                    fontSize: 8,
                    color: RetroColors.primary,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Play classic games\nagainst an on-device\nGemma LLM.',
                  style: TextStyle(
                    fontFamily: 'PressStart2P',
                    fontSize: 6,
                    color: RetroColors.textMuted,
                    height: 1.8,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Chess | Dammen | Ballerburg',
                  style: TextStyle(
                    fontFamily: 'PressStart2P',
                    fontSize: 6,
                    color: RetroColors.secondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      '// $title',
      style: const TextStyle(
        fontFamily: 'PressStart2P',
        fontSize: 8,
        color: RetroColors.secondary,
      ),
    );
  }
}

class _ToggleTile extends StatelessWidget {
  final String label;
  final bool value;
  final VoidCallback onToggle;

  const _ToggleTile({
    required this.label,
    required this.value,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onToggle,
      child: PixelBorder(
        color: RetroColors.primaryDim,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontFamily: 'PressStart2P',
                fontSize: 7,
                color: RetroColors.textSecondary,
              ),
            ),
            Container(
              width: 40,
              height: 20,
              decoration: BoxDecoration(
                color: value ? RetroColors.primaryDim : RetroColors.surface,
                border: Border.all(
                  color: value ? RetroColors.primary : RetroColors.textMuted,
                  width: 2,
                ),
              ),
              child: Align(
                alignment:
                    value ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  width: 16,
                  height: 16,
                  color: value ? RetroColors.primary : RetroColors.textMuted,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
