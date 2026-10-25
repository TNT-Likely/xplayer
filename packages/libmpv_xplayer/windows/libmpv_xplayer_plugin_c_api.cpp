#include "include/libmpv_xplayer/libmpv_xplayer_plugin_c_api.h"

#include <iostream>

#include <flutter/plugin_registrar_windows.h>

void LibmpvXplayerPluginCApiRegisterWithRegistrar(FlutterDesktopPluginRegistrarRef registrar) {
  std::cout << "package:libmpv_xplayer registered." << std::endl;
}
