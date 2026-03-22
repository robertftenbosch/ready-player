import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/retro_colors.dart';
import '../widgets/pixel_border.dart';
import '../widgets/pixel_button.dart';
import '../widgets/pixel_loading_indicator.dart';
import '../widgets/scanline_overlay.dart';
import '../../home/home_screen.dart';
import 'llm_service.dart';

enum _SetupState {
  checking,
  modelReady,
  promptDownload,
  downloading,
  downloadSuccess,
  downloadError,
}

class LlmSetupScreen extends ConsumerStatefulWidget {
  const LlmSetupScreen({super.key});

  @override
  ConsumerState<LlmSetupScreen> createState() => _LlmSetupScreenState();
}

class _LlmSetupScreenState extends ConsumerState<LlmSetupScreen> {
  _SetupState _state = _SetupState.checking;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _checkModel();
  }

  Future<void> _checkModel() async {
    final llmService = ref.read(llmServiceProvider);
    final downloaded = await llmService.isModelDownloaded();

    if (!mounted) return;

    if (downloaded) {
      setState(() => _state = _SetupState.modelReady);
      ref.read(llmReadyProvider.notifier).state = true;
      await Future.delayed(const Duration(milliseconds: 1200));
      if (mounted) _navigateToHome();
    } else {
      setState(() => _state = _SetupState.promptDownload);
    }
  }

  Future<void> _startDownload() async {
    setState(() => _state = _SetupState.downloading);
    final llmService = ref.read(llmServiceProvider);
    try {
      await llmService.downloadModel();
      if (!mounted) return;
      ref.read(llmReadyProvider.notifier).state = true;
      setState(() => _state = _SetupState.downloadSuccess);
      await Future.delayed(const Duration(milliseconds: 1500));
      if (mounted) _navigateToHome();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _state = _SetupState.downloadError;
        _errorMessage = e.toString();
      });
    }
  }

  void _navigateToHome() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const HomeScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: RetroColors.background,
      body: ScanlineOverlay(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: _buildContent(),
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    switch (_state) {
      case _SetupState.checking:
        return _buildChecking();
      case _SetupState.modelReady:
        return _buildModelReady();
      case _SetupState.promptDownload:
        return _buildPromptDownload();
      case _SetupState.downloading:
        return _buildDownloading();
      case _SetupState.downloadSuccess:
        return _buildDownloadSuccess();
      case _SetupState.downloadError:
        return _buildDownloadError();
    }
  }

  Widget _buildChecking() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildTitle(),
        const SizedBox(height: 32),
        const PixelLoadingIndicator(),
        const SizedBox(height: 16),
        const Text(
          'CHECKING MODEL...',
          style: TextStyle(
            fontFamily: 'PressStart2P',
            fontSize: 8,
            color: RetroColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildModelReady() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildTitle(),
        const SizedBox(height: 32),
        const Icon(Icons.check_circle_outline, color: RetroColors.primary, size: 48),
        const SizedBox(height: 16),
        const Text(
          'MODEL READY!',
          style: TextStyle(
            fontFamily: 'PressStart2P',
            fontSize: 10,
            color: RetroColors.primary,
          ),
        ),
      ],
    );
  }

  Widget _buildPromptDownload() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildTitle(),
        const SizedBox(height: 24),
        PixelBorder(
          color: RetroColors.primaryDim,
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const Icon(Icons.smart_toy_outlined, color: RetroColors.secondary, size: 48),
              const SizedBox(height: 16),
              const Text(
                'GEMMA 2B LLM',
                style: TextStyle(
                  fontFamily: 'PressStart2P',
                  fontSize: 10,
                  color: RetroColors.primary,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                '~1.4 GB',
                style: TextStyle(
                  fontFamily: 'PressStart2P',
                  fontSize: 8,
                  color: RetroColors.textSecondary,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'On-device AI opponent\nfor all games.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'PressStart2P',
                  fontSize: 6,
                  color: RetroColors.textMuted,
                  height: 1.8,
                ),
              ),
              const SizedBox(height: 24),
              PixelButton(
                text: 'DOWNLOAD MODEL',
                color: RetroColors.primary,
                onPressed: _startDownload,
              ),
              const SizedBox(height: 12),
              PixelButton(
                text: 'SKIP',
                color: RetroColors.secondary,
                onPressed: _navigateToHome,
              ),
              const SizedBox(height: 16),
              const Text(
                'Games work without\nthe model using\nrandom fallback.',
                textAlign: TextAlign.center,
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
      ],
    );
  }

  Widget _buildDownloading() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildTitle(),
        const SizedBox(height: 32),
        PixelBorder(
          color: RetroColors.primaryDim,
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const Icon(Icons.downloading_outlined, color: RetroColors.primary, size: 48),
              const SizedBox(height: 16),
              const Text(
                'SETTING UP MODEL...',
                style: TextStyle(
                  fontFamily: 'PressStart2P',
                  fontSize: 8,
                  color: RetroColors.primary,
                ),
              ),
              const SizedBox(height: 16),
              const PixelLoadingIndicator(),
              const SizedBox(height: 16),
              const Text(
                'Please wait...',
                style: TextStyle(
                  fontFamily: 'PressStart2P',
                  fontSize: 6,
                  color: RetroColors.textMuted,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDownloadSuccess() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildTitle(),
        const SizedBox(height: 32),
        const Icon(Icons.check_circle_outline, color: RetroColors.primary, size: 48),
        const SizedBox(height: 16),
        const Text(
          'MODEL READY!',
          style: TextStyle(
            fontFamily: 'PressStart2P',
            fontSize: 10,
            color: RetroColors.primary,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'LOADING GAMES...',
          style: TextStyle(
            fontFamily: 'PressStart2P',
            fontSize: 7,
            color: RetroColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildDownloadError() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildTitle(),
        const SizedBox(height: 24),
        PixelBorder(
          color: RetroColors.accentDim,
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const Icon(Icons.error_outline, color: RetroColors.accent, size: 48),
              const SizedBox(height: 16),
              const Text(
                'SETUP FAILED',
                style: TextStyle(
                  fontFamily: 'PressStart2P',
                  fontSize: 10,
                  color: RetroColors.accent,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                _errorMessage,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'PressStart2P',
                  fontSize: 5,
                  color: RetroColors.textMuted,
                  height: 1.8,
                ),
              ),
              const SizedBox(height: 20),
              PixelButton(
                text: 'RETRY',
                color: RetroColors.primary,
                onPressed: _startDownload,
              ),
              const SizedBox(height: 12),
              PixelButton(
                text: 'SKIP',
                color: RetroColors.secondary,
                onPressed: _navigateToHome,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTitle() {
    return const Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'READY PLAYER',
          style: TextStyle(
            fontFamily: 'PressStart2P',
            fontSize: 16,
            color: RetroColors.primary,
            shadows: [
              Shadow(
                color: RetroColors.primaryGlow,
                blurRadius: 20,
              ),
            ],
          ),
        ),
        SizedBox(height: 8),
        Text(
          'AI SETUP',
          style: TextStyle(
            fontFamily: 'PressStart2P',
            fontSize: 10,
            color: RetroColors.secondary,
          ),
        ),
      ],
    );
  }
}
