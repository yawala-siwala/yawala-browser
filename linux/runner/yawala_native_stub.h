// linux/runner/yawala_native_stub.h - Safe-fallback method-channel stubs for
// Yawala Browser on the Linux (GTK) runner.
//
// Call yawala_register_browser_stub() from my_application_activate() right
// after the FlView is created (see my_application.cc once the runner is
// generated with `flutter create . --platforms=linux`).
#pragma once

#include <flutter_linux/flutter_linux.h>

G_BEGIN_DECLS

/// Registers safe-fallback handlers for the Yawala Browser channel on [view].
void yawala_register_browser_stub(FlView* view);

G_END_DECLS
