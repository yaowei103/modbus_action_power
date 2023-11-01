//
//  Generated file. Do not edit.
//

// clang-format off

#include "generated_plugin_registrant.h"

#include <flutter_libserialport/flutter_libserialport_plugin.h>
#include <modbus_action_power/modbus_action_power_plugin_c_api.h>

void RegisterPlugins(flutter::PluginRegistry* registry) {
  FlutterLibserialportPluginRegisterWithRegistrar(
      registry->GetRegistrarForPlugin("FlutterLibserialportPlugin"));
  ModbusActionPowerPluginCApiRegisterWithRegistrar(
      registry->GetRegistrarForPlugin("ModbusActionPowerPluginCApi"));
}
