namespace AppManager.Utils {
    public class FileUtils {
        public static string compute_checksum(string path) throws Error {
            var checksum = new GLib.Checksum(GLib.ChecksumType.SHA256);
            var stream = File.new_for_path(path).read();
            var buffer = new uint8[64 * 1024];
            ssize_t read = 0;
            while ((read = stream.read(buffer, null)) > 0) {
                checksum.update(buffer, (size_t)read);
            }
            stream.close();
            return checksum.get_string();
        }

        public static void ensure_parent(string path) throws Error {
            var parent = Path.get_dirname(path);
            if (parent == null || parent == ".") {
                return;
            }
            DirUtils.create_with_parents(parent, 0755);
        }

        public static string unique_path(string desired_path) {
            if (!File.new_for_path(desired_path).query_exists()) {
                return desired_path;
            }
            var dir = Path.get_dirname(desired_path);
            var filename = Path.get_basename(desired_path);
            var stem = filename;
            var ext = "";
            var dot = filename.last_index_of_char('.');
            if (dot > 0) {
                stem = filename.substring(0, dot);
                ext = filename.substring(dot);
            }
            for (int i = 1; i < 1000; i++) {
                var candidate = Path.build_filename(dir, "%s-%d%s".printf(stem, i, ext));
                if (!File.new_for_path(candidate).query_exists()) {
                    return candidate;
                }
            }
            return desired_path;
        }

        public static string create_temp_dir(string prefix) throws Error {
            var template = prefix + "XXXXXX";
            return DirUtils.mkdtemp(template);
        }

        public static void file_copy(string source_path, string dest_path) throws Error {
            ensure_parent(dest_path);
            var src = File.new_for_path(source_path);
            var dest = File.new_for_path(dest_path);
            src.copy(dest, FileCopyFlags.OVERWRITE, null, null);
        }

        public static void remove_dir_recursive(string path) {
            try {
                if (!File.new_for_path(path).query_exists()) {
                    return;
                }
                var enumerator = File.new_for_path(path).enumerate_children("standard::name", FileQueryInfoFlags.NONE);
                FileInfo info;
                while ((info = enumerator.next_file()) != null) {
                    var child = enumerator.get_child(info);
                    if (info.get_file_type() == FileType.DIRECTORY) {
                        remove_dir_recursive(child.get_path());
                    } else {
                        child.delete(null);
                    }
                }
                File.new_for_path(path).delete(null);
            } catch (Error e) {
                warning("Failed to delete %s: %s", path, e.message);
            }
        }
    }
}
