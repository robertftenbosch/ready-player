package com.readyplayer.ready_player.llm

import android.content.Context
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.launch

class LlmMethodChannel(
    private val context: Context,
    binaryMessenger: BinaryMessenger
) : MethodChannel.MethodCallHandler {

    private val channel = MethodChannel(binaryMessenger, "com.readyplayer/llm")
    private val inferenceService = LlmInferenceService(context)
    private val scope = CoroutineScope(Dispatchers.Main + SupervisorJob())

    init {
        channel.setMethodCallHandler(this)
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "initialize" -> {
                scope.launch {
                    try {
                        inferenceService.initialize()
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("INIT_ERROR", e.message, null)
                    }
                }
            }
            "generate" -> {
                val prompt = call.argument<String>("prompt")
                if (prompt == null) {
                    result.error("INVALID_ARGS", "prompt is required", null)
                    return
                }
                scope.launch {
                    try {
                        val response = inferenceService.generate(prompt)
                        result.success(response)
                    } catch (e: Exception) {
                        result.error("GENERATE_ERROR", e.message, null)
                    }
                }
            }
            "isModelDownloaded" -> {
                result.success(inferenceService.isModelDownloaded)
            }
            "getModelPath" -> {
                result.success(inferenceService.modelPath)
            }
            "downloadModel" -> {
                if (inferenceService.isModelDownloaded) {
                    result.success(true)
                } else {
                    result.error(
                        "MODEL_NOT_FOUND",
                        "Place gemma-2b-it-gpu-int4.bin in app files directory. Use: adb push model.bin /data/data/com.readyplayer.ready_player/files/",
                        null
                    )
                }
            }
            else -> result.notImplemented()
        }
    }

    fun dispose() {
        channel.setMethodCallHandler(null)
        inferenceService.close()
    }
}
