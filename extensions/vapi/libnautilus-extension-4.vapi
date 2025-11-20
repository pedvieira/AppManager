[CCode (cprefix = "Nautilus", lower_case_cprefix = "nautilus_", cheader_filename = "nautilus/nautilus-extension.h")]
namespace Nautilus {
    [CCode (cheader_filename = "nautilus/nautilus-extension.h", type_id = "NAUTILUS_TYPE_MENU_PROVIDER", type_cname = "NautilusMenuProviderInterface")]
    public interface MenuProvider : GLib.Object {
        [CCode (array_length = false, array_null_terminated = false, type = "GList*")]
        public abstract GLib.List<MenuItem> get_file_items(Gtk.Widget? window, [CCode (type = "GList*")] GLib.List<FileInfo> files);

        [CCode (array_length = false, array_null_terminated = false, type = "GList*")]
        public abstract GLib.List<MenuItem> get_background_items(Gtk.Widget? window, FileInfo current_folder);
    }

    [CCode (cheader_filename = "nautilus/nautilus-extension.h", type_id = "NAUTILUS_TYPE_MENU_ITEM")]
    public class MenuItem : GLib.Object {
        [CCode (has_construct_function = false)]
        public MenuItem(string name, string label, string tip, string? icon);

        public signal void activate();
    }

    [CCode (cheader_filename = "nautilus/nautilus-extension.h", type_id = "NAUTILUS_TYPE_FILE_INFO")]
    public class FileInfo : GLib.Object {
        public GLib.File? get_location();
        public string? get_uri();
    }
}
