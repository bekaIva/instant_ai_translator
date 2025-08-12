package com.example.instant_ai_translator

import android.app.Activity
import android.content.ClipData
import android.content.ClipboardManager
import android.content.Context
import android.content.Intent
import android.os.Bundle
import android.view.View
import android.view.ViewGroup
import android.widget.*
import com.example.instant_ai_translator.ConfigReader.ContextMenuConfig

/**
 * Android Process Text entry that:
 * - Loads dynamic context menu actions from Flutter-managed SharedPreferences
 * - Sends selected text + operation to Flutter via a headless engine
 * - Replaces the selection with the processed text (editable) or provides Copy (read-only)
 */
class ProcessTextActivity : Activity() {

    private lateinit var container: LinearLayout
    private lateinit var progressBar: ProgressBar
    private lateinit var statusText: TextView
    private var isProcessing = false

    // Keep original selection and read-only flag so "Reprocess" applies to original (no chaining)
    private lateinit var originalText: String
    private var readOnly: Boolean = false

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        val selectedText = intent?.getCharSequenceExtra(Intent.EXTRA_PROCESS_TEXT)?.toString() ?: ""
        val isReadOnly = intent?.getBooleanExtra(Intent.EXTRA_PROCESS_TEXT_READONLY, false) ?: false

        if (selectedText.isEmpty()) {
            Toast.makeText(this, "No text received", Toast.LENGTH_SHORT).show()
            finish()
            return
        }

        // Persist for reprocessing without chaining
        originalText = selectedText
        readOnly = isReadOnly

        setContentView(buildUi(originalText, readOnly))
        populateActions(originalText, readOnly)
    }

    private fun dp(v: Int) = (v * resources.displayMetrics.density).toInt()

    private fun buildUi(selectedText: String, isReadOnly: Boolean): View {
        val root = ScrollView(this)
        container = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            setPadding(dp(16), dp(16), dp(16), dp(16))
            layoutParams = ViewGroup.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT,
                ViewGroup.LayoutParams.WRAP_CONTENT
            )
        }
        root.addView(container)

        val title = TextView(this).apply {
            text = "Instant AI Translator"
            textSize = 20f
        }
        val preview = TextView(this).apply {
            text = ConfigReader.previewOf(selectedText)
            setPadding(0, dp(8), 0, dp(16))
        }

        progressBar = ProgressBar(this).apply {
            visibility = View.GONE
        }
        statusText = TextView(this).apply {
            text = ""
            visibility = View.GONE
            setPadding(0, dp(8), 0, dp(8))
        }

        container.addView(title)
        container.addView(preview)
        container.addView(progressBar)
        container.addView(statusText)

        // Footer actions
        val cancelBtn = Button(this).apply {
            text = "Cancel"
            isAllCaps = false
            setOnClickListener {
                if (!isProcessing) {
                    setResult(RESULT_CANCELED)
                    finish()
                }
            }
        }
        container.addView(cancelBtn)

        // Note to user about read-only
        if (isReadOnly) {
            val note = TextView(this).apply {
                text = "Note: Source is read-only. Result will be copied to clipboard."
                setPadding(0, dp(6), 0, dp(0))
            }
            container.addView(note, 3) // after status
        }

        return root
    }

    private fun addActionButton(label: String, onClick: () -> Unit) {
        val btn = Button(this).apply {
            text = label
            isAllCaps = false
        }
        btn.setOnClickListener { if (!isProcessing) onClick() }
        // Insert before the footer "Cancel" button (which is currently the last child)
        container.addView(btn, container.childCount - 1)
    }

    private fun setLoading(loading: Boolean, message: String = "") {
        isProcessing = loading
        progressBar.visibility = if (loading) View.VISIBLE else View.GONE
        statusText.visibility = if (message.isNotEmpty()) View.VISIBLE else View.GONE
        statusText.text = message
        // Disable/enable all children buttons except Cancel
        for (i in 0 until container.childCount) {
            val v = container.getChildAt(i)
            if (v is Button && v.text.toString() != "Cancel") {
                v.isEnabled = !loading
            }
        }
    }

    private fun populateActions(selectedText: String, isReadOnly: Boolean) {
        val configs = ConfigReader.getEnabledConfigs(this)

        if (configs.isEmpty()) {
            // Fallback demo actions if user hasn't configured anything yet
            addActionButton("Uppercase") {
                handleResult(selectedText.uppercase(), isReadOnly)
            }
            addActionButton("Prefix [AI] ") {
                handleResult("[AI] $selectedText", isReadOnly)
            }
            addActionButton("Echo") {
                handleResult(selectedText, isReadOnly)
            }
            val hint = TextView(this).apply {
                text = "Tip: Configure dynamic actions in the Flutter app (Context Menu Manager)."
                setPadding(0, dp(8), 0, dp(8))
            }
            container.addView(hint, container.childCount - 1)
            return
        }

        // Dynamic actions from Flutter-managed preferences
        for (cfg in configs) {
            addActionButton(cfg.label.ifEmpty { cfg.id }) {
                processViaFlutter(cfg, selectedText, isReadOnly)
            }
        }
    }

    private fun processViaFlutter(cfg: ContextMenuConfig, selectedText: String, isReadOnly: Boolean) {
        setLoading(true, "Processing: ${cfg.label}")
        FlutterProcessor.processText(
            context = this,
            text = selectedText,
            operation = cfg.operation
        ) { result, error ->
            if (error != null) {
                setLoading(false, "Error: ${error.message ?: "Unknown error"}")
                Toast.makeText(this, "Processing failed", Toast.LENGTH_SHORT).show()
                // Show result screen to allow Copy or Reprocess (applies to original text)
                showResultScreen("ERROR: ${error.message ?: "Processing failed"}")
                return@processText
            }
            val output = (result ?: "").ifEmpty { selectedText }
            setLoading(false)
            handleResult(output, isReadOnly)
        }
    }

    private fun handleResult(result: String, readOnly: Boolean) {
        // Show an interstitial result screen with actions:
        // - Apply (editable only): return replacement and finish
        // - Copy: copy and finish
        // - Reprocess: go back to operations and run again on ORIGINAL text (no chaining)
        // - Close: finish
        showResultScreen(result)
    }

    private fun copyAndFinish(text: String) {
        val cm = getSystemService(Context.CLIPBOARD_SERVICE) as ClipboardManager
        cm.setPrimaryClip(ClipData.newPlainText("Processed Text", text))
        Toast.makeText(this, "Copied to clipboard", Toast.LENGTH_SHORT).show()
        setResult(RESULT_CANCELED)
        finish()
    }

    private fun showResultScreen(result: String) {
        // Build a simple result UI dynamically
        val root = ScrollView(this)
        container = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            setPadding(dp(16), dp(16), dp(16), dp(16))
            layoutParams = ViewGroup.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT,
                ViewGroup.LayoutParams.WRAP_CONTENT
            )
        }
        root.addView(container)

        val title = TextView(this).apply {
            text = "Processed Result"
            textSize = 20f
        }
        val resultView = TextView(this).apply {
            text = result
            setPadding(0, dp(8), 0, dp(16))
            // Allow users to select result text
            setTextIsSelectable(true)
        }

        container.addView(title)
        container.addView(resultView)

        // Buttons
        if (!readOnly) {
            val applyBtn = Button(this).apply {
                text = "Apply"
                isAllCaps = false
                setOnClickListener {
                    // Return replacement text to the calling app
                    setResult(
                        RESULT_OK,
                        Intent().putExtra(Intent.EXTRA_PROCESS_TEXT, result)
                    )
                    finish()
                }
            }
            container.addView(applyBtn)
        }

        val copyBtn = Button(this).apply {
            text = "Copy"
            isAllCaps = false
            setOnClickListener {
                val cm = getSystemService(Context.CLIPBOARD_SERVICE) as ClipboardManager
                cm.setPrimaryClip(ClipData.newPlainText("Processed Text", result))
                Toast.makeText(this@ProcessTextActivity, "Copied to clipboard", Toast.LENGTH_SHORT).show()
                // Finish and return to source app
                setResult(RESULT_CANCELED)
                finish()
            }
        }
        container.addView(copyBtn)

        val reprocessBtn = Button(this).apply {
            text = "Reprocess"
            isAllCaps = false
            setOnClickListener {
                reopenActionMenu()
            }
        }
        container.addView(reprocessBtn)

        val closeBtn = Button(this).apply {
            text = "Close"
            isAllCaps = false
            setOnClickListener {
                setResult(RESULT_CANCELED)
                finish()
            }
        }
        container.addView(closeBtn)

        setContentView(root)
    }

    private fun reopenActionMenu() {
        // Rebuild initial screen and repopulate actions using ORIGINAL text (no chaining)
        setContentView(buildUi(originalText, readOnly))
        populateActions(originalText, readOnly)
    }
}