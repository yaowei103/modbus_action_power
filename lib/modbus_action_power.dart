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

      master485 = ModbusMaster();
      await master485.initMaster(filePath485);
    } catch (e) {
      returnEntity.status = -1;
      returnEntity.message = 'init modbus error: ${e.toString()}';
    }
    print('init success');
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
      print('----disConnect done----');
      returnEntity.status = 0;
    } else {
      print('----disConnect error, please retry----');
      returnEntity.status = -1;
      returnEntity.message = 'disConnect error, try again!';
    }
    return returnEntity;
  }

  Future<ReturnEntity> getData({required String startRegAddr, required String dataCount}) async {
    // req_21504_3001
    ReturnEntity res = await master.getRegister(index: '1', startRegAddr: startRegAddr, dataCount: dataCount); // 3072_54
    print('=====get $startRegAddr, $dataCount result=====:${res.data}');
    return res;
  }

  Future<ReturnEntity> setData({required String startRegAddr, required String serializableDat}) async {
    ReturnEntity res = await master.setRegister(index: '1', startRegAddr: startRegAddr, serializableDat: serializableDat); // 3072_54
    print('=====set $startRegAddr, $serializableDat result=====:${res.data}');
    return res;
  }

  Future<ReturnEntity> get2bData({required String objectName}) async {
    ReturnEntity res = await master.get2bRegister(objectName: objectName);
    print('=====get 2b result=====:${res.data}');
    return res;
  }

  // 飞梭获取数据
  Future<ReturnEntity> getData485({required String startRegAddr, required String dataCount}) async {
    ReturnEntity res = await master485.getRegister(index: '1', startRegAddr: startRegAddr, dataCount: dataCount); // 3072_54
    print('=====get485 result=====:${res.data}');
    return res;
  }

  // 飞梭设置数据
  Future<ReturnEntity> setData485({required String startRegAddr, required String serializableDat}) async {
    ReturnEntity res = await master485.setRegister(index: '1', startRegAddr: startRegAddr, serializableDat: serializableDat); // 3072_54
    print('=====set485 $startRegAddr, $serializableDat result=====:${res.data}');
    return res;
  }
}
