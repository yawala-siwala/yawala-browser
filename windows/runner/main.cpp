// windows/runner/main.cpp - Windows runner bootstrap stub.
//
// The full generated runner (flutter create . --platforms=windows) owns the
// Win32 + FlutterWindow bootstrap; this committed stub documents the bundle
// identity and links the safe-fallback response table from
// yawala_native_stub.h until the runner integration lands.
//   ProductName:   Yawala Browser
//   InternalName:  com.yawalasiwala.browser
//   CompanyName:   Yawala-Siwala
#include <windows.h>

#include "yawala_native_stub.h"

int APIENTRY wWinMain(HINSTANCE, HINSTANCE, PWSTR, int) {
  // Smoke-exercise the stub table so the linker keeps it and CI proves the
  // binary links; real channel wiring arrives with the generated runner.
  const std::string probe = yawala_stub::responseFor("openCustomTab");
  OutputDebugStringA(probe.c_str());
  return 0;
}
