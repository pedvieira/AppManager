using GLib;

namespace AppManager.Core {
    public class DesktopEntry : Object {
        private KeyFile key_file;
        private string? file_path;

        public string? name { get; set; }
        public string? version { get; set; }
        public string? exec { get; set; }
        public string? icon { get; set; }
        public string? keywords { get; set; }
        public string? categories { get; set; }
        public string? startup_wm_class { get; set; }
        public bool terminal { get; set; }
        public bool no_display { get; set; }
        public string? appimage_homepage { get; set; }
        public string? appimage_update_url { get; set; }
        public string? appimage_version { get; set; }
        public string? actions { get; set; }

        public DesktopEntry(string? path = null) {
            key_file = new KeyFile();
            if (path != null) {
                try {
                    load(path);
                } catch (Error e) {
                    warning("Failed to load desktop file %s: %s", path, e.message);
                }
            }
        }

        public void load(string path) throws Error {
            file_path = path;
            key_file.load_from_file(path, KeyFileFlags.KEEP_COMMENTS | KeyFileFlags.KEEP_TRANSLATIONS);
            
            // Standard keys
            name = get_string("Name");
            version = get_string("Version");
            exec = get_string("Exec");
            icon = get_string("Icon");
            keywords = get_string("Keywords");
            categories = get_string("Categories");
            startup_wm_class = get_string("StartupWMClass");
            terminal = get_boolean("Terminal");
            no_display = get_boolean("NoDisplay");
            actions = get_string("Actions");

            // X-AppImage keys
            appimage_homepage = get_string("X-AppImage-Homepage");
            appimage_update_url = get_string("X-AppImage-UpdateURL");
            appimage_version = get_string("X-AppImage-Version");
            
            // Fallback for version if standard Version is missing but X-AppImage-Version exists
            if (version == null && appimage_version != null) {
                version = appimage_version;
            }
            
            // Some AppImages place X-AppImage-Version in other groups or at the end
            if (version == null) {
                version = find_key_in_any_group("X-AppImage-Version");
            }
        }

        public void save(string? path = null) throws Error {
            var target_path = path ?? file_path;
            if (target_path == null) {
                throw new FileError.FAILED("No path specified for saving desktop file");
            }

            set_string("Name", name);
            set_string("Version", version);
            set_string("Exec", exec);
            set_string("Icon", icon);
            set_string("Keywords", keywords);
            set_string("Categories", categories);
            set_string("StartupWMClass", startup_wm_class);
            set_boolean("Terminal", terminal);
            set_boolean("NoDisplay", no_display);
            set_string("Actions", actions);
            
            set_string("X-AppImage-Homepage", appimage_homepage);
            set_string("X-AppImage-UpdateURL", appimage_update_url);
            set_string("X-AppImage-Version", appimage_version);

            key_file.save_to_file(target_path);
        }

        public string to_data() {
            set_string("Name", name);
            set_string("Version", version);
            set_string("Exec", exec);
            set_string("Icon", icon);
            set_string("Keywords", keywords);
            set_string("Categories", categories);
            set_string("StartupWMClass", startup_wm_class);
            set_boolean("Terminal", terminal);
            set_boolean("NoDisplay", no_display);
            set_string("Actions", actions);
            
            set_string("X-AppImage-Homepage", appimage_homepage);
            set_string("X-AppImage-UpdateURL", appimage_update_url);
            set_string("X-AppImage-Version", appimage_version);
            
            return key_file.to_data(null, null);
        }

        public void set_action_group(string action_name, string name, string exec, string icon) {
            var group = "Desktop Action %s".printf(action_name);
            key_file.set_string(group, "Name", name);
            key_file.set_string(group, "Exec", exec);
            key_file.set_string(group, "Icon", icon);
        }

        public void remove_key(string key, string group = "Desktop Entry") {
            try {
                if (key_file.has_key(group, key)) {
                    key_file.remove_key(group, key);
                }
            } catch (Error e) {}
        }

        public string? get_string(string key, string group = "Desktop Entry") {
            try {
                if (key_file.has_key(group, key)) {
                    var val = key_file.get_string(group, key);
                    return val.strip() != "" ? val.strip() : null;
                }
            } catch (Error e) {}
            return null;
        }

        public bool get_boolean(string key, string group = "Desktop Entry") {
            try {
                if (key_file.has_key(group, key)) {
                    return key_file.get_boolean(group, key);
                }
            } catch (Error e) {}
            return false;
        }

        public void set_string(string key, string? value, string group = "Desktop Entry") {
            if (value != null && value.strip() != "") {
                key_file.set_string(group, key, value.strip());
            } else {
                try {
                    if (key_file.has_key(group, key)) {
                        key_file.remove_key(group, key);
                    }
                } catch (Error e) {}
            }
        }

        public void set_boolean(string key, bool value, string group = "Desktop Entry") {
            if (value) {
                key_file.set_boolean(group, key, true);
            } else {
                // Usually false means remove the key or set to false. 
                // For NoDisplay/Terminal, default is false, so removing is cleaner.
                try {
                    if (key_file.has_key(group, key)) {
                        key_file.remove_key(group, key);
                    }
                } catch (Error e) {}
            }
        }
        
        private string? find_key_in_any_group(string key) {
            try {
                foreach (var group in key_file.get_groups()) {
                    if (key_file.has_key(group, key)) {
                        var value = key_file.get_string(group, key).strip();
                        if (value.length > 0) {
                            return value;
                        }
                    }
                }
            } catch (Error e) {
                // Ignore errors when searching
            }
            return null;
        }
        
        // Expose underlying KeyFile for advanced usage
        public KeyFile get_key_file() {
            return key_file;
        }
    }
}
