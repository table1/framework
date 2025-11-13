# NAS / Network Share Mounting Feature

## Overview
Add programmatic mounting of network shares (NAS) to Framework connections system.

## Use Case
Make it easier to attach network storage (NAS devices, network shares) to Framework projects on macOS and Linux.

## Platform Support

### macOS
```bash
# SMB/CIFS
mount -t smbfs //user:password@server/share /mount/point

# NFS
mount -t nfs server:/export/path /mount/point

# AFP (deprecated but still works)
mount -t afp afp://user:password@server/share /mount/point
```

### Linux
```bash
# SMB/CIFS
mount -t cifs //server/share /mount/point -o username=user,password=pass

# NFS
mount -t nfs server:/export/path /mount/point
```

## Proposed Implementation

### 1. GUI - Add Third Section to ConnectionsPanel
Add "Network Shares / NAS" section alongside Databases and S3-compatible Storage:

**Fields:**
- Connection Name
- Protocol (SMB/CIFS, NFS, AFP)
- Server
- Share/Export Path
- Mount Point (local directory)
- Username (optional for NFS)
- Password (optional for NFS)

### 2. Configuration Format
```yaml
connections:
  framework:
    driver: sqlite
    database: framework.db

  nas_backup:
    driver: nas
    protocol: smb  # or nfs, afp
    server: env("NAS_SERVER", "nas.local")
    share: env("NAS_SHARE", "backups")
    mount_point: env("NAS_MOUNT", "~/mounts/nas")
    username: env("NAS_USER", "")
    password: env("NAS_PASSWORD", "")
```

### 3. R Functions
Provide helper functions in Framework:

```r
# Mount network share (auto-detects OS)
mount_nas("nas_backup")

# Check mount status
nas_status("nas_backup")  # Returns: "mounted", "unmounted", "error"

# Unmount
unmount_nas("nas_backup")

# Auto-mount on scaffold
scaffold()  # Could auto-mount configured NAS connections
```

### 4. Implementation Details

**Platform Detection:**
- Use `Sys.info()["sysname"]` to detect OS
- Route to appropriate mount command (macOS vs Linux)

**Security Considerations:**
- Store credentials in `.env` (gitignored)
- Never hardcode passwords
- Consider OS keychain integration for credentials
- Warn if credentials in plain text

**Mount Logic:**
- Check if already mounted before attempting (`mount | grep`)
- Create mount point directory if doesn't exist (`dir.create()`)
- Handle permission errors gracefully
- Provide clear error messages
- Log mount/unmount operations

**User Experience:**
- Optional auto-mount on `scaffold()` if configured
- Status indicators in GUI
- Graceful handling when NAS unavailable
- Cross-platform path normalization
- Support for tilde expansion in mount points

### 5. Error Handling
- NAS server not reachable
- Invalid credentials
- Mount point already in use
- Insufficient permissions
- Platform not supported (Windows would need different approach)

### 6. Testing Considerations
- Mock mount commands in tests
- Test cross-platform path handling
- Test credential security
- Test mount status detection

## Benefits
- Seamless NAS integration for data workflows
- Platform-agnostic interface
- Credentials managed through .env
- Can auto-mount on project startup
- Useful for storing large datasets externally

## Future Enhancements
- Windows support (net use command)
- SFTP/SSH filesystem mounting
- Mount health checks/monitoring
- Automatic remount on disconnect
- Multi-user NAS configuration
