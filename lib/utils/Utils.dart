import 'dart:typed_data';
import 'dart:developer' as developer;
import 'package:collection/collection.dart';
import 'package:decimal/decimal.dart';

import '../packages/modbus_client/modbus_client.dart';
import '../entity/ReturnEntity.dart';
import '../packages/modbus_client_serial/src/modbus_client_serial.dart';

class Utils {
  // Int16, Uint16, Uint32, Int32 的16进制 转 10进制数字
  static num getResponseData(int val, {type}) {
    if (type == 'float') {
      Int8List bytes = Int8List(4);
      ByteData byteData = ByteData.view(bytes.buffer);
      byteData.setUint32(0, val, Endian.big);
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
    return 0;
  }

  // 10进制数字转Int16, Uint16, Uint32, Int32 的16进制
  static transformFrom10ToInt(double val, {required String type, double? resolution}) {
    if (type == 'float') {
      int? decimalCount = resolution != null ? Utils.countDecimalPlaces(resolution) : null; //resolution.toString().split('.')[1].length : null;
      Float32List float32list = Float32List.fromList([decimalCount != null ? double.parse(val.toStringAsFixed(decimalCount)) : val]);
      Int32List int32list = Int32List.view(float32list.buffer);
      String hexValue = int32list[0].toRadixString(16);
      return int.parse(hexValue, radix: 16);
    } else if (type == 'uint16') {
      Uint16List uint16list = Uint16List.fromList([(resolution != null ? val / resolution : val).toInt()]);
      Uint16List uint16list1 = Uint16List.view(uint16list.buffer);
      String hexValue = uint16list1[0].toRadixString(16);
      return int.parse(hexValue, radix: 16);
    } else if (type == 'int16') {
      Int16List int16list = Int16List.fromList([(resolution != null ? val / resolution : val).toInt()]);
      Int16List int16list1 = Int16List.view(int16list.buffer);
      String hexValue = int16list1[0].toRadixString(16);
      return int.parse(hexValue, radix: 16);
    } else if (type == 'uint32') {
      Uint32List uint32list = Uint32List.fromList([(resolution != null ? val / resolution : val).toInt()]);
      Uint32List uint32list1 = Uint32List.view(uint32list.buffer);
      String hexValue = uint32list1[0].toRadixString(16);
      return int.parse(hexValue, radix: 16);
    }
  }

  // element 分包
  static ReturnEntity<List<Map<String, dynamic>>?> getElementsGroup(
    String startRegAddr,
    Map<int, ExcelInfor> excelInfoAll, {
    int? dataCount,
    List<String>? serializableDat,
  }) {
    var returnEntity = ReturnEntity<List<Map<String, dynamic>>?>();
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

    /// 请求Element分包
    List<ModbusElement<dynamic>> cacheArr = [];

    /// 请求数据分包
    List<dynamic> cacheDataArr = [];
    do {
      ExcelInfor? currentAddressConfig = excelInfoAll[currentAddress];
      String? excelAddressType = currentAddressConfig?.type;
      double? resolution = currentAddressConfig?.resolution;
      if (currentAddressConfig != null && excelAddressType != null && excelAddressType != 'null') {
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
                var res = Utils.getResponseData(val.toInt(), type: excelAddressType);
                return (resolution != null && resolution != 1) ? res * resolution : res;
              },
            ));
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
                var res = Utils.getResponseData(val.toInt(), type: excelAddressType);
                return (resolution != null && resolution != 1) ? res * resolution : res;
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
                var res = Utils.getResponseData(val.toInt(), type: excelAddressType);
                return (resolution != null && resolution != 1) ? res * resolution : res;
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
                // float 按resolution保留位数
                // var resolution = currentAddressConfig.resolution;
                double res = Utils.getResponseData(val.toInt(), type: excelAddressType) as double;
                // int decimalCount = resolution.toString().split('.')[1].length;
                // return resolution != null ? double.parse(res.toStringAsFixed(decimalCount)) : res;
                return double.parse(res.toStringAsPrecision(7));
              },
            ));
            break;
        }
        serializableDat != null ? cacheDataArr.add(Utils.transformFrom10ToInt(double.parse(serializableDat[allLength]), type: excelAddressType, resolution: resolution)) : null;
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
      } else if (currentAddressConfig == null) {
        returnEntity.status = -1;
        returnEntity.message = '未配置该地址';
        return returnEntity;
      }
      currentAddress += 1;
    } while (allLength < (dataCount ?? -1) || allLength < (serializableDat?.length ?? -1));
    returnEntity.data = arr;
    return returnEntity;
  }

  // 2b功能码返回值crc校验
  static check2bDataCrc(Uint8List res) {
    Uint8List resCrc = res.sublist(res.length - 2);
    Uint8List computedCrc = ModbusClientSerialRtu.computeCRC16(res.sublist(0, res.length - 2));
    return resCrc.equals(computedCrc);
  }

  // 解析2b功能码返回数据, 对象数量，（对象id，对象长度，对象值），（...）
  static List<String> format2bResponseData(Uint8List res) {
    if (res.length < 4) return [];

    List<String> result = [];
    int objCount = res[0];
    Uint8List listData = res.sublist(1);

    int? currentObjId;
    int? currentObjLength;
    List<int> asciiObjArr = [];
    for (int i = 0; i < listData.length; i++) {
      if (currentObjId == null || currentObjLength == null) {
        currentObjId = listData[i];
        currentObjLength = listData[i + 1];
        i++;
        continue;
      } else {
        if (asciiObjArr.length < currentObjLength) {
          asciiObjArr.add(listData[i]);
        }
        if (asciiObjArr.length == currentObjLength) {
          currentObjId = null;
          currentObjLength = null;
          result.add(translateIntToChar(asciiObjArr).join(''));
          asciiObjArr = [];
        }
      }
    }
    if (result.length != objCount) {
      return [];
    }
    return result;
  }

  static List<String> translateIntToChar(List<int> par) {
    String value = '';
    for (int i = 0; i < par.length; i++) {
      String tempValue = '';
      String aSCIIValue = par[i].toRadixString(16).padLeft(4, '0');
      tempValue = aSCIIValue.substring(aSCIIValue.length - 2);
      tempValue = int.parse(tempValue, radix: 16).toString();
      value += String.fromCharCode(int.parse(tempValue));
      tempValue = aSCIIValue.substring(0, 2);
      tempValue = int.parse(tempValue, radix: 16).toString();
      value += String.fromCharCode(int.parse(tempValue));
    }
    List<String> data = value.split('\u0000');

    return data.where((s) => s.isNotEmpty).toList();
  }

  /// 计算小数有几位小数位数
  static int countDecimalPlaces(double number) {
    Decimal decimal = Decimal.parse(number.toString());
    String decimalString = decimal.toString();

    RegExp decimalRegex = RegExp(r'\.(\d*)$');
    RegExpMatch? match = decimalRegex.firstMatch(decimalString);

    if (match != null && match.groupCount > 0) {
      String decimalPart = match.group(1)!;
      return decimalPart.length;
    }

    return 0;
  }

  /// 打印日志
  static void log(String? text, {String? name, bool? showStackTrace}) {
    developer.log(
      text ?? 'default modbus error, no error message',
      time: DateTime.now(),
      name: 'MODBUS',
      stackTrace: (showStackTrace ?? false) ? StackTrace.current : null,
    );
  }
}
