import 'package:flutter_test/flutter_test.dart';
import 'package:modbus_action_power/modbus_action_power.dart';
import 'package:modbus_action_power/modbus_action_power_method_channel.dart';
import 'package:modbus_action_power/modbus_action_power_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockModbusActionPowerPlatform with MockPlatformInterfaceMixin implements ModbusActionPowerPlatform {
  @override
  Future<String?> getPlatformVersion() => Future.value('42');
}

void main() {
  final ModbusActionPowerPlatform initialPlatform = ModbusActionPowerPlatform.instance;

  test('$MethodChannelModbusActionPower is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelModbusActionPower>());
  });

  test('getPlatformVersion', () async {
    ModbusActionPower modbusActionPowerPlugin = ModbusActionPower();
    MockModbusActionPowerPlatform fakePlatform = MockModbusActionPowerPlatform();
    ModbusActionPowerPlatform.instance = fakePlatform;

    // expect(await modbusActionPowerPlugin.getPlatformVersion(), '42');
  });
}
