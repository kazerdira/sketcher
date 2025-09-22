#!/bin/bash

# Sketcher Native Library Build Script
# Builds high-performance C++ calligraphy library for all platforms

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🚀 Building Sketcher Native Library${NC}"

# Configuration
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
NATIVE_DIR="$PROJECT_ROOT/native"
BUILD_DIR="$NATIVE_DIR/build"
OUTPUT_DIR="$PROJECT_ROOT/lib/native/libs"

# Create directories
mkdir -p "$BUILD_DIR"
mkdir -p "$OUTPUT_DIR"

# Function to build for a specific platform
build_platform() {
    local platform=$1
    local generator=${2:-"Unix Makefiles"}
    local additional_args=$3
    
    echo -e "${YELLOW}📦 Building for $platform...${NC}"
    
    local platform_build_dir="$BUILD_DIR/$platform"
    mkdir -p "$platform_build_dir"
    cd "$platform_build_dir"
    
    # Configure with CMake
    cmake "$NATIVE_DIR" \
        -DCMAKE_BUILD_TYPE=Release \
        -DCMAKE_POSITION_INDEPENDENT_CODE=ON \
        -G "$generator" \
        $additional_args
    
    # Build
    cmake --build . --config Release --parallel
    
    echo -e "${GREEN}✅ $platform build completed${NC}"
}

# Detect platform and build accordingly
if [[ "$OSTYPE" == "msys" || "$OSTYPE" == "win32" ]]; then
    # Windows
    echo -e "${BLUE}🪟 Detected Windows platform${NC}"
    
    # Build for Windows x64
    build_platform "windows-x64" "Visual Studio 17 2022" "-A x64"
    
    # Copy DLL to output
    cp "$BUILD_DIR/windows-x64/Release/sketcher_native.dll" "$OUTPUT_DIR/"
    
elif [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS
    echo -e "${BLUE}🍎 Detected macOS platform${NC}"
    
    # Build for macOS
    build_platform "macos" "Unix Makefiles" "-DCMAKE_OSX_ARCHITECTURES=x86_64;arm64"
    
    # Copy dylib to output
    cp "$BUILD_DIR/macos/libsketcher_native.dylib" "$OUTPUT_DIR/"
    
elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
    # Linux
    echo -e "${BLUE}🐧 Detected Linux platform${NC}"
    
    # Build for Linux
    build_platform "linux" "Unix Makefiles"
    
    # Copy so to output
    cp "$BUILD_DIR/linux/libsketcher_native.so" "$OUTPUT_DIR/"
    
else
    echo -e "${RED}❌ Unsupported platform: $OSTYPE${NC}"
    exit 1
fi

# Build for Android (if Android SDK is available)
if command -v flutter &> /dev/null; then
    echo -e "${YELLOW}🤖 Building for Android...${NC}"
    
    # Get Android NDK path from Flutter
    ANDROID_NDK_HOME=$(flutter config android-ndk 2>/dev/null | grep "android-ndk" | cut -d':' -f2 | tr -d ' ')
    
    if [[ -n "$ANDROID_NDK_HOME" && -d "$ANDROID_NDK_HOME" ]]; then
        # Build for Android ARM64
        build_platform "android-arm64" "Ninja" \
            "-DCMAKE_TOOLCHAIN_FILE=$ANDROID_NDK_HOME/build/cmake/android.toolchain.cmake \
             -DANDROID_ABI=arm64-v8a \
             -DANDROID_PLATFORM=android-21 \
             -DANDROID_NDK=$ANDROID_NDK_HOME"
        
        # Create Android output directory
        ANDROID_OUTPUT="$OUTPUT_DIR/android/arm64-v8a"
        mkdir -p "$ANDROID_OUTPUT"
        cp "$BUILD_DIR/android-arm64/libsketcher_native.so" "$ANDROID_OUTPUT/"
        
        echo -e "${GREEN}✅ Android ARM64 build completed${NC}"
    else
        echo -e "${YELLOW}⚠️  Android NDK not found, skipping Android build${NC}"
    fi
fi

echo -e "${GREEN}🎉 All builds completed successfully!${NC}"
echo -e "${BLUE}📁 Native libraries available in: $OUTPUT_DIR${NC}"

# List built libraries
echo -e "${YELLOW}📋 Built libraries:${NC}"
find "$OUTPUT_DIR" -name "*.dll" -o -name "*.so" -o -name "*.dylib" | while read lib; do
    echo -e "  ${GREEN}✓${NC} $(basename "$lib")"
done