# Project Architecture Analysis

## 1. Code Inventory

### Entry Points

* **src/main.vala**
  * `main(string[] args)`: Entry point. Instantiates and runs `AppManager.Application`.

### Application Logic

* **src/application.vala** (`AppManager.Application`)
  * **Variables**: `main_window`, `registry`, `installer`, `settings`, `bg_update_service`, `directory_monitor`, `preferences_dialog`.
  * **CLI Options**: `opt_version`, `opt_help`, `opt_background_update`, `opt_install`, `opt_uninstall`, `opt_is_installed`.
  * **Methods**:
    * `handle_local_options()`: Handles CLI flags like --help, --version.
    * `startup()`: Initializes subsystems (icons, styles, background service, monitor, actions).
    * `activate()`: Shows main window, triggers background update check.
    * `open()`: Handles file opening (drag & drop onto dock icon).
    * `show_drop_window()`: Opens the installer window for a file.
    * `command_line()`: Handles CLI commands (install, uninstall, query).
    * `uninstall_record()`: Async wrapper for uninstallation with UI feedback.
    * `extract_installation()`: Async wrapper for converting portable to extracted.
    * `locate_record()`: Helper to find record by path or checksum.
    * `present_preferences()`: Shows preferences dialog.
    * `run_background_update()`: CLI entry for background updates.

### Core Domain

* **src/core/app_constants.vala**
  
  * **Constants**: `APPLICATION_ID`, `REGISTRY_FILENAME`, `UPDATES_LOG_FILENAME`, `DATA_DIRNAME`, `APPLICATIONS_DIRNAME`, `EXTRACTED_DIRNAME`, `DESKTOP_FILE_PREFIX`, `SQUASHFS_ROOT_DIR`, `LOCAL_BIN_DIRNAME`.

* **src/core/app_paths.vala** (`AppManager.Core.AppPaths`)
  
  * **Properties**: `data_dir`, `registry_file`, `updates_log_file`, `applications_dir`, `extracted_root`, `desktop_dir`, `icons_dir`, `local_bin_dir`, `current_executable_path`.
  * **Role**: Centralizes path resolution and directory creation.

* **src/core/installation_record.vala** (`AppManager.Core.InstallationRecord`)
  
  * **Enums**: `InstallMode` (PORTABLE, EXTRACTED).
  * **Constants**: `CLEARED_VALUE`.
  * **Properties**: `id`, `name`, `mode`, `source_checksum`, `source_path`, `installed_path`, `desktop_file`, `icon_path`, `bin_symlink`, `installed_at`, `updated_at`, `version`, `etag`, `last_release_tag`, `entry_exec`, `is_terminal`.
  * **Original Props**: `original_commandline_args`, `original_keywords`, `original_icon_name`, `original_startup_wm_class`, `original_update_link`, `original_web_page`.
  * **Custom Props**: `custom_commandline_args`, `custom_keywords`, `custom_icon_name`, `custom_startup_wm_class`, `custom_update_link`, `custom_web_page`.
  * **Methods**: `get_effective_*()`, `has_custom_values()`, `to_json()`, `to_history_json()`, `from_json()`, `apply_history()`.

* **src/core/installation_registry.vala** (`AppManager.Core.InstallationRegistry`)
  
  * **Variables**: `records` (HashTable), `history` (HashTable), `registry_file`.
  * **Signals**: `changed`.
  * **Methods**:
    * `list()`: Returns all records.
    * `lookup_by_*()`: Find records by checksum, path, source.
    * `register()`, `update()`, `unregister()`: CRUD operations.
    * `save_to_history()`, `lookup_history()`, `remove_history()`, `apply_history_to_record()`: Manages persistence of settings for uninstalled apps.
    * `persist()`, `reload()`: Disk I/O.
    * `reconcile_with_filesystem()`: Detects and removes orphaned records.

* **src/core/installer.vala** (`AppManager.Core.Installer`)
  
  * **Dependencies**: `InstallationRegistry`, `Settings`.
  * **Methods**:
    * `install()`, `upgrade()`, `reinstall()`: Public API.
    * `install_sync()`: Main installation logic.
    * `install_portable()`, `install_extracted()`: Strategy implementations.
    * `finalize_desktop_and_icon()`: Creates .desktop file and icon.
    * `uninstall()`: Removes files and registry entry.
    * `rewrite_desktop()`: Modifies .desktop file content (injects Exec, Icon, Actions).
    * `resolve_exec_path_for_record()`: Determines actual binary path.
    * `apply_record_customizations_to_desktop()`: Updates .desktop file with user settings.
    * `create_bin_symlink()`, `remove_bin_symlink_for_record()`: Manages ~/.local/bin links.

* **src/core/updater.vala** (`AppManager.Core.Updater`)
  
  * **Classes**: `UpdateResult`, `UpdateProbeResult`, `UpdateCheckInfo`.
  * **Methods**:
    * `probe_updates()`, `update_all()`: Batch operations (parallel).
    * `probe_single()`, `update_single()`: Single record operations.
    * `check_for_update()`: Async check.
    * `resolve_update_source()`: Parses URL into `GithubSource`, `GitlabSource`, or `DirectUrlSource`.
    * `fetch_latest_release()`: API calls to GitHub/GitLab.
    * `download_file()`: Downloads asset.
    * `select_appimage_asset()`: Heuristic to find correct architecture.

* **src/core/app_image_assets.vala** (`AppManager.Core.AppImageAssets`)
  
  * **Classes**: `DesktopEntryMetadata`, `DwarfsTools`.
  * **Methods**:
    * `parse_desktop_file()`: Reads Name, Version, Terminal from .desktop.
    * `extract_desktop_entry()`, `extract_icon()`: Extracts files from AppImage (SquashFS/DwarFS).
    * `ensure_apprun_present()`: Validates AppRun.
    * `check_compatibility()`: Verifies AppImage structure.
    * `resolve_symlink()`: Handles internal symlinks during extraction.

* **src/core/app_image_metadata.vala** (`AppManager.Core.AppImageMetadata`)
  
  * **Properties**: `file`, `path`, `basename`, `display_name`, `is_executable`, `checksum`.
  * **Methods**: `sanitized_basename()`, `derive_name()`.

* **src/core/background_update_service.vala** (`AppManager.Core.BackgroundUpdateService`)
  
  * **Methods**:
    * `request_background_permission()`: Uses XDG Portal to request autostart.
    * `perform_background_check()`: Runs the update check logic.
    * `should_check_now()`: Checks interval against last run time.
    * `write_autostart_file()`, `remove_autostart_file()`: Manages ~/.config/autostart.

* **src/core/directory_monitor.vala** (`AppManager.Core.DirectoryMonitor`)
  
  * **Methods**: `start()`, `stop()`. Monitors `~/Applications` for manual deletions.

* **src/core/version_utils.vala** (`AppManager.Core.VersionUtils`)
  
  * **Methods**: `sanitize()`, `compare()`. Centralized version parsing logic.

### UI Components

* **src/windows/main_window.vala** (`AppManager.MainWindow`)
  
  * **UI**: `Adw.NavigationView`, `Adw.PreferencesPage` (list), `Gtk.Stack` (empty state).
  * **Methods**:
    * `refresh_installations()`: Rebuilds the app list.
    * `populate_group()`: Creates rows for apps.
    * `start_update_check()`, `start_update_install()`: Update workflow.
    * `show_detail_page()`: Navigates to `DetailsWindow`.
    * `on_refresh_clicked()`: Manual sync with filesystem.

* **src/windows/details_window.vala** (`AppManager.DetailsWindow`)
  
  * **UI**: `Adw.PreferencesPage` with groups for Header, Cards, Properties, Update Info, Actions.
  * **Methods**:
    * `build_ui()`: Constructs the view.
    * `persist_record_and_refresh_desktop()`: Saves changes.
    * `present_extract_warning()`: Confirmation for extraction.
    * `uninstall_requested`, `update_requested`: Signals.

* **src/windows/drop_window.vala** (`AppManager.DropWindow`)
  
  * **UI**: Drag & Drop target for installing new AppImages.
  * **Methods**:
    * `start_install()`: Initiates installation.
    * `run_installation()`: Calls `Installer`.
    * `check_compatibility()`: Validates dropped file.

* **src/windows/preferences_window.vala** (`AppManager.PreferencesDialog`)
  
  * **UI**: Settings for Thumbnails, Auto-updates, Links.
  * **Methods**: `apply_thumbnail_background_preference()`, `handle_auto_update_toggle()`.

* **src/windows/dialog_window.vala** (`AppManager.DialogWindow`)
  
  * **Role**: Custom modal dialog implementation (legacy/custom style).

### Utilities

* **src/utils/file_utils.vala** (`AppManager.Utils.FileUtils`)
  
  * **Methods**: `compute_checksum`, `ensure_parent`, `unique_path`, `create_temp_dir`, `file_copy`, `remove_dir_recursive`, `get_path_size`, `detect_image_extension`.

* **src/utils/ui_utils.vala** (`AppManager.Utils.UiUtils`)
  
  * **Methods**: `load_app_icon`, `load_record_icon`, `format_size`, `open_folder`, `open_url`, `ensure_app_card_styles`.

## 2. Call Graph & Dependencies

### Key Flows

1. **Installation Flow**:
   
   *   `Application.open()` -> `DropWindow`
   
   *   `DropWindow` -> `Installer.install()`
   
   *   `Installer.install()` -> `AppImageMetadata` (read info)
   
   *   `Installer.install()` -> `AppImageAssets.extract_*` (get icon/desktop)
   
   *   `Installer.install()` -> `Installer.finalize_desktop_and_icon()` (write .desktop)
   
   *   `Installer.install()` -> `InstallationRegistry.register()` (save to JSON)
   
   *   `InstallationRegistry` emits `changed` -> `MainWindow.refresh_installations()`

2. **Update Flow**:
   
   *   `MainWindow` (Update Button) -> `Updater.probe_updates()`
   
   *   `Updater` -> `InstallationRegistry.list()`
   
   *   `Updater` -> `fetch_latest_release()` (GitHub/GitLab API)
   
   *   `Updater` -> `Installer.upgrade()` (if update found)
   
   *   `Installer.upgrade()` -> `Installer.reinstall()` -> `Installer.uninstall()` + `Installer.install_sync()`

3. **Startup Flow**:
   
   *   `main()` -> `Application.startup()`
   
   *   `Application.startup()` -> `UiUtils.ensure_app_card_styles()`
   
   *   `Application.startup()` -> `BackgroundUpdateService` (init)
   
   *   `Application.startup()` -> `DirectoryMonitor.start()`
   
   *   `Application.activate()` -> `MainWindow` (init)
   
   *   `MainWindow` -> `InstallationRegistry.reconcile_with_filesystem()` (cleanup)

### Class Dependencies

* **Installer** is the central hub for write operations. It depends on `Registry` to save state and `AppImageAssets` to read files.
* **Updater** depends on `Installer` to perform the actual file replacement.
* **MainWindow** observes `Registry` and commands `Installer` and `Updater`.

## 3. Analysis & Suggestions

### Redundancy & Duplication

1. **Desktop File Parsing**:
   
   *   `AppImageAssets.parse_desktop_file`: Parses Name, Version, Terminal.
   
   *   `Installer.extract_desktop_properties`: Parses Icon, Keywords, StartupWMClass, Exec, Homepage, UpdateURL.
   
   *   `DetailsWindow.load_desktop_file_properties`: Parses NoDisplay.
   
   *   **Suggestion**: Create a unified `DesktopFileHandler` or `DesktopEntry` class in `src/core` that handles reading, parsing, and writing .desktop files. It should support all fields used across the app (Name, Version, Exec, Icon, Keywords, Categories, NoDisplay, X-AppImage-*).

2. **Icon Loading**:
   
   *   `UiUtils.load_app_icon`: Loads from path or theme.
   
   *   `UiUtils.load_record_icon`: Wrapper around `Gdk.Texture.from_file`.
   
   *   `DropWindow.load_icons_async`: Custom logic to extract and load icon.
   
   *   **Suggestion**: Consolidate into `UiUtils`. Add `UiUtils.load_icon_from_appimage(path)` to handle the extraction logic used in `DropWindow`.

3. **Dialogs**:
   
   *   `DialogWindow` is a custom implementation.
   
   *   `DetailsWindow` and `MainWindow` use `Adw.AlertDialog`.
   
   *   **Suggestion**: Deprecate `DialogWindow` and migrate `DropWindow` and `UninstallNotification` to use `Adw.AlertDialog` or `Adw.MessageDialog` for consistency with the rest of the UI (Libadwaita style).

4. **File Operations**:
   
   *   `Installer` has private methods like `ensure_executable`, `quote_exec_token`.
   
   *   `FileUtils` has general file ops.
   
   *   **Suggestion**: Move `ensure_executable` to `FileUtils`.

### Simplification Opportunities

1. **Installer Complexity**:
   
   *   `Installer.vala` is very large (over 800 lines). It handles installation strategies, desktop file rewriting, symlink management, and uninstall logic.
   
   *   **Refactoring**: Split into `PortableStrategy` and `ExtractedStrategy` classes? Or at least move the desktop file rewriting logic to the proposed `DesktopFileHandler`.

2. **AppImageAssets**:
   
   *   Contains `DwarfsTools` inner class.
   
   *   **Refactoring**: Move `DwarfsTools` to its own file `src/core/dwarfs_tools.vala` to keep `AppImageAssets` focused on the high-level asset extraction API.

3. **Update Logic**:
   
   *   `Updater` handles both API interaction (GitHub/GitLab) and update orchestration.
   
   *   **Refactoring**: Extract `UpdateSource` and its subclasses (`GithubSource`, `GitlabSource`) into a separate file `src/core/update_sources.vala`.

### Code Quality Observations

1. **Error Handling**: The code generally uses GError (Vala `throws Error`) well.
2. **Async/Threading**: Heavy use of `Thread` + `Idle.add` pattern. Vala's `async`/`yield` is used in some places (`BackgroundUpdateService`), but `MainWindow` and `DropWindow` often spawn threads manually.
   
   *   **Suggestion**: Prefer Vala's `async` methods over manual `Thread` creation where possible for better readability and integration with the main loop.
3. **Hardcoded Strings**: Most user-facing strings are wrapped in `I18n.tr()`, which is good.
4. **CSS**: CSS is injected via `UiUtils` and `MainWindow`.
   
   *   **Suggestion**: Move all CSS definitions to a resource file (`.css`) and load it once, rather than having CSS strings in Vala code.

### Missing Features / Potential Bugs

1. **Exec Resolution**: The logic to resolve `Exec` keys and `AppRun` binaries is complex and duplicated in parts. `Installer.resolve_exec_from_desktop` vs `Installer.resolve_exec_path`. Consolidating this into the `DesktopFileHandler` would reduce bugs related to launching apps.
2. **Thumbnailer**: The app provides a preference to hide thumbnail backgrounds but doesn't seem to register itself as a thumbnailer for AppImages (unless handled by external `appimage-thumbnailer`).

## 4. Summary of Recommendations

1. **Create `src/core/desktop_file.vala`**: Encapsulate all .desktop file I/O.
2. **Create `src/core/update_sources.vala`**: Move `UpdateSource` classes out of `Updater`.
3. **Standardize Dialogs**: Replace `DialogWindow` with `Adw.AlertDialog`.
4. **Refactor `Installer`**: Extract desktop rewriting and maybe installation strategies.
5. **Use Resources for CSS**: Move CSS from `UiUtils.vala` to `data/resources/style.css`.
