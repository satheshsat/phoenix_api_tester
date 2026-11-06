#include "my_application.h"

#include <flutter_linux/flutter_linux.h>
#ifdef GDK_WINDOWING_X11
#include <gdk/gdkx.h>
#endif

#include "flutter/generated_plugin_registrant.h"

struct _MyApplication {
  GtkApplication parent_instance;
  char** dart_entrypoint_arguments;
};

G_DEFINE_TYPE(MyApplication, my_application, GTK_TYPE_APPLICATION)

static void setup_window_icon(GtkWindow* window);

// Called when first Flutter frame received.
static void first_frame_cb(MyApplication* self, FlView* view) {
  GtkWindow* window = GTK_WINDOW(gtk_widget_get_toplevel(GTK_WIDGET(view)));
  gtk_widget_show(GTK_WIDGET(window));
  setup_window_icon(window);
}

// Sets the window icon for the application.
static void setup_window_icon(GtkWindow* window) {
  // Ensure application ID and prgname are configured.
  g_set_prgname(APPLICATION_ID);
#ifdef GDK_WINDOWING_X11
  gdk_set_program_class(APPLICATION_ID);
#endif

  // Set the icon name matching the application ID (phoenix.api.tester).
  gtk_window_set_icon_name(window, APPLICATION_ID);
  gtk_window_set_default_icon_name(APPLICATION_ID);

  // 1. Try loading directly from the bundle relative to the executable.
  g_autofree gchar* exe_path = g_file_read_link("/proc/self/exe", nullptr);
  g_autofree gchar* exe_dir = nullptr;
  if (exe_path != nullptr) {
    exe_dir = g_path_get_dirname(exe_path);
  }

  // Register bundle icon directories with default GtkIconTheme
  GtkIconTheme* theme = gtk_icon_theme_get_default();
  if (exe_dir != nullptr && theme != nullptr) {
    g_autofree gchar* data_icons = g_build_filename(exe_dir, "data", "icons", nullptr);
    if (g_file_test(data_icons, G_FILE_TEST_IS_DIR)) {
      gtk_icon_theme_append_search_path(theme, data_icons);
    }
    g_autofree gchar* share_icons = g_build_filename(exe_dir, "share", "icons", nullptr);
    if (g_file_test(share_icons, G_FILE_TEST_IS_DIR)) {
      gtk_icon_theme_append_search_path(theme, share_icons);
    }
    g_autofree gchar* data_dir = g_build_filename(exe_dir, "data", nullptr);
    if (g_file_test(data_dir, G_FILE_TEST_IS_DIR)) {
      gtk_icon_theme_append_search_path(theme, data_dir);
    }
  }

  // Search candidate paths for the icon image
  const gchar* rel_paths[] = {
    "data/app_icon.png",
    "data/flutter_assets/assets/icon/icon.png",
    "data/flutter_assets/assets/icon/icon.jpg",
    "runner/resources/app_icon.png",
    "assets/icon/icon.png",
    "assets/icon/icon.jpg",
    "app_icon.png"
  };

  g_autoptr(GdkPixbuf) base_pixbuf = nullptr;

  if (exe_dir != nullptr) {
    for (const gchar* rel_path : rel_paths) {
      g_autofree gchar* full_path = g_build_filename(exe_dir, rel_path, nullptr);
      if (g_file_test(full_path, G_FILE_TEST_EXISTS)) {
        base_pixbuf = gdk_pixbuf_new_from_file(full_path, nullptr);
        if (base_pixbuf != nullptr) {
          break;
        }
      }
    }
  }

  // 2. Fallback: check standard user/system icon directories.
  if (base_pixbuf == nullptr) {
    const gchar* home_dir = g_get_home_dir();
    if (home_dir != nullptr) {
      const gchar* sizes[] = {"512x512", "256x256", "128x128", "64x64", "48x48", "32x32", "16x16"};
      for (const gchar* size_str : sizes) {
        g_autofree gchar* user_icon = g_build_filename(
            home_dir, ".local", "share", "icons", "hicolor", size_str, "apps",
            APPLICATION_ID ".png", nullptr);
        if (g_file_test(user_icon, G_FILE_TEST_EXISTS)) {
          base_pixbuf = gdk_pixbuf_new_from_file(user_icon, nullptr);
          if (base_pixbuf != nullptr) {
            break;
          }
        }
      }
    }
  }

  // 3. Fallback: check working directory for development runs.
  if (base_pixbuf == nullptr) {
    const gchar* dev_paths[] = {
      "linux/runner/resources/app_icon.png",
      "assets/icon/icon.png",
      "../assets/icon/icon.png",
      "../../assets/icon/icon.png"
    };
    for (const gchar* dev_path : dev_paths) {
      if (g_file_test(dev_path, G_FILE_TEST_EXISTS)) {
        base_pixbuf = gdk_pixbuf_new_from_file(dev_path, nullptr);
        if (base_pixbuf != nullptr) {
          break;
        }
      }
    }
  }

  // Set the icon on window with multiple scaled resolutions (16 to 512)
  if (base_pixbuf != nullptr) {
    GList* icon_list = nullptr;
    const int target_sizes[] = {16, 24, 32, 48, 64, 128, 256, 512};
    for (int s : target_sizes) {
      GdkPixbuf* scaled = gdk_pixbuf_scale_simple(
          base_pixbuf, s, s, GDK_INTERP_BILINEAR);
      if (scaled != nullptr) {
        icon_list = g_list_append(icon_list, scaled);
      }
    }
    icon_list = g_list_append(icon_list, g_object_ref(base_pixbuf));

    gtk_window_set_icon_list(window, icon_list);
    gtk_window_set_default_icon_list(icon_list);

    g_list_free_full(icon_list, g_object_unref);
  }
}

// Implements GApplication::activate.
static void my_application_activate(GApplication* application) {
  MyApplication* self = MY_APPLICATION(application);
  GtkWindow* window =
      GTK_WINDOW(gtk_application_window_new(GTK_APPLICATION(application)));

  // Use a header bar when running in GNOME as this is the common style used
  // by applications and is the setup most users will be using (e.g. Ubuntu
  // desktop).
  // If running on X and not using GNOME then just use a traditional title bar
  // in case the window manager does more exotic layout, e.g. tiling.
  // If running on Wayland assume the header bar will work (may need changing
  // if future cases occur).
  gboolean use_header_bar = TRUE;
#ifdef GDK_WINDOWING_X11
  GdkScreen* screen = gtk_window_get_screen(window);
  if (GDK_IS_X11_SCREEN(screen)) {
    const gchar* wm_name = gdk_x11_screen_get_window_manager_name(screen);
    if (g_strcmp0(wm_name, "GNOME Shell") != 0) {
      use_header_bar = FALSE;
    }
  }
#endif
  if (use_header_bar) {
    GtkHeaderBar* header_bar = GTK_HEADER_BAR(gtk_header_bar_new());
    gtk_widget_show(GTK_WIDGET(header_bar));
    gtk_header_bar_set_title(header_bar, "Phoenix Api Tester");
    gtk_header_bar_set_show_close_button(header_bar, TRUE);
    gtk_window_set_titlebar(window, GTK_WIDGET(header_bar));
  } else {
    gtk_window_set_title(window, "Phoenix Api Tester");
  }

  gtk_window_set_default_size(window, 1280, 720);
  setup_window_icon(window);

  g_autoptr(FlDartProject) project = fl_dart_project_new();
  fl_dart_project_set_dart_entrypoint_arguments(
      project, self->dart_entrypoint_arguments);

  FlView* view = fl_view_new(project);
  GdkRGBA background_color;
  // Background defaults to black, override it here if necessary, e.g. #00000000
  // for transparent.
  gdk_rgba_parse(&background_color, "#000000");
  fl_view_set_background_color(view, &background_color);
  gtk_widget_show(GTK_WIDGET(view));
  gtk_container_add(GTK_CONTAINER(window), GTK_WIDGET(view));

  // Show the window when Flutter renders.
  // Requires the view to be realized so we can start rendering.
  g_signal_connect_swapped(view, "first-frame", G_CALLBACK(first_frame_cb),
                           self);
  gtk_widget_realize(GTK_WIDGET(view));

  fl_register_plugins(FL_PLUGIN_REGISTRY(view));

  gtk_widget_grab_focus(GTK_WIDGET(view));
}

// Implements GApplication::local_command_line.
static gboolean my_application_local_command_line(GApplication* application,
                                                  gchar*** arguments,
                                                  int* exit_status) {
  MyApplication* self = MY_APPLICATION(application);
  // Strip out the first argument as it is the binary name.
  self->dart_entrypoint_arguments = g_strdupv(*arguments + 1);

  g_autoptr(GError) error = nullptr;
  if (!g_application_register(application, nullptr, &error)) {
    g_warning("Failed to register: %s", error->message);
    *exit_status = 1;
    return TRUE;
  }

  g_application_activate(application);
  *exit_status = 0;

  return TRUE;
}

// Implements GApplication::startup.
static void my_application_startup(GApplication* application) {
  // MyApplication* self = MY_APPLICATION(object);

  // Perform any actions required at application startup.

  G_APPLICATION_CLASS(my_application_parent_class)->startup(application);
}

// Implements GApplication::shutdown.
static void my_application_shutdown(GApplication* application) {
  // MyApplication* self = MY_APPLICATION(object);

  // Perform any actions required at application shutdown.

  G_APPLICATION_CLASS(my_application_parent_class)->shutdown(application);
}

// Implements GObject::dispose.
static void my_application_dispose(GObject* object) {
  MyApplication* self = MY_APPLICATION(object);
  g_clear_pointer(&self->dart_entrypoint_arguments, g_strfreev);
  G_OBJECT_CLASS(my_application_parent_class)->dispose(object);
}

static void my_application_class_init(MyApplicationClass* klass) {
  G_APPLICATION_CLASS(klass)->activate = my_application_activate;
  G_APPLICATION_CLASS(klass)->local_command_line =
      my_application_local_command_line;
  G_APPLICATION_CLASS(klass)->startup = my_application_startup;
  G_APPLICATION_CLASS(klass)->shutdown = my_application_shutdown;
  G_OBJECT_CLASS(klass)->dispose = my_application_dispose;
}

static void my_application_init(MyApplication* self) {}

MyApplication* my_application_new() {
  // Set the program name to the application ID, which helps various systems
  // like GTK and desktop environments map this running application to its
  // corresponding .desktop file. This ensures better integration by allowing
  // the application to be recognized beyond its binary name.
  g_set_prgname(APPLICATION_ID);

  return MY_APPLICATION(g_object_new(my_application_get_type(),
                                     "application-id", APPLICATION_ID, "flags",
                                     G_APPLICATION_NON_UNIQUE, nullptr));
}
