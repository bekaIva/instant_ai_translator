# Android Native Integration Plan for Instant AI Translator

This document explains the Android-native implementation that complements the existing Linux-native path. It uses Android’s official Process Text API to appear in the OS selection toolbar, process the selected text with Gemini, and return replacement text when allowed.

Scope
- Target platform: Android 6.0+ (API 23+) where Process Text is available.
- No private APIs, no AccessibilityService, no overlays. Only INTERNET permission.
- Flutter remains the management console (configure actions, API keys, model, view activity log).

High-level UX on Android
1) User selects text in any compatible app.
2) In the selection toolbar overflow, user taps “Instant AI Translator”.
3) Our ProcessTextActivity opens, showing enabled actions (Translate, Improve, etc.).
4) User picks an action → we call Gemini → if editable, Android replaces the original selection with the result; if read-only, we show the result with Copy/Share.

Why this is allowed by Android
- Uses the official ACTION_PROCESS_TEXT interface. It is designed for cross-app text processing.
- Explicitly user-initiated; no background interception.
- Minimal permissions. Only INTERNET is required for the network call.
- Play policy compliant: no accessibility abuse, no overlays, no hidden hooks.

Mapping from Linux-native to Android-native
- Global menu registration → Not applicable. Android shows one entry; our activity lists the actions.
- Get current selection → Provided via Intent.EXTRA_PROCESS_TEXT.
- Replace selection → Return the processed text via setResult + Intent.EXTRA_PROCESS_TEXT.
- Hotkey / popup → Not supported; use the selection toolbar entry.
- D-Bus / files → Not needed; the OS hands us the text and we return the result.

Data contract across Flutter and Android
- Storage file: “FlutterSharedPreferences” (the default file used by Flutter’s shared_preferences plugin).
- Keys (prefixed with “flutter.” in Android):
  - flutter.context_menu_configs → JSON array of menu configs written by Flutter.
  - flutter.ai_settings → JSON object with AI provider, apiKey, baseUrl, model, enabled.
- We read both keys from Android to render actions and to call Gemini with the user’s configuration.

JSON shapes (for reference)
- context_menu_configs: List<ContextMenuConfig>
  {
    "id": "translate",
    "label": "🌐 Translate to English",
    "operation": "...system instruction text...",
    "description": "Translate text to another language",
    "enabled": true,
    "icon": "🌐",
    "sortOrder": 1
  }
- ai_settings: AISettings
  {
    "provider": "google",
    "apiKey": "YOUR_API_KEY",
    "baseUrl": "https://generativelanguage.googleapis.com/v1beta",
    "model": "models/gemini-1.5-flash",
    "enabled": true
  }

Android components (new files)
- android/app/src/main/kotlin/com/example/instant_ai_translator/ProcessTextActivity.kt
- android/app/src/main/kotlin/com/example/instant_ai_translator/GeminiClient.kt
- android/app/src/main/kotlin/com/example/instant_ai_translator/ConfigReader.kt
- android/app/src/main/kotlin/com/example/instant_ai_translator/HistoryLogger.kt

Manifest and Gradle changes
- AndroidManifest.xml
  - Add INTERNET permission at manifest root:
    <uses-permission android:name="android.permission.INTERNET" />
  - Declare ProcessTextActivity:
    <activity
        android:name=".ProcessTextActivity"
        android:exported="true"
        android:label="Instant AI Translator">
      <intent-filter>
        <action android:name="android.intent.action.PROCESS_TEXT" />
        <category android:name="android.intent.category.DEFAULT" />
        <data android:mimeType="text/plain" />
      </intent-filter>
    </activity>
- app/build.gradle(.kts)
  - Add dependencies (example):
    implementation("com.squareup.okhttp3:okhttp:4.12.0")
    implementation("org.jetbrains.kotlinx:kotlinx-serialization-json:1.7.3")

Kotlin data classes and readers
- ConfigReader.kt
  - Reads FlutterSharedPreferences:
    val prefs = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
    val configsJson = prefs.getString("flutter.context_menu_configs", null)
    val settingsJson = prefs.getString("flutter.ai_settings", null)
  - Data classes:
    data class ContextMenuConfig(
      val id: String, val label: String, val operation: String,
      val description: String, val enabled: Boolean, val icon: String, val sortOrder: Int
    )
    data class AISettings(
      val provider: String, val apiKey: String, val baseUrl: String, val model: String, val enabled: Boolean = true
    )
  - Methods:
    fun getEnabledConfigs(context: Context): List<ContextMenuConfig>
    fun getAISettings(context: Context): AISettings?

GeminiClient.kt
- Responsibility: Mirror the logic of Dart’s Gemini client.
- API:
  suspend fun generateContent(
    apiKey: String,
    baseUrl: String = "https://generativelanguage.googleapis.com/v1beta",
    model: String,
    systemInstruction: String,
    userText: String
  ): String
- Behavior:
  - Ensure model has “models/” prefix (same as Dart’s getFullModelName).
  - POST to: {baseUrl}/{model}:generateContent?key={apiKey}
  - Body:
    {
      "contents":[{"parts":[{"text":"{systemInstruction}\n\nUser input: {userText}\n\nResponse:"}]}],
      "generationConfig":{"temperature":0.2,"topK":40,"topP":0.8,"maxOutputTokens":2048,"stopSequences":[]},
      "safetySettings":[
        {"category":"HARM_CATEGORY_HARASSMENT","threshold":"BLOCK_MEDIUM_AND_ABOVE"},
        {"category":"HARM_CATEGORY_HATE_SPEECH","threshold":"BLOCK_MEDIUM_AND_ABOVE"},
        {"category":"HARM_CATEGORY_SEXUALLY_EXPLICIT","threshold":"BLOCK_MEDIUM_AND_ABOVE"},
        {"category":"HARM_CATEGORY_DANGEROUS_CONTENT","threshold":"BLOCK_MEDIUM_AND_ABOVE"}
      ]
    }
  - Parse response candidates[0].content.parts[0].text; trim; throw on error codes.

ProcessTextActivity.kt (UI and flow)
- Intent inputs:
  - Intent.EXTRA_PROCESS_TEXT (String) → the selected text.
  - Intent.EXTRA_PROCESS_TEXT_READONLY (Boolean) → whether replacement is allowed.
- UI:
  - Title: first 1–2 lines of selected text (truncated).
  - List of enabled actions (sorted by sortOrder).
  - Progress indicator during network call; cancel option.
- Flow:
  1) Load enabled configs and AI settings. If invalid/missing (e.g., no API key), show error UI with “Open App” button (launch MainActivity) and exit RESULT_CANCELED.
  2) When an action is tapped, call GeminiClient with operation as systemInstruction and selected text as userText.
  3) On success:
     - If readOnly=false: setResult(RESULT_OK, Intent().putExtra(Intent.EXTRA_PROCESS_TEXT, result)) and finish().
     - If readOnly=true: show result page with Copy/Share; allow closing with RESULT_CANCELED.
  4) Log the action via HistoryLogger (success flag, timestamps, error if any).

HistoryLogger.kt (shared log for Flutter Activity Monitor)
- Pref key suggestion: flutter.activity_log (JSON array, newest first, bounded to N=100).
- Record shape:
  {
    "menuId": "translate",
    "originalText": "…",
    "processedText": "…",
    "timestamp": "2025-01-01T12:34:56.789Z",
    "success": true,
    "error": null
  }
- Append algorithm:
  - Read existing array; insert at head; trim to N; write back.

Flutter codebase adjustments (to avoid Android crashes)
- Guard FFI loader in lib/native/system_integration_safe.dart:
  - The top-level DynamicLibrary.open currently throws on non-Linux. Convert to lazy init or split per-platform:
    Option A (lazy): move DynamicLibrary.open into initialize(), protect with if (Platform.isLinux) else no-op.
    Option B (split): create system_integration_linux.dart (current FFI) and system_integration_stub.dart (no-op), and import the right one behind a simple facade to avoid evaluation on Android.
- Make ProductionContextMenuService Android-aware:
  - In initialize(): if Platform.isAndroid, skip _systemIntegration.initialize(), menu registration, and polling. Set status “Ready (Android Process Text mode)”.
  - Ensure code never calls _systemIntegration.replaceSelection() on Android paths.

Security and privacy
- The OS hands your app the selected text only after explicit user action.
- We transmit that text to Gemini over HTTPS per user configuration.
- No background capture, no global hooks, no overlays.

Error handling
- Missing API settings: error UI with “Open App” (MainActivity) and an option to Copy error to clipboard.
- Network errors / timeouts: show message and allow retry; backoff on repeated failures.
- Read-only selections: present result with Copy/Share; also allow “Share to…” system sheet.

Compatibility notes
- Many editors and IM apps support ACTION_PROCESS_TEXT; some custom editors may not.
- Some sources mark selection read-only (e.g., webviews or protected fields); replacement will be disabled but viewing/copying the result still works.

Performance considerations
- Run everything in a small, native activity (no Flutter engine start) for low startup latency.
- Keep dependencies minimal (OkHttp + kotlinx-serialization or org.json).
- Show immediate progress feedback and allow cancel.

Testing strategy
- Unit tests (JVM):
  - GeminiClient: request body composition, URL formation, response parsing, error codes.
- Instrumentation tests:
  - A test activity with an EditText; invoke ACTION_PROCESS_TEXT and assert replacement text on editable vs read-only.
- Manual tests:
  - Validate in popular apps (Chrome, Gmail, Docs, WhatsApp, Keep, etc.).
- Interop tests:
  - Write configs in Flutter; read in Android. Append log in Android; confirm Flutter Activity Monitor renders entries.

Milestones (execution order)
- M1: Flutter refactor to guard FFI on Android; adjust ProductionContextMenuService Android path.
- M2: Manifest permission + ProcessTextActivity declaration; stub the activity showing enabled actions from prefs.
- M3: Implement GeminiClient; wire processing and return replacement text.
- M4: Implement read-only result UI and HistoryLogger (bounded list).
- M5: Polish (quick-run default action when only one action is enabled, better errors, spinner/cancel).
- M6: Documentation and troubleshooting guide.

Future enhancements (optional)
- Quick settings tile to open the app or last action configuration.
- Analytics counters (local-only) for action usage; opt-in.
- Caching short responses to reduce latency on repeated prompts.

Implementation checklist (condensed)
- [ ] Add INTERNET permission and ProcessTextActivity to AndroidManifest.xml.
- [ ] Add OkHttp + JSON dependency in app Gradle.
- [ ] Implement ConfigReader (prefs interop), GeminiClient (API), HistoryLogger (log).
- [ ] Implement ProcessTextActivity UI and flow.
- [ ] Refactor Flutter FFI loader and ProductionContextMenuService for Android paths.
- [ ] Test across editable/read-only sources and verify Flutter Activity Monitor integration.

References to existing code (for alignment)
- Dart Gemini logic to mirror: lib/services/gemini_ai_service.dart
- AI settings model and helpers (model name rule): lib/services/ai_settings_service.dart
- Context menu configs format: lib/services/context_menu_config_service.dart
- Production action record fields (shape parity): lib/services/production_context_menu_service.dart

Conclusion
This design uses Android’s official Process Text API, keeps Flutter as the single source of truth for configurations and keys, runs processing natively for speed and reliability, and remains compliant with platform and Play policies. It aligns behavior with the existing Linux implementation wherever feasible and provides a clear, testable path to ship Android support incrementally.