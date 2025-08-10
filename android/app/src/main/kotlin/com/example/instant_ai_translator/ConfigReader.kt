package com.example.instant_ai_translator

import android.content.Context
import org.json.JSONArray
import org.json.JSONObject

/**
 * Reads Flutter-managed SharedPreferences to fetch dynamic context menu configs
 * defined in the Flutter app.
 *
 * SharedPreferences file: "FlutterSharedPreferences"
 * Keys are prefixed with "flutter." by the plugin. We read:
 *  - "flutter.context_menu_configs" (JSON array)
 *
 * JSON schema follows lib/services/context_menu_config_service.dart:
 * {
 *   "id": String,
 *   "label": String,
 *   "operation": String,
 *   "description": String,
 *   "enabled": Boolean,
 *   "icon": String,
 *   "sortOrder": Int
 * }
 */
object ConfigReader {

    data class ContextMenuConfig(
        val id: String,
        val label: String,
        val operation: String,
        val description: String,
        val enabled: Boolean,
        val icon: String,
        val sortOrder: Int
    )

    private const val PREFS_NAME = "FlutterSharedPreferences"
    private const val KEY_CONTEXT_MENU_CONFIGS = "flutter.context_menu_configs"

    /**
     * Returns enabled configs sorted by sortOrder ascending.
     */
    fun getEnabledConfigs(context: Context): List<ContextMenuConfig> {
        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        val json = prefs.getString(KEY_CONTEXT_MENU_CONFIGS, null) ?: return emptyList()

        return try {
            val arr = JSONArray(json)
            val list = mutableListOf<ContextMenuConfig>()
            for (i in 0 until arr.length()) {
                val o = arr.optJSONObject(i) ?: continue
                val enabled = o.optBoolean("enabled", false)
                if (!enabled) continue

                list += ContextMenuConfig(
                    id = o.optString("id", ""),
                    label = o.optString("label", ""),
                    operation = o.optString("operation", ""),
                    description = o.optString("description", ""),
                    enabled = enabled,
                    icon = o.optString("icon", "🔧"),
                    sortOrder = o.optInt("sortOrder", 0)
                )
            }
            list.sortBy { it.sortOrder }
            list
        } catch (e: Exception) {
            emptyList()
        }
    }

    /**
     * Utility to create a compact preview of long text.
     */
    fun previewOf(text: String, maxChars: Int = 140): String {
        val firstLine = text.lineSequence().firstOrNull().orEmpty()
        val head = if (firstLine.length > maxChars) firstLine.substring(0, maxChars) + "…" else firstLine
        val more = if (text.contains('\n')) "\n…" else ""
        return "Selected:\n$head$more"
    }

    /**
     * Helper to encode a simple Android->Flutter request arguments payload.
     */
    fun buildProcessArgs(text: String, operation: String): JSONObject {
        val obj = JSONObject()
        obj.put("text", text)
        obj.put("operation", operation)
        return obj
    }
}