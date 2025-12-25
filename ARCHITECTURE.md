# AppManager Architecture Documentation

> **Generated:** December 25, 2025  
> **Purpose:** Complete code analysis including classes, functions, dependencies, and optimization suggestions.

---

## Table of Contents

1. [Project Overview](#project-overview)
2. [File Structure](#file-structure)
3. [Detailed File Analysis](#detailed-file-analysis)
   
   - [Entry Points](#entry-points)
   
   - [Core Module](#core-module)
   
   - [Utils Module](#utils-module)
   
   - [Windows Module](#windows-module)
4. [Dependency Graph](#dependency-graph)
5. [Function Call Graph](#function-call-graph)
6. [Redundancy Analysis & Optimization Suggestions](#redundancy-analysis--optimization-suggestions)

---

## Project Overview

AppManager is a GTK4/Libadwaita desktop application written in Vala for managing AppImage applications on Linux. It provides:

- Installation and uninstallation of AppImages
- Desktop integration (icons, .desktop files)
- Automatic update checking (GitHub/GitLab)
- Background update service via XDG portal

**Build System:** Meson  
**UI Framework:** GTK4 + Libadwaita  
**Dependencies:** libsoup3, json-glib, libgee, libportal

---

## File Structure

```
src/
├── main.vala                    # Entry point
├── application.vala             # Main application class
├── core/
│   ├── app_constants.vala       # Global constants
│   ├── app_paths.vala           # Path resolution utilities
│   ├── app_image_metadata.vala  # AppImage file metadata
│   ├── app_image_assets.vala    # Asset extraction (icons, desktop files)
│   ├── installation_record.vala # Data model for installed apps
│   ├── installation_registry.vala # Persistent storage of installations
│   ├── installer.vala           # Install/uninstall logic
│   ├── updater.vala             # Update checking and downloading
│   ├── background_update_service.vala # Background update scheduler
│   ├── directory_monitor.vala   # Filesystem monitoring
│   ├── i18n.vala                # Internationalization stub
│   └── build_info.vala.in       # Build-time version info
├── utils/
│   ├── file_utils.vala          # File system utilities
│   └── ui_utils.vala            # UI helper functions
└── windows/
    ├── main_window.vala         # Main application window
    ├── details_window.vala      # App details/edit page
    ├── drop_window.vala         # Drag-and-drop installer
    ├── dialog_window.vala       # Reusable dialog component
    └── preferences_window.vala  # Settings dialog
```

---

## Detailed File Analysis

### Entry Points

#### `src/main.vala`

| Type     | Name                  | Description                                                    |
| -------- | --------------------- | -------------------------------------------------------------- |
| Function | `main(string[] args)` | Application entry point, creates and runs Application instance |

**Calls:**

- `AppManager.Application()` → `application.vala:46`
- `app.run(args)` → GTK Application lifecycle

---

#### `src/application.vala`

**Namespace:** `AppManager`

| Type  | Name                 | Line  | Description                            |
| ----- | -------------------- | ----- | -------------------------------------- |
| Class | `Application`        | 7     | Main GTK Application subclass          |
| Field | `main_window`        | 8     | MainWindow? - Primary window reference |
| Field | `registry`           | 9     | InstallationRegistry - App storage     |
| Field | `installer`          | 10    | Installer - Install/uninstall logic    |
| Field | `settings`           | 11    | GLib.Settings - App preferences        |
| Field | `bg_update_service`  | 12    | BackgroundUpdateService?               |
| Field | `directory_monitor`  | 13    | DirectoryMonitor?                      |
| Field | `preferences_dialog` | 14    | PreferencesDialog?                     |
| Field | `opt_*` (static)     | 15-20 | Command line option flags              |
| Const | `options`            | 22    | OptionEntry[] - CLI options definition |

**Methods:**
| Method | Line | Callers | Description |
|--------|------|---------|-------------|
| `Application()` | 33 | `main.vala:2` | Constructor |
| `handle_local_options()` | 46 | GTK runtime | CLI help/version handling |
| `startup()` | 70 | GTK runtime | App initialization, actions setup |
| `activate()` | 137 | GTK runtime | Window creation on activation |
| `open()` | 156 | GTK runtime | Handle file open requests |
| `show_drop_window()` | 163 | `open():160` | Opens DropWindow for file |
| `command_line()` | 174 | GTK runtime | CLI command processing |
| `uninstall_record()` | 244 | `MainWindow`, `DetailsWindow` | Async uninstall with toast |
| `extract_installation()` | 265 | `MainWindow` via signal | Convert portable to extracted |
| `present_extract_error()` | 305 | `extract_installation():296,300` | Error dialog |
| `locate_record()` | 313 | `command_line():221` | Find record by path/checksum |
| `present_preferences()` | 333 | Action handler | Show preferences dialog |
| `request_background_updates()` | 352 | `activate():149` | Request portal permission |
| `run_background_update()` | 358 | `command_line():178` | Background update execution |

---

### Core Module

#### `src/core/app_constants.vala`

**Namespace:** `AppManager.Core`

| Type  | Name                   | Value                            | Used By                          |
| ----- | ---------------------- | -------------------------------- | -------------------------------- |
| Const | `APPLICATION_ID`       | "com.github.AppManager"          | Application, settings            |
| Const | `ORGANIZATION`         | "com.github"                     | Not used (candidate for removal) |
| Const | `APPLICATION_NAME`     | "AppManager"                     | Not used (candidate for removal) |
| Const | `REGISTRY_FILENAME`    | "installations.json"             | AppPaths                         |
| Const | `UPDATES_LOG_FILENAME` | "updates.log"                    | AppPaths                         |
| Const | `DATA_DIRNAME`         | "app-manager"                    | AppPaths                         |
| Const | `APPLICATIONS_DIRNAME` | "Applications"                   | AppPaths                         |
| Const | `EXTRACTED_DIRNAME`    | ".installed"                     | AppPaths                         |
| Const | `MIME_TYPE_APPIMAGE`   | "application/x-iso9660-appimage" | Not used (candidate for removal) |

---

#### `src/core/app_paths.vala`

**Namespace:** `AppManager.Core`

| Type     | Name                      | Line | Description                    |
| -------- | ------------------------- | ---- | ------------------------------ |
| Class    | `AppPaths`                | 1    | Static path resolution         |
| Property | `data_dir`                | 2    | XDG data home + app-manager    |
| Property | `registry_file`           | 10   | JSON registry path             |
| Property | `updates_log_file`        | 16   | Update log path                |
| Property | `applications_dir`        | 22   | ~/Applications                 |
| Property | `extracted_root`          | 30   | ~/Applications/.installed      |
| Property | `desktop_dir`             | 38   | ~/.local/share/applications    |
| Property | `icons_dir`               | 46   | ~/.local/share/icons           |
| Property | `current_executable_path` | 54   | Self exe path (AppImage aware) |

**Callers:**
| Property | Called From |
|----------|-------------|
| `data_dir` | `Updater:43`, `BackgroundUpdateService:15` |
| `registry_file` | `InstallationRegistry:14` |
| `applications_dir` | `Installer:381,413`, `DetailsWindow:475` |
| `extracted_root` | `Installer:215`, `DirectoryMonitor:31` |
| `desktop_dir` | `Installer:354` |
| `icons_dir` | `Installer:323` |
| `current_executable_path` | `Installer:506`, `PreferencesDialog:184`, `BackgroundUpdateService:48` |

---

#### `src/core/app_image_metadata.vala`

**Namespace:** `AppManager.Core`

| Type     | Name               | Line | Description                             |
| -------- | ------------------ | ---- | --------------------------------------- |
| Class    | `AppImageMetadata` | 2    | Metadata extraction from AppImage files |
| Property | `file`             | 3    | Source GLib.File                        |
| Property | `path`             | 4    | File path string                        |
| Property | `basename`         | 5    | File basename                           |
| Property | `display_name`     | 6    | Human-readable name                     |
| Property | `is_executable`    | 7    | Execute permission check                |
| Property | `checksum`         | 8    | SHA256 checksum                         |

**Methods:**
| Method | Line | Callers | Description |
|--------|------|---------|-------------|
| `AppImageMetadata(File)` | 10 | `Installer:79`, `DropWindow:52` | Constructor |
| `detect_executable()` | 20 | Constructor | Check unix execute bit |
| `sanitized_basename()` | 31 | `Installer:214,225` | Safe filename generation |
| `derive_name()` | 45 | Constructor | Extract display name |

---

#### `src/core/app_image_assets.vala`

**Namespace:** `AppManager.Core`

| Type        | Name                   | Line | Description                      |
| ----------- | ---------------------- | ---- | -------------------------------- |
| Errordomain | `AppImageAssetsError`  | 4    | Error types for asset extraction |
| Class       | `DesktopEntryMetadata` | 11   | Parsed .desktop file info        |
| Class       | `DwarfsTools`          | 19   | DwarFS extraction utilities      |
| Class       | `AppImageAssets`       | 92   | Main asset extraction class      |

**DwarfsTools Methods:**
| Method | Line | Callers | Description |
|--------|------|---------|-------------|
| `init_tool_paths()` | 26 | All public methods | Locate DwarFS binaries |
| `available()` | 73 | `extract_entry()`, `list_paths()` | Check tool availability |
| `log_missing_once()` | 78 | `try_extract_entry()`, `list_archive_paths()` | Warning log |
| `extract_entry()` | 85 | `AppImageAssets.try_extract_entry()` | Extract single file |
| `extract_all()` | 106 | `Installer:561` | Full extraction |
| `list_paths()` | 110 | `AppImageAssets.list_archive_paths()` | List archive contents |

**AppImageAssets Methods:**
| Method | Line | Callers | Description |
|--------|------|---------|-------------|
| `parse_desktop_file()` | 97 | `Installer:277`, `DropWindow:755` | Parse .desktop metadata |
| `extract_desktop_entry()` | 127 | `Installer:273`, `DropWindow:753` | Extract .desktop file |
| `extract_icon()` | 148 | `Installer:274`, `DropWindow:709` | Extract icon file |
| `ensure_apprun_present()` | 173 | `Installer:247` | Verify AppRun exists |
| `check_compatibility()` | 188 | `DropWindow:254` | Validate AppImage structure |

---

#### `src/core/installation_record.vala`

**Namespace:** `AppManager.Core`

| Type  | Name                 | Line | Description                    |
| ----- | -------------------- | ---- | ------------------------------ |
| Const | `CLEARED_VALUE`      | 3    | Marker for user-cleared fields |
| Enum  | `InstallMode`        | 5    | PORTABLE, EXTRACTED            |
| Class | `InstallationRecord` | 10   | Data model for installed app   |

**InstallationRecord Properties:**
| Property | Type | Description |
|----------|------|-------------|
| `id` | string | SHA256 checksum (construct) |
| `name` | string | Display name |
| `mode` | InstallMode | Installation type |
| `source_checksum` | string | Original file checksum |
| `source_path` | string | Original file path |
| `installed_path` | string | Current installation path |
| `desktop_file` | string | .desktop file path |
| `icon_path` | string? | Icon file path |
| `bin_symlink` | string? | ~/.local/bin symlink |
| `installed_at` | int64 | Install timestamp |
| `updated_at` | int64 | Last update timestamp |
| `version` | string? | App version |
| `etag` | string? | HTTP ETag for updates |
| `last_release_tag` | string? | Last known release tag |
| `original_*` | string? | Original .desktop values |
| `custom_*` | string? | User-customized values |

**Methods:**
| Method | Line | Callers | Description |
|--------|------|---------|-------------|
| `get_effective_*()` | 48-72 | `Installer`, `DetailsWindow` | Get merged original/custom value |
| `has_custom_values()` | 78 | `InstallationRegistry.save_to_history()` | Check for customizations |
| `to_json()` | 87 | `InstallationRegistry.save()` | Serialize to JSON |
| `to_history_json()` | 155 | `InstallationRegistry.save_to_history()` | Serialize custom values only |
| `from_json()` | 186 | `InstallationRegistry.load()` | Deserialize from JSON |
| `apply_history()` | 249 | `InstallationRegistry.apply_history_to_record()` | Restore custom values |
| `parse_mode()` | 268 | `from_json()` | Parse mode string |
| `mode_label()` | 282 | Display purposes | Human-readable mode |

---

#### `src/core/installation_registry.vala`

**Namespace:** `AppManager.Core`

| Type   | Name                   | Line | Description                                |
| ------ | ---------------------- | ---- | ------------------------------------------ |
| Class  | `InstallationRegistry` | 4    | Persistent storage manager                 |
| Field  | `records`              | 5    | HashTable of installations                 |
| Field  | `history`              | 7    | HashTable of uninstalled app custom values |
| Field  | `registry_file`        | 8    | GLib.File reference                        |
| Signal | `changed`              | 9    | Emitted on data changes                    |

**Methods:**
| Method | Line | Callers | Description |
|--------|------|---------|-------------|
| `InstallationRegistry()` | 11 | `Application:38` | Constructor, loads data |
| `list()` | 17 | Many | Get all records as array |
| `is_installed_checksum()` | 25 | `Installer:80`, `Updater` | Check if checksum exists |
| `lookup_by_checksum()` | 29 | `Application:326`, `DropWindow:214` | Find by checksum |
| `lookup_by_installed_path()` | 38 | `Application:315`, `DirectoryMonitor` | Find by path |
| `lookup_by_source()` | 47 | `Application:315`, `DropWindow:210` | Find by source path |
| `register()` | 56 | `Installer:102` | Add new installation |
| `update()` | 68 | `DetailsWindow` | Update existing record |
| `unregister()` | 79 | `Installer:416` | Remove installation |
| `save_to_history()` | 87 | `unregister()`, `reconcile_with_filesystem()` | Preserve custom values |
| `lookup_history()` | 97 | `apply_history_to_record()` | Get saved custom values |
| `remove_history()` | 104 | `register()` | Clear history entry |
| `apply_history_to_record()` | 117 | `Installer:290` | Restore custom values |
| `persist()` | 127 | `Updater`, `Installer` | Save without signal |
| `reload()` | 136 | `MainWindow.on_refresh_clicked()` | Reload from disk |
| `reconcile_with_filesystem()` | 147 | `Application:141`, `DropWindow:55`, `MainWindow:348` | Clean orphaned records |
| `load()` | 185 | Constructor, `reload()` | Load from JSON file |
| `save()` | 241 | Various | Write to JSON file |
| `notify_changed()` | 274 | Various | Emit changed signal |

---

#### `src/core/installer.vala`

**Namespace:** `AppManager.Core`

| Type        | Name             | Line | Description               |
| ----------- | ---------------- | ---- | ------------------------- |
| Errordomain | `InstallerError` | 5    | Installation error types  |
| Class       | `Installer`      | 13   | Install/uninstall manager |
| Signal      | `progress`       | 19   | Progress message signal   |

**Methods:**
| Method | Line | Callers | Description |
|--------|------|---------|-------------|
| `Installer()` | 21 | `Application:39` | Constructor |
| `install()` | 28 | `DropWindow:530` | Install new AppImage |
| `upgrade()` | 32 | `DropWindow:526`, `Updater` | Upgrade existing |
| `reinstall()` | 36 | `Application:271` | Uninstall + install |
| `install_sync()` | 40 | `install()`, `upgrade()`, `reinstall()` | Core install logic |
| `install_portable()` | 105 | `install_sync()` | Portable mode install |
| `parse_bin_from_apprun()` | 109 | `install_extracted()` | Extract BIN= from AppRun |
| `install_extracted()` | 140 | `install_sync()` | Extracted mode install |
| `finalize_desktop_and_icon()` | 211 | `install_*()` | Desktop integration |
| `uninstall()` | 405 | `Application`, `reinstall()` | Public uninstall |
| `uninstall_sync()` | 409 | `uninstall()` | Uninstall implementation |
| `cleanup_failed_installation()` | 433 | `install_sync()` catch block | Rollback on failure |
| `rewrite_desktop()` | 456 | `finalize_desktop_and_icon()` | Generate .desktop file |
| `ensure_executable()` | 637 | Various | chmod +x |
| `slugify_app_name()` | 652 | `finalize_desktop_and_icon()` | Create URL-safe slug |
| `ensure_install_name()` | 677 | `finalize_desktop_and_icon()` | Rename to slug |
| `move_portable_to_applications()` | 705 | `finalize_desktop_and_icon()` | Move to ~/Applications |
| `resolve_uninstall_prefix()` | 718 | Constructor | Flatpak-aware exec prefix |
| `create_bin_symlink()` | 765 | `finalize_desktop_and_icon()` | Create ~/.local/bin link |
| `ensure_bin_symlink_for_record()` | 787 | `DetailsWindow` | Create symlink for record |
| `resolve_exec_path_for_record()` | 801 | `DetailsWindow`, self | Get executable path |
| `remove_bin_symlink_for_record()` | 854 | `DetailsWindow` | Remove symlink |
| `apply_record_customizations_to_desktop()` | 874 | `DetailsWindow` | Update .desktop from record |
| `set_desktop_entry_property()` | 912 | `DetailsWindow` | Update single .desktop key |
| `migrate_uninstall_execs()` | 942 | Constructor | Migration for old installs |

---

#### `src/core/updater.vala`

**Namespace:** `AppManager.Core`

| Type  | Name                | Line | Description              |
| ----- | ------------------- | ---- | ------------------------ |
| Enum  | `UpdateStatus`      | 6    | UPDATED, SKIPPED, FAILED |
| Enum  | `UpdateSkipReason`  | 12   | NO_UPDATE_URL, etc.      |
| Class | `UpdateResult`      | 20   | Result of update attempt |
| Class | `UpdateProbeResult` | 38   | Result of update check   |
| Class | `UpdateCheckInfo`   | 53   | Update availability info |
| Class | `Updater`           | 66   | Main update manager      |

**Updater Signals:**
| Signal | Callers | Description |
|--------|---------|-------------|
| `record_checking` | Internal | Started checking record |
| `record_downloading` | Internal | Started downloading |
| `record_succeeded` | Internal | Update completed |
| `record_failed` | Internal | Update failed |
| `record_skipped` | Internal | Update skipped |

**Key Methods:**
| Method | Line | Callers | Description |
|--------|------|---------|-------------|
| `Updater()` | 85 | `Application`, `MainWindow` | Constructor |
| `get_update_url()` | 93 | `DetailsWindow` display | Get effective update URL |
| `probe_updates()` | 97 | `MainWindow.start_update_check()` | Check all for updates |
| `probe_single()` | 106 | `MainWindow.start_single_probe()` | Check one record |
| `update_all()` | 110 | `MainWindow`, `BackgroundUpdateService` | Update all records |
| `update_single()` | 118 | `MainWindow.trigger_single_update()` | Update one record |
| `normalize_update_url()` (static) | 152 | `DetailsWindow` on blur | Normalize to project URL |
| `probe_record()` | 268 | `probe_*()` methods | Internal probe logic |
| `update_record()` | 310 | `update_*()` methods | Internal update logic |
| `select_appimage_asset()` | 433 | `probe_record()`, `update_record()` | Find correct arch asset |

---

#### `src/core/background_update_service.vala`

**Namespace:** `AppManager.Core`

| Type  | Name                      | Line | Description                   |
| ----- | ------------------------- | ---- | ----------------------------- |
| Class | `BackgroundUpdateService` | 6    | XDG portal background updates |

**Methods:**
| Method | Line | Callers | Description |
|--------|------|---------|-------------|
| `BackgroundUpdateService()` | 14 | `Application:90`, `Application:361` | Constructor |
| `request_background_permission()` | 20 | `Application.request_background_updates()` | Portal permission request |
| `write_autostart_file()` | 48 | `request_background_permission()` | Create autostart .desktop |
| `perform_background_check()` | 67 | `Application.run_background_update()` | Execute update check |
| `should_check_now()` | 100 | `Application.run_background_update()` | Time check |
| `log_debug()` | 113 | Internal | Log + file write |
| `append_update_log()` | 118 | `log_debug()`, `perform_background_check()` | Write to log file |

---

#### `src/core/directory_monitor.vala`

**Namespace:** `AppManager.Core`

| Type   | Name               | Line | Description               |
| ------ | ------------------ | ---- | ------------------------- |
| Class  | `DirectoryMonitor` | 6    | Filesystem change monitor |
| Signal | `app_deleted`      | 12   | File deletion detected    |
| Signal | `changes_detected` | 13   | Any change detected       |

**Methods:**
| Method | Line | Callers | Description |
|--------|------|---------|-------------|
| `DirectoryMonitor()` | 15 | `Application:91` | Constructor |
| `start()` | 19 | `Application:98` | Start monitoring |
| `stop()` | 38 | Not currently called | Stop monitoring |
| `on_applications_changed()` | 49 | GLib.FileMonitor | Handle ~/Applications changes |
| `on_extracted_changed()` | 65 | GLib.FileMonitor | Handle .installed changes |

---

#### `src/core/i18n.vala`

**Namespace:** `AppManager.Core`

| Type   | Name   | Line | Description               |
| ------ | ------ | ---- | ------------------------- |
| Class  | `I18n` | 2    | Internationalization stub |
| Method | `tr()` | 4    | Pass-through (no-op)      |

**Callers:** Used throughout all files for translatable strings.

---

### Utils Module

#### `src/utils/file_utils.vala`

**Namespace:** `AppManager.Utils`

| Type  | Name        | Line | Description           |
| ----- | ----------- | ---- | --------------------- |
| Class | `FileUtils` | 2    | File system utilities |

**Methods:**
| Method | Line | Callers | Description |
|--------|------|---------|-------------|
| `compute_checksum()` | 3 | `AppImageMetadata`, `Application:324` | SHA256 file hash |
| `ensure_parent()` | 15 | `Installer:351` | mkdir -p for parent |
| `unique_path()` | 22 | `Installer:216,668` | Add -N suffix if exists |
| `create_temp_dir()` | 38 | Many | mkdtemp wrapper |
| `file_copy()` | 43 | `Application:270`, `Installer:324`, `DropWindow:285` | Copy file |
| `remove_dir_recursive()` | 49 | Many | rm -rf |
| `get_path_size()` | 66 | `DetailsWindow`, `MainWindow` | Calculate size |
| `ensure_directory()` | 100 | `PreferencesDialog:227` | mkdir -p |
| `write_text_file()` | 110 | `PreferencesDialog:228` | Write string to file |
| `read_text_file_or_empty()` | 114 | `ensure_line_in_file()`, `remove_line_in_file()` | Read or return "" |
| `ensure_line_in_file()` | 126 | `PreferencesDialog:229` | Add line if missing |
| `remove_line_in_file()` | 143 | `PreferencesDialog:231` | Remove matching line |
| `delete_file_if_exists()` | 174 | `PreferencesDialog:232` | Safe delete |
| `detect_image_extension()` | 183 | `Installer:331` | Detect PNG/SVG from magic |

---

#### `src/utils/ui_utils.vala`

**Namespace:** `AppManager.Utils`

| Type  | Name           | Line | Description         |
| ----- | -------------- | ---- | ------------------- |
| Class | `UiUtils`      | 6    | UI helper utilities |
| Const | `APP_CARD_CSS` | 13   | CSS for card styles |

**Methods:**
| Method | Line | Callers | Description |
|--------|------|---------|-------------|
| `gtk_style_context_add_provider_for_display_compat()` | 7 | `apply_app_css()` | Extern binding |
| `load_app_icon()` | 43 | `DetailsWindow:60`, `MainWindow:267` | Load icon from path |
| `format_size()` | 73 | `MainWindow:339`, `DetailsWindow:131` | Human-readable size |
| `open_folder()` | 87 | `DetailsWindow:119` | Open in file manager |
| `open_url()` | 97 | `DetailsWindow:214`, `PreferencesDialog` | Open in browser |
| `ensure_app_card_styles()` | 105 | `Application:88`, `MainWindow:224` | Apply CSS once |
| `apply_app_css()` | 140 | `ensure_app_card_styles()` | Internal CSS apply |
| `get_accent_background_color()` | 150 | Not currently used | Get system accent |
| `get_accent_foreground_color()` | 155 | Not currently used | Contrast foreground |
| `rgba_to_hex()` | 166 | Not currently used | Color to hex string |
| `rgba_to_css()` | 173 | Not currently used | Color to CSS rgba() |
| `parse_color()` | 181 | `get_accent_*()` | Parse color string |

---

### Windows Module

#### `src/windows/main_window.vala`

**Namespace:** `AppManager`

| Type  | Name                  | Line | Description                    |
| ----- | --------------------- | ---- | ------------------------------ |
| Class | `MainWindow`          | 8    | Primary application window     |
| Enum  | `UpdateWorkflowState` | 27   | READY_TO_CHECK, CHECKING, etc. |

**Key Fields:**
| Field | Type | Description |
|-------|------|-------------|
| `registry` | InstallationRegistry | Data source |
| `installer` | Installer | Install operations |
| `updater` | Updater | Update operations |
| `apps_group` | Adw.PreferencesGroup | App list container |
| `pending_update_keys` | HashSet<string> | Apps with available updates |
| `updating_records` | HashSet<string> | Currently updating apps |
| `active_details_window` | DetailsWindow? | Currently open details |

**Key Methods:**
| Method | Line | Callers | Description |
|--------|------|---------|-------------|
| `MainWindow()` | 35 | `Application:143` | Constructor |
| `add_toast()` | 103 | Various | Show toast notification |
| `refresh_installations()` | 128 | Registry changed, search, etc. | Rebuild app list |
| `populate_group()` | 208 | `refresh_installations()` | Create row widgets |
| `start_update_check()` | 296 | Button, shortcut | Begin update probe |
| `start_update_install()` | 312 | Button | Install pending updates |
| `trigger_single_update()` | 341 | Details page | Update one app |
| `show_detail_page()` | 424 | Row click | Open DetailsWindow |
| `present_shortcuts_dialog()` | 175 | Menu action | Show shortcuts |
| `present_about_dialog()` | 417 | Menu action | Show about |

---

#### `src/windows/details_window.vala`

**Namespace:** `AppManager`

| Type  | Name            | Line | Description                      |
| ----- | --------------- | ---- | -------------------------------- |
| Class | `DetailsWindow` | 5    | App details/edit navigation page |

**Signals:**
| Signal | Connected From | Description |
|--------|----------------|-------------|
| `uninstall_requested` | `MainWindow:430` | User clicked delete |
| `update_requested` | `MainWindow:433` | User clicked update |
| `check_update_requested` | `MainWindow:436` | User clicked check |
| `extract_requested` | `MainWindow:439` | User clicked extract |

**Key Methods:**
| Method | Line | Callers | Description |
|--------|------|---------|-------------|
| `DetailsWindow()` | 20 | `MainWindow.show_detail_page()` | Constructor |
| `matches_record()` | 30 | `MainWindow` sync methods | Check if same record |
| `set_update_available()` | 34 | `MainWindow` | Update UI state |
| `set_update_loading()` | 39 | `MainWindow` | Show/hide spinner |
| `persist_record_and_refresh_desktop()` | 44 | Field change handlers | Save and sync .desktop |
| `build_ui()` | 49 | Constructor | Build all UI elements |
| `refresh_update_button()` | 495 | State changes | Update button appearance |
| `load_desktop_file_properties()` | 579 | `build_ui()` | Read .desktop file |
| `extract_exec_args()` | 609 | `build_ui()` | Parse Exec arguments |
| `present_extract_warning()` | 628 | Extract button | Confirm dialog |

---

#### `src/windows/drop_window.vala`

**Namespace:** `AppManager`

| Type  | Name              | Line | Description                  |
| ----- | ----------------- | ---- | ---------------------------- |
| Class | `DropWindow`      | 8    | Drag-and-drop installer      |
| Enum  | `VersionRelation` | 230  | Version comparison result    |
| Enum  | `InstallIntent`   | 325  | NEW_INSTALL, UPDATE, REPLACE |

**Key Methods:**
| Method | Line | Callers | Description |
|--------|------|---------|-------------|
| `DropWindow()` | 35 | `Application.show_drop_window()` | Constructor |
| `build_ui()` | 60 | Constructor | Create drag UI |
| `check_compatibility()` | 254 | Constructor | Verify AppImage valid |
| `detect_existing_installation()` | 203 | `start_install()` | Find existing record |
| `start_install()` | 222 | Drag gesture end | Begin install flow |
| `present_install_warning_dialog()` | 163 | `start_install()` | New install confirm |
| `present_update_dialog()` | 329 | `start_install()` | Update confirm |
| `present_replace_dialog()` | 419 | `start_install()` | Replace confirm |
| `run_installation()` | 512 | Dialog responses | Execute install |
| `setup_drag_install()` | 625 | `build_ui()` | Configure drag gesture |
| `extract_app_name()` | 740 | Constructor | Get name from .desktop |

---

#### `src/windows/dialog_window.vala`

**Namespace:** `AppManager`

| Type  | Name                    | Line | Description                   |
| ----- | ----------------------- | ---- | ----------------------------- |
| Class | `DialogWindow`          | 5    | Reusable modal dialog         |
| Class | `UninstallNotification` | 82   | Static uninstall notification |

**DialogWindow Methods:**
| Method | Line | Callers | Description |
|--------|------|---------|-------------|
| `DialogWindow()` | 10 | `DropWindow`, `UninstallNotification` | Constructor |
| `append_body()` | 52 | Various | Add widget to body |
| `add_option()` | 56 | Various | Add action button |

---

#### `src/windows/preferences_window.vala`

**Namespace:** `AppManager`

| Type  | Name                | Line | Description     |
| ----- | ------------------- | ---- | --------------- |
| Class | `PreferencesDialog` | 5    | Settings dialog |

**Key Methods:**
| Method | Line | Callers | Description |
|--------|------|---------|-------------|
| `PreferencesDialog()` | 19 | `Application.present_preferences()` | Constructor |
| `build_ui()` | 26 | Constructor | Create settings UI |
| `check_portal_availability()` | 145 | Constructor (async) | Check XDG portal |
| `handle_auto_update_toggle()` | 176 | Settings change | Manage autostart file |
| `apply_thumbnail_background_preference()` | 220 | Settings change | Write GTK CSS override |

---

## Dependency Graph

```
┌─────────────────────────────────────────────────────────────────────┐
│                            main.vala                                 │
│                                │                                     │
│                                ▼                                     │
│                         Application                                  │
│                 ┌──────────┼──────────┐                             │
│                 ▼          ▼          ▼                             │
│          MainWindow  InstallationRegistry  Installer                │
│               │              │              │                        │
│               ▼              │              │                        │
│        DetailsWindow         │              │                        │
│               │              │              │                        │
│               └──────────────┼──────────────┘                        │
│                              │                                       │
│                              ▼                                       │
│                    InstallationRecord                                │
└─────────────────────────────────────────────────────────────────────┘

Core Dependencies:
┌────────────────────┐     ┌─────────────────────┐
│     Installer      │────▶│ InstallationRegistry │
│                    │     └─────────────────────┘
│                    │              │
│                    │              ▼
│                    │     ┌─────────────────────┐
│                    │────▶│ InstallationRecord  │
└────────────────────┘     └─────────────────────┘
         │
         ▼
┌────────────────────┐     ┌─────────────────────┐
│  AppImageAssets    │────▶│   AppImageMetadata  │
└────────────────────┘     └─────────────────────┘
         │
         ▼
┌────────────────────┐
│    DwarfsTools     │
└────────────────────┘

Update Flow:
┌────────────────────┐     ┌─────────────────────┐
│      Updater       │────▶│ InstallationRegistry │
│                    │     └─────────────────────┘
│                    │              │
│                    │              ▼
│                    │────▶┌─────────────────────┐
│                    │     │     Installer       │
└────────────────────┘     └─────────────────────┘
         │
         ▼
┌────────────────────────────────────┐
│    BackgroundUpdateService         │
└────────────────────────────────────┘

Utils Dependencies (used by all):
┌────────────────────┐     ┌─────────────────────┐
│    FileUtils       │     │      UiUtils        │
└────────────────────┘     └─────────────────────┘
```

---

## Function Call Graph

### Installation Flow

```
DropWindow.start_install() [drop_window.vala:222]
    │
    ├──▶ detect_existing_installation() [drop_window.vala:203]
    │       └──▶ InstallationRegistry.lookup_by_* [installation_registry.vala]
    │
    ├──▶ present_install_warning_dialog() [drop_window.vala:163]
    │       └──▶ DialogWindow [dialog_window.vala:10]
    │
    └──▶ run_installation() [drop_window.vala:512]
            │
            ├──▶ prepare_staging_copy() [drop_window.vala:278]
            │       └──▶ FileUtils.create_temp_dir() [file_utils.vala:38]
            │       └──▶ FileUtils.file_copy() [file_utils.vala:43]
            │
            └──▶ Installer.install() / upgrade() [installer.vala:28,32]
                    │
                    └──▶ install_sync() [installer.vala:40]
                            │
                            ├──▶ AppImageMetadata() [app_image_metadata.vala:10]
                            │       └──▶ FileUtils.compute_checksum() [file_utils.vala:3]
                            │
                            ├──▶ install_portable() / install_extracted() [installer.vala:105,140]
                            │       │
                            │       └──▶ finalize_desktop_and_icon() [installer.vala:211]
                            │               │
                            │               ├──▶ AppImageAssets.extract_desktop_entry() [app_image_assets.vala:127]
                            │               ├──▶ AppImageAssets.extract_icon() [app_image_assets.vala:148]
                            │               ├──▶ AppImageAssets.parse_desktop_file() [app_image_assets.vala:97]
                            │               └──▶ rewrite_desktop() [installer.vala:456]
                            │
                            └──▶ InstallationRegistry.register() [installation_registry.vala:56]
```

### Update Check Flow

```
MainWindow.start_update_check() [main_window.vala:296]
    │
    └──▶ Updater.probe_updates() [updater.vala:97]
            │
            └──▶ probe_updates_parallel() [updater.vala:194]
                    │
                    └──▶ probe_record() [updater.vala:268]
                            │
                            ├──▶ read_update_url() [updater.vala:175]
                            │       └──▶ record.get_effective_update_link() [installation_record.vala:68]
                            │
                            ├──▶ resolve_update_source() [updater.vala:161]
                            │       ├──▶ GithubSource.parse() [updater.vala:599]
                            │       └──▶ GitlabSource.parse() [updater.vala:625]
                            │
                            └──▶ fetch_latest_release() [updater.vala:469]
                                    ├──▶ fetch_github_release() [updater.vala:480]
                                    └──▶ fetch_gitlab_release() [updater.vala:520]
```

---

## Redundancy Analysis & Optimization Suggestions

### 1. **Duplicate Icon Loading Functions**

**Issue:** `load_record_icon()` is duplicated in multiple files with nearly identical code.

| Location             | File                 | Line |
| -------------------- | -------------------- | ---- |
| `load_record_icon()` | `drop_window.vala`   | 491  |
| `load_record_icon()` | `dialog_window.vala` | 105  |

**Suggestion:** Move to `UiUtils` class:

```vala
// In ui_utils.vala
public static Gdk.Paintable? load_record_icon(InstallationRecord record) {
    if (record.icon_path == null || record.icon_path.strip() == "") {
        return null;
    }
    try {
        var file = File.new_for_path(record.icon_path);
        if (file.query_exists()) {
            return Gdk.Texture.from_file(file);
        }
    } catch (Error e) {
        warning("Failed to load record icon: %s", e.message);
    }
    return null;
}
```

---

### 2. **Duplicate `create_wrapped_label()` Functions**

**Issue:** Nearly identical label creation functions exist in:

| Location                 | File                 | Line |
| ------------------------ | -------------------- | ---- |
| `create_wrapped_label()` | `drop_window.vala`   | 469  |
| `create_wrapped_label()` | `dialog_window.vala` | 126  |

**Suggestion:** Move to `UiUtils`:

```vala
// In ui_utils.vala
public static Gtk.Label create_wrapped_label(string text, bool use_markup = false, bool dim = false) {
    var label = new Gtk.Label(null);
    label.wrap = true;
    label.set_wrap_mode(Pango.WrapMode.WORD_CHAR);
    label.halign = Gtk.Align.CENTER;
    label.justify = Gtk.Justification.CENTER;
    label.use_markup = use_markup;
    if (use_markup) {
        label.set_markup(text);
    } else {
        label.set_text(text);
    }
    if (dim) {
        label.add_css_class("dim-label");
    }
    return label;
}
```

---

### 3. **Unused Constants in `app_constants.vala`**

**Issue:** Several constants are defined but never used:

| Constant             | Status           |
| -------------------- | ---------------- |
| `ORGANIZATION`       | Never referenced |
| `APPLICATION_NAME`   | Never referenced |
| `MIME_TYPE_APPIMAGE` | Never referenced |

**Suggestion:** Remove unused constants or add usage:

```vala
// Remove these lines from app_constants.vala:
// public const string ORGANIZATION = "com.github";
// public const string APPLICATION_NAME = "AppManager";
// public const string MIME_TYPE_APPIMAGE = "application/x-iso9660-appimage";
```

---

### 4. **Unused Color Utility Functions in `ui_utils.vala`**

**Issue:** These functions are defined but never called:

| Function                        | Status       |
| ------------------------------- | ------------ |
| `get_accent_background_color()` | Never called |
| `get_accent_foreground_color()` | Never called |
| `rgba_to_hex()`                 | Never called |
| `rgba_to_css()`                 | Never called |

**Suggestion:** Either remove or document for future use. If intended for theming:

```vala
// Consider removing lines 150-181 in ui_utils.vala
// Or add TODO comment explaining future use
```

---

### 5. **Duplicate Version Comparison Logic**

**Issue:** Version comparison exists in two places:

| Location                    | File               | Line |
| --------------------------- | ------------------ | ---- |
| `compare_version_strings()` | `drop_window.vala` | 260  |
| `compare_versions()`        | `updater.vala`     | 577  |

**Suggestion:** Create shared utility in core:

```vala
// New file: src/core/version_utils.vala
namespace AppManager.Core {
    public class VersionUtils {
        public static int compare(string? left, string? right) {
            var a = sanitize(left);
            var b = sanitize(right);
            // ... unified implementation
        }

        public static string? sanitize(string? value) {
            // ... strip 'v' prefix, etc.
        }
    }
}
```

---

### 6. **Duplicate Autostart File Writing**

**Issue:** Autostart file creation is duplicated:

| Location                      | File                             | Line |
| ----------------------------- | -------------------------------- | ---- |
| `write_autostart_file()`      | `background_update_service.vala` | 48   |
| `handle_auto_update_toggle()` | `preferences_window.vala`        | 176  |

**Suggestion:** Centralize in `BackgroundUpdateService`:

```vala
// In background_update_service.vala, make write_autostart_file() public
public void write_autostart_file() { ... }
public void remove_autostart_file() { ... }

// In preferences_window.vala, use the service
bg_service.write_autostart_file();
bg_service.remove_autostart_file();
```

---

### 7. **Redundant Desktop File Parsing**

**Issue:** Desktop file is parsed multiple times in `DetailsWindow.build_ui()`:

```vala
// Line ~135: load_desktop_file_properties() reads all keys
var desktop_props = load_desktop_file_properties(record.desktop_file);

// Then individual values extracted from same file via get_effective_*()
var effective_icon = record.get_effective_icon_name();
```

**Suggestion:** The `InstallationRecord` already stores original values. Remove redundant parsing in `DetailsWindow` and rely on record properties:

```vala
// Remove load_desktop_file_properties() call
// Use record.original_* and record.custom_* directly
```

---

### 8. **Inconsistent Error Handling Patterns**

**Issue:** Some methods use exceptions, others return null:

| Pattern     | Example                                 |
| ----------- | --------------------------------------- |
| Exception   | `AppImageMetadata()` throws Error       |
| Null return | `DwarfsTools.list_paths()` returns null |

**Suggestion:** Standardize on one pattern. For internal helpers, exceptions are cleaner:

```vala
// Prefer:
public static ArrayList<string> list_paths(string archive) throws Error {
    if (!available()) {
        throw new AppImageAssetsError.EXTRACTION_FAILED("DwarFS tools not available");
    }
    // ...
}
```

---

### 9. **Large Method Complexity**

**Issue:** Several methods are excessively long:

| Method              | File                  | Lines | Complexity |
| ------------------- | --------------------- | ----- | ---------- |
| `build_ui()`        | `details_window.vala` | ~440  | Very High  |
| `rewrite_desktop()` | `installer.vala`      | ~180  | High       |
| `install_sync()`    | `installer.vala`      | ~110  | High       |

**Suggestion:** Extract sub-methods:

```vala
// details_window.vala
private void build_ui() {
    build_header_group();
    build_cards_group();
    build_properties_group();
    build_actions_group();
}

private void build_header_group() { /* ... */ }
private void build_cards_group() { /* ... */ }
// etc.
```

---

### 10. **Potential Memory Leak: Thread Without Cleanup**

**Issue:** Several `new Thread<void>()` calls don't have explicit cleanup:

```vala
// installer.vala:524 (in run_installation)
new Thread<void>("appmgr-install", () => { ... });
```

**Suggestion:** Consider using GLib.Task or async/await pattern for better lifecycle management:

```vala
// Alternative using async
private async void run_installation_async(...) {
    SourceFunc callback = run_installation_async.callback;
    new Thread<void>("appmgr-install", () => {
        // ... work ...
        Idle.add((owned) callback);
    });
    yield;
}
```

---

### 11. **Hardcoded Strings**

**Issue:** Some strings that could be constants are hardcoded:

| String            | Location                 | Suggested Constant                      |
| ----------------- | ------------------------ | --------------------------------------- |
| `"appmanager-"`   | `installer.vala:352`     | `DESKTOP_FILE_PREFIX`                   |
| `".local/bin"`    | `details_window.vala:16` | Already const, but could be in AppPaths |
| `"squashfs-root"` | `installer.vala:227,232` | `SQUASHFS_ROOT_DIR`                     |

---

### 12. **Suggestions Summary Table**

| Priority | Issue                              | Impact          | Effort   |
| -------- | ---------------------------------- | --------------- | -------- |
| High     | Duplicate `load_record_icon()`     | Maintainability | Low      |
| High     | Duplicate `create_wrapped_label()` | Maintainability | Low      |
| Medium   | Duplicate version comparison       | Bug risk        | Medium   |
| Medium   | Duplicate autostart writing        | Maintainability | Low      |
| Medium   | Unused constants                   | Code clarity    | Very Low |
| Medium   | Unused UI utility functions        | Code size       | Very Low |
| Low      | Large method complexity            | Readability     | High     |
| Low      | Inconsistent error handling        | Consistency     | Medium   |

---

## Recommendations for Refactoring

### Short-term (Low effort, high impact):

1. **Create `UiUtils.load_record_icon()`** - consolidate from 2 files
2. **Create `UiUtils.create_wrapped_label()`** - consolidate from 2 files  
3. **Remove unused constants** from `app_constants.vala`
4. **Remove unused color functions** from `ui_utils.vala` (or add TODO)

### Medium-term:

5. **Create `VersionUtils`** class to unify version comparison
6. **Centralize autostart file management** in `BackgroundUpdateService`
7. **Remove redundant desktop file parsing** in `DetailsWindow`

### Long-term:

8. **Refactor `DetailsWindow.build_ui()`** into smaller methods
9. **Refactor `Installer.rewrite_desktop()`** into smaller methods
10. **Standardize error handling patterns** across the codebase
11. **Consider async/await** instead of raw threads for better lifecycle

---

## Class Inheritance Diagram

```
GLib.Object
├── AppImageMetadata
├── DesktopEntryMetadata
├── DwarfsTools
├── AppImageAssets
├── InstallationRecord
├── InstallationRegistry
├── Installer
├── Updater
├── BackgroundUpdateService
├── DirectoryMonitor
├── I18n
├── FileUtils
├── UiUtils
├── UpdateResult
├── UpdateProbeResult
└── UpdateCheckInfo

Adw.Application
└── Application

Adw.Window
├── MainWindow
└── DropWindow
    └── DialogWindow

Adw.PreferencesDialog
└── PreferencesDialog

Adw.NavigationPage
└── DetailsWindow
```

---

*Document generated by code analysis. Review suggestions carefully before implementing changes.*
