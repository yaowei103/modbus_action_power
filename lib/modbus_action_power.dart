import 'package:modbus_action_power/src/ModbusMaster.dart';
import 'package:modbus_action_power/src/ReturnEntity.dart';
import 'package:modbus_action_power/utils/Utils.dart';
import './packages/modbus_client/modbus_client.dart';
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

  getData() async {
    // req_21504_3001
    ReturnEntity res = await master.getRegister(index: 1, startRegAddr: 3072, dataCount: 54); // 3072_54
    print('=====result=====:${res.data}');
    return res.data;
  }

  setData() async {
    ModbusInt32Register setRequest = ModbusInt32Register(
      name: "BatteryTemperature",
      type: ModbusElementType.holdingRegister,
      address: 3072,
      uom: "",
      multiplier: 1,
      offset: 0,
      onUpdate: (self) => print('-----setData response---${self}'),
    );
    if (master.modbusClientRtu.isConnected) {
      var val = Utils.transformFrom10ToInt(50.512345, type: 'float');
      await master.modbusClientRtu.send(setRequest.getWriteRequest(val, rawValue: true));
      print('----set done----');
      return setRequest.value ?? '';
    } else {
      print('---not connected----');
    }
  }
}
