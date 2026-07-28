#!/usr/bin/env bash
# GuitarBridge Build Script (macOS/Linux)
# Usage: ./tool/build.sh [android|ios|windows|macos|web|all] [--release]

set -euo pipefail
cd "$(dirname "$0")/.."

PLATFORM="${1:-macos}"
MODE="debug"
[[ "${2:-}" == "--release" ]] && MODE="release"

echo -e "\033[36m=== GuitarBridge Build ===\033[0m"
echo -e "\033[33mPlatform: $PLATFORM | Mode: $MODE\033[0m"

flutter pub get
flutter analyze

build_platform() {
    echo -e "\n\033[32m--- Building $1 ($MODE) ---\033[0m"
    if [[ "$1" == "ios" ]]; then
        flutter build ios --"$MODE" --no-codesign
    else
        flutter build "$1" --"$MODE"
    fi
}

if [[ "$PLATFORM" == "all" ]]; then
    case "$(uname -s)" in
        Darwin) platforms=(android ios macos web) ;;
        Linux) platforms=(android linux web) ;;
        *)
            echo "Unsupported host for all-platform build: $(uname -s)" >&2
            exit 2
            ;;
    esac
    for p in "${platforms[@]}"; do
        build_platform "$p"
    done
else
    build_platform "$PLATFORM"
fi

echo -e "\n\033[36m=== Build Complete ===\033[0m"
echo -e "\033[33mArtifacts:\033[0m"
[[ "$PLATFORM" =~ "android" ]] && echo "  Android: build/app/outputs/flutter-apk/*.apk"
[[ "$PLATFORM" =~ "macos" ]]   && echo "  macOS:   build/macos/Build/Products/Release/"
[[ "$PLATFORM" =~ "windows" ]] && echo "  Windows: build/windows/x64/runner/Release/"
[[ "$PLATFORM" =~ "linux" ]]   && echo "  Linux:   build/linux/x64/release/bundle/"
[[ "$PLATFORM" =~ "web" ]]     && echo "  Web:     build/web/"
