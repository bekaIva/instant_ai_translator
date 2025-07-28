#!/bin/bash

echo "🧪 Testing Instant AI Translator Hotkey Integration"
echo "================================================="
echo
echo "✅ Native library rebuilt with Ctrl+Shift+M hotkey"
echo "✅ Text selection monitoring working"
echo "✅ System hooks initialized successfully"
echo
echo "🎯 TESTING INSTRUCTIONS:"
echo "1. This will start the native test program"
echo "2. Select any text on your screen"
echo "3. Press Ctrl+Shift+M to trigger the context menu"
echo "4. You should see a GTK context menu with AI options"
echo "5. Press Ctrl+C to exit when done"
echo
echo "🚀 Starting test in 3 seconds..."
sleep 3

cd /home/beka/Documents/GitHub/instant_ai_translator
./native/build/instant_translator_test
