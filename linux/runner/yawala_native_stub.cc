#include "yawala_native_stub.h"

#include <flutter_linux/flutter_linux.h>

static const gchar kBrowserChannelName[] = "com.yawalasiwala/browser";

// Resolves every browser method to a safe fallback so the Dart gateway
// always receives a well-formed response on Linux.
static void browser_method_call_cb(FlMethodChannel* channel,
                                   FlMethodCall* method_call,
                                   gpointer user_data) {
  const gchar* method = fl_method_call_get_name(method_call);
  g_autoptr(FlMethodResponse) response = nullptr;

  if (g_strcmp0(method, "openCustomTab") == 0) {
    response = FL_METHOD_RESPONSE(
        fl_method_success_response_new(fl_value_new_bool(FALSE)));
  } else if (g_strcmp0(method, "createWebViewController") == 0 ||
             g_strcmp0(method, "navigate") == 0 ||
             g_strcmp0(method, "clearCookiesAndCache") == 0) {
    response = FL_METHOD_RESPONSE(
        fl_method_success_response_new(fl_value_new_null()));
  } else {
    response =
        FL_METHOD_RESPONSE(fl_method_not_implemented_response_new());
  }

  g_autoptr(GError) error = nullptr;
  fl_method_call_respond(method_call, response, &error);
}

void yawala_register_browser_stub(FlView* view) {
  // Keep the channel alive for the process lifetime; re-registration is a
  // no-op so hot restarts stay safe.
  static FlMethodChannel* channel = nullptr;
  if (channel != nullptr) {
    return;
  }
  channel = fl_method_channel_new(fl_view_get_binary_messenger(view),
                                  kBrowserChannelName,
                                  FL_METHOD_CODEC(fl_standard_method_codec_new()));
  fl_method_channel_set_method_call_handler(channel, browser_method_call_cb,
                                            nullptr, nullptr);
}
