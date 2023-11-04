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
    if (!modbusClientRtu.isConnected) {
      print('----disConnect done----');
    } else {
      print('----disConnect error, please retry----');
    }
  }

  getData({required String startRegAddr, required String dataCount}) async {
    // req_21504_3001
    ReturnEntity res = await master.getRegister(index: '1', startRegAddr: startRegAddr, dataCount: dataCount); // 3072_54
    print('=====get result=====:${res.data}');
    if (res.status != 0) {
      print(res.message);
    }
    return res.data;
  }

  setData({required String startRegAddr, required String serializableDat}) async {
    ReturnEntity res = await master.setRegister(index: '1', startRegAddr: startRegAddr, serializableDat: serializableDat); // 3072_54
    print('=====set result=====:${res.data}');
    if (res.status != 0) {
      print(res.message);
    }
    return res.data;
  }
}
