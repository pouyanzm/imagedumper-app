#include "my_application.h"

#include <flutter_linux/flutter_linux.h>
#ifdef GDK_WINDOWING_X11
#include <gdk/gdkx.h>
#endif

#include "flutter/generated_plugin_registrant.h"
#include "network_service_linux.h"
#include <thread>
#include <chrono>
#include <atomic>

struct _MyApplication {
  GtkApplication parent_instance;
  char** dart_entrypoint_arguments;
  FlEventChannel* event_channel;
  std::thread* monitoring_thread;
  std::atomic<bool>* is_monitoring;
};

G_DEFINE_TYPE(MyApplication, my_application, GTK_TYPE_APPLICATION)

// Forward declarations
static void start_network_monitoring(MyApplication* self);
static void stop_network_monitoring(MyApplication* self);
static void send_network_update(MyApplication* self);

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
    gtk_header_bar_set_title(header_bar, "ImageDumper");
    gtk_header_bar_set_show_close_button(header_bar, TRUE);
    gtk_window_set_titlebar(window, GTK_WIDGET(header_bar));
  } else {
    gtk_window_set_title(window, "ImageDumper");
  }

  gtk_window_set_default_size(window, 1280, 720);
  gtk_widget_show(GTK_WIDGET(window));

  g_autoptr(FlDartProject) project = fl_dart_project_new();
  fl_dart_project_set_dart_entrypoint_arguments(project, self->dart_entrypoint_arguments);

  FlView* view = fl_view_new(project);
  gtk_widget_show(GTK_WIDGET(view));
  gtk_container_add(GTK_CONTAINER(window), GTK_WIDGET(view));

  fl_register_plugins(FL_PLUGIN_REGISTRY(view));

  // Set up method channel for network service
  g_autoptr(FlMethodChannel) network_channel = fl_method_channel_new(
      fl_engine_get_binary_messenger(fl_view_get_engine(view)),
      "network_service",
      FL_METHOD_CODEC(fl_standard_method_codec_new()));

  fl_method_channel_set_method_call_handler(network_channel,
      [](FlMethodChannel* channel, FlMethodCall* method_call, gpointer user_data) {
        MyApplication* app = MY_APPLICATION(user_data);
        const gchar* method = fl_method_call_get_name(method_call);
        g_autoptr(FlMethodResponse) response = nullptr;

        if (strcmp(method, "isConnectedToWifiOrEthernet") == 0) {
          bool result = NetworkServiceLinux::IsConnectedToWifiOrEthernet();
          g_autoptr(FlValue) fl_result = fl_value_new_bool(result);
          response = FL_METHOD_RESPONSE(fl_method_success_response_new(fl_result));
        } else if (strcmp(method, "getNetworkType") == 0) {
          std::string result = NetworkServiceLinux::GetNetworkType();
          g_autoptr(FlValue) fl_result = fl_value_new_string(result.c_str());
          response = FL_METHOD_RESPONSE(fl_method_success_response_new(fl_result));
        } else if (strcmp(method, "isConnected") == 0) {
          bool result = NetworkServiceLinux::IsConnected();
          g_autoptr(FlValue) fl_result = fl_value_new_bool(result);
          response = FL_METHOD_RESPONSE(fl_method_success_response_new(fl_result));
        } else if (strcmp(method, "startNetworkMonitoring") == 0) {
          start_network_monitoring(app);
          response = FL_METHOD_RESPONSE(fl_method_success_response_new(nullptr));
        } else if (strcmp(method, "stopNetworkMonitoring") == 0) {
          stop_network_monitoring(app);
          response = FL_METHOD_RESPONSE(fl_method_success_response_new(nullptr));
        } else {
          response = FL_METHOD_RESPONSE(fl_method_not_implemented_response_new());
        }

        fl_method_call_respond(method_call, response, nullptr);
      },
      self, nullptr);

  // Set up event channel
  self->event_channel = fl_event_channel_new(fl_engine_get_binary_messenger(fl_view_get_engine(view)),
      "network_service/events", FL_METHOD_CODEC(fl_standard_method_codec_new()));

  fl_event_channel_set_stream_handler(self->event_channel,
      [](FlEventChannel* channel, FlValue* arguments, gpointer user_data) -> FlMethodErrorResponse* {
        // Stream started
        return nullptr;
      },
      [](FlEventChannel* channel, FlValue* arguments, gpointer user_data) -> FlMethodErrorResponse* {
        // Stream cancelled
        return nullptr;
      },
      self, nullptr);

  gtk_widget_grab_focus(GTK_WIDGET(view));
}

// Implements GApplication::local_command_line.
static gboolean my_application_local_command_line(GApplication* application, gchar*** arguments, int* exit_status) {
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
  //MyApplication* self = MY_APPLICATION(object);

  // Perform any actions required at application startup.

  G_APPLICATION_CLASS(my_application_parent_class)->startup(application);
}

// Implements GApplication::shutdown.
static void my_application_shutdown(GApplication* application) {
  //MyApplication* self = MY_APPLICATION(object);

  // Perform any actions required at application shutdown.

  G_APPLICATION_CLASS(my_application_parent_class)->shutdown(application);
}

// Implements GObject::dispose.
static void my_application_dispose(GObject* object) {
  MyApplication* self = MY_APPLICATION(object);
  stop_network_monitoring(self);
  if (self->is_monitoring) {
    delete self->is_monitoring;
    self->is_monitoring = nullptr;
  }
  g_clear_pointer(&self->dart_entrypoint_arguments, g_strfreev);
  G_OBJECT_CLASS(my_application_parent_class)->dispose(object);
}

static void my_application_class_init(MyApplicationClass* klass) {
  G_APPLICATION_CLASS(klass)->activate = my_application_activate;
  G_APPLICATION_CLASS(klass)->local_command_line = my_application_local_command_line;
  G_APPLICATION_CLASS(klass)->startup = my_application_startup;
  G_APPLICATION_CLASS(klass)->shutdown = my_application_shutdown;
  G_OBJECT_CLASS(klass)->dispose = my_application_dispose;
}

static void my_application_init(MyApplication* self) {
  self->event_channel = nullptr;
  self->monitoring_thread = nullptr;
  self->is_monitoring = new std::atomic<bool>(false);
}

MyApplication* my_application_new() {
  // Set the program name to the application ID, which helps various systems
  // like GTK and desktop environments map this running application to its
  // corresponding .desktop file. This ensures better integration by allowing
  // the application to be recognized beyond its binary name.
  g_set_prgname(APPLICATION_ID);

  return MY_APPLICATION(g_object_new(my_application_get_type(),
                                     "application-id", APPLICATION_ID,
                                     "flags", G_APPLICATION_NON_UNIQUE,
                                     nullptr));
}

static void start_network_monitoring(MyApplication* self) {
  if (self->is_monitoring->load()) {
    return;
  }
  
  self->is_monitoring->store(true);
  
  if (self->monitoring_thread) {
    delete self->monitoring_thread;
  }
  
  self->monitoring_thread = new std::thread([self]() {
    std::string lastNetworkType = "";
    bool lastIsConnected = false;
    bool lastIsWifiOrEthernet = false;
    
    while (self->is_monitoring->load()) {
      std::string currentNetworkType = NetworkServiceLinux::GetNetworkType();
      bool currentIsConnected = NetworkServiceLinux::IsConnected();
      bool currentIsWifiOrEthernet = NetworkServiceLinux::IsConnectedToWifiOrEthernet();
      
      // Check if network state changed
      if (currentNetworkType != lastNetworkType || 
          currentIsConnected != lastIsConnected ||
          currentIsWifiOrEthernet != lastIsWifiOrEthernet) {
        
        lastNetworkType = currentNetworkType;
        lastIsConnected = currentIsConnected;
        lastIsWifiOrEthernet = currentIsWifiOrEthernet;
        
        send_network_update(self);
      }
      
      std::this_thread::sleep_for(std::chrono::milliseconds(1000)); // Check every second
    }
  });
  
  // Send initial state
  send_network_update(self);
}

static void stop_network_monitoring(MyApplication* self) {
  if (self->is_monitoring && self->is_monitoring->load()) {
    self->is_monitoring->store(false);
    if (self->monitoring_thread && self->monitoring_thread->joinable()) {
      self->monitoring_thread->join();
      delete self->monitoring_thread;
      self->monitoring_thread = nullptr;
    }
  }
}

static void send_network_update(MyApplication* self) {
  if (self->event_channel) {
    g_autoptr(FlValue) network_data = fl_value_new_map();
    
    fl_value_set_string_take(network_data, "isConnected", 
        fl_value_new_bool(NetworkServiceLinux::IsConnected()));
    fl_value_set_string_take(network_data, "isWifiOrEthernet", 
        fl_value_new_bool(NetworkServiceLinux::IsConnectedToWifiOrEthernet()));
    fl_value_set_string_take(network_data, "networkType", 
        fl_value_new_string(NetworkServiceLinux::GetNetworkType().c_str()));
    fl_value_set_string_take(network_data, "timestamp", 
        fl_value_new_int(static_cast<int64_t>(std::chrono::duration_cast<std::chrono::milliseconds>(
            std::chrono::system_clock::now().time_since_epoch()).count())));
    
    fl_event_channel_send(self->event_channel, network_data, nullptr, nullptr, nullptr);
  }
}
