#include "include/modbus_action_power/modbus_action_power_plugin_c_api.h"

#include <flutter/plugin_registrar_windows.h>

#include "modbus_action_power_plugin.h"

void ModbusActionPowerPluginCApiRegisterWithRegistrar(
    FlutterDesktopPluginRegistrarRef registrar) {
  modbus_action_power::ModbusActionPowerPlugin::RegisterWithRegistrar(
      flutter::PluginRegistrarManager::GetInstance()
          ->GetRegistrar<flutter::PluginRegistrarWindows>(registrar));
}
