#!/bin/bash
set -euo pipefail

# Project root & output directory
ROOT_DIR=$(cd "$(dirname "$0")" && pwd)
OUT_DIR=${OUT_DIR:-"$ROOT_DIR/prebuilt"}
mkdir -p "$OUT_DIR"

info() { echo -e "\033[1;34m[INFO]\033[0m $*"; }
warn() { echo -e "\033[1;33m[WARN]\033[0m $*"; }
err()  { echo -e "\033[1;31m[ERR ]\033[0m $*"; }

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
        info "Exported $triple -> $dest/$(basename "$chosen")"
    else
        warn "Artifact not found: $libpath_a or $libpath_lib (skip)"
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
)
ANDROID_TRIPLES=(
    "armv7-linux-androideabi"
    "aarch64-linux-android"
)

NON_ANDROID_TRIPLES=(
    "aarch64-unknown-linux-musl"    # Linux ARM64
    "aarch64-apple-darwin"          # macOS ARM64
    "x86_64-apple-darwin"           # macOS Intel
    "x86_64-pc-windows-gnu"         # Windows x64 (GNU)
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

# Export artifacts per target
for t in "${ANDROID_TRIPLES[@]}"; do copy_lib "$t"; done
for t in "${NON_ANDROID_TRIPLES[@]}"; do copy_lib "$t"; done

# Export headers
export_headers

info "Done. Artifacts at: $OUT_DIR"