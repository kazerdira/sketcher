@echo off
REM Sketcher Native Library Build Script for Windows
REM Builds h        cmake "%NATIVE_DIR%" ^
            -DCMAKE_BUILD_TYPE=Release ^
            -DCMAKE_TOOLCHAIN_FILE=%ANDROID_NDK_HOME%\build\cmake\android.toolchain.cmake ^
            -DANDROID_ABI=arm64-v8a ^
            -DANDROID_PLATFORM=android-21 ^
            -DANDROID_NDK=%ANDROID_NDK_HOME% ^
            -G "Unix Makefiles"formance C++ calligraphy library

setlocal enabledelayedexpansion

echo 🚀 Building Sketcher Native Library for Windows

REM Configuration
set PROJECT_ROOT=%~dp0
set NATIVE_DIR=%PROJECT_ROOT%native
set BUILD_DIR=%NATIVE_DIR%\build
set OUTPUT_DIR=%PROJECT_ROOT%lib\native\libs

REM Create directories
if not exist "%BUILD_DIR%" mkdir "%BUILD_DIR%"
if not exist "%OUTPUT_DIR%" mkdir "%OUTPUT_DIR%"

REM Check for Visual Studio
where cmake >nul 2>nul
if %errorlevel% neq 0 (
    echo ❌ CMake not found! Please install CMake and add it to PATH
    exit /b 1
)

echo 📦 Building for Windows x64...

REM Create build directory
set PLATFORM_BUILD_DIR=%BUILD_DIR%\windows-x64
if not exist "%PLATFORM_BUILD_DIR%" mkdir "%PLATFORM_BUILD_DIR%"
cd /d "%PLATFORM_BUILD_DIR%"

REM Configure with CMake
cmake "%NATIVE_DIR%" ^
    -DCMAKE_BUILD_TYPE=Release ^
    -DCMAKE_POSITION_INDEPENDENT_CODE=ON ^
    -G "Visual Studio 17 2022" ^
    -A x64

if %errorlevel% neq 0 (
    echo ❌ CMake configuration failed!
    exit /b 1
)

REM Build
cmake --build . --config Release --parallel

if %errorlevel% neq 0 (
    echo ❌ Build failed!
    exit /b 1
)

REM Copy DLL to output
copy "%PLATFORM_BUILD_DIR%\Release\sketcher_native.dll" "%OUTPUT_DIR%\"

if %errorlevel% neq 0 (
    echo ❌ Failed to copy DLL!
    exit /b 1
)

echo ✅ Windows x64 build completed

REM Build for Android if Flutter is available
where flutter >nul 2>nul
if %errorlevel% equ 0 (
    echo 🤖 Building for Android...
    
    REM Use the latest Android NDK
    set ANDROID_SDK_ROOT=C:\Users\boure_rr1habg\AppData\Local\Android\sdk
    set ANDROID_NDK_HOME=%ANDROID_SDK_ROOT%\ndk\27.0.12077973
    
    if exist "%ANDROID_NDK_HOME%" (
        REM Build for Android ARM64
        set ANDROID_BUILD_DIR=%BUILD_DIR%\android-arm64
        if not exist "!ANDROID_BUILD_DIR!" mkdir "!ANDROID_BUILD_DIR!"
        cd /d "!ANDROID_BUILD_DIR!"
        
        cmake "%NATIVE_DIR%" ^
            -DCMAKE_BUILD_TYPE=Release ^
            -DCMAKE_TOOLCHAIN_FILE=%ANDROID_NDK_HOME%\build\cmake\android.toolchain.cmake ^
            -DANDROID_ABI=arm64-v8a ^
            -DANDROID_PLATFORM=android-21 ^
            -DANDROID_NDK=%ANDROID_NDK_HOME% ^
            -G "Ninja"
        
        if !errorlevel! equ 0 (
            cmake --build . --config Release
            
            if !errorlevel! equ 0 (
                set ANDROID_OUTPUT=%OUTPUT_DIR%\android\arm64-v8a
                if not exist "!ANDROID_OUTPUT!" mkdir "!ANDROID_OUTPUT!"
                copy "!ANDROID_BUILD_DIR!\libsketcher_native.so" "!ANDROID_OUTPUT!\"
                echo ✅ Android ARM64 build completed
            ) else (
                echo ⚠️  Android build failed
            )
        ) else (
            echo ⚠️  Android CMake configuration failed
        )
    ) else (
        echo ⚠️  Android NDK not found at %ANDROID_NDK_HOME%, skipping Android build
    )
) else (
    echo ⚠️  Flutter not found, skipping Android build
)

echo 🎉 All builds completed successfully!
echo 📁 Native libraries available in: %OUTPUT_DIR%

REM List built libraries
echo 📋 Built libraries:
for %%f in ("%OUTPUT_DIR%\*.dll") do echo   ✓ %%~nxf
for /r "%OUTPUT_DIR%" %%f in (*.so) do echo   ✓ %%~nxf

cd /d "%PROJECT_ROOT%"
pause