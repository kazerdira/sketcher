cmake_minimum_required(VERSION 3.15)

project(sketcher_native LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Define the library
add_library(sketcher_native SHARED
    src/calligraphy_native.cpp
)

# Include directories
target_include_directories(sketcher_native PRIVATE
    include
)

# Compiler-specific optimizations
if(MSVC)
    target_compile_options(sketcher_native PRIVATE /O2 /arch:AVX2)
else()
    target_compile_options(sketcher_native PRIVATE -O3 -march=native -ffast-math)
endif()

# Platform-specific configurations
if(WIN32)
    set_target_properties(sketcher_native PROPERTIES
        OUTPUT_NAME "sketcher_native"
        SUFFIX ".dll"
    )
elseif(APPLE)
    set_target_properties(sketcher_native PROPERTIES
        OUTPUT_NAME "sketcher_native"
        SUFFIX ".dylib"
    )
else()
    set_target_properties(sketcher_native PROPERTIES
        OUTPUT_NAME "sketcher_native"
        SUFFIX ".so"
    )
endif()

# Android-specific configuration
if(ANDROID)
    set_target_properties(sketcher_native PROPERTIES
        LIBRARY_OUTPUT_DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}/../android/app/src/main/jniLibs/${ANDROID_ABI}"
    )
endif()

# iOS-specific configuration  
if(IOS)
    set_target_properties(sketcher_native PROPERTIES
        FRAMEWORK TRUE
        MACOSX_FRAMEWORK_IDENTIFIER "com.sketcher.native"
    )
endif()