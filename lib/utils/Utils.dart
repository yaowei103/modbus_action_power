import 'dart:typed_data';
import '../packages/modbus_client/modbus_client.dart';

import '../src/ReturnEntity.dart';

class Utils {
  static getResponseData(int val, {type}) {
    if (type == 'float') {
      Int8List bytes = Int8List(4); // 创建一个长度为4的字节列表
      ByteData byteData = ByteData.view(bytes.buffer); // 将字节列表转换为字节缓冲区视图
      byteData.setInt32(0, val, Endian.big);
      double resVal = byteData.getFloat32(0, Endian.big);
      return resVal;
    } else if (type == 'uint16') {
      Int8List bytes = Int8List(2); // 创建一个长度为4的字节列表
      ByteData byteData = ByteData.view(bytes.buffer); // 将字节列表转换为字节缓冲区视图
      byteData.setUint16(0, val, Endian.big);
      int resVal = byteData.getUint16(0, Endian.big);
      return resVal;
    } else if (type == 'int16') {
      Int8List bytes = Int8List(2); // 创建一个长度为4的字节列表
      ByteData byteData = ByteData.view(bytes.buffer); // 将字节列表转换为字节缓冲区视图
      byteData.setInt16(0, val, Endian.big);
      int resVal = byteData.getInt16(0, Endian.big);
      return resVal;
    } else if (type == 'uint32') {
      Int8List bytes = Int8List(4); // 创建一个长度为4的字节列表
      ByteData byteData = ByteData.view(bytes.buffer); // 将字节列表转换为字节缓冲区视图
      byteData.setUint32(0, val, Endian.big);
      int resVal = byteData.getUint32(0, Endian.big);
      return resVal;
    }
  }

  static ModbusElementsGroup getElementsGroup(int startRegAddr, int dataCount, Map<int, ExcelInfor> excelInfoAll, handleUpdate) {
    List<ModbusElement<dynamic>> arr = [];
    int currentAddress = startRegAddr;
    int i = 0;
    do {
      ExcelInfor? excelAddress = excelInfoAll[currentAddress];
      String? excelAddressType = excelInfoAll[currentAddress]?.type;
      if (excelAddress != null && excelAddressType != null && excelAddressType != 'null') {
        switch (excelAddressType) {
          case 'int16':
            int ii = i;
            arr.add(ModbusInt16Register(
              name: "ModBusRegisterName",
              type: ModbusElementType.holdingRegister, //03， 06， 10
              address: currentAddress,
              uom: "",
              multiplier: 1,
              offset: 0,
              onUpdate: (self) {
                var val = Utils.getResponseData(self.value.toInt(), type: excelAddressType);
                handleUpdate(val, ii);
              },
            ));
            break;
          case 'uint16':
            int ii = i;
            arr.add(ModbusUint16Register(
              name: "ModBusRegisterName",
              type: ModbusElementType.holdingRegister, //03， 06， 10
              address: currentAddress,
              uom: "",
              multiplier: 1,
              offset: 0,
              onUpdate: (self) {
                var val = Utils.getResponseData(self.value.toInt(), type: excelAddressType);
                handleUpdate(val, ii);
              },
            ));
            break;
          case 'uint32':
            int ii = i;
            arr.add(ModbusUint32Register(
              name: "ModBusRegisterName",
              type: ModbusElementType.holdingRegister,
              address: currentAddress,
              uom: "",
              multiplier: 1,
              offset: 0,
              onUpdate: (self) {
                var val = Utils.getResponseData(self.value.toInt(), type: excelAddressType);
                handleUpdate(val, ii);
              },
            ));
            break;
          case 'float':
            int ii = i;
            arr.add(ModbusInt32Register(
              name: "ModBusRegisterName",
              type: ModbusElementType.holdingRegister,
              address: currentAddress,
              uom: "",
              multiplier: 1,
              offset: 0,
              onUpdate: (self) {
                var val = Utils.getResponseData(self.value.toInt(), type: excelAddressType);
                handleUpdate(val, ii);
              },
            ));
            break;
        }
        i++;
      }
      currentAddress += 1;
    } while (arr.length < dataCount);

    return ModbusElementsGroup(arr);
  }
}
