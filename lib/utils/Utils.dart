import 'dart:typed_data';
import 'dart:developer' as developer;
import 'package:collection/collection.dart';
import 'package:decimal/decimal.dart';

import '../packages/modbus_client/modbus_client.dart';
import '../entity/ReturnEntity.dart';
import '../packages/modbus_client_serial/src/modbus_client_serial.dart';

class Utils {
  /// 数据类型对应寄存器个数
  static int getTypeRegisterSize(String type) {
    if (!['int16', 'uint16', 'uint32', 'float'].contains(type)) {
      return 0;
    }
    Map<String, int> dataTypeMapping = {
      'int16': 1,
      'uint16': 1,
      'uint32': 2,
      'float': 2,
    };
    return dataTypeMapping[type]!;
  }

  // Int16, Uint16, Uint32, Int32 的16进制 转 10进制数字
  static num getResponseData(int val, {required String type, double? resolution}) {
    if (type == 'float') {
      Int8List bytes = Int8List(4);
      ByteData byteData = ByteData.view(bytes.buffer);
      byteData.setUint32(0, val, Endian.big);
      double resVal = byteData.getFloat32(0, Endian.big);
      return double.parse(resVal.toStringAsPrecision(7));
    } else if (type == 'uint16') {
      Int8List bytes = Int8List(2); // 创建一个长度为4的字节列表
      ByteData byteData = ByteData.view(bytes.buffer); // 将字节列表转换为字节缓冲区视图
      byteData.setUint16(0, val, Endian.big);
      int resVal = byteData.getUint16(0, Endian.big);
      return (resolution != null && resolution != 1) ? resVal * resolution : resVal;
    } else if (type == 'int16') {
      Int8List bytes = Int8List(2); // 创建一个长度为4的字节列表
      ByteData byteData = ByteData.view(bytes.buffer); // 将字节列表转换为字节缓冲区视图
      byteData.setInt16(0, val, Endian.big);
      int resVal = byteData.getInt16(0, Endian.big);
      return (resolution != null && resolution != 1) ? resVal * resolution : resVal;
    } else if (type == 'uint32') {
      Int8List bytes = Int8List(4); // 创建一个长度为4的字节列表
      ByteData byteData = ByteData.view(bytes.buffer); // 将字节列表转换为字节缓冲区视图
      byteData.setUint32(0, val, Endian.big);
      int resVal = byteData.getUint32(0, Endian.big);
      return (resolution != null && resolution != 1) ? resVal * resolution : resVal;
    }
    return 0;
  }

  // 10进制数字转Int16, Uint16, Uint32, Int32 的16进制
  static int transformFrom10ToInt(num val, {required String type, double? resolution}) {
    if (type == 'float') {
      int? decimalCount = resolution != null ? Utils.countDecimalPlaces(resolution) : null; //resolution.toString().split('.')[1].length : null;
      Float32List float32list = Float32List.fromList([(decimalCount != null ? double.parse(val.toStringAsFixed(decimalCount)) : val) as double]);
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
    } else {
      return 0;
    }
  }

  /// 将num转换成单寄存器数据int list

  static List<int> dataToIntList({required num val, required String type}) {
    switch (type) {
      case 'float':
        // Float (4 bytes)
        var list = Uint16List(2);
        list.buffer.asFloat32List()[0] = (val as double);
        return list.reversed.toList();
      case 'uint16':
        // Unsigned 16-bit integer (2 bytes)
        return Uint16List(1)..buffer.asUint16List()[0] = (val as int);
      case 'int16':
        // Signed 16-bit integer (2 bytes)
        return Uint16List(1)..buffer.asInt16List()[0] = (val as int);
      case 'uint32':
        // Unsigned 32-bit integer (4 bytes)
        var list = Uint16List(2);
        list.buffer.asUint32List()[0] = (val as int);
        return list.reversed.toList();
      default:
        throw ArgumentError('Invalid data type: $type');
    }
  }

  // element 分包
  static ReturnEntity<List<Map<String, dynamic>>?> getElementsGroup(
    String startRegAddr,
    Map<int, ExcelInfo> excelInfoAll, {
    int? dataCount,
    List<String>? serializableDat,
  }) {
    var returnEntity = ReturnEntity<List<Map<String, dynamic>>?>();
    List<Map<String, dynamic>> arr = [];
    int currentAddress = int.parse(startRegAddr);

    // 分包，100 byte
    int allLength = 0;
    int cacheLength = 0;

    /// 请求Element分包
    List<ModbusElement<dynamic>> cacheArr = [];

    /// 请求数据分包
    List<dynamic> cacheDataArr = [];
    do {
      ExcelInfo? currentAddressConfig = excelInfoAll[currentAddress];
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
                return Utils.getResponseData(val.toInt(), type: excelAddressType, resolution: resolution);
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
                return Utils.getResponseData(val.toInt(), type: excelAddressType);
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
                return Utils.getResponseData(val.toInt(), type: excelAddressType) as double;
                // int decimalCount = resolution.toString().split('.')[1].length;
                // return resolution != null ? double.parse(res.toStringAsFixed(decimalCount)) : res;
              },
            ));
            break;
        }
        serializableDat != null ? cacheDataArr.add(Utils.transformFrom10ToInt(double.parse(serializableDat[allLength]), type: excelAddressType, resolution: resolution)) : null;
        cacheLength += Utils.getTypeRegisterSize(excelAddressType);
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
  static checkResDataCrc(Uint8List res) {
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

  /// 0x14 将 readFileRequests 进行分包
  /// 分包前
  /// [
  ///   ReadFileRequest(fileNum: 2, recordNum: 0, dataLength: 9), // recordLength: 11
  ///   ReadFileRequest(fileNum: 2, recordNum: 15, dataLength: 300 * 9), // recordLength: 300 * 17
  /// ]
  ///
  /// 分包后
  /// [
  ///   [
  ///     ReadFineInfo(fileNum:2, recordNum: 0, recordLength: 9, excelInfos: [],
  ///     ReadFileInfo(fileNum:2, recordNum: 15, recordLength: 100, excelInfos: []),
  ///     ReadFileInfo(fileNum:2, recordNum: 115, recordLength: 100, excelInfos: []),
  ///     ReadFileInfo(fileNum:2, recordNum: 215, recordLength: 100, excelInfos: []),
  ///   ]
  /// ]
  static ReturnEntity<List<List<ReadFileInfo>>> packageReadFileRequest(List<ReadFileRequest> readFileRequests, Map<int, ExcelInfo> excelInfoAll) {
    ReturnEntity<List<List<ReadFileInfo>>> returnEntity = ReturnEntity();
    // 子请求和响应最大字节长度
    // int maxReqLength = 256 - 5; // subDevice, functionCode, 字节数， CRC
    int maxResLength = 256 - 5 - 5; // subDevice, functionCode, 响应数据长度，CRC，多空一些字符

    List<List<ReadFileInfo>> allPackageData = [];
    // 单包大小计数
    int packResSize = 0;
    List<ExcelInfo> excelInfos = [];
    List<ReadFileInfo> singPackageRecords = [];
    for (ReadFileRequest readFileRequest in readFileRequests) {
      int fileNum = readFileRequest.fileNum;
      int recordNum = readFileRequest.recordNum;
      ReadFileInfo singleRecord = ReadFileInfo(fileNum: fileNum, recordNum: recordNum, recordLength: 0, excelInfos: []);
      packResSize += 2; // 响应长度、参考类型
      int excelKey = (fileNum << 16) + recordNum;
      for (int i = 0; i < readFileRequest.dataLength; i++) {
        ExcelInfo? excel = excelInfoAll[excelKey];
        if (excel == null) {
          returnEntity.status = -1;
          returnEntity.message = '未找到对应的文件号：${excelKey >> 16}或记录号：${excelKey & 0xffff}';
          return returnEntity;
        }
        int registerSize = Utils.getTypeRegisterSize(excel.type!);
        packResSize += registerSize * 2; // 记录数据高低位
        singleRecord.recordLength = singleRecord.recordLength + registerSize;

        excelInfos.add(excel);
        if (packResSize >= maxResLength || i == (readFileRequest.dataLength - 1)) {
          singleRecord.excelInfos = excelInfos;
          singPackageRecords.add(ReadFileInfo(
            fileNum: singleRecord.fileNum,
            recordNum: singleRecord.recordNum,
            recordLength: singleRecord.recordLength,
            excelInfos: excelInfos.toList(),
          ));
          if (packResSize >= maxResLength) {
            packResSize = 0;
            allPackageData.add(singPackageRecords.toList());
            singPackageRecords.clear();
          }
          excelInfos.clear();
          singleRecord.recordNum = (excelKey & 0x0000ffff) + registerSize;
          ;
          singleRecord.recordLength = 0;
          singleRecord.excelInfos = [];
        }
        excelKey += registerSize;
      }
      if (singPackageRecords.isNotEmpty) {
        allPackageData.add(singPackageRecords.toList());
      }
      singPackageRecords.clear();
      packResSize = 0;
    }

    returnEntity.data = allPackageData;
    return returnEntity;
  }

  /// 0x15 数据分包
  static ReturnEntity<List<List<WriteFileInfo>>> packageWriteFileRequest(List<WriteFileRequest> writeFileRequests, Map<int, ExcelInfo> excelInfoAll) {
    ReturnEntity<List<List<WriteFileInfo>>> returnEntity = ReturnEntity();
    // 0x15 请求和响应数据类型一致，同上采用maxResLength
    int maxResLength = 256 - 5 - 7; // subDevice, functionCode, 响应数据长度，CRC，多空一些字符,兼容Modbus-TCP的MBAP头(7)字节
    List<List<WriteFileInfo>> allPackageData = [];

    // 单包大小计数
    int packResSize = 0;
    List<ExcelInfo> excelInfos = [];
    List<WriteFileInfo> singPackageRecords = [];
    for (WriteFileRequest writeFileRequest in writeFileRequests) {
      int fileNum = writeFileRequest.fileNum;
      int recordNum = writeFileRequest.recordNum;
      WriteFileInfo singleRecord = WriteFileInfo(fileNum: fileNum, recordNum: recordNum, recordData: [], excelInfos: []);
      packResSize += (1 + 2 + 2 + 2); // 参考类型，文件号，记录号，记录长度
      int excelKey = (fileNum << 16) + recordNum;
      for (int i = 0; i < writeFileRequest.recordData.length; i++) {
        ExcelInfo? excel = excelInfoAll[excelKey];
        if (excel == null) {
          returnEntity.status = -1;
          returnEntity.message = '未找到对应的文件号：${excelKey >> 16}或记录号：${excelKey & 0xffff}';
          return returnEntity;
        }
        int registerSize = Utils.getTypeRegisterSize(excel.type!);
        packResSize += registerSize * 2; // 记录数据高低位

        num currentData = writeFileRequest.recordData[i];
        List<int> currentDataToInt = Utils.dataToIntList(val: currentData, type: excel.type!);
        singleRecord.recordData.addAll(currentDataToInt);

        excelInfos.add(excel);
        if (packResSize >= maxResLength || i == (writeFileRequest.recordData.length - 1)) {
          singleRecord.excelInfos = excelInfos;
          singPackageRecords.add(WriteFileInfo(
            fileNum: singleRecord.fileNum,
            recordNum: singleRecord.recordNum,
            recordData: singleRecord.recordData,
            excelInfos: excelInfos.toList(),
          ));
          if (packResSize >= maxResLength) {
            packResSize = 0;
            allPackageData.add(singPackageRecords.toList());
            singPackageRecords.clear();
          }
          excelInfos.clear();
          singleRecord.recordNum = (excelKey & 0x0000ffff) + registerSize;
          singleRecord.recordData = [];
          singleRecord.excelInfos = [];
        }
        excelKey += registerSize;
      }
      if (singPackageRecords.isNotEmpty) {
        allPackageData.add(singPackageRecords.toList());
      }
      singPackageRecords.clear();
      packResSize = 0;
    }
    returnEntity.data = allPackageData;
    return returnEntity;
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
