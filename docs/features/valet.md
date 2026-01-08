# Feature: Framework Valet

## Overview

Framework Valet is a shell-based installer that provides an always-running Framework GUI server accessible via a memorable URL. It follows the pattern of Laravel Valet, Homebrew, and similar developer tools.

**Goal**: User runs a one-liner and gets a persistent Framework GUI at `http://framework.r` (or `localhost:1215` for simpler setups).

### Key Design Decision

The R package remains focused on R functionality. Valet handles system administration (services, DNS, proxies) via shell scripts. This separation keeps the right tools for the right job - R for data analysis, shell for system administration.

---

## Requirements

### Core Requirements
- [ ] Persistent GUI server that survives terminal closure
- [ ] Auto-start on system boot/login
- [ ] Clean URLs (`framework.r` instead of `localhost:8080`)
- [ ] Easy installation via one-liner
- [ ] CLI for management (start/stop/status)
- [ ] Clean uninstallation

### Platform Requirements
- [ ] macOS support (Phase 1)
- [ ] Linux support (Phase 2)
- [ ] Windows support (Phase 5 - deferred)

### Installation Tier Requirements
- [ ] Tier 1 (Simple): `localhost:1215` - no additional dependencies
- [ ] Tier 2 (DNS): `framework.r:1215` - requires dnsmasq
- [ ] Tier 3 (Full): `framework.r` - requires dnsmasq + nginx

---

## Implementation Checklist

### Phase 1: MVP (macOS, Tier 1 only)
- [ ] Create `inst/valet/` directory structure
- [ ] Write `install.sh` with detection and Tier 1 installation
- [ ] Write `framework-valet` CLI with start/stop/status/uninstall
- [ ] Write launchd plist template
- [ ] Test on macOS

### Phase 2: Linux Support
- [ ] Add systemd service template
- [ ] Add Linux detection to `install.sh`
- [ ] Add Linux-specific functions in `lib/linux.sh`
- [ ] Test on Ubuntu, Fedora

### Phase 3: Tier 2 (DNS)
- [ ] Add dnsmasq installation and configuration
- [ ] Add resolver setup (macOS) / dnsmasq integration (Linux)
- [ ] Handle existing dnsmasq/Valet detection
- [ ] Add `framework-valet upgrade` command

### Phase 4: Tier 3 (Full)
- [ ] Add nginx installation and configuration
- [ ] Handle port 80 permissions
- [ ] Test end-to-end

### Phase 5: Windows (Future)
- [ ] Research Windows service management
- [ ] Research Acrylic DNS Proxy
- [ ] Write PowerShell installer
- [ ] Test on Windows 10/11

---

## Technical Details

### Architecture

| Component | Responsibility |
|-----------|----------------|
| **Framework R Package** | Data workflows, `gui()` function, R-based tooling |
| **Framework Valet** | System services, DNS, reverse proxy, CLI management |

### File Structure

All valet-related files will live within the R package at `inst/valet/`:

```
inst/valet/
├── install.sh              # Main Unix installer (curl target)
├── install.ps1             # Windows installer (future)
├── framework-valet         # CLI tool installed to PATH
├── templates/
│   ├── launchd.plist       # macOS service definition
│   ├── systemd.service     # Linux service definition
│   ├── dnsmasq.conf        # DNS config for .r TLD
│   └── nginx.conf          # Reverse proxy config (Tier 3)
└── lib/
    ├── common.sh           # Shared functions (logging, prompts, etc.)
    ├── detect.sh           # System detection and compatibility checks
    ├── macos.sh            # macOS-specific installation
    └── linux.sh            # Linux-specific installation
```

### Installation Tiers

#### Tier 1: Simple (Port-Only)
- **URL**: `http://localhost:1215`
- **Requirements**: R + Framework package
- **Installs**: launchd (macOS) or systemd (Linux) service, `framework-valet` CLI
- **Sudo required**: No

#### Tier 2: DNS (Nice URL + Port)
- **URL**: `http://framework.r:1215`
- **Requirements**: R + Framework + dnsmasq
- **Installs**: Everything from Tier 1 + dnsmasq + DNS resolver configuration
- **Sudo required**: Yes (for resolver setup)

#### Tier 3: Full (No Port)
- **URL**: `http://framework.r`
- **Requirements**: R + Framework + dnsmasq + nginx
- **Installs**: Everything from Tier 2 + nginx reverse proxy on port 80
- **Sudo required**: Yes (for port 80)

### Platform Support

| Platform | DNS Solution | Service Manager | Status |
|----------|-------------|-----------------|--------|
| **macOS** | dnsmasq + `/etc/resolver/r` | launchd | Phase 1 |
| **Linux** | dnsmasq or systemd-resolved | systemd user service | Phase 2 |
| **Windows** | Acrylic DNS Proxy | Task Scheduler/NSSM | Phase 5 (deferred) |

---

## User Experience

### Installation

**One-liner install:**
```bash
curl -fsSL https://raw.githubusercontent.com/your-org/framework/main/inst/valet/install.sh | bash
```

**Interactive flow:**
```
Framework Valet Installer
=========================

Checking system...
✓ macOS 14.2 detected
✓ R 4.3.2 found at /usr/local/bin/R
✓ Framework package installed (v0.1.0)
✓ Homebrew found
✓ Port 1215 available
✗ dnsmasq not installed

Choose installation type:

  1) Simple  - http://localhost:1215
              No additional dependencies

  2) DNS     - http://framework.r:1215
              Installs dnsmasq, requires sudo

  3) Full    - http://framework.r
              Installs dnsmasq + nginx, requires sudo

Enter choice [1-3]: 
```

**Non-interactive install:**
```bash
curl -fsSL .../install.sh | bash -s -- --tier simple
curl -fsSL .../install.sh | bash -s -- --tier dns
curl -fsSL .../install.sh | bash -s -- --tier full
```

### CLI Commands

After installation, `framework-valet` is available in PATH:

```bash
framework-valet start       # Start the GUI server
framework-valet stop        # Stop the GUI server
framework-valet restart     # Restart the GUI server
framework-valet status      # Show running status, URL, uptime
framework-valet doctor      # Diagnose issues, check all components
framework-valet upgrade     # Upgrade to a higher tier
framework-valet uninstall   # Remove everything (with confirmation)
framework-valet logs        # Tail the server logs
framework-valet open        # Open the GUI in default browser
```

**Status output example:**
```
$ framework-valet status

Framework Valet
  Status:  Running
  URL:     http://framework.r:1215
  Tier:    dns
  Uptime:  3 days, 2 hours
  PID:     12345
  
Components:
  ✓ R 4.3.2
  ✓ Framework 0.1.0
  ✓ dnsmasq running
  ✓ DNS resolver configured
```

---

## Detection & Compatibility

Before installation, the script will check:

### System Requirements
- Operating system (macOS version, Linux distro)
- R installation and version
- Framework package installed
- Homebrew (macOS) or package manager (Linux)

### Port Availability
- Port 1215 not in use
- Port 80 not in use (Tier 3 only)

### Existing Installations
- Existing Framework Valet installation
- Existing dnsmasq installation
- Existing Laravel Valet (can coexist)
- Existing nginx installation
- systemd-resolved conflicts (Linux)

### Detection Outcomes
- **Clean system**: Proceed with full install
- **Existing dnsmasq**: Add `.r` config to existing setup
- **Existing Laravel Valet**: Coexist, add `.r` alongside `.test`
- **Port conflict**: Warn user, offer alternative port
- **Existing Framework Valet**: Offer upgrade/reconfigure/uninstall

---

## Service Templates

### macOS launchd

`~/Library/LaunchAgents/com.framework.gui.plist`:
```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.framework.gui</string>
    <key>ProgramArguments</key>
    <array>
        <string>/usr/local/bin/Rscript</string>
        <string>-e</string>
        <string>framework::gui(port = 1215, browse = FALSE)</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <true/>
    <key>StandardOutPath</key>
    <string>~/.config/framework/valet/gui.log</string>
    <key>StandardErrorPath</key>
    <string>~/.config/framework/valet/gui.error.log</string>
</dict>
</plist>
```

### Linux systemd

`~/.config/systemd/user/framework-gui.service`:
```ini
[Unit]
Description=Framework GUI Server
After=network.target

[Service]
Type=simple
ExecStart=/usr/bin/Rscript -e "framework::gui(port = 1215, browse = FALSE)"
Restart=always
RestartSec=10

[Install]
WantedBy=default.target
```

### dnsmasq Configuration

`/opt/homebrew/etc/dnsmasq.d/framework.conf` (macOS) or `/etc/dnsmasq.d/framework.conf` (Linux):
```
# Framework Valet - resolve .r TLD to localhost
address=/.r/127.0.0.1
```

### macOS Resolver

`/etc/resolver/r`:
```
nameserver 127.0.0.1
```

### nginx Reverse Proxy (Tier 3)

```nginx
server {
    listen 80;
    server_name framework.r;
    
    location / {
        proxy_pass http://127.0.0.1:1215;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;
    }
}
```

---

## Configuration Storage

`~/.config/framework/valet/config.yml`:
```yaml
tier: dns
port: 1215
installed_at: 2026-01-08T10:30:00Z
version: 1.0.0

components:
  dnsmasq: true
  nginx: false
  
paths:
  r: /usr/local/bin/R
  rscript: /usr/local/bin/Rscript
  dnsmasq_config: /opt/homebrew/etc/dnsmasq.d/framework.conf
  service: ~/Library/LaunchAgents/com.framework.gui.plist
```

---

## Uninstallation

`framework-valet uninstall` will:

1. Stop the running service
2. Remove launchd/systemd service files
3. Remove dnsmasq configuration (but not dnsmasq itself)
4. Remove nginx configuration (but not nginx itself)
5. Remove resolver file (macOS)
6. Remove `~/.config/framework/valet/`
7. Remove `framework-valet` from PATH
8. **NOT** remove the Framework R package

---

## Dependencies

### For Tier 1
- None (uses built-in OS service managers)

### For Tier 2
- dnsmasq (installed via Homebrew/apt/dnf)

### For Tier 3
- nginx (installed via Homebrew/apt/dnf)

### Breaking Changes
None - this is a new, optional feature that doesn't affect existing functionality.

---

## Testing Strategy

### Unit Tests
- Test detection functions (OS, R, Framework, existing installations)
- Test configuration file generation
- Test CLI argument parsing

### Integration Tests
- Test full installation flow on macOS
- Test full installation flow on Linux (Ubuntu, Fedora)
- Test upgrade between tiers
- Test uninstallation
- Test coexistence with Laravel Valet

### Manual Testing
- Test on fresh macOS installation
- Test on fresh Linux installation
- Test with existing dnsmasq
- Test with existing Laravel Valet
- Test service persistence across reboots

---

## Documentation Updates

- [ ] Add valet section to README.md
- [ ] Create user-facing installation guide
- [ ] Document CLI commands
- [ ] Document troubleshooting steps
- [ ] Update CLAUDE.md with valet architecture notes

---

## Design Decisions

1. **Shell scripts over R**: System administration (services, DNS, proxies) is better handled by shell scripts than R. This follows the Unix philosophy of using the right tool for the job.

2. **`.r` TLD**: Single-letter TLDs are reserved by ICANN and will never be real TLDs, making `.r` safe for local use and memorable for R users.

3. **Port 1215**: Memorable number. High enough to not require root.

4. **Tiered installation**: Users can choose their comfort level - simple (no dependencies), DNS (nice URLs), or full (cleanest URLs).

5. **In-package location**: Keeping valet scripts in `inst/valet/` keeps everything together for now. Can split to separate repo later if needed.

---

## Open Questions (To Resolve Before Implementation)

1. **Script hosting URL**: Where does `install.sh` get served from?
   - `https://raw.githubusercontent.com/your-org/framework/main/inst/valet/install.sh`
   - A shorter vanity URL? (requires web hosting)

2. **CLI name**: `framework-valet` vs `fw-valet` vs `fvalet`?
   - Leaning: `framework-valet` (explicit, no conflicts)

3. **R package helpers**: Should the R package have any valet-related functions?
   - Option A: None - complete separation
   - Option B: Minimal helpers like `valet_status()` that shell out to CLI
   - Leaning: Option A for now, add later if needed

4. **GUI behavior without project context**:
   - When user visits `framework.r` from anywhere, what do they see?
   - Project picker/dashboard? Last-used project? Landing page?
   - This may require GUI changes beyond the valet installer

5. **Logging**: Where do logs go? How much to log?
   - Leaning: `~/.config/framework/valet/gui.log`, rotate at reasonable size

6. **Update mechanism**: How does user update valet itself?
   - Re-run installer? (`curl ... | bash` is idempotent)
   - `framework-valet update` command?

---

## Future Enhancements

- Windows support (Phase 5)
- HTTPS support with self-signed certificates
- Multiple project support with subdomains (`project-name.framework.r`)
- System tray integration
- Health monitoring and auto-restart on failure
