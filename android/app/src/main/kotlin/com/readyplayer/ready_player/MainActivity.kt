package com.readyplayer.ready_player

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import com.readyplayer.ready_player.llm.LlmMethodChannel

class MainActivity : FlutterActivity() {
    private var llmChannel: LlmMethodChannel? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        llmChannel = LlmMethodChannel(
            applicationContext,
            flutterEngine.dartExecutor.binaryMessenger
        )
    }

    override fun onDestroy() {
        llmChannel?.dispose()
        super.onDestroy()
    }
}
