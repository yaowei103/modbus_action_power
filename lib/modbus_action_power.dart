import 'package:modbus_action_power/src/ModbusMaster.dart';

class ModbusActionPower {
  late ModbusMaster master;
  String filePath = 'assets/ppmDCModbus2.xlsx';

  void initModbus() {
    master = ModbusMaster();
    master.readComFileInfo(filePath);
  }
}
