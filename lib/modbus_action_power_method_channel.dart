import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'modbus_action_power_platform_interface.dart';

/// An implementation of [ModbusActionPowerPlatform] that uses method channels.
class MethodChannelModbusActionPower extends ModbusActionPowerPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('modbus_action_power');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }
}
