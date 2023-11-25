import 'package:flutter/material.dart';
import 'package:modbus_action_power/src/ModbusMaster.dart';
import 'package:modbus_action_power/entity/ReturnEntity.dart';
export 'entity/ReturnEntity.dart';

class ModbusActionPower {
  late ModbusMaster master;
  late ModbusMaster master485;

  late Future<ReturnEntity> _initialization; // 延迟初始化一个Future对象
  ModbusActionPower._(); // 私有构造函数，用于工厂构造函数

  factory ModbusActionPower({required String filePath, required String filePath485}) {
    final instance = ModbusActionPower._();
    // 在工厂构造函数中调用init方法并赋值给延迟初始化的Future对象
    instance._initialization = instance.initModbus(filePath: filePath, filePath485: filePath485);
    return instance;
  }

  Future<ReturnEntity> initDone() {
    return _initialization; // 返回延迟初始化的Future对象
  }

  Future<ReturnEntity> initModbus({required String filePath, required String filePath485}) async {
    ReturnEntity returnEntity = ReturnEntity();
    try {
      master = ModbusMaster();
      await master.initMaster(filePath);
      await Future.delayed(const Duration(milliseconds: 200));
      master485 = ModbusMaster();
      await master485.initMaster(filePath485);
    } catch (e) {
      returnEntity.status = -1;
      returnEntity.message = 'init modbus error: ${e.toString()}';
    }
    debugPrint('init success');
    return returnEntity;
  }

  Future<ReturnEntity> disConnect() async {
    ReturnEntity returnEntity = ReturnEntity();
    if (master.modbusClientRtu.isConnected) {
      master.modbusClientRtu.disconnect();
    }
    if (master485.modbusClientRtu.isConnected) {
      master485.modbusClientRtu.disconnect();
    }
    if (!master.modbusClientRtu.isConnected && !master485.modbusClientRtu.isConnected) {
      debugPrint('----disConnect done----');
      returnEntity.status = 0;
    } else {
      debugPrint('----disConnect error, please retry----');
      returnEntity.status = -1;
      returnEntity.message = 'disConnect error, try again!';
    }
    return returnEntity;
  }

  /// 03功能码获取数据
  /// String startRegAddr 起始地址
  /// String dataCount 寄存器个数
  /// Duration customTimeout 单包超时时间
  Future<ReturnEntity> getData({required String startRegAddr, required String dataCount, Duration? customTimeout}) async {
    // req_21504_3001
    Stopwatch sw = Stopwatch()..start();
    ReturnEntity res = await master.getRegister(index: '1', startRegAddr: startRegAddr, dataCount: dataCount, customTimeout: customTimeout); // 3072_54
    debugPrint('===get $startRegAddr, $dataCount');
    debugPrint('===get result: ${res.status == 0 ? res.data : res.message}');
    debugPrint('===time: ${(sw..stop()).elapsedMilliseconds}');
    return res;
  }

  /// 06/10功能码下发数据
  /// String startRegAddr 起始地址
  /// String serializableDat：发送的数据 eg. 1,2,3,4
  /// Duration customTimeout 单包超时时间
  Future<ReturnEntity> setData({required String startRegAddr, required String serializableDat, Duration? customTimeout}) async {
    Stopwatch sw = Stopwatch()..start();
    ReturnEntity res = await master.setRegister(index: '1', startRegAddr: startRegAddr, serializableDat: serializableDat, customTimeout: customTimeout); // 3072_54
    debugPrint('===set $startRegAddr, $serializableDat');
    debugPrint('===set result: ${res.status == 0 ? res.data : res.message}');
    debugPrint('===time: ${(sw..stop()).elapsedMilliseconds}');
    return res;
  }

  /// 2b功能码下发数据
  /// String objectName 对象名称
  Future<ReturnEntity> get2bData({required String objectName}) async {
    Stopwatch sw = Stopwatch()..start();
    ReturnEntity res = await master.get2bRegister(objectName: objectName);
    debugPrint('===get 2b result:${res.status == 0 ? res.data : res.message}');
    debugPrint('===time: ${(sw..stop()).elapsedMilliseconds}');
    return res;
  }

  // 飞梭获取数据
  /// 获取飞梭数据
  /// String startRegAddr 起始地址
  /// String dataCount 寄存器个数
  Future<ReturnEntity> getData485({required String startRegAddr, required String dataCount}) async {
    Stopwatch sw = Stopwatch()..start();
    ReturnEntity res = await master485.getRegister(index: '1', startRegAddr: startRegAddr, dataCount: dataCount); // 3072_54
    debugPrint('===get485 result:${res.status == 0 ? res.data : res.message}');
    debugPrint('===time: ${(sw..stop()).elapsedMilliseconds}');
    return res;
  }

  // 飞梭设置数据
  /// 设置飞梭数据
  /// String startRegAddr 起始地址
  /// String serializableDat 设置的数据
  Future<ReturnEntity> setData485({required String startRegAddr, required String serializableDat}) async {
    Stopwatch sw = Stopwatch()..start();
    ReturnEntity res = await master485.setRegister(index: '1', startRegAddr: startRegAddr, serializableDat: serializableDat); // 3072_54
    debugPrint('===set485 $startRegAddr, $serializableDat result=====:${res.status == 0 ? res.data : res.message}');
    debugPrint('===time: ${(sw..stop()).elapsedMilliseconds}');
    return res;
  }
}
