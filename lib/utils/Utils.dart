import 'dart:typed_data';
import 'package:collection/collection.dart';

import '../packages/modbus_client/modbus_client.dart';
import '../src/ReturnEntity.dart';

class Utils {
  // Int16, Uint16, Uint32, Int32 转 10进制数字
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

  // 10进制数字转Int16, Uint16, Uint32, Int32
  static transformFrom10ToInt(String val, {type}) {
    if (type == 'float') {
      // 0x42480000
      Float32List float32list = Float32List.fromList([double.parse(val)]);
      Int32List int32list = Int32List.view(float32list.buffer);
      String hexValue = int32list[0].toRadixString(16);
      return int.parse('0x$hexValue');
    } else if (type == 'uint16') {
      Uint16List uint16list = Uint16List.fromList([int.parse(val)]);
      Uint16List uint16list1 = Uint16List.view(uint16list.buffer);
      String hexValue = uint16list1[0].toRadixString(16);
      return int.parse('0x$hexValue');
    } else if (type == 'int16') {
      Int16List int16list = Int16List.fromList([int.parse(val)]);
      Int16List int16list1 = Int16List.view(int16list.buffer);
      String hexValue = int16list1[0].toRadixString(16);
      return int.parse('0x$hexValue');
    } else if (type == 'uint32') {
      Uint32List uint32list = Uint32List.fromList([int.parse(val)]);
      Uint32List uint32list1 = Uint32List.view(uint32list.buffer);
      String hexValue = uint32list1[0].toRadixString(16);
      return int.parse('0x$hexValue');
    }
  }

  // element 分包
  static List<Map<String, dynamic>> getElementsGroup(
    String startRegAddr,
    Map<int, ExcelInfor> excelInfoAll, {
    int? dataCount,
    List<String>? serializableDat,
  }) {
    List<Map<String, dynamic>> arr = [];
    int currentAddress = int.parse(startRegAddr);

    Map<String, int> dataTypeMapping = {
      'int16': 1,
      'uint16': 1,
      'uint32': 2,
      'float': 2,
    };

    // 分包，100 byte
    int allLength = 0;
    int cacheLength = 0;
    List<ModbusElement<dynamic>> cacheArr = [];
    List<dynamic> cacheDataArr = [];
    do {
      ExcelInfor? excelAddress = excelInfoAll[currentAddress];
      String? excelAddressType = excelInfoAll[currentAddress]?.type;
      if (excelAddress != null && excelAddressType != null && excelAddressType != 'null') {
        switch (excelAddressType) {
          case 'int16':
            cacheArr.add(ModbusInt16Register(
                name: "ModBusRegisterName",
                type: ModbusElementType.holdingRegister, //03， 06， 10
                address: currentAddress,
                uom: "",
                multiplier: 1,
                offset: 0,
                format: (val) {
                  return Utils.getResponseData(val.toInt(), type: excelAddressType);
                }));
            break;
          case 'uint16':
            cacheArr.add(ModbusUint16Register(
              name: "ModBusRegisterName",
              type: ModbusElementType.holdingRegister, //03， 06， 10
              address: currentAddress,
              uom: "",
              multiplier: 1,
              offset: 0,
              format: (val) {
                return Utils.getResponseData(val.toInt(), type: excelAddressType);
                // handleUpdate(val, ii);
              },
            ));
            break;
          case 'uint32':
            cacheArr.add(ModbusUint32Register(
              name: "ModBusRegisterName",
              type: ModbusElementType.holdingRegister,
              address: currentAddress,
              uom: "",
              multiplier: 1,
              offset: 0,
              format: (val) {
                return Utils.getResponseData(val.toInt(), type: excelAddressType);
                // handleUpdate(val, ii);
              },
            ));
            break;
          case 'float':
            cacheArr.add(ModbusInt32Register(
              name: "ModBusRegisterName",
              type: ModbusElementType.holdingRegister,
              address: currentAddress,
              uom: "",
              multiplier: 1,
              offset: 0,
              format: (val) {
                return Utils.getResponseData(val.toInt(), type: excelAddressType);
                // handleUpdate(val, ii);
              },
            ));
            break;
        }
        serializableDat != null ? cacheDataArr.add(Utils.transformFrom10ToInt(serializableDat![allLength], type: excelAddressType)) : null;
        cacheLength += dataTypeMapping[excelAddressType]!;
        allLength += 1;
        if (cacheLength >= 100 || allLength >= (dataCount ?? double.infinity) || allLength >= (serializableDat?.length ?? double.infinity)) {
          Iterable<ModbusElement<dynamic>> group = []
            ..addAll(cacheArr)
            ..map((item) => item);

          arr.add({
            'group': group,
            'data': []
              ..addAll(cacheDataArr)
              ..map((item) => item),
          });
          cacheArr.clear();
          cacheDataArr.clear();
          cacheLength = 0;
        }
      }
      currentAddress += 1;
    } while (allLength < (dataCount ?? -1) || allLength < (serializableDat?.length ?? -1));

    return arr;
  }

  // 请求data分包
  static List<List<dynamic>> getReqDataGroup(String serializableDat, List<ModbusElementsGroup> elementGroupList) {
    List<List<dynamic>> result = [];
    List dataArr = serializableDat.split(',').toList();

    int start = 0;
    int end = elementGroupList[0].length;
    for (int i = 0; i < elementGroupList.length; i++) {
      int currentGroupItemLength = elementGroupList[i].length;
      int nextGroupItemLength = elementGroupList[i + 1].length;
      result.add(dataArr.sublist(start, end));
      start = currentGroupItemLength;
      end = currentGroupItemLength + nextGroupItemLength;
    }
    return result;
  }
}
