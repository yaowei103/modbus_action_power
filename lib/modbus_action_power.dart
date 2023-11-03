import 'package:modbus_action_power/src/ModbusMaster.dart';
import 'package:modbus_action_power/entity/ReturnEntity.dart';
import './packages/modbus_client_serial/modbus_client_serial.dart';

class ModbusActionPower {
  late ModbusMaster master;
  String filePath = 'assets/ppmDCModbus2.xlsx';
  late ModbusClientSerialRtu modbusClientRtu;

  void initModbus() {
    master = ModbusMaster();
    master.readComFileInfo(filePath);
  }

  testInit() async {
    master = ModbusMaster();
    await master.initMaster();
  }

  disConnect() {
    modbusClientRtu.disconnect();
    print('----disConnect done----');
  }

  getData({required String startRegAddr, required String dataCount}) async {
    // req_21504_3001
    ReturnEntity res = await master.getRegister(index: '1', startRegAddr: startRegAddr, dataCount: dataCount); // 3072_54
    print('=====get result=====:${res.data}');
    return res.data;
  }

  setData({required String startRegAddr, required String serializableDat}) async {
    ReturnEntity res = await master.setRegister(index: '1', startRegAddr: startRegAddr, serializableDat: serializableDat); // 3072_54
    print('=====set result=====:${res.data}');
    return res.data;
  }

  // set06Data({required String startRegAddr, required String serializableDat}) async {
  //   ModbusInt32Register setRequest = ModbusInt32Register(
  //     name: "BatteryTemperature",
  //     type: ModbusElementType.holdingRegister,
  //     address: int.parse(startRegAddr),
  //     uom: "",
  //     multiplier: 1,
  //     offset: 0,
  //     onUpdate: (self) => print('-----setData response---${self}'),
  //   );
  //   if (master.modbusClientRtu.isConnected) {
  //     var val = Utils.transformFrom10ToInt(serializableDat, type: 'float'); // 1112145920
  //     await master.modbusClientRtu.send(setRequest.getWriteRequest(val, rawValue: true));
  //     print('----set done----');
  //     return setRequest.value ?? '';
  //   } else {
  //     print('---not connected----');
  //   }
  // }
  //
  // set10Data({required String startRegAddr, required String serializableDat}) async {
  //   ModbusElementsGroup setRequest = ModbusElementsGroup([
  //     ModbusInt32Register(
  //       name: "BatteryTemperature",
  //       type: ModbusElementType.holdingRegister,
  //       address: 3072,
  //       uom: "",
  //       multiplier: 1,
  //       offset: 0,
  //       onUpdate: (self) => print('-----setData response---${self}'),
  //     ),
  //     ModbusInt32Register(
  //       name: "BatteryTemperature",
  //       type: ModbusElementType.holdingRegister,
  //       address: 3074,
  //       uom: "",
  //       multiplier: 1,
  //       offset: 0,
  //       onUpdate: (self) => print('-----setData response---${self}'),
  //     ),
  //   ]);
  //
  //   if (master.modbusClientRtu.isConnected) {
  //     var val = Utils.transformFrom10ToInt('50.1', type: 'float'); // 1112041061
  //     var val2 = Utils.transformFrom10ToInt('50.2', type: 'float'); // 1112067277
  //     await master.modbusClientRtu.send(setRequest.getWriteRequest([val, val2], rawValue: true));
  //     print('----set done----');
  //     return 'success';
  //   } else {
  //     print('---not connected----');
  //   }
  // }
}
