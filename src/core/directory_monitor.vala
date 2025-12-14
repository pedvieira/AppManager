namespace AppManager.Core {
    /**
     * Monitors the Applications directory and extracted apps directory
     * for manual file deletions and changes.
     */
    public class DirectoryMonitor : Object {
        private FileMonitor? applications_monitor;
        private FileMonitor? extracted_monitor;
        private InstallationRegistry registry;
        
        public signal void app_deleted(string path);
        public signal void changes_detected();
        
        public DirectoryMonitor(InstallationRegistry registry) {
            this.registry = registry;
        }
        
        public void start() {
            try {
                // Monitor ~/Applications directory
                var applications_dir = File.new_for_path(AppPaths.applications_dir);
                applications_monitor = applications_dir.monitor_directory(
                    FileMonitorFlags.NONE,
                    null
                );
                applications_monitor.changed.connect(on_applications_changed);
                
                // Monitor ~/Applications/.extracted directory
                var extracted_dir = File.new_for_path(AppPaths.extracted_root);
                extracted_monitor = extracted_dir.monitor_directory(
                    FileMonitorFlags.NONE,
                    null
                );
                extracted_monitor.changed.connect(on_extracted_changed);
                
                debug("Directory monitoring started");
            } catch (Error e) {
                warning("Failed to start directory monitoring: %s", e.message);
            }
        }
        
        public void stop() {
            if (applications_monitor != null) {
                applications_monitor.cancel();
                applications_monitor = null;
            }
            if (extracted_monitor != null) {
                extracted_monitor.cancel();
                extracted_monitor = null;
            }
            debug("Directory monitoring stopped");
        }
        
        private void on_applications_changed(File file, File? other_file, FileMonitorEvent event_type) {
            if (event_type != FileMonitorEvent.DELETED && event_type != FileMonitorEvent.MOVED_OUT) {
                return;
            }
            
            var path = file.get_path();
            if (path == null) {
                return;
            }
            
            // Check if this file is in the registry as a PORTABLE installation
            var record = registry.lookup_by_installed_path(path);
            if (record != null && record.mode == InstallMode.PORTABLE) {
                debug("Detected manual deletion of portable app: %s", path);
                app_deleted(path);
                changes_detected();
            }
        }
        
        private void on_extracted_changed(File file, File? other_file, FileMonitorEvent event_type) {
            if (event_type != FileMonitorEvent.DELETED && event_type != FileMonitorEvent.MOVED_OUT) {
                return;
            }
            
            var path = file.get_path();
            if (path == null) {
                return;
            }
            
            // For extracted apps, we need to check if the parent directory was deleted
            // The installed_path points to the extracted directory
            foreach (var record in registry.list()) {
                if (record.mode == InstallMode.EXTRACTED) {
                    // Check if the deleted path is part of this record's installation
                    if (path.has_prefix(record.installed_path) || path == record.installed_path) {
                        debug("Detected manual deletion of extracted app: %s", record.name);
                        app_deleted(record.installed_path);
                        changes_detected();
                        break;
                    }
                }
            }
        }
    }
}
