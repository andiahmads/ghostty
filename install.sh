#!/bin/bash

set -euo pipefail

REPOSITORY_URL="https://github.com/andiahmads/Momok.git"
SOURCE_DIR="${MOMOK_SOURCE_DIR:-$HOME/.momok-source}"
APP_PATH="/Applications/Momok.app"

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

say "Memeriksa kebutuhan Momok..."

if ! command -v xcodebuild >/dev/null 2>&1; then
  fail "Install Xcode dari App Store, buka Xcode satu kali, lalu jalankan installer ini lagi."
fi

if ! xcodebuild -version >/dev/null 2>&1; then
  fail "Buka Xcode satu kali dan setujui lisensinya, lalu jalankan installer ini lagi."
fi

if ! command -v zig >/dev/null 2>&1; then
  if command -v brew >/dev/null 2>&1; then
    say "Zig belum tersedia. Meng-install Zig dengan Homebrew..."
    brew install zig
  else
    fail "Zig belum tersedia. Install Homebrew dari https://brew.sh, lalu jalankan installer ini lagi."
  fi
fi

if [ -d "$SOURCE_DIR/.git" ]; then
  say "Memperbarui source Momok..."
  git -C "$SOURCE_DIR" fetch origin main
  git -C "$SOURCE_DIR" checkout main
  git -C "$SOURCE_DIR" pull --ff-only origin main
else
  say "Mengunduh Momok..."
  if [ -e "$SOURCE_DIR" ]; then
    fail "$SOURCE_DIR sudah ada tetapi bukan repository Momok. Hapus atau pindahkan folder tersebut, lalu coba lagi."
  fi
  git clone --depth 1 "$REPOSITORY_URL" "$SOURCE_DIR"
fi

say "Membuat Momok versi Release. Proses pertama dapat memerlukan beberapa menit..."
(cd "$SOURCE_DIR" && zig build -Doptimize=ReleaseFast)

BUILT_APP="$SOURCE_DIR/macos/build/ReleaseLocal/Momok.app"
if [ ! -d "$BUILT_APP" ]; then
  fail "Build selesai tetapi Momok.app tidak ditemukan."
fi

say "Memasang Momok ke folder Applications..."
pkill -f '/Applications/Momok.app/Contents/MacOS/ghostty' 2>/dev/null || true

if [ -d "$APP_PATH" ]; then
  BACKUP_PATH="$HOME/.Trash/Momok-previous-$(date +%Y%m%d-%H%M%S).app"
  mv "$APP_PATH" "$BACKUP_PATH"
fi

ditto "$BUILT_APP" "$APP_PATH"
touch "$APP_PATH"
killall Dock 2>/dev/null || true
open "$APP_PATH"

say "Momok berhasil di-install dan sudah dibuka."
printf '%s\n' "Aplikasi: $APP_PATH"
printf '%s\n' "Untuk update, jalankan kembali perintah installer yang sama."

