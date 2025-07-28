#!/bin/bash
# Instant AI Translator Release Launcher
# Starts the application in release mode with proper native library paths

echo "🚀 Starting Instant AI Translator (Release Mode)"
echo "================================================="

# Set working directory to project root
cd "$(dirname "$0")"

# Add native library to library search path
export LD_LIBRARY_PATH="./lib/native/libs:$LD_LIBRARY_PATH"

# Run the application
./build/linux/x64/release/bundle/instant_ai_translator

echo ""
echo "✨ Instant AI Translator has been stopped."
