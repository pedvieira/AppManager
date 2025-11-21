# AppManager AI Coding Instructions

You are an expert Vala/GTK developer working on AppManager, a Libadwaita utility for managing AppImages on GNOME.

## Project Architecture

### Core Shared Library (`src/core/`)
**CRITICAL**: All files in `src/core/` are compiled into BOTH the main application AND the Nautilus extension. Any changes here impact both components simultaneously.

- `installer.vala`: The heart of the application—handles moving/extracting AppImages, rewriting `.desktop` files, extracting icons via `7z`, and cleanup.
- `installation_registry.vala`: Manages the JSON database at `~/.local/share/app-manager/installations.json`. The single source of truth for what's installed. Never bypass it for file existence checks.
- `app_image_metadata.vala`: Lightweight inspection—computes SHA256 checksums, derives display names, checks executability.
- `installation_record.vala`: Defines `InstallMode` enum (`PORTABLE`, `EXTRACTED`) and record serialization/deserialization.
- `app_paths.vala`: Centralized path resolution for `~/Applications`, `~/.local/share/app-manager`, desktop entries, and icons.
- `app_constants.vala`: Application ID, MIME type, directory names.
- `file_utils.vala`: SHA256 checksums, unique path generation, recursive directory removal, temp dir creation.

### UI Layer (`src/windows/`)
- `drop_window.vala`: macOS-style drag-and-drop installer with animated icon transitions. Programmatically built UI (no `.ui` templates).
- `main_window.vala`: Preferences and installed apps list viewer.
- `dialog_window.vala`: Reusable dialog patterns.

### File Manager Integration (`extensions/`)
- `nautilus_extension.vala`: Right-click context menus for `.appimage` files. Queries registry to show "Install AppImage" or "Move to Trash". Spawns main app via CLI (`--install`, `--uninstall`).
- Compiled as `libnautilus-app-manager.so` into `/usr/lib/nautilus/extensions-4/`.

### Data Persistence
- **Registry**: `~/.local/share/app-manager/installations.json` (JSON array of `InstallationRecord` objects).
- **Settings**: `data/com.github.AppManager.gschema.xml` (GSettings keys: `default-install-mode`, `auto-clean-temp`, `use-system-icons`).

## Build & Development

```bash
# Setup
meson setup build
meson compile -C build

# Run (from project root)
./build/src/app-manager

# Install locally (for testing Nautilus extension)
meson install -C build --destdir "$HOME/.local"
# Then: killall nautilus && nautilus &

# CLI modes
./build/src/app-manager --install /path/to/app.AppImage
./build/src/app-manager --uninstall /path/or/checksum
./build/src/app-manager --is-installed /path/to/app.AppImage
```

**Dependencies**: `libadwaita-1 (>=1.4)`, `gtk4`, `gio-2.0`, `glib-2.0`, `json-glib-1.0`, `gee-0.8`, `libnautilus-extension-4` (optional).  
**Runtime Requirement**: `7z` (p7zip) is MANDATORY—used to extract `.desktop` files, icons, and AppImage contents.

## Key Patterns & Workflows

### Installation Modes
- **`PORTABLE`**: Moves AppImage to `~/Applications`, marks executable, unpacks `.desktop`+icon via `7z`, rewrites `Exec` to point at moved `.AppImage`.
- **`EXTRACTED`**: Fully unpacks AppImage to `~/Applications/.installed/<slug>/`, rewrites `.desktop` `Exec` to point at `AppRun` inside extracted tree.
- Default mode controlled by `default-install-mode` GSettings key ("portable" or "extracted").
- When modifying installation logic, ALWAYS handle both paths in `installer.vala` (see `install_portable()` and `install_extracted()`).

### Registry Lifecycle
1. `AppImageMetadata` computes SHA256 checksum on file open.
2. `Installer.install()` checks `registry.is_installed_checksum()` to prevent duplicates.
3. After successful install, `registry.register(record)` saves to JSON and emits `changed()` signal.
4. Uninstall deletes files, desktop entry, icon, then calls `registry.unregister(id)`.

### Desktop Integration Flow
1. Extract AppImage to temp dir (`/tmp/appmgr-XXXXXX`) with `run_7z()`.
2. Recursively search for `*.desktop` file (`find_desktop_entry()`).
3. Parse for `Name` and `X-AppImage-Version` keys.
4. Extract icon (`*.png`, `*.svg`), preferring 256x256 or 512x512 sizes.
5. Rewrite `.desktop` file:
   - Replace `Exec=AppRun` with absolute path to installed executable.
   - Replace `Icon=` with either system icon name (if `use-system-icons=true`) or absolute path.
   - Inject `[Desktop Action Uninstall]` with custom uninstall command.
6. Save rewritten `.desktop` to `~/.local/share/applications/appmanager-<slug>.desktop`.
7. Clean temp dir if `auto-clean-temp=true`.

### 7z Extraction Pattern
All `7z` calls use `Process.spawn_sync()` in `Installer.run_7z()` and `DropWindow.run_7z()`:
```vala
run_7z({"x", source_path, "-o" + dest_dir, "-y"});  // Extract all
run_7z({"x", source_path, "-o" + dest_dir, "*.desktop", "-r", "-y"});  // Extract .desktop only
```
If `7z` returns non-zero, throw `InstallerError.EXTRACTION_FAILED` or `SEVEN_ZIP_MISSING`.

### Error Handling
- Use `try/catch` blocks with GLib `Error` for all file I/O, JSON parsing, and subprocess spawning.
- Custom errordomain: `InstallerError` (in `installer.vala`): `ALREADY_INSTALLED`, `DESKTOP_MISSING`, `EXTRACTION_FAILED`, `SEVEN_ZIP_MISSING`, `UNINSTALL_FAILED`.
- Log with `warning()`, `debug()`, or `critical()` (GLib logging).

### Nautilus Extension Integration
- Extension links against `core_sources` directly (see `extensions/meson.build`).
- On right-click, computes file checksum and queries `InstallationRegistry`.
- Spawns main app asynchronously: `Process.spawn_async(null, ["app-manager", "--install", path], ...)`.
- No direct UI—all operations delegated to main application.

## Code Style & Conventions

- **Language**: Vala (target GLib 2.74, specified in `meson.build`).
- **Indentation**: 4 spaces, no tabs.
- **Namespaces**: `AppManager`, `AppManager.Core`, `AppManager.Utils`.
- **Object Construction**: Use GObject-style construction: `Object(property: value, ...)`.
- **UI Construction**: Programmatic (no `.ui` templates)—build widget trees in constructors.
- **Logging**: Use `debug()`, `warning()`, `critical()` instead of `print()` or `stdout`.
- **Paths**: Always use `Path.build_filename()` for cross-platform safety.

## Common Pitfalls

1. **Forgetting dual compilation**: Changes to `src/core/` require rebuilding BOTH `app-manager` and `libnautilus-app-manager.so`. Test Nautilus integration after core changes.
2. **Bypassing registry**: Don't check file existence directly—always query `InstallationRegistry` to determine install status.
3. **Missing `7z` checks**: If `7z` is unavailable, extraction silently fails. `run_7z()` throws errors, but catch and inform user.
4. **Temp cleanup**: If `auto-clean-temp=false`, temp dirs accumulate in `/tmp`. Document this in user-facing messages.
5. **Desktop entry uniqueness**: Desktop files use `appmanager-<slug>.desktop` naming. Ensure slug generation (`slugify_app_name()`) handles collisions.

## Testing & Debugging

- **Manual Testing**: Drop various AppImages (executable/non-executable, with/without icons) into drop window.
- **CLI Testing**: Use `--install`, `--uninstall`, `--is-installed` flags to test headless operation.
- **Nautilus Testing**: After `meson install`, restart Nautilus: `killall nautilus && nautilus &`. Check context menus on `.appimage` files.
- **Logs**: Run with `G_MESSAGES_DEBUG=all ./build/src/app-manager` to see debug output.
- **Registry Inspection**: `cat ~/.local/share/app-manager/installations.json | jq` to verify registry state.

## Critical Files Reference

| File | Purpose |
|------|---------|
| `src/core/installer.vala` | Installation/uninstallation orchestration, desktop integration |
| `src/core/installation_registry.vala` | JSON persistence, lookup by checksum/path |
| `src/windows/drop_window.vala` | Drag-and-drop UI, icon animation, mode selection |
| `extensions/nautilus_extension.vala` | File manager context menus |
| `data/com.github.AppManager.gschema.xml` | User preferences schema |
| `meson.build` | Build config, shared `core_sources` definition |
