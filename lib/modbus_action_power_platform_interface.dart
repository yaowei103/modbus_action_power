import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'modbus_action_power_method_channel.dart';

abstract class ModbusActionPowerPlatform extends PlatformInterface {
  /// Constructs a ModbusActionPowerPlatform.
  ModbusActionPowerPlatform() : super(token: _token);

  static final Object _token = Object();

  static ModbusActionPowerPlatform _instance = MethodChannelModbusActionPower();

  /// The default instance of [ModbusActionPowerPlatform] to use.
  ///
  /// Defaults to [MethodChannelModbusActionPower].
  static ModbusActionPowerPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [ModbusActionPowerPlatform] when
  /// they register themselves.
  static set instance(ModbusActionPowerPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }
}
