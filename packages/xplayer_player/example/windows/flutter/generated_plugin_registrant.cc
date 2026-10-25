//
//  Generated file. Do not edit.
//

// clang-format off

#include "generated_plugin_registrant.h"

#include <libmpv_xplayer/libmpv_xplayer_plugin_c_api.h>
#include <media_kit_video/media_kit_video_plugin_c_api.h>

void RegisterPlugins(flutter::PluginRegistry* registry) {
  LibmpvXplayerPluginCApiRegisterWithRegistrar(
      registry->GetRegistrarForPlugin("LibmpvXplayerPluginCApi"));
  MediaKitVideoPluginCApiRegisterWithRegistrar(
      registry->GetRegistrarForPlugin("MediaKitVideoPluginCApi"));
}
