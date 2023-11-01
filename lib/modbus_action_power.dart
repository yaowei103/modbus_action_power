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
    ReturnEntity res = await master.getRegister(index: 1, startRegAddr: 304, dataCount: 26);
    print('=====result=====:${res.data}');
  }

  getDataFloat() {
    var getRequest = ModbusElementsGroup([
      ModbusInt32Register(
        name: "BatteryTemperature",
        type: ModbusElementType.holdingRegister,
        address: 314,
        uom: "",
        multiplier: 1,
        offset: 0,
        onUpdate: (self) {
          // 304_21的正常返回值
          // 2050.0100098,0.218631,0.4481957,-0.4578384,0.5839773,1.1064787,0,1,187,2000,60,30,3000,0.5,1,2050,63,33,1,1,0
          var res = Utils.getResponseData(self.value.toInt(), type: 'float');
          print('---getData 314 response:----${res}');
        },
      ),
      ModbusInt16Register(
        name: "BatteryTemperature",
        type: ModbusElementType.holdingRegister,
        address: 316,
        uom: "",
        multiplier: 1,
        offset: 0,
        onUpdate: (self) {
          var res = Utils.getResponseData(self.value.toInt(), type: 'uint16');
          print('---getData 316 response:----$res');
        },
      ),
      ModbusInt32Register(
        name: "BatteryTemperature",
        type: ModbusElementType.holdingRegister, //读写
        address: 317,
        uom: "",
        multiplier: 1,
        offset: 0,
        onUpdate: (self) {
          var res = Utils.getResponseData(self.value.toInt(), type: 'uint32');
          print('---getData 317 response:----$res');
        },
      ),
    ]);
    if (modbusClientRtu.isConnected) {
      modbusClientRtu.send(getRequest.getReadRequest());
      print('----get done----');
      print('get multiple response: ${List.from(getRequest)}');
    } else {
      print('---not connected');
    }
  }

  setData() {
    ModbusInt16Register setRequest = ModbusInt16Register(
      name: "BatteryTemperature",
      type: ModbusElementType.holdingRegister,
      address: 22,
      uom: "°C",
      multiplier: 1,
      onUpdate: (self) => print('-----setData response---${self}'),
    );
    if (modbusClientRtu.isConnected) {
      modbusClientRtu.send(setRequest.getWriteRequest(123, rawValue: true)); //'01 03 02 02 00 01 24 72'
      print('----set done----');
    } else {
      print('---not connected----');
    }
  }
}
