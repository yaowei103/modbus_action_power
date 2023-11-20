import 'dart:io';
import 'dart:typed_data';

// import 'package:excel/excel.dart';
import 'package:intl/intl.dart';
import 'package:modbus_action_power/src/IModbus.dart';
import 'package:modbus_action_power/entity/ReturnEntity.dart';
import 'package:spreadsheet_decoder/spreadsheet_decoder.dart';
import 'package:modbus_action_power/utils/Utils.dart';
import '../entity/InfoRTU.dart';
import '../packages/modbus_client/modbus_client.dart';
import '../packages/modbus_client_serial/modbus_client_serial.dart';

import 'Files.dart';

class ModbusMaster extends IModbus {
  /// 含义名称加载信息
  Map<String, (int, int)> _excelInfor2BName = {};
  ModbusMasterType _masterType = ModbusMasterType.RTU;

  /// 可表示的最小最大值
  int intMinValue = -2147483648;
  int intMaxValue = 2147483647;
  int uint16MaxValue = 65535;
  int uint32MaxValue = 4294967295;
  int shortMinValue = -32768;
  int shortMaxValue = 32767;
  int ushortMaxValue = 65535;
  double floatMinValue = double.parse('-3.40282347E+38');
  double floatMaxValue = double.parse('3.40282347E+38');
  double doubleMinValue = double.parse('-1.7976931348623157E+308');
  double doubleMaxValue = double.parse('1.7976931348623157E+308');

  /// 重写后新增 start
  late InfoRTU infoRTU;
  Map<int, ExcelInfor> excelInfoAll = {};
  late ModbusClientSerialRtu modbusClientRtu;
  late ModbusClientSerialAscii modbusClientSerialAscii;
  String filePath = '';
  String toFilePath = '';
  // 配置信息sheets
  List<String> configSheetNames = ["Modbus-TCP", "Modbus-RTU", "TCP通讯设置", "RTU通讯设置", "大小端配置", "设备信息"];

  Future<ReturnEntity> initMaster(String filePath) async {
    var stopwatchInit = Stopwatch()..start();
    var returnEntity = ReturnEntity();
    var readComFileResult = await readComFileInfo(filePath);
    if (readComFileResult.status != 0) {
      print(readComFileResult.message);
      return readComFileResult;
    }
    modbusClientRtu = ModbusClientSerialRtu(
      portName: '/dev/${infoRTU.portNames[0]}', //'ttyS3',
      unitId: 1,
      connectionMode: ModbusConnectionMode.autoConnectAndDisconnect,
      baudRate: infoRTU.baudRates[0],
      dataBits: SerialDataBits.bits8,
      stopBits: infoRTU.stopBits[0],
      parity: infoRTU.parities[0],
      flowControl: SerialFlowControl.none,
      responseTimeout: Duration(milliseconds: int.parse(infoRTU.timeout)),
    );
    print('init modbus done!, time: ${(stopwatchInit..stop()).elapsedMilliseconds}');

    return returnEntity;
  }

  /// 重写后新增 end

  /// 加载协议
  /// <param name="protocol1">协议文件全路径</param>
  @override
  Future<ReturnEntity> readComFileInfo(String protocol1) async {
    filePath = protocol1;
    List<String> vs = protocol1.split('\\');
    for (var vsnum = 0; vsnum < vs.length - 1; vsnum++) {
      toFilePath += '${vs[vsnum]}\\';
    }
    List<String> vs1 = vs[vs.length - 1].split('.');

    toFilePath += '${vs1[0]}协议备份${DateFormat('yyyy_MM_dd HH_mm_ss').format(DateTime.now())}.${vs1[1]}';
    ReturnEntity returnEntity = await readComFileInfo1(); //读取协议文件，并检查协议文件正确性
    return returnEntity;
  }

  //#region 读协议与清除协议字典信息
  int pageNum = 0; //页签索引页，用于故障上报索引
  String pageName = "";
  int rowNum = 0; //行索引，用于故障上报索引
  int keyType = 0; //确认地址/名称的键值重复定位，用于故障上报索引
  /// <summary>
  /// 读取协议文件，并检查协议文件正确性
  /// </summary>
  /// <returns></returns>
  Future<ReturnEntity> readComFileInfo1() async {
    ReturnEntity returnEntity = ReturnEntity(); //异常信息返回对象
    try {
      returnEntity = await Files.copyFileToLocal(filePath, toFilePath); //协议文件备份
      if (returnEntity.status != 0) {
        return returnEntity;
      }
      toFilePath = returnEntity.data!;

      /// 读取协议文件
      var bytes = File(toFilePath).readAsBytesSync();
      var excel = SpreadsheetDecoder.decodeBytes(bytes);
      List<String> list = excel.tables.keys.toList(); //获取协议所有页签
      //获取通信对象及通信规约类型
      if (list.contains("Modbus-TCP")) {
        print('读取Modbus-TCP配置');
      } else if (list.contains("Modbus-RTU")) {
        SpreadsheetTable dt = excel.tables['Modbus-RTU']!;
        _masterType = ModbusMasterType.RTU;
        infoRTU = InfoRTU.fromDataTable(dt);
      }
      //int[] ErrorCode = { -16449008, -16449007 };
      //将各个sheet数据加载到对应字典中，key为地址
      for (int pagenum = 0; pagenum < list.length; pagenum++) {
        keyType = 0;
        pageNum = pagenum;
        pageName = list[pagenum];
        if (configSheetNames.contains(list[pagenum])) {
          //不加载这些配置sheet信息
          continue;
        } else {
          List<String> rowString = excel.tables[pageName]!.rows[0].map((e) => e.toString()).toList(); //读取本Sheet页首行信息，从而得到它支持的功能码
          String char = '码';
          List<String> sArray = rowString[0].split(char); // 一定是单引
          String functionCode = sArray.last.toLowerCase(); //得到功能码信息
          List<String?> currentSheetFunctionCode = List.from(['0x03', '0x06', '0x10', '0x2b'].map((e) {
            if (functionCode.contains(e)) {
              return e;
            }
          }));
          Stopwatch sw = Stopwatch()..start();
          var dt = excel.tables[pageName]!;
          sw.stop();
          print("Work done! Sheet $pageName used time: ${sw.elapsedMicroseconds}ms.");

          // 全部功能码数据start
          // 单个重复区数据
          List<ExcelInfor> repeatPartInfo = [];
          int tempNum = 0;
          int key = 0;
          bool tempFlag = false; //是否位于重复区段
          for (int i = 2; i < dt.rows.length; i++) {
            rowNum = i;
            ExcelInfor excelInfor = ExcelInfor(); // 每行的excelInfo

            if (ExcelInfor.getAddressFromDt(dt, i)?.contains("重复数据区开始") ?? false) {
              tempFlag = true;
              tempNum = int.parse(dt.rows[i][1].toString()); // 重复数据个数
              key = int.parse(dt.rows[i + 1][0].toString()); // 当前循环重复区 开始key
              continue;
            }

            if (ExcelInfor.getAddressFromDt(dt, i)?.contains("重复数据区结束") ?? false) {
              if (tempFlag) {
                // 循环重复区
                int repeatLength = repeatPartInfo.length;
                int repeatItemKey = key;
                for (int w = 0; w < tempNum; w++) {
                  // 循环重复区每个item
                  for (int j = 0; j < repeatLength; j++) {
                    ExcelInfor repeatItemExcelInfo = ExcelInfor.copy(repeatPartInfo[j]);
                    repeatItemExcelInfo.meaning = repeatItemExcelInfo.meaning != null ? '${repeatItemExcelInfo.meaning}_${w + 1}' : null;
                    excelInfoAll[repeatItemKey] = repeatItemExcelInfo;
                    repeatItemKey++;
                  }
                }
              }
              tempFlag = false;
              repeatPartInfo.clear();
              continue;
            }

            if (tempFlag) {
              ExcelInfor excelInforRepeat = ExcelInfor(
                meaning: ExcelInfor.getMeaningFromDt(dt, i), //currentRow[2],
                type: ExcelInfor.getTypeFromDt(dt, i), //currentRow[3],
                unit: ExcelInfor.getUnitFromDt(dt, i), //currentRow[4],
                resolution: ExcelInfor.getResolutionFromDt(dt, i),
                min: ExcelInfor.getMinFromDt(dt, i),
                max: ExcelInfor.getMaxFromDt(dt, i),
                dafaultVal: ExcelInfor.getDefaultValFromDt(dt, i),
                functionCode: currentSheetFunctionCode,
              );
              repeatPartInfo.add(excelInforRepeat);
            }

            if (dt.rows[i][0].toString() != "" && !dt.rows[i][0].toString().contains("重复数据区开始") && !tempFlag) {
              excelInfor.meaning = ExcelInfor.getMeaningFromDt(dt, i); //dt.rows[i][2].toString();
              excelInfor.min = ExcelInfor.getMinFromDt(dt, i);
              excelInfor.max = ExcelInfor.getMaxFromDt(dt, i);
              excelInfor.resolution = ExcelInfor.getResolutionFromDt(dt, i);
              excelInfor.type = ExcelInfor.getTypeFromDt(dt, i);

              if (i > 0 && excelInfor.type == null) {
                if ((ExcelInfor.getTypeFromDt(dt, i - 1)?.contains("int32") ?? false) || (ExcelInfor.getTypeFromDt(dt, i - 1)?.contains("float") ?? false)) {
                  excelInfoAll[int.parse('${ExcelInfor.getAddressFromDt(dt, i) ?? '-1'}')] = excelInfor;
                } else if ((ExcelInfor.getTypeFromDt(dt, i - 1)?.contains("double") ?? false) ||
                    (ExcelInfor.getTypeFromDt(dt, i - 2)?.contains("double") ?? false) ||
                    (ExcelInfor.getTypeFromDt(dt, i - 3)?.contains("double") ?? false)) {
                  excelInfoAll[int.parse('${ExcelInfor.getAddressFromDt(dt, i) ?? '-1'}')] = excelInfor;
                } else {
                  returnEntity.status = -16449008 + pagenum;
                  returnEntity.message = "协议加载失败,${"${list[pagenum]}_${i + 2}行_寄存器地址:_${dt.rows[i][0]}"}数据类型有误";
                }
              } else {
                var ifInt32Orfloat = (excelInfor.type?.contains("int32") ?? false) || (excelInfor.type?.contains("float") ?? false);
                var ifRepeatPart = (i + 1 < dt.rows.length) && ExcelInfor.getMeaningFromDt(dt, i + 1) == null && !ExcelInfor.getAddressFromDt(dt, i + 1).contains("重复数据区开始");
                if ((ifInt32Orfloat && ifRepeatPart) || (excelInfor.type?.contains("int16") ?? false)) {
                  excelInfoAll[int.parse('${ExcelInfor.getAddressFromDt(dt, i) ?? '0'}')] = excelInfor;
                } else if ((excelInfor.type?.contains("double") ?? false) &&
                    ExcelInfor.getMeaningFromDt(dt, i + 1) == null &&
                    ExcelInfor.getMeaningFromDt(dt, i + 2) == null &&
                    ExcelInfor.getMeaningFromDt(dt, i + 3) == null) {
                  excelInfoAll[int.parse('${ExcelInfor.getAddressFromDt(dt, i) ?? '0'}')] = excelInfor;
                } else {
                  returnEntity.status = -16449008 + pagenum;
                  returnEntity.message = "协议加载失败,${"${list[pagenum]}_${i + 2}行_寄存器地址:_${dt.rows[i][0]}"}数据类型有误";
                }
              }
            }
          }
          // 全部功能码数据end

          if (returnEntity.status != 0) {
            //有告警信息
            // Excel.Close();//关闭EXCEL
            return returnEntity;
          }
        }
      }

      //加载设备信息页内容
      if (list.contains("设备信息")) {
        var dt = excel.tables["设备信息"]!;
        for (int i = 2; i < dt.rows.length; i++) {
          rowNum = i;
          if (rowNum == 195) {
            print('error: $rowNum');
          }
          try {
            if (dt.rows[i][0].toString() != "" && dt.rows[i][0].toString() != "…") {
              int value1 = int.parse('${dt.rows[i][0] ?? '0'}');
              int value2 = 1;
              if (dt.rows[i].length < 5) {
              } else {
                value2 = int.parse(dt.rows[i][4].toString());
              }
              late (int, int) tempinfoname;
              if (dt.rows[i][1].toString() != "") {
                tempinfoname = (value1, value2);
                _excelInfor2BName[dt.rows[i][1].toString()] = tempinfoname;
              }
            }
            if (dt.rows[i][0].toString() == "…") {
              break;
            }
          } catch (ex) {
            returnEntity.status = -1;
            returnEntity.message = "协议加载失败,含义重复${"设备信息${i + 3}行$ex"}";
          }
        }
      }

      // Excel.Close();//解除占用
      returnEntity = Files.DeleteFile(toFilePath);
      if (returnEntity.status != 0) {
        return returnEntity;
      }
    } catch (ex) {
      // Excel.Close();//解除占用
      print('----error: ${ex.toString()}');
      Files.DeleteFile(toFilePath);

      if (ex.toString().contains("已添加了具有相同键的项") && keyType == 0) {
        //地址重复
        returnEntity.status = (-16448988 + pageNum);
      } else if (ex.toString().contains("已添加了具有相同键的项") && keyType == 1) {
        //名称重复
        returnEntity.status = -16448968 + pageNum;
      } else {
        returnEntity.status = -16449010;
      }
      returnEntity.message = "协议加载异常：$pageName页${rowNum + 1}行$ex";
    }

    return returnEntity;
  }

  @override
  Future<ReturnEntity> getRegister({required String index, required String startRegAddr, required String dataCount}) async {
    var returnEntity = ReturnEntity();
    List<Map<String, dynamic>> getRequestList = Utils.getElementsGroup(
      startRegAddr,
      excelInfoAll,
      dataCount: int.parse(dataCount),
    );
    modbusClientRtu.connect();
    if (modbusClientRtu.isConnected) {
      List resultArr = await retryGetRequest(getRequestList);
      returnEntity = handleResponse(resultArr);
    } else {
      returnEntity.status = -1;
      returnEntity.message = 'not connected or register element group is empty';
    }
    modbusClientRtu.disconnect();
    return returnEntity;
  }

  Future<ReturnEntity> get2bRegister({required String objectName}) async {
    var returnEntity = ReturnEntity();
    modbusClientRtu.connect();
    if (_excelInfor2BName[objectName] == null) {
      returnEntity.status = -1;
      returnEntity.message = 'there is no this config in excel: $objectName';
      return returnEntity;
    }
    if (modbusClientRtu.isConnected) {
      (int, int) excelConfig = _excelInfor2BName[objectName]!;
      returnEntity = retryGet2bRequest(deviceId: 2, objectId: excelConfig.$1, length: excelConfig.$2);
      if (returnEntity.status != 0) {
        return returnEntity;
      }
      Uint8List res = returnEntity.data;
      List<String> resArr = Utils.format2bResponseData(res.sublist(7, res.length - 2));
      returnEntity.data = resArr.join(',');
    } else {
      returnEntity.status = -1;
      returnEntity.message = 'not connected';
    }
    modbusClientRtu.disconnect();
    return returnEntity;
  }

  retryGet2bRequest({required int deviceId, required int objectId, required int length, int? tryTimes}) {
    int maxTry = tryTimes ?? 0;
    int resAllLength = length + 8 + 2;
    ReturnEntity returnEntity = ReturnEntity(
      data: Uint8List(resAllLength),
    );

    var pdu = Uint8List(5);
    ByteData.view(pdu.buffer)
      ..setUint8(0, 0x01) // 从机地址
      ..setUint8(1, 0x2b) //2B 功能码
      ..setUint8(2, 0x0e) // MEI类型 0E
      ..setUint8(3, deviceId) // 读设备ID码
      ..setUint8(4, objectId); // 对象ID

    var crcMsg = ModbusClientSerialRtu.computeCRC16(pdu);
    var pduWithCrc = Uint8List.fromList([...(pdu.toList()), ...(crcMsg.toList())]);

    modbusClientRtu.serialPort!.write(pduWithCrc, timeout: modbusClientRtu.responseTimeout.inMilliseconds);
    returnEntity.data = modbusClientRtu.serialPort!.read(resAllLength, timeout: 20); // modbusClientRtu.responseTimeout.inMilliseconds
    if (returnEntity.data.isEmpty) {
      returnEntity.status = -3;
      returnEntity.message = 'Serial port connection error';
      return returnEntity;
    }
    bool checkCrcResult = Utils.check2bDataCrc(returnEntity.data);
    if (!checkCrcResult && maxTry < 5) {
      return retryGet2bRequest(deviceId: deviceId, objectId: objectId, length: length);
    } else if (!checkCrcResult && maxTry >= 5) {
      returnEntity.status = -1;
      returnEntity.data = Uint8List(resAllLength);
      returnEntity.message = 'get data error';
      return returnEntity;
    }
    return returnEntity;
  }

  @override
  Future<ReturnEntity> getRegisterByName({required String index, required String startRegName, required String dataCount}) async {
    ReturnEntity returnEntity = ReturnEntity();

    return returnEntity;
  }

  @override
  Future<ReturnEntity> setRegister({required String index, required String startRegAddr, required String serializableDat, int setDatLength = 0}) async {
    var returnEntity = ReturnEntity();

    List<String> reqArr = serializableDat.split(',').toList();

    List<Map<String, dynamic>> getRequestList = Utils.getElementsGroup(
      startRegAddr,
      excelInfoAll,
      serializableDat: reqArr,
    );
    modbusClientRtu.connect();
    if (modbusClientRtu.isConnected) {
      List resultArr = await (reqArr.length == 1 ? retrySetRequest06(getRequestList, serializableDat) : retrySetRequest10(getRequestList, serializableDat));
      returnEntity = handleResponse(resultArr);
    } else {
      returnEntity.status = -1;
      returnEntity.message = 'not connected or register element group is empty';
    }
    modbusClientRtu.disconnect();
    return returnEntity;
  }

  @override
  Future<ReturnEntity> setRegisterByName({required String index, required String startRegName, required String serializableDat, int setDatLength = 0}) {
    // TODO: implement setRegisterByName
    throw UnimplementedError();
  }

  // 0x03
  retryGetRequest(List<Map<String, dynamic>> elementsGroupList, [int? tryTimes]) async {
    List resultArr = [];
    int maxTry = tryTimes ?? 0;
    print('---包数量---${elementsGroupList.length}');
    for (int i = 0; i < elementsGroupList.length; i++) {
      await modbusClientRtu.send(ModbusElementsGroup(elementsGroupList[i]['group']).getReadRequest());
      resultArr.addAll(ModbusElementsGroup(elementsGroupList[i]['group']).map((item) => item.value));
    }
    if (resultArr.contains(null) && maxTry < 5) {
      maxTry += 1;
      resultArr = [];
      print('------currentReTry------$maxTry');
      return await retryGetRequest(elementsGroupList, maxTry);
    } else if (resultArr.contains(null) && maxTry >= 5) {
      return [];
    } else {
      return resultArr;
    }
  }

  // 0x10
  retrySetRequest10(List<Map<String, dynamic>> elementsGroupList, String serializableDat, [int? tryTimes]) async {
    List resultArr = [];
    int maxTry = tryTimes ?? 0;
    print('---包数量---${elementsGroupList.length}');
    for (int i = 0; i < elementsGroupList.length; i++) {
      await modbusClientRtu.send(ModbusElementsGroup(elementsGroupList[i]['group']).getWriteRequest(elementsGroupList[i]['data'], rawValue: true));
      resultArr.addAll(ModbusElementsGroup(elementsGroupList[i]['group']).map((item) => item.value));
    }
    if (resultArr.contains(null) && maxTry < 5) {
      maxTry += 1;
      resultArr = [];
      print('------currentReTry------$maxTry');
      return await retryGetRequest(elementsGroupList, maxTry);
    } else if (resultArr.contains(null) && maxTry >= 5) {
      return [];
    } else {
      return resultArr;
    }
  }

  // 0x06
  retrySetRequest06(List<Map<String, dynamic>> elementsGroupList, String serializableDat, [int? tryTimes]) async {
    List resultArr = [];
    int maxTry = tryTimes ?? 0;
    // 0x06只有一个element，不需要循环
    var element = elementsGroupList[0]['group'][0];
    var data = elementsGroupList[0]['data'][0];
    await modbusClientRtu.send(element.getWriteRequest(data, rawValue: true));
    resultArr.add(element.value);

    if (resultArr.contains(null) && maxTry < 5) {
      maxTry += 1;
      resultArr = [];
      print('------currentReTry------$maxTry');
      return await retryGetRequest(elementsGroupList, maxTry);
    } else {
      return resultArr;
    }
  }

  // 处理返回的数据arr
  ReturnEntity handleResponse(List resArr) {
    var returnEntity = ReturnEntity();
    if (resArr.isEmpty || resArr.contains(null)) {
      returnEntity.status = -1;
      returnEntity.message = 'No modbus Slave';
      returnEntity.data = '';
    } else {
      returnEntity.data = resArr.join(',');
    }
    return returnEntity;
  }
}
