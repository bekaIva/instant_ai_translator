#!/bin/bash

# Build script for Instant AI Translator native library
# Phase 4: Linux Context Menu Implementation

set -e

echo "🏗️  Building Instant AI Translator Native Library"
echo "================================================="

# Check dependencies
echo "📋 Checking system dependencies..."

# Check for required packages
REQUIRED_PACKAGES=(
    "build-essential"
    "cmake"
    "libgtk-3-dev"
    "libx11-dev"
    "libxtst-dev"
    "libdbus-1-dev"
    "libglib2.0-dev"
    "xclip"
    "xdotool"
)

MISSING_PACKAGES=()

for package in "${REQUIRED_PACKAGES[@]}"; do
    if ! dpkg -l | grep -q "^ii  $package "; then
        MISSING_PACKAGES+=("$package")
    fi
done

if [ ${#MISSING_PACKAGES[@]} -ne 0 ]; then
    echo "❌ Missing required packages: ${MISSING_PACKAGES[*]}"
    echo "📦 Installing missing packages..."
    sudo apt update
    sudo apt install -y "${MISSING_PACKAGES[@]}"
fi

echo "✅ All dependencies satisfied"

# Create build directory
BUILD_DIR="native/build"
echo "📁 Creating build directory: $BUILD_DIR"
mkdir -p "$BUILD_DIR"

cd "$BUILD_DIR"

# Configure with CMake
echo "⚙️  Configuring with CMake..."
cmake .. -DCMAKE_BUILD_TYPE=Release

# Build the library
echo "🔨 Building native library..."
make -j$(nproc)

# Check if library was built successfully
if [ -f "libinstant_translator_native.so.1.0" ]; then
    echo "✅ Library built successfully: libinstant_translator_native.so.1.0"
    
    # Copy to lib directory for Flutter
    echo "📋 Copying library to Flutter lib directory..."
    mkdir -p "../../lib/native/libs"
    
    # Copy the main library file
    cp "libinstant_translator_native.so.1.0" "../../lib/native/libs/"
    
    # Store current directory
    BUILD_DIR=$(pwd)
    
    # Create symlinks for version management
    cd "../../lib/native/libs"
    ln -sf "libinstant_translator_native.so.1.0" "libinstant_translator_native.so.1"
    ln -sf "libinstant_translator_native.so.1.0" "libinstant_translator_native.so"
    
    # Return to build directory
    cd "$BUILD_DIR"
    
    echo "🎯 Testing library..."
    if [ -f "instant_translator_test" ]; then
        echo "📋 Test executable built: instant_translator_test"
        echo "💡 You can run it with: ./native/build/instant_translator_test"
    fi
    
    echo ""
    echo "🎉 Build completed successfully!"
    echo "📍 Library location: lib/native/libs/libinstant_translator_native.so"
    echo "🧪 Test executable: native/build/instant_translator_test"
    echo ""
    echo "🚀 Next steps:"
    echo "   1. Test the native library: ./native/build/instant_translator_test"
    echo "   2. Run Flutter app to test integration"
    echo "   3. Select text and press Ctrl+Shift+M to trigger context menu"
    
else
    echo "❌ Build failed - library not found"
    exit 1
fi
