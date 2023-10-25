#ifndef FLUTTER_PLUGIN_MODBUS_ACTION_POWER_PLUGIN_H_
#define FLUTTER_PLUGIN_MODBUS_ACTION_POWER_PLUGIN_H_

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>

#include <memory>

namespace modbus_action_power {

class ModbusActionPowerPlugin : public flutter::Plugin {
 public:
  static void RegisterWithRegistrar(flutter::PluginRegistrarWindows *registrar);

  ModbusActionPowerPlugin();

  virtual ~ModbusActionPowerPlugin();

  // Disallow copy and assign.
  ModbusActionPowerPlugin(const ModbusActionPowerPlugin&) = delete;
  ModbusActionPowerPlugin& operator=(const ModbusActionPowerPlugin&) = delete;

  // Called when a method is called on this plugin's channel from Dart.
  void HandleMethodCall(
      const flutter::MethodCall<flutter::EncodableValue> &method_call,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);
};

}  // namespace modbus_action_power

#endif  // FLUTTER_PLUGIN_MODBUS_ACTION_POWER_PLUGIN_H_
