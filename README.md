# ☁️ Cloudflare Switcher (macOS Menu Bar App)

An ultra-lightweight native macOS app built with **Swift** and **SwiftUI** to control `cloudflared tunnel` on-demand directly from the **Menu Bar (Top Bar)**, without running it as a persistent background daemon or service.

Bundle size: **~600 KB** | Memory footprint: **~15–20 MB**

---

## 👨‍💻 Author

**Jemiro Kasih** ([@jemirokasih](https://github.com/jemirokasih))

---

## ✨ Features

- ⚡ **On-Demand Switching**: Toggle your Cloudflare tunnel ON/OFF anytime with a single switch.
- 🔒 **Secure Token Storage**: Encrypted storage via native **macOS Keychain** (`Security.framework`).
- 🖥️ **Menu Bar Only**: Runs seamlessly in the macOS menu bar (`LSUIElement = true`) without docking.
- 🚦 **Dynamic Status Indicator**: Top bar icon and badge reflect live connection states:
  - ⚪ **Gray**: Disconnected / Stopped
  - 🟡 **Orange**: Connecting / Disconnecting
  - 🟢 **Green**: Active / Connected (Tunnel live)
  - 🔴 **Red**: Error / Binary missing
- 📦 **Auto-Detect & One-Click Install**: Automatically detects `cloudflared` binary path (`/opt/homebrew/bin`, `/usr/local/bin`, or PATH). Offers 1-click Homebrew installation if missing.
- 📜 **Live Terminal Logs**: Collapsible terminal log viewer with auto-scroll and 1-click copy to clipboard.
- 🛡️ **Graceful Shutdown**: Sends `SIGINT` to gracefully disconnect sessions at Cloudflare Edge when stopped or quitting.

---

## 🚀 Installation & Running

### Option 1: Run the Prebuilt Bundle

```bash
open CloudflareSwitcher.app
```

*(Optional)* Drag `CloudflareSwitcher.app` into `/Applications` to launch via Spotlight or Launchpad.

### Option 2: Build from Source

Clone repository and run packaging script:
```bash
git clone https://github.com/jemirokasih/cloudflared-switcher.git
cd cloudflared-switcher
./bundle.sh
open CloudflareSwitcher.app
```

Or run via Swift CLI:
```bash
swift run
```

---

## 📖 How to Use

1. Launch `CloudflareSwitcher.app` — the cloud icon appears in your **macOS Menu Bar**.
2. Click the menu bar icon to open the switcher panel.
3. Paste your Cloudflare Tunnel Token into the **Tunnel Token** input and click **Save**.
   - *Token can be retrieved from Cloudflare Zero Trust Dashboard (`eyJh...`).*
4. Toggle **Tunnel Service** to **ON**.
5. Once connected, the status badge turns **Active (Connected)** with green icon.
6. Toggle **OFF** anytime to cleanly terminate the tunnel.
7. Click **About** in the footer for credits.

---

## 🛠️ System Requirements

- **macOS**: 13.0 (Ventura), 14.0 (Sonoma), 15.0 (Sequoia), or later.
- **Architecture**: Apple Silicon (M1/M2/M3/M4) & Intel x86_64.
- **cloudflared**: Auto-detected or installable via `brew install cloudflared`.

---

## 📄 License

MIT License. Free for personal and commercial use.