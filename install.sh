#!/bin/bash

set -euo pipefail

REPOSITORY="andiahmads/Momok"
APP_PATH="/Applications/Momok.app"
ARCHIVE_NAME="Momok-macOS-universal.zip"

say() {
  printf '\n%s\n' "$1"
}

fail() {
  printf '\nMomok belum dapat di-install.\n%s\n' "$1" >&2
  exit 1
}

if [ "$(uname -s)" != "Darwin" ]; then
  fail "Installer ini hanya untuk macOS."
fi

say "Mengunduh Momok versi terbaru..."
DOWNLOAD_URL="https://github.com/$REPOSITORY/releases/latest/download/$ARCHIVE_NAME"
TEMP_DIR="$(mktemp -d /tmp/momok-installer.XXXXXX)"
trap 'rm -rf "$TEMP_DIR"' EXIT

if ! curl -fL --retry 3 --progress-bar "$DOWNLOAD_URL" -o "$TEMP_DIR/$ARCHIVE_NAME"; then
  fail "Release Momok belum tersedia atau koneksi internet bermasalah. Coba lagi beberapa saat."
fi

ditto -x -k "$TEMP_DIR/$ARCHIVE_NAME" "$TEMP_DIR/unpacked"
BUILT_APP="$TEMP_DIR/unpacked/Momok.app"
[ -d "$BUILT_APP" ] || fail "File download tidak berisi Momok.app yang valid."

say "Memasang Momok ke folder Applications..."
pkill -f '/Applications/Momok.app/Contents/MacOS/ghostty' 2>/dev/null || true

if [ -d "$APP_PATH" ]; then
  BACKUP_PATH="$HOME/.Trash/Momok-previous-$(date +%Y%m%d-%H%M%S).app"
  mv "$APP_PATH" "$BACKUP_PATH"
fi

ditto "$BUILT_APP" "$APP_PATH"
xattr -dr com.apple.quarantine "$APP_PATH" 2>/dev/null || true
touch "$APP_PATH"
killall Dock 2>/dev/null || true
open "$APP_PATH"

say "Momok berhasil di-install dan sudah dibuka."
printf '%s\n' "Aplikasi: $APP_PATH"
printf '%s\n' "Untuk update, jalankan kembali perintah installer yang sama."

