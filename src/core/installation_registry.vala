using Gee;

namespace AppManager.Core {
    public class InstallationRegistry : Object {
        private HashTable<string, InstallationRecord> records;
        private File registry_file;
        public signal void changed();

        public InstallationRegistry() {
            records = new HashTable<string, InstallationRecord>(GLib.str_hash, GLib.str_equal);
            registry_file = File.new_for_path(AppPaths.registry_file);
            load();
        }

        public InstallationRecord[] list() {
            var list = new ArrayList<InstallationRecord>();
            foreach (var record in records.get_values()) {
                list.add(record);
            }
            return list.to_array();
        }

        public bool is_installed_checksum(string checksum) {
            return lookup_by_checksum(checksum) != null;
        }

        public InstallationRecord? lookup_by_checksum(string checksum) {
            foreach (var record in records.get_values()) {
                if (record.source_checksum == checksum) {
                    return record;
                }
            }
            return null;
        }

        public InstallationRecord? lookup_by_installed_path(string path) {
            foreach (var record in records.get_values()) {
                if (record.installed_path == path) {
                    return record;
                }
            }
            return null;
        }

        public InstallationRecord? lookup_by_source(string path) {
            foreach (var record in records.get_values()) {
                if (record.source_path == path) {
                    return record;
                }
            }
            return null;
        }

        public void register(InstallationRecord record) {
            records.insert(record.id, record);
            save();
            notify_changed();
        }

        public void unregister(string id) {
            records.remove(id);
            save();
            notify_changed();
        }

        public void persist(bool notify = true) {
            save();
            if (notify) {
                notify_changed();
            }
        }

        /**
         * Reconciles the registry with the filesystem.
         * Removes registry entries for apps that no longer exist on disk
         * and cleans up their desktop files, icons, and symlinks.
         * Returns the list of orphaned records that were cleaned up.
         */
        public Gee.ArrayList<InstallationRecord> reconcile_with_filesystem() {
            var orphaned = new Gee.ArrayList<InstallationRecord>();
            var records_to_remove = new Gee.ArrayList<string>();
            
            foreach (var record in records.get_values()) {
                var installed_file = File.new_for_path(record.installed_path);
                if (!installed_file.query_exists()) {
                    debug("Found orphaned record: %s (path: %s)", record.name, record.installed_path);
                    orphaned.add(record);
                    records_to_remove.add(record.id);
                    
                    // Clean up associated files
                    cleanup_record_files(record);
                }
            }
            
            // Remove orphaned records from registry
            foreach (var id in records_to_remove) {
                records.remove(id);
            }
            
            if (records_to_remove.size > 0) {
                save();
                notify_changed();
            }
            
            return orphaned;
        }

        private void cleanup_record_files(InstallationRecord record) {
            try {
                // Clean up desktop file
                if (record.desktop_file != null) {
                    var desktop_file = File.new_for_path(record.desktop_file);
                    if (desktop_file.query_exists()) {
                        desktop_file.delete(null);
                        debug("Cleaned up desktop file: %s", record.desktop_file);
                    }
                }
                
                // Clean up icon
                if (record.icon_path != null) {
                    var icon_file = File.new_for_path(record.icon_path);
                    if (icon_file.query_exists()) {
                        icon_file.delete(null);
                        debug("Cleaned up icon: %s", record.icon_path);
                    }
                }
                
                // Clean up bin symlink
                if (record.bin_symlink != null) {
                    var symlink_file = File.new_for_path(record.bin_symlink);
                    if (symlink_file.query_exists()) {
                        symlink_file.delete(null);
                        debug("Cleaned up bin symlink: %s", record.bin_symlink);
                    }
                }
            } catch (Error e) {
                warning("Failed to cleanup files for orphaned record %s: %s", record.name, e.message);
            }
        }

        private void load() {
            if (!registry_file.query_exists(null)) {
                return;
            }
            try {
                var path = registry_file.get_path();
                if (path == null) {
                    return;
                }
                string contents;
                if (!GLib.FileUtils.get_contents(path, out contents)) {
                    warning("Failed to read registry file %s", path);
                    return;
                }
                var parser = new Json.Parser();
                parser.load_from_data(contents, contents.length);
                var root = parser.get_root();
                if (root != null && root.get_node_type() == Json.NodeType.ARRAY) {
                    foreach (var node in root.get_array().get_elements()) {
                        if (node.get_node_type() == Json.NodeType.OBJECT) {
                            var obj = node.get_object();
                            var record = InstallationRecord.from_json(obj);
                            records.insert(record.id, record);
                        }
                    }
                }
            } catch (Error e) {
                warning("Failed to load registry: %s", e.message);
            }
        }

        private void save() {
            try {
                var builder = new Json.Builder();
                builder.begin_array();
                foreach (var record in records.get_values()) {
                    builder.add_value(record.to_json());
                }
                builder.end_array();
                var generator = new Json.Generator();
                generator.set_root(builder.get_root());
                var json = generator.to_data(null);
                FileUtils.set_contents(registry_file.get_path(), json);
            } catch (Error e) {
                warning("Failed to save registry: %s", e.message);
            }
        }

        private void notify_changed() {
            GLib.Idle.add(() => {
                changed();
                return GLib.Source.REMOVE;
            });
        }
    }
}
