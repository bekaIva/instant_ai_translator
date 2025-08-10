package com.example.instant_ai_translator

import android.content.Context
import android.os.Handler
import android.os.Looper
import io.flutter.FlutterInjector
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.dart.DartExecutor.DartEntrypoint
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugins.GeneratedPluginRegistrant
import java.util.concurrent.atomic.AtomicBoolean
import kotlin.math.min

/**
 * Starts a headless FlutterEngine and calls into the Flutter side to process text.
 * Flutter entrypoint function: processMain() defined in lib/main.dart.
 * Channel name: "instant_ai/process"
 *
 * This avoids launching the Flutter UI and mirrors the Linux processing pipeline.
 */
object FlutterProcessor {

    private const val CHANNEL_NAME = "instant_ai/process"
    private var engine: FlutterEngine? = null
    private val engineReady = AtomicBoolean(false)
    private val mainHandler = Handler(Looper.getMainLooper())

    @Synchronized
    private fun ensureEngine(context: Context) {
        if (engineReady.get()) return

        // Ensure Flutter runtime is initialized
        val loader = FlutterInjector.instance().flutterLoader()
        if (!loader.initialized()) {
            loader.startInitialization(context.applicationContext)
            loader.ensureInitializationComplete(context.applicationContext, null)
        }

        // Start a headless engine with custom Dart entrypoint: processMain
        val e = FlutterEngine(context.applicationContext)
        // Register plugins so shared_preferences, http, etc. work in headless mode
        try {
            GeneratedPluginRegistrant.registerWith(e)
        } catch (_: Throwable) {
            // Some newer embeddings auto-register; ignore if not present
        }
        val appBundlePath = loader.findAppBundlePath()
        val entrypoint = DartEntrypoint(appBundlePath, "processMain")
        e.dartExecutor.executeDartEntrypoint(entrypoint)

        engine = e
        engineReady.set(true)
    }

    /**
     * Process text via Flutter Gemini pipeline.
     * The callback is always invoked on the main thread.
     * Includes a short retry loop to allow channel registration on cold start.
     */
    fun processText(
        context: Context,
        text: String,
        operation: String,
        onResult: (result: String?, error: Throwable?) -> Unit
    ) {
        try {
            ensureEngine(context)
        } catch (t: Throwable) {
            mainHandler.post { onResult(null, t) }
            return
        }

        val e = engine
        if (e == null) {
            mainHandler.post { onResult(null, IllegalStateException("FlutterEngine not available")) }
            return
        }

        val channel = MethodChannel(e.dartExecutor.binaryMessenger, CHANNEL_NAME)
        invokeWithRetry(channel, text, operation, 0, onResult)
    }

    private fun invokeWithRetry(
        channel: MethodChannel,
        text: String,
        operation: String,
        attempt: Int,
        onResult: (result: String?, error: Throwable?) -> Unit
    ) {
        channel.invokeMethod(
            "processText",
            mapOf("text" to text, "operation" to operation),
            object : MethodChannel.Result {
                override fun success(result: Any?) {
                    mainHandler.post { onResult(result as? String ?: "", null) }
                }

                override fun error(errorCode: String, errorMessage: String?, errorDetails: Any?) {
                    // If Flutter isn't ready yet, try a couple more times briefly
                    if (attempt < 3 && (errorMessage?.contains("MissingPluginException") == true)) {
                        val delay = min(300L * (attempt + 1), 900L)
                        mainHandler.postDelayed({
                            invokeWithRetry(channel, text, operation, attempt + 1, onResult)
                        }, delay)
                    } else {
                        mainHandler.post { onResult(null, RuntimeException("$errorCode: ${errorMessage ?: "Unknown error"}")) }
                    }
                }

                override fun notImplemented() {
                    if (attempt < 3) {
                        val delay = min(300L * (attempt + 1), 900L)
                        mainHandler.postDelayed({
                            invokeWithRetry(channel, text, operation, attempt + 1, onResult)
                        }, delay)
                    } else {
                        mainHandler.post { onResult(null, RuntimeException("Flutter method not implemented")) }
                    }
                }
            }
        )
    }
}