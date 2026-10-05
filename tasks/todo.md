# Task List: Cloudflare Tunnel Switcher

## Phase 1: Project Setup & Core Models

### Task 1: Setup Swift Package & Application Structure
**Description:** Inisialisasi Swift Package Manager project dengan executable target `CloudflareSwitcher`, setup Info.plist dengan `LSUIElement = true` (Menu Bar only app tanpa icon dock yang mengganggu), dan konfigurasi deployment target macOS 13+.
**Acceptance criteria:**
- [x] File `Package.swift` terkonfigurasi dengan benar.
- [x] Project berhasil dikompilasi via `swift build`.
- [x] Struktur folder terorganisir: `Sources/CloudflareSwitcher/{App, Models, Services, Views}`.
**Verification:**
- [x] Build succeeds: `swift build`
**Dependencies:** None
**Estimated scope:** Small (1-3 files)

---

### Task 2: Implement Secure TokenStorage (Keychain Wrapper)
**Description:** Buat service `TokenStorage` menggunakan macOS Keychain Services API (`Security.framework`) untuk menyimpan, membaca, dan menghapus Cloudflare Tunnel token secara aman. Sediakan fallback in-memory/encrypted preference jika diperlukan.
**Acceptance criteria:**
- [x] Token dapat disimpan ke Keychain dengan service identifier unik.
- [x] Token dapat dibaca kembali saat aplikasi dibuka kembali.
- [x] Token dapat dihapus atau diperbarui.
**Verification:**
- [x] Unit test: `swift test` atau test script memverifikasi write/read/delete token di Keychain.
**Dependencies:** Task 1
**Estimated scope:** Small (1-2 files)

---

### Task 3: Implement BinaryDetector & One-Click Installer
**Description:** Buat service `BinaryDetector` untuk mendeteksi lokasi binary `cloudflared` di sistem (Apple Silicon `/opt/homebrew/bin/cloudflared`, Intel `/usr/local/bin/cloudflared`, PATH environment). Jika tidak ditemukan, sediakan helper untuk menjalankan instalasi via `brew install cloudflared` secara asynchronous dengan callback progress.
**Acceptance criteria:**
- [x] Deteksi otomatis mengembalikan full path `cloudflared` yang valid jika sudah terpasang.
- [x] Memberikan status `missing` jika binary belum terpasang.
- [x] Method `installViaBrew()` menjalankan `brew install cloudflared` dan menangkap log output instalasi.
**Verification:**
- [x] Test command/script memverifikasi deteksi binary pada sistem saat ini (`/opt/homebrew/bin/cloudflared`).
**Dependencies:** Task 1
**Estimated scope:** Small (1-2 files)

---

## Checkpoint 1: Foundation
- [x] `swift build` berhasil tanpa warning/error.
- [x] `TokenStorage` dan `BinaryDetector` teruji dan berfungsi.

---

## Phase 2: Tunnel Process Management

### Task 4: Implement TunnelManager & Process Lifecycle
**Description:** Buat kelas `TunnelManager` (ObservableObject) yang mengelola lifecycle child process `cloudflared tunnel run --token <token>`. Menangani starting, piping output stdout/stderr secara real-time, regex parsing status koneksi ("Registered tunnel connection"), dan graceful stop via `SIGINT`/`SIGTERM`.
**Acceptance criteria:**
- [x] Process spawn dengan argument `--token <token>` dan `--no-autoupdate`.
- [x] Status berubah secara reaktif: `.stopped` -> `.starting` -> `.running` -> `.stopping` -> `.stopped`.
- [x] Menghentikan process secara bersih tanpa meninggalkan orphan process (`cloudflared`).
- [x] Menyimpan ringkasan log buffer (misal 50-100 baris terakhir) untuk ditampilkan di UI.
- [x] Menangani error exit code (misal token invalid, network disconnected).
**Verification:**
- [x] Eksekusi lifecycle test start & stop process.
**Dependencies:** Task 2, Task 3
**Estimated scope:** Medium (2-3 files)

---

## Checkpoint 2: Core Logic
- [x] `TunnelManager` mampu mengeksekusi binary dan menghentikannya dengan graceful signal.
- [x] Log output tertangkap di log buffer.

---

## Phase 3: SwiftUI Menu Bar UI

### Task 5: Setup MenuBarExtra & Dynamic Status Icon
**Description:** Implementasikan `CloudflareSwitcherApp` dengan `MenuBarExtra` di SwiftUI. Tampilkan status icon dinamis di Top Bar (Awan abu-abu saat OFF, oranye berkedip saat Connecting, hijau/biru saat Active ON, merah saat Error).
**Acceptance criteria:**
- [x] Icon muncul di menu bar macOS (Top Bar).
- [x] Icon berubah warna/simbol sesuai `TunnelManager.status`.
- [x] Klik icon membuka popover window SwiftUI.
**Verification:**
- [x] Manual test: jalankan aplikasi dan periksa tampilan icon di menu bar.
**Dependencies:** Task 4
**Estimated scope:** Small (1-2 files)

---

### Task 6: Implement Main Switch & Status Card View
**Description:** Buat tampilan utama di dalam popover window menu bar: status badge yang jelas, Toggle switch besar untuk Turn ON / OFF tunnel, animasi feedback saat connecting, dan validasi (switch disable jika token kosong atau binary tidak ada).
**Acceptance criteria:**
- [x] Desain modern, bersih, dan estetik (Apple Human Interface Guidelines).
- [x] Toggle ON memanggil `tunnelManager.start()`, Toggle OFF memanggil `tunnelManager.stop()`.
- [x] State loading/connecting terindikasi dengan jelas.
**Verification:**
- [x] Toggle switch merespon klik dan memicu transisi status.
**Dependencies:** Task 5
**Estimated scope:** Small (1-2 files)

---

### Task 7: Implement Token Input & Management View
**Description:** Buat UI input field untuk Cloudflare Tunnel Token dengan tombol Show/Hide (mata), tombol Save/Update, indikator status penyimpanan, dan validasi format dasar token.
**Acceptance criteria:**
- [x] Token dapat diedit dan disimpan ke Keychain.
- [x] Mode obscured / secure field default dengan opsi reveal plaintext.
- [x] Tombol Clear / Remove token.
**Verification:**
- [x] Simpan token baru, tutup dan buka kembali popover -> token tetap tersimpan.
**Dependencies:** Task 6
**Estimated scope:** Small (1-2 files)

---

### Task 8: Implement Missing Binary Banner & One-Click Installer Sheet
**Description:** Jika `cloudflared` belum terinstall di komputer user, tampilkan alert/banner edukatif di popover dengan tombol "Install via Homebrew". Tampilkan progress spinner dan console log saat brew install sedang berjalan.
**Acceptance criteria:**
- [x] Banner otomatis muncul jika `BinaryDetector` tidak menemukan binary.
- [x] Klik install memicu instalasi di background tanpa membekukan UI.
- [x] Setelah instalasi sukses, banner hilang dan tombol switch langsung aktif.
**Verification:**
- [x] UI mendeteksi binary terpasang dan beralih ke mode siap pakai.
**Dependencies:** Task 6
**Estimated scope:** Small (1-2 files)

---

### Task 9: Implement Collapsible Log Viewer & Footer Actions
**Description:** Tambahkan drawer log yang dapat dibuka/tutup (collapsible) untuk melihat live terminal output dari `cloudflared` (sangat berguna jika tunnel gagal terhubung), tombol Copy Logs, dan tombol `Quit Cloudflare Switcher`.
**Acceptance criteria:**
- [x] Baris log muncul secara live dengan auto-scroll ke baris paling bawah.
- [x] Tombol Copy All Logs ke clipboard.
- [x] Tombol Quit menghentikan proses tunnel terlebih dahulu (jika masih aktif) lalu menutup aplikasi dengan aman.
**Verification:**
- [x] Log output terlihat saat tunnel dijalankan; tombol Quit mematikan tunnel & app.
**Dependencies:** Task 6, Task 7
**Estimated scope:** Small (1-2 files)

---

## Checkpoint 3: UI & End-to-End
- [x] Seluruh alur (Input token -> Klik ON -> Tunnel terhubung -> Cek log -> Klik OFF -> Tunnel berhenti) berfungsi mulus dari Top Bar.

---

## Phase 4: Packaging & Distribution

### Task 10: App Bundle Packaging Script (`bundle.sh`)
**Description:** Buat shell script `bundle.sh` untuk mengompilasi binary rilis (`swift build -c release`) dan menyusun struktur `CloudflareSwitcher.app` lengkap dengan `Info.plist` (LSUIElement = true), icon aset `.icns`, sehingga bisa langsung di-drag ke folder `/Applications`.
**Acceptance criteria:**
- [x] Script `./bundle.sh` menghasilkan `CloudflareSwitcher.app` yang valid dan executable.
- [x] Aplikasi dapat dibuka langsung dari Finder atau Terminal `open CloudflareSwitcher.app`.
- [x] Berjalan di background sebagai menu bar agent tanpa icon di dock.
**Verification:**
- [x] Jalankan `./bundle.sh` dan verifikasi `open CloudflareSwitcher.app`.
**Dependencies:** Phase 3
**Estimated scope:** Small (1-2 files)

---

### Task 11: Documentation & User Guide
**Description:** Buat `README.md` komprehensif dalam bahasa Indonesia dan Inggris yang menjelaskan cara build, cara install, cara mendapatkan token di Cloudflare Dashboard, serta tips troubleshooting.
**Acceptance criteria:**
- [x] Panduan lengkap, jelas, dan mudah diikuti.
**Verification:**
- [x] Review dokumentasi.
**Dependencies:** Task 10
**Estimated scope:** Small (1 file)
