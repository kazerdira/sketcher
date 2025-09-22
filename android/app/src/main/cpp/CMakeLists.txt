cmake_minimum_required(VERSION 3.15)

project(sketcher_native)

# Set C++ standard
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Source files
set(SOURCES
    src/calligraphy_native.cpp
)

# Header files
set(HEADERS
    include/sketcher_native.h
)

# Create shared library
add_library(${PROJECT_NAME} SHARED ${SOURCES} ${HEADERS})

# Set include directories
target_include_directories(${PROJECT_NAME} PRIVATE include)

# Platform-specific configurations
if(WIN32)
    # Windows specific settings
    set_target_properties(${PROJECT_NAME} PROPERTIES
        OUTPUT_NAME "sketcher_native"
        RUNTIME_OUTPUT_DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}/../lib/native/libs"
        RUNTIME_OUTPUT_DIRECTORY_RELEASE "${CMAKE_CURRENT_SOURCE_DIR}/../lib/native/libs"
    )
    
    # Compiler optimizations for Windows
    if(MSVC)
        target_compile_options(${PROJECT_NAME} PRIVATE /O2 /Ob2 /Ot /arch:AVX2)
        target_compile_definitions(${PROJECT_NAME} PRIVATE WIN32_LEAN_AND_MEAN)
    endif()
    
elseif(ANDROID)
    # Android specific settings
    set_target_properties(${PROJECT_NAME} PROPERTIES
        OUTPUT_NAME "sketcher_native"
    )
    # Let Gradle package the .so; enable optimizations
    target_compile_options(${PROJECT_NAME} PRIVATE -O3 -ffast-math)
    
else()
    # Default settings for other platforms
    set_target_properties(${PROJECT_NAME} PROPERTIES
        OUTPUT_NAME "sketcher_native"
        LIBRARY_OUTPUT_DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}/../lib/native/libs"
    )
    
    # Compiler optimizations
    if(CMAKE_CXX_COMPILER_ID STREQUAL "GNU" OR CMAKE_CXX_COMPILER_ID STREQUAL "Clang")
        target_compile_options(${PROJECT_NAME} PRIVATE -O3 -ffast-math -march=native)
    endif()
endif()

# Export symbols for FFI
set_target_properties(${PROJECT_NAME} PROPERTIES
    CXX_VISIBILITY_PRESET hidden
    VISIBILITY_INLINES_HIDDEN YES
)

# Link libraries
if(ANDROID)
    target_link_libraries(${PROJECT_NAME} log)
endif()

# Compiler-specific flags
if(CMAKE_CXX_COMPILER_ID STREQUAL "GNU" OR CMAKE_CXX_COMPILER_ID STREQUAL "Clang")
    target_compile_options(${PROJECT_NAME} PRIVATE -fPIC -Wall -Wextra)
elseif(MSVC)
    target_compile_options(${PROJECT_NAME} PRIVATE /W4)
endif()