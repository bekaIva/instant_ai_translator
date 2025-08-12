package com.example.instant_ai_translator

import android.app.Activity
import android.app.AlertDialog
import android.content.ClipData
import android.content.ClipboardManager
import android.content.Context
import android.content.Intent
import android.os.Bundle
import android.widget.Toast
import android.widget.LinearLayout
import android.widget.ProgressBar
import android.widget.TextView
import android.view.ViewGroup

/**
 * Share target for ACTION_SEND so our action appears in apps (like Slack) that promote
 * share targets into their custom selection toolbars (similar to Acrobat's "Create PDF").
 *
 * Flow:
 * - Receives shared text
 * - Loads dynamic menu items from SharedPreferences (via ConfigReader)
 * - Lets the user choose an operation
 * - Processes via headless Flutter (FlutterProcessor)
 * - Presents the result with "Copy" and "Share Result" options
 */
class ShareToInstantAIActivity : Activity() {

    private var loadingDialog: AlertDialog? = null

    private fun showLoading(message: String = "Processing…") {
        dismissLoading()
        val padding = (16 * resources.displayMetrics.density).toInt()
        val container = LinearLayout(this).apply {
            orientation = LinearLayout.HORIZONTAL
            setPadding(padding, padding, padding, padding)
            layoutParams = ViewGroup.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.WRAP_CONTENT)
        }
        val progress = ProgressBar(this).apply {
            isIndeterminate = true
        }
        val msg = TextView(this).apply {
            text = message
            setPadding((12 * resources.displayMetrics.density).toInt(), 0, 0, 0)
        }
        container.addView(progress)
        container.addView(msg)

        loadingDialog = AlertDialog.Builder(this)
            .setTitle("Instant AI Translator")
            .setView(container)
            .setCancelable(false)
            .create().also { it.show() }
    }

    private fun dismissLoading() {
        loadingDialog?.dismiss()
        loadingDialog = null
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        val action = intent?.action
        val type = intent?.type
        if (action != Intent.ACTION_SEND || type == null || !(type.startsWith("text/"))) {
            Toast.makeText(this, "Unsupported share type", Toast.LENGTH_SHORT).show()
            finish()
            return
        }

        val sharedText = intent.getStringExtra(Intent.EXTRA_TEXT)?.toString()?.trim().orEmpty()
        if (sharedText.isEmpty()) {
            Toast.makeText(this, "No text received", Toast.LENGTH_SHORT).show()
            finish()
            return
        }

        // Load dynamic menu items from Flutter-managed SharedPreferences
        val configs = ConfigReader.getEnabledConfigs(this)
        val menuItems = configs
            .filter { it.enabled }
            .sortedBy { it.sortOrder }
            .map { Triple(it.id, it.label, it.operation) } // (id, label, operation)

        if (menuItems.isEmpty()) {
            showFallbackMenu(sharedText)
        } else {
            showDynamicMenu(sharedText, menuItems)
        }
    }

    private fun showDynamicMenu(
        sourceText: String,
        items: List<Triple<String, String, String>> // (id, label, operation)
    ) {
        val labels = items.map { it.second }.toTypedArray()

        AlertDialog.Builder(this)
            .setTitle("Instant AI Translator")
            .setItems(labels) { _, which ->
                val selected = items[which]
                processWithOperation(sourceText, selected.third)
            }
            .setOnCancelListener { finish() }
            .show()
    }

    private fun showFallbackMenu(sourceText: String) {
        val actions = arrayOf(
            "Uppercase",
            "Prefix [AI] ",
            "Echo"
        )

        AlertDialog.Builder(this)
            .setTitle("Instant AI Translator")
            .setItems(actions) { _, which ->
                val result = when (which) {
                    0 -> sourceText.uppercase()
                    1 -> "[AI] $sourceText"
                    else -> sourceText
                }
                showResultActions(result, sourceText)
            }
            .setOnCancelListener { finish() }
            .show()
    }

    private fun processWithOperation(sourceText: String, operation: String) {
        // Show loading indicator while headless Flutter processes text
        showLoading("Processing…")
 
        // Offload to Flutter for AI processing
        FlutterProcessor.processText(
            context = this,
            text = sourceText,
            operation = operation
        ) { result, error ->
            // Always hide the loading dialog on callback
            dismissLoading()
 
            if (error != null) {
                Toast.makeText(this, "Processing failed: ${error.message}", Toast.LENGTH_LONG).show()
                showResultActions("ERROR: ${error.message}", sourceText)
                return@processText
            }
 
            val processed = result?.trim().orEmpty()
            if (processed.isEmpty()) {
                Toast.makeText(this, "Empty result", Toast.LENGTH_SHORT).show()
                finish()
            } else {
                showResultActions(processed, sourceText)
            }
        }
    }

    private fun showResultActions(result: String, originalText: String) {
        AlertDialog.Builder(this)
            .setTitle("Processed Result")
            .setMessage(result)
            .setPositiveButton("Copy") { _, _ ->
                copyToClipboard(result)
                Toast.makeText(this, "Copied", Toast.LENGTH_SHORT).show()
                finish()
            }
            .setNeutralButton("Share Result") { _, _ ->
                shareText(result)
                finish()
            }
            // Use Negative button slot for "Reprocess" (Cancel/back will still close)
            .setNegativeButton("Reprocess") { _, _ ->
                reopenMenuFor(originalText)
            }
            .setOnCancelListener { finish() }
            .show()
    }

    private fun reopenMenuFor(sourceText: String) {
        val configs = ConfigReader.getEnabledConfigs(this)
        val menuItems = configs
            .filter { it.enabled }
            .sortedBy { it.sortOrder }
            .map { Triple(it.id, it.label, it.operation) }

        if (menuItems.isEmpty()) {
            showFallbackMenu(sourceText)
        } else {
            showDynamicMenu(sourceText, menuItems)
        }
    }

    private fun previewOf(text: String): String {
        val firstLine = text.lineSequence().firstOrNull().orEmpty()
        val head = if (firstLine.length > 140) firstLine.substring(0, 140) + "…" else firstLine
        val more = if (text.contains('\n')) "\n…" else ""
        return "Shared text:\n$head$more"
    }

    private fun copyToClipboard(value: String) {
        val cm = getSystemService(Context.CLIPBOARD_SERVICE) as ClipboardManager
        cm.setPrimaryClip(ClipData.newPlainText("Instant AI Result", value))
    }

    private fun shareText(value: String) {
        val share = Intent(Intent.ACTION_SEND).apply {
            type = "text/plain"
            putExtra(Intent.EXTRA_TEXT, value)
        }
        startActivity(Intent.createChooser(share, "Share processed text"))
    }
    override fun onDestroy() {
        dismissLoading()
        super.onDestroy()
    }
}