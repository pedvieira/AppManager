using Nautilus;
using AppManager.Core;
using AppManager.Utils;

namespace AppManager.Extensions {
    public class NautilusExtension : Object, Nautilus.MenuProvider {
        private InstallationRegistry registry;

        public NautilusExtension() {
            registry = new InstallationRegistry();
        }

    public GLib.List<Nautilus.MenuItem> get_file_items(Gtk.Widget? window, GLib.List<Nautilus.FileInfo> files) {
            var items = new GLib.List<Nautilus.MenuItem>();
            if (files == null || files.length() != 1) {
                return items;
            }
            var file = files.nth_data(0);
            if (file == null) {
                return items;
            }

            var gfile = file.get_location();
            if (gfile == null || gfile.get_path() == null) {
                return items;
            }
            var path = gfile.get_path();
            if (!path.down().has_suffix(".appimage")) {
                return items;
            }

            bool installed = false;
            try {
                var checksum = Utils.FileUtils.compute_checksum(path);
                installed = registry.is_installed_checksum(checksum);
            } catch (Error e) {
                warning("Failed to compute checksum for Nautilus menu: %s", e.message);
            }

            if (!installed) {
                var install_item = new Nautilus.MenuItem("appmanager-install", I18n.tr("Install AppImage"), I18n.tr("Install using AppManager"), null);
                install_item.activate.connect(() => {
                    run_cli({"--install", path});
                });
                items.append(install_item);
            } else {
                var trash_item = new Nautilus.MenuItem("appmanager-trash", I18n.tr("Move AppImage to Trash"), I18n.tr("Uninstall using AppManager"), null);
                trash_item.activate.connect(() => {
                    run_cli({"--uninstall", path});
                });
                items.append(trash_item);
            }

            return items;
        }

        public GLib.List<Nautilus.MenuItem> get_background_items(Gtk.Widget? window, Nautilus.FileInfo current_folder) {
            return new GLib.List<Nautilus.MenuItem>();
        }

        private void run_cli(string[] args) {
            var argv = new string[1 + args.length];
            argv[0] = "app-manager";
            for (int i = 0; i < args.length; i++) {
                argv[i + 1] = args[i];
            }
            try {
                GLib.Pid child_pid;
                Process.spawn_async(null, argv, null, SpawnFlags.SEARCH_PATH, null, out child_pid);
            } catch (Error e) {
                warning("Failed to launch CLI: %s", e.message);
            }
        }
    }
}
