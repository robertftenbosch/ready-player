package com.readyplayer.ready_player.llm

import android.content.Context
import com.google.mediapipe.tasks.genai.llminference.LlmInference
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import java.io.File

class LlmInferenceService(private val context: Context) {
    private var llmInference: LlmInference? = null
    private val modelFileName = "gemma-2b-it-gpu-int4.bin"

    val isModelDownloaded: Boolean
        get() = File(context.filesDir, modelFileName).exists()

    val modelPath: String
        get() = File(context.filesDir, modelFileName).absolutePath

    suspend fun initialize() = withContext(Dispatchers.IO) {
        if (llmInference != null) return@withContext

        val modelFile = File(context.filesDir, modelFileName)
        if (!modelFile.exists()) {
            throw IllegalStateException("Model file not found. Please download the model first.")
        }

        val options = LlmInference.LlmInferenceOptions.builder()
            .setModelPath(modelFile.absolutePath)
            .setMaxTokens(256)
            .setTopK(40)
            .setTemperature(0.7f)
            .setRandomSeed(System.currentTimeMillis().toInt())
            .build()

        llmInference = LlmInference.createFromOptions(context, options)
    }

    suspend fun generate(prompt: String): String = withContext(Dispatchers.IO) {
        val inference = llmInference
            ?: throw IllegalStateException("LLM not initialized. Call initialize() first.")
        inference.generateResponse(prompt)
    }

    fun close() {
        llmInference?.close()
        llmInference = null
    }
}
