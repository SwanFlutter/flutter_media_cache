//
//  Generated file. Do not edit.
//

// clang-format off

#include "generated_plugin_registrant.h"

#include <path_provider_master/path_provider_master_plugin.h>

void fl_register_plugins(FlPluginRegistry* registry) {
  g_autoptr(FlPluginRegistrar) path_provider_master_registrar =
      fl_plugin_registry_get_registrar_for_plugin(registry, "PathProviderMasterPlugin");
  path_provider_master_plugin_register_with_registrar(path_provider_master_registrar);
}
