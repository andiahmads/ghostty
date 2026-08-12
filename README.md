<h1 align="center">
  <img src="momok-dock.png" alt="Momok logo" width="128">
  <br>Momok
</h1>

<p align="center">
  Terminal workspace native untuk macOS dengan vertical tabs, project explorer,
  preview file, dan workflow Neovim terintegrasi.
</p>

> [!IMPORTANT]
>
> Momok adalah proyek eksperimen dan fork independen dari
> [Ghostty](https://github.com/ghostty-org/ghostty). Momok terinspirasi oleh
> workflow modern [Warp Terminal](https://www.warp.dev/), tetapi dibangun di
> atas core native Ghostty untuk mempertahankan rendering Metal, startup yang
> cepat, dan performa terminal yang ringan. Momok tidak berafiliasi dengan atau
> didukung secara resmi oleh Ghostty maupun Warp.

## Tentang Momok

Momok menggabungkan terminal native berperforma tinggi dengan workspace yang
lebih praktis untuk coding. Fokus eksperimen ini adalah menghadirkan pengalaman
kerja modern seperti navigasi project dan preview terintegrasi tanpa mengganti
terminal dengan UI berbasis web atau runtime yang lebih berat.

Core terminal tetap menggunakan Zig, `libghostty`, dan renderer Metal dari
Ghostty. Fitur workspace macOS dikembangkan secara native dengan AppKit dan
SwiftUI.

## Fitur

- Horizontal tabs bawaan atau vertical tab sidebar yang dapat diubah lebarnya.
- Project explorer yang mengikuti working directory terminal aktif.
- Lazy directory loading, pencarian file, refresh, Reveal in Finder, dan Copy
  Path.
- Satu Neovim split di sisi kanan yang digunakan kembali saat membuka file.
- Integrasi Neovim RPC untuk membuka file berikutnya sebagai editor tab.
- Editor tabline dengan label tipe file, indikator perubahan, perpindahan tab,
  dan tombol tutup.
- Preview Markdown native dengan heading, list, quote, code block, table, dan
  inline formatting.
- Preview gambar native untuk format yang didukung macOS, termasuk PNG, JPEG,
  GIF, TIFF, HEIC, BMP, dan WebP yang tersedia pada versi macOS pengguna.
- Panel preview yang dapat di-resize, di-refresh, dan ditutup.
- Dukungan true color untuk aplikasi terminal seperti Codex.
- Branding, bundle identifier, menu, nama aplikasi, dan ikon Dock Momok.

## Instalasi di macOS

### Persyaratan

- macOS
- Xcode 26 dengan macOS 26 SDK
- Zig 0.16.0 atau lebih baru
- Git

### Build dan install

Clone repository lalu buat build Release agar Momok berjalan tanpa banner dan
overhead Debug:

```shell
git clone https://github.com/andiahmads/Momok.git
cd Momok
zig build -Doptimize=ReleaseFast
```

Bundle aplikasi akan dibuat di `macos/build/ReleaseLocal/Momok.app`. Tutup
Momok versi lama, lalu install ke folder Applications:

```shell
pkill -f '/Applications/Momok.app/Contents/MacOS/ghostty' 2>/dev/null || true
ditto macos/build/ReleaseLocal/Momok.app /Applications/Momok.app
open /Applications/Momok.app
```

Jika ikon Dock belum berubah setelah update, jalankan:

```shell
killall Dock
open /Applications/Momok.app
```

### Update

```shell
cd Momok
git pull
zig build -Doptimize=ReleaseFast
pkill -f '/Applications/Momok.app/Contents/MacOS/ghostty' 2>/dev/null || true
ditto macos/build/ReleaseLocal/Momok.app /Applications/Momok.app
open /Applications/Momok.app
```

## Konfigurasi

Momok masih kompatibel dengan konfigurasi core Ghostty. Konfigurasi terminal
yang sudah ada di `~/.config/ghostty/config` tetap dapat digunakan, termasuk
font, theme, key binding, shell integration, dan pengaturan terminal lainnya.

Untuk menjaga warna aplikasi CLI seperti Codex, jangan menetapkan environment
variable `NO_COLOR=1`. Momok menyediakan `TERM=xterm-256color` dan
`COLORTERM=truecolor` kepada proses terminal.

## Pengembangan

Build aplikasi untuk pengembangan:

```shell
zig build
open macos/build/Debug/Momok.app
```

Build Debug menampilkan peringatan performa dan hanya ditujukan untuk proses
development. Gunakan build `ReleaseFast` untuk pemakaian harian.

Panduan teknis core dan kontribusi upstream yang masih relevan tersedia di
[HACKING.md](HACKING.md) dan [CONTRIBUTING.md](CONTRIBUTING.md).

## Kredit dan status

Momok memanfaatkan karya open-source Ghostty sebagai fondasi terminalnya dan
mempertahankan lisensi serta atribusi upstream yang berlaku. Ide workspace
modernnya terinspirasi oleh Warp Terminal, kemudian diimplementasikan sebagai
fitur macOS native di atas core Ghostty.

Proyek ini bersifat eksperimental. API, UI, struktur konfigurasi Momok, dan
fitur workspace dapat berubah selama pengembangan.

## Lisensi

Lihat [LICENSE](LICENSE) untuk ketentuan lisensi proyek dan komponen upstream.
