#!/usr/bin/env bash
# All device-controlled content lives in
# devices/<name>/{configs,files}; this script only applies those files.
set -euo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"

DEV="${1:-dir-3040}"
TARGET="${TARGET:-ramips}"
SUBTARGET="${SUBTARGET:-mt7621}"

D="$ROOT/devices/$DEV"
TARGET_DIR="$ROOT/target/linux/$TARGET"
SUBTARGET_DIR="$TARGET_DIR/$SUBTARGET"

die() {
    echo "ERROR: $*" >&2
    exit 1
}

cd "$ROOT"

[ -d "$TARGET_DIR" ] ||
    die "target $TARGET not found"

[ -d "$SUBTARGET_DIR" ] ||
    die "subtarget $SUBTARGET not found"

[ -d "$D" ] ||
    die "$D not found"

[ -f "$D/configs/$DEV.config" ] ||
    die "$D/configs/$DEV.config not found"

[ -f "$D/configs/kernel-$SUBTARGET.config" ] ||
    die "$D/configs/kernel-$SUBTARGET.config not found"

KVER="$(
    grep -m1 '^KERNEL_PATCHVER:=' "$TARGET_DIR/Makefile" |
    cut -d= -f2
)"

[ -n "$KVER" ] ||
    die "unable to determine kernel version"

KERNEL_CONFIG="$SUBTARGET_DIR/config-$KVER"
DEVICE_KERNEL_CONFIG="$D/configs/kernel-$SUBTARGET.config"

TMP_DIR="$ROOT/tmp"
TMP_CONFIG="$TMP_DIR/smartwrt-kernel-config.tmp"

cleanup() {
    rm -f "$TMP_CONFIG"
}

trap cleanup EXIT

mkdir -p "$TMP_DIR"

./scripts/kconfig.pl + \
    "$KERNEL_CONFIG" \
    "$DEVICE_KERNEL_CONFIG" \
    > "$TMP_CONFIG"

mv "$TMP_CONFIG" "$KERNEL_CONFIG"

cp "$D/configs/$DEV.config" .config
cp -a "$D/files/." files/