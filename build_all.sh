#!/bin/bash
set -euo pipefail

# Project root & output directory
ROOT_DIR=$(cd "$(dirname "$0")" && pwd)
OUT_DIR=${OUT_DIR:-"$ROOT_DIR/prebuilt"}

# Set custom linkers for cross-compilation (if needed)
# brew tap messense/macos-cross-toolchains
# # install x86_64-unknown-linux-gnu toolchain
# brew install x86_64-unknown-linux-gnu
# # install aarch64-unknown-linux-gnu toolchain
# brew install aarch64-unknown-linux-gnu
export PATH=$(brew --prefix aarch64-unknown-linux-gnu)/bin:$PATH
export CARGO_TARGET_X86_64_UNKNOWN_LINUX_GNU_LINKER=x86_64-linux-gnu-gcc
export CARGO_TARGET_AARCH64_UNKNOWN_LINUX_GNU_LINKER=aarch64-linux-gnu-gcc

mkdir -p "$OUT_DIR"

info() { echo -e "\033[1;34m[INFO]\033[0m $*"; }
warn() { echo -e "\033[1;33m[WARN]\033[0m $*"; }
err()  { echo -e "\033[1;31m[ERR ]\033[0m $*"; }

strip_lib() {
    local file="$1"
    local triple="$2"

    if [[ ! -f "$file" ]]; then
        return
    fi

    local strip_cmd=""
    local strip_args=""

    # Determine the appropriate strip command based on target triple
    case "$triple" in
        *-apple-darwin)
            # macOS: use native strip with -x (preserve external symbols)
            strip_cmd="strip"
            strip_args="-x"
            ;;
        x86_64-unknown-linux-gnu)
            # Linux x86_64
            if command -v x86_64-linux-gnu-strip >/dev/null 2>&1; then
                strip_cmd="x86_64-linux-gnu-strip"
            elif command -v strip >/dev/null 2>&1; then
                strip_cmd="strip"
            fi
            ;;
        aarch64-unknown-linux-gnu)
            # Linux ARM64
            if command -v aarch64-linux-gnu-strip >/dev/null 2>&1; then
                strip_cmd="aarch64-linux-gnu-strip"
            elif command -v strip >/dev/null 2>&1; then
                strip_cmd="strip"
            fi
            ;;
        armv7-linux-androideabi)
            # Android ARMv7
            if command -v arm-linux-androideabi-strip >/dev/null 2>&1; then
                strip_cmd="arm-linux-androideabi-strip"
            elif [[ -n "${ANDROID_NDK_HOME:-}" ]]; then
                strip_cmd="$ANDROID_NDK_HOME/toolchains/llvm/prebuilt/*/bin/llvm-strip"
            fi
            ;;
        aarch64-linux-android)
            # Android ARM64
            if command -v aarch64-linux-android-strip >/dev/null 2>&1; then
                strip_cmd="aarch64-linux-android-strip"
            elif [[ -n "${ANDROID_NDK_HOME:-}" ]]; then
                strip_cmd="$ANDROID_NDK_HOME/toolchains/llvm/prebuilt/*/bin/llvm-strip"
            fi
            ;;
        i686-linux-android|x86_64-linux-android)
            # Android x86/x86_64
            if [[ -n "${ANDROID_NDK_HOME:-}" ]]; then
                strip_cmd="$ANDROID_NDK_HOME/toolchains/llvm/prebuilt/*/bin/llvm-strip"
            fi
            ;;
        *)
            # Fallback to generic strip if available
            if command -v strip >/dev/null 2>&1; then
                strip_cmd="strip"
            fi
            ;;
    esac

    if [[ -n "$strip_cmd" ]]; then
        set +e
        $strip_cmd $strip_args "$file" 2>/dev/null
        if [[ $? -eq 0 ]]; then
            info "Stripped: $(basename "$file")"
        else
            warn "Failed to strip: $(basename "$file")"
        fi
        set -e
    else
        warn "No strip command available for $triple"
    fi
}

copy_lib() {
    local triple="$1"
    local libpath_a="$ROOT_DIR/target/$triple/release/libresvg.so"  # Unix-like naming
    local libpath_lib="$ROOT_DIR/target/$triple/release/resvg.dll" # Windows naming
    local libpath_dylib="$ROOT_DIR/target/$triple/release/libresvg.dylib" # macOS naming
    local dest="$OUT_DIR/$triple"

    local chosen=""
    if [[ -f "$libpath_a" ]]; then
        chosen="$libpath_a"
        elif [[ -f "$libpath_lib" ]]; then
        chosen="$libpath_lib"
        elif [[ -f "$libpath_dylib" ]]; then
        chosen="$libpath_dylib"
    fi

    if [[ -n "$chosen" ]]; then
        mkdir -p "$dest"
        cp -f "$chosen" "$dest/"
        local dest_file="$dest/$(basename "$chosen")"
        info "Exported $triple -> $dest_file"
        strip_lib "$dest_file" "$triple"
    else
        warn "Artifact not found: $libpath_a or $libpath_lib (skip)"
    fi
}

copy_android_lib() {
    local triple="$1"
    local abi="$2"
    local libpath_so="$ROOT_DIR/target/$triple/release/libresvg.so"
    local dest="$OUT_DIR/jniLibs/$abi"

    if [[ -f "$libpath_so" ]]; then
        mkdir -p "$dest"
        cp -f "$libpath_so" "$dest/"
        local dest_file="$dest/libresvg.so"
        info "Exported Android $abi -> $dest/"
        strip_lib "$dest_file" "$triple"
    else
        warn "Android artifact not found: $libpath_so (skip)"
    fi
}

export_headers() {
    local include_dir="$OUT_DIR/include"
    mkdir -p "$include_dir"
    # Copy headers if present
    [[ -f "$ROOT_DIR/resvg.h" ]] && cp -f "$ROOT_DIR/resvg.h" "$include_dir/" && info "Exported header: resvg.h"
}

ANDROID_ABIS=(
    "armeabi-v7a"
    "arm64-v8a"
    "x86"
    "x86_64"
)

ANDROID_TRIPLES=(
    "armv7-linux-androideabi"
    "aarch64-linux-android"
    "i686-linux-android"
    "x86_64-linux-android"
)

NON_ANDROID_TRIPLES=(
    "x86_64-unknown-linux-gnu"      # Linux x64
    "aarch64-unknown-linux-gnu"     # Linux ARM64
    "aarch64-apple-darwin"          # macOS ARM64
    "x86_64-apple-darwin"           # macOS Intel
)

try_build_target() {
    local triple="$1"
    info "Building target: $triple"
    set +e
    rustup target add "$triple" >/dev/null 2>&1
    cargo build --release --target "$triple"
    local rc=$?
    set -e
    if [[ $rc -ne 0 ]]; then
        warn "Build failed: $triple (skipped; will still try to stage any leftover artifacts)"
    else
        info "Build succeeded: $triple"
    fi
}

# Build Android (if cargo-ndk is available)
for t in "${ANDROID_TRIPLES[@]}"; do
    rustup target add "$t" >/dev/null 2>&1
done
if command -v cargo-ndk >/dev/null 2>&1; then
    info "Building Android (${ANDROID_ABIS[*]})..."
    set +e
    cargo ndk ${ANDROID_ABIS[@]/#/-t } build --release
    rc=$?
    set -e
    if [[ $rc -ne 0 ]]; then
        warn "Android build failed (skipped)"
    fi
else
    warn "cargo-ndk not found, skip Android build"
fi

# Build other targets one by one
for t in "${NON_ANDROID_TRIPLES[@]}"; do
    try_build_target "$t"
done

info "Build phase finished; staging artifacts..."

# Export Android artifacts to jniLibs structure
for i in "${!ANDROID_TRIPLES[@]}"; do
    triple="${ANDROID_TRIPLES[$i]}"
    abi="${ANDROID_ABIS[$i]}"
    copy_android_lib "$triple" "$abi"
done

# Export other targets
for t in "${NON_ANDROID_TRIPLES[@]}"; do copy_lib "$t"; done

# Export headers
export_headers

info "Done. Artifacts at: $OUT_DIR"
