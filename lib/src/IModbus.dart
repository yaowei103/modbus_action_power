// ignore_for_file: constant_identifier_names

import 'dart:io';
import 'dart:typed_data';

import 'package:modbus_action_power/packages/modbus_client/modbus_client.dart';
import 'package:path_provider/path_provider.dart';
import 'package:spreadsheet_decoder/spreadsheet_decoder.dart';

import '../entity/InfoRTU.dart';
import '../packages/modbus_client/src/modbus_file_record.dart';
import '../packages/modbus_client_serial/modbus_client_serial.dart';

import '../entity/ReturnEntity.dart';
import '../utils/ModbusFiles.dart';
import '../utils/Utils.dart';

enum ModbusMasterType {
  RTU,
  TCP,
}

class SerialPort {
  String? portName;
  int? baudRate;
  SerialParity? parity;
  int? dataBits;
  SerialStopBits? stopBits;
  int? readTimeout;
  int? writeTimeout;

  SerialPort({
    this.portName,
    this.baudRate,
    this.parity,
    this.dataBits,
    this.stopBits,
    this.readTimeout,
    this.writeTimeout,
  });
}

/// Modbus 通信接口
abstract class IModbus {
  /// 含义名称加载信息
  final Map<String, (int, int)> excelInfo2BName = {};
  // ModbusMasterType _masterType = ModbusMasterType.RTU;

  late InfoRTU infoRTU;

  /// 0x03, 0x06, 0x10, 0x14，0x15功能码 excel集合
  /// key: 在0x03， 0x06, 0x10功能码的时候, key = 寄存器地址
  /// key： 在0x14, 0x15功能码的时候，key = (文件名 << 16位) + 记录号
  Map<int, ExcelInfo> excelInfoAll = {};

  late ModbusClientSerialRtu modbusClientRtu;
  String filePath = '';
  String fileName = ''; // modbus 协议配置文件名称
  String toFilePath = '';

  int maxRetry = 5;

  // 用于故障上报
  int pageNum = 0; //页签索引页，用于故障上报索引
  String pageName = "";
  int rowNum = 0; //行索引，用于故障上报索引

  Future<ReturnEntity> initMaster(String filePathStr);

  /// index 设备索引号，0起始
  /// startRegAddr 更新寄存器起始地址
  /// serializableDat 待更新寄存器数据，数据以‘,’分割
  /// SetDatLength 下发数据长度，下发默认值时使用
  Future<ReturnEntity> setRegister({
    required String index,
    required String startRegAddr,
    required String serializableDat,
  });

  /// index 设备索引号
  /// startRegName 更新寄存器起始含义
  /// serializableDat 待更新寄存器数据，数据以‘,’分割
  /// SetDatLength 下发数据长度，下发默认值时使用
  // Future<ReturnEntity> setRegisterByName({
  //   required String index,
  //   required String startRegName,
  //   required String serializableDat,
  //   int setDatLength = 0,
  // });

  /// index 设备地址
  /// startRegAddr 寄存器起始地址
  /// dataCount 读取数据个数
  Future<ReturnEntity> getRegister({
    required String index,
    required String startRegAddr,
    required String dataCount,
  });

  /// 通过寄存器物理量名称从设备读取规定寄存器对应的实际物理量
  ///
  /// index 设备地址
  /// startRegName 首个寄存器名称
  /// dataCount 读取数据个数
  // Future<ReturnEntity> getRegisterByName({
  //   required String index,
  //   required String startRegName,
  //   required String dataCount,
  // });

  // 2b 功能码
  Future<ReturnEntity> get2bRegister({required String objectName});

  Future<ReturnEntity> readComFileInfo1() async {
    ReturnEntity returnEntity = ReturnEntity(); //异常信息返回对象
    try {
      // returnEntity = await Files.copyFileToLocal(filePath, toFilePath); //协议文件备份
      // if (returnEntity.status != 0) {
      //   return returnEntity;
      // }
      // toFilePath = returnEntity.data!;
      // init之前已经copy过modbus配置文件
      var supportDir = await getApplicationSupportDirectory();
      toFilePath = '${supportDir.path}/$fileName';

      /// 读取协议文件
      var bytes = File(toFilePath).readAsBytesSync();
      var excel = SpreadsheetDecoder.decodeBytes(bytes);
      List<String> list = excel.tables.keys.toList(); //获取协议所有页签
      //获取通信对象及通信规约类型
      if (list.contains("Modbus-TCP")) {
        Utils.log('读取Modbus-TCP配置');
      } else if (list.contains("Modbus-RTU")) {
        SpreadsheetTable dt = excel.tables['Modbus-RTU']!;
        // _masterType = ModbusMasterType.RTU;
        infoRTU = InfoRTU.fromDataTable(dt);
      }
      //int[] ErrorCode = { -16449008, -16449007 };
      //将各个sheet数据加载到对应字典中，key为地址
      for (int pagenum = 0; pagenum < list.length; pagenum++) {
        pageNum = pagenum;
        pageName = list[pagenum];
        List<String> notDataSheets = ["Modbus-TCP", "Modbus-RTU", "TCP通讯设置", "RTU通讯设置", "大小端配置", "设备信息"];

        if (notDataSheets.contains(list[pagenum])) {
          //不加载这些配置sheet信息
          continue;
        } else {
          List<String> rowString = excel.tables[pageName]!.rows[0].map((e) => e.toString()).toList(); //读取本Sheet页首行信息，从而得到它支持的功能码
          String char = '码';
          List<String> sArray = rowString[0].split(char);
          String functionCode = sArray.last.toLowerCase(); //得到功能码信息
          List<String> currentSheetFunctionCode = ['0x03', '0x06', '0x10', '0x2b', '0x14', '0x15'].where((e) {
            return functionCode.contains(e);
          }).toList();
          bool ifFileFunctionCode = currentSheetFunctionCode.contains('0x14') || currentSheetFunctionCode.contains('0x15');
          Stopwatch sw = Stopwatch()..start();
          var dt = excel.tables[pageName]!;
          sw.stop();
          Utils.log("Work done! Sheet $pageName used time: ${sw.elapsedMicroseconds}ms.");

          // 循环rows放入excelInfoAll中
          /// 单个重复区数据
          List<ExcelInfo> repeatPartInfo = [];

          /// 重复数据个数
          int tempNum = 0;

          /// 当前循环重复区 开始key
          int key = 0;

          /// 是否位于重复区段
          bool tempFlag = false;

          for (int i = 2; i < dt.rows.length; i++) {
            rowNum = i;
            ExcelInfo excelInfo = ExcelInfo(); // 每行的excelInfo
            // 寄存器重复区
            bool? registerRepeatStart = ExcelInfo.getAddressFromDt(dt, i)?.contains('重复数据区开始');
            bool? registerRepeatEnd = ExcelInfo.getAddressFromDt(dt, i)?.contains('重复数据区结束');
            // 文件功能码重复区
            bool? fileRepeatStart = ExcelInfo.getFileNameFromDt(dt, i)?.contains('重复数据区开始');
            bool? fileRepeatEnd = ExcelInfo.getFileNameFromDt(dt, i)?.contains('重复数据区结束');

            // excelInfo 赋值变量
            String? registerAddress = ExcelInfo.getAddressFromDt(dt, i);
            String? excelInfoMeaning = ExcelInfo.getMeaningFromDt(dt, i);
            String? excelInfoType = ExcelInfo.getTypeFromDt(dt, i);
            String? excelInfoUnit = ExcelInfo.getUnitFromDt(dt, i);
            double? excelInfoResolution = ExcelInfo.getResolutionFromDt(dt, i);
            double? excelInfoMin = ExcelInfo.getMinFromDt(dt, i);
            double? excelInfoMax = ExcelInfo.getMaxFromDt(dt, i);
            String? excelInfoDefaultVal = ExcelInfo.getDefaultValFromDt(dt, i);
            String? excelInfoFileNum = ExcelInfo.getFileNameFromDt(dt, i);
            String? excelInfoRecordNum = ExcelInfo.getFileRecordNumberFromDt(dt, i);

            // 重复区开始
            if (registerRepeatStart ?? fileRepeatStart ?? false) {
              tempFlag = true;
              tempNum = int.parse(dt.rows[i][1].toString()); // 重复数据个数
              key = fileRepeatStart == true
                  ? ((int.parse(dt.rows[i + 1][0].toString()) << 16) + int.parse(dt.rows[i + 1][1].toString()))
                  : int.parse(dt.rows[i + 1][0].toString()); // 当前循环重复区 开始key
              continue;
            }

            // 重复区结束
            if (registerRepeatEnd ?? fileRepeatEnd ?? false) {
              if (tempFlag) {
                // 循环重复区
                int repeatLength = repeatPartInfo.length;
                int repeatItemKey = key;
                for (int w = 0; w < tempNum; w++) {
                  // 循环重复区每个item
                  for (int j = 0; j < repeatLength; j++) {
                    ExcelInfo repeatItemExcelInfo = ExcelInfo.copy(repeatPartInfo[j]);
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

            // 重复区数据 放入重复区数组
            if (tempFlag) {
              ExcelInfo excelInfoRepeat = ExcelInfo(
                meaning: excelInfoMeaning, //currentRow[2],
                type: excelInfoType, //currentRow[3],
                unit: excelInfoUnit, //currentRow[4],
                resolution: excelInfoResolution,
                min: excelInfoMin,
                max: excelInfoMax,
                defaultVal: excelInfoDefaultVal,
                functionCode: currentSheetFunctionCode,
                fileNum: int.tryParse(excelInfoFileNum ?? ''),
                recordNum: int.tryParse(excelInfoRecordNum ?? ''),
              );
              repeatPartInfo.add(excelInfoRepeat);
            }

            if (dt.rows[i][0].toString() != "" && !dt.rows[i][0].toString().contains("重复数据区开始") && !tempFlag) {
              excelInfo.meaning = excelInfoMeaning; //dt.rows[i][2].toString();
              excelInfo.type = excelInfoType;
              excelInfo.unit = excelInfoUnit;
              excelInfo.resolution = excelInfoResolution;
              excelInfo.min = excelInfoMin;
              excelInfo.max = excelInfoMax;
              excelInfo.defaultVal = excelInfoDefaultVal;
              excelInfo.functionCode = currentSheetFunctionCode;
              excelInfo.fileNum = int.tryParse(excelInfoFileNum ?? '');
              excelInfo.recordNum = int.tryParse(excelInfoRecordNum ?? '');

              // 如果是文件功能码
              int excelInfoKey = ifFileFunctionCode ? ((int.parse(excelInfoFileNum!) << 16) + int.parse(excelInfoRecordNum!)) : int.parse(registerAddress!);

              if (i > 0 && excelInfo.type == null) {
                if ((ExcelInfo.getTypeFromDt(dt, i - 1)?.contains("int32") ?? false) || (ExcelInfo.getTypeFromDt(dt, i - 1)?.contains("float") ?? false)) {
                  // excelInfoAll[int.parse('${ExcelInfo.getAddressFromDt(dt, i) ?? '-1'}')] = excelInfo;
                  excelInfoAll[excelInfoKey] = excelInfo;
                } else if ((ExcelInfo.getTypeFromDt(dt, i - 1)?.contains("double") ?? false) ||
                    (ExcelInfo.getTypeFromDt(dt, i - 2)?.contains("double") ?? false) ||
                    (ExcelInfo.getTypeFromDt(dt, i - 3)?.contains("double") ?? false)) {
                  excelInfoAll[excelInfoKey] = excelInfo;
                } else {
                  returnEntity.status = -16449008 + pagenum;
                  returnEntity.message = "协议加载失败,${list[pagenum]}_${i + 2}行_寄存器地址:_${dt.rows[i][0]}数据类型有误";
                }
              } else {
                var ifInt32Orfloat = ((excelInfo.type?.contains('int32') ?? false) || (excelInfo.type?.contains('float') ?? false)) &&
                    (i + 1 < dt.rows.length) &&
                    ExcelInfo.getMeaningFromDt(dt, i + 1) == null &&
                    !(ExcelInfo.getAddressFromDt(dt, i + 1)?.contains('重复数据区开始') ?? false || ExcelInfo.getFileNameFromDt(dt, i + 1)?.contains('重复数据区开始'));

                if (ifInt32Orfloat || (excelInfo.type?.contains("int16") ?? false)) {
                  excelInfoAll[excelInfoKey] = excelInfo;
                } else if ((excelInfo.type?.contains("double") ?? false) &&
                    ExcelInfo.getMeaningFromDt(dt, i + 1) == null &&
                    ExcelInfo.getMeaningFromDt(dt, i + 2) == null &&
                    ExcelInfo.getMeaningFromDt(dt, i + 3) == null) {
                  excelInfoAll[excelInfoKey] = excelInfo;
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
          try {
            if (dt.rows[i][0].toString() != "" && dt.rows[i][0].toString() != "…") {
              int value1 = int.parse('${dt.rows[i][0] ?? '0'}');
              int value2 = 1;
              if (dt.rows[i].length < 5) {
              } else {
                value2 = int.parse(dt.rows[i][4].toString());
              }
              late (int, int) tempInfoName;
              if (dt.rows[i][1].toString() != "") {
                tempInfoName = (value1, value2);
                excelInfo2BName[dt.rows[i][1].toString()] = tempInfoName;
              }
            }
            if (dt.rows[i][0].toString() == "…") {
              break;
            }
          } catch (ex) {
            returnEntity.status = -1;
            returnEntity.message = "协议加载失败,含义重复${"设备信息${i + 1}行$ex"}";
          }
        }
      }

      // Excel.Close();//解除占用
      returnEntity = ModbusFiles.DeleteFile(toFilePath);
      if (returnEntity.status != 0) {
        return returnEntity;
      }
    } catch (ex) {
      // Excel.Close();//解除占用
      Utils.log('---error: ${ex.toString()}');
      ModbusFiles.DeleteFile(toFilePath);

      returnEntity.message = "协议加载异常：$pageName页${rowNum + 1}行：$ex";
    }

    return returnEntity;
  }

  // 单次发送2b请求
  /// subDeviceId 从机地址
  /// readDeviceId 读设备ID码
  /// objectId 起始对象ID
  /// length 对象字节数量
  ReturnEntity retryGet2bRequest({
    required int subDeviceId,
    required int readDeviceId,
    required int objectId,
    required int length,
    int tryTimes = 0,
  }) {
    int resAllLength = length + 8 + 2;
    ReturnEntity returnEntity = ReturnEntity(
      data: Uint8List(resAllLength),
    );

    var pdu = Uint8List(5);
    ByteData.view(pdu.buffer)
      ..setUint8(0, 0x01) // 从机地址
      ..setUint8(1, 0x2b) // 2B 功能码
      ..setUint8(2, 0x0e) // MEI类型 0E
      ..setUint8(3, readDeviceId) // 读设备ID码
      ..setUint8(4, objectId); // 对象ID

    returnEntity.data = customSendData(pdu, resAllLength);

    if (returnEntity.data.isEmpty) {
      returnEntity.status = -3;
      returnEntity.message = 'Serial port connection error';
      return returnEntity;
    }
    bool checkCrcResult = Utils.checkResDataCrc(returnEntity.data);
    if (!checkCrcResult && tryTimes < maxRetry) {
      return retryGet2bRequest(subDeviceId: subDeviceId, readDeviceId: readDeviceId, objectId: objectId, length: length, tryTimes: tryTimes + 1);
    } else if (!checkCrcResult && tryTimes >= maxRetry) {
      returnEntity.status = -1;
      returnEntity.data = Uint8List(resAllLength);
      returnEntity.message = 'get 2b data error';
      return returnEntity;
    }
    return returnEntity;
  }

  /// 0x14
  /// allPackageData List<List<ReadFileInfo>> 包集合
  /// List<ReadFileInfo> 单包
  Future<ReturnEntity<List<int>>> readFileRequest({required List<List<ReadFileInfo>> allPackageData}) async {
    var returnEntity = ReturnEntity<List<int>>();
    List<List<int>> resultArr = [];
    // 每个数据的占据寄存器个数，方便做结果数据组装,元素个数和结果个数相等
    List<int> resultTypeMapping = [];
    // 循环发送多包数据
    Utils.log('===包数量：${allPackageData.length}');
    for (int i = 0; i < allPackageData.length; i++) {
      List<ModbusFileRecord> singlePackageRecords = allPackageData[i].map((item) {
        resultTypeMapping.addAll(item.dataSizes);
        return ModbusFileRecord.empty(
          fileNumber: item.fileNum,
          recordNumber: item.recordNum,
          recordLength: item.recordLength,
        );
      }).toList();
      Utils.log('===当前包：${singlePackageRecords.map((item) => '${item.fileNumber}-${item.recordNumber}-${item.recordLength}').toList().join(',')}');
      ModbusFileRecordsReadRequest request = ModbusFileRecordsReadRequest(singlePackageRecords);

      ModbusResponseCode responseCode = await retrySinglePackage(
        request: request,
        packageIndex: i,
      );
      if (responseCode != ModbusResponseCode.requestSucceed) {
        returnEntity.status = -3;
        returnEntity.message = responseCode.name;
        return returnEntity;
      }
      resultArr.addAll(request.fileRecords.map((e) => e.recordBytes).toList());
    }
    // 结果全部展开
    List<int> expandResultArr = resultArr.expand((element) => element).toList();
    // 返回的结果
    List<int> resArr = [];
    for (int i = 0; i < resultTypeMapping.length; i++) {
      int dataType = resultTypeMapping[i];
      if (dataType == 1) {
        resArr.add(expandResultArr.removeAt(0));
      } else {
        int hi = expandResultArr.removeAt(0);
        int lo = expandResultArr.removeAt(0);
        resArr.add((hi << 16) + lo);
      }
    }
    returnEntity.data = resArr;
    return returnEntity;
  }

  /// 直接调用串口发送数据
  /// {@param pdu} 要发送的数据，不包括CRC
  /// {@param resSize} 响应总字节长度
  Uint8List customSendData(Iterable<int> pdu, int resSize) {
    Uint8List crcMsg = ModbusClientSerialRtu.computeCRC16(pdu);
    Uint8List pduWithCrc = Uint8List.fromList([...(pdu.toList()), ...(crcMsg.toList())]);

    modbusClientRtu.serialPort!.write(pduWithCrc, timeout: modbusClientRtu.responseTimeout.inMilliseconds);
    return modbusClientRtu.serialPort!.read(resSize, timeout: modbusClientRtu.responseTimeout.inMilliseconds);
  }

  /// 发送单包数据
  /// {@param request} ModbusRequest
  /// {@param retry} 第几次重试
  /// {@param packageIndex} 发送第几包数据
  Future<ModbusResponseCode> retrySinglePackage({
    required ModbusRequest request,
    int retry = 0,
    required int packageIndex,
  }) async {
    ModbusResponseCode responseCode = await modbusClientRtu.send(request);
    if (responseCode == ModbusResponseCode.requestSucceed) {
      return responseCode;
    } else if (retry < maxRetry) {
      Utils.log('---重发 第${packageIndex + 1}包第${retry + 1}次, $responseCode');
      await Future.delayed(const Duration(milliseconds: 2));
      return retrySinglePackage(request: request, retry: retry + 1, packageIndex: packageIndex);
    } else {
      return responseCode;
    }
  }

  // 0x03
  Future<ReturnEntity> getRequest03({required List<Map<String, dynamic>> elementsGroupList}) async {
    var returnEntity = ReturnEntity();
    List resultArr = [];
    Utils.log('===包数量：${elementsGroupList.length}');
    for (int i = 0; i < elementsGroupList.length; i++) {
      ModbusResponseCode responseCode = await retrySinglePackage(
        request: ModbusElementsGroup(elementsGroupList[i]['group']).getReadRequest(),
        packageIndex: i,
      );
      if (responseCode != ModbusResponseCode.requestSucceed) {
        returnEntity.status = -3;
        returnEntity.message = responseCode.name;
        return returnEntity;
      }
      resultArr.addAll(ModbusElementsGroup(elementsGroupList[i]['group']).map((item) => item.value));
    }

    returnEntity.data = resultArr.join(',');
    return returnEntity;
  }

  // 0x06
  Future<ReturnEntity> setRequest06({
    required List<Map<String, dynamic>> elementsGroupList,
    required String serializableDat,
    int? tryTimes,
  }) async {
    var returnEntity = ReturnEntity();
    List resultArr = [];
    // 0x06只有一个element，不需要循环
    var element = elementsGroupList[0]['group'][0];
    var data = elementsGroupList[0]['data'][0];
    ModbusResponseCode responseCode = await retrySinglePackage(
      request: element.getWriteRequest(data, rawValue: true),
      packageIndex: 0,
    );
    if (responseCode != ModbusResponseCode.requestSucceed) {
      returnEntity.status = -3;
      returnEntity.message = responseCode.name;
      return returnEntity;
    }
    resultArr.add(element.value);

    returnEntity.data = resultArr.join(',');
    return returnEntity;
  }

  // 0x10
  Future<ReturnEntity> setRequest10({
    required List<Map<String, dynamic>> elementsGroupList,
    required String serializableDat,
  }) async {
    var returnEntity = ReturnEntity();
    List resultArr = [];
    Utils.log('===包数量：${elementsGroupList.length}');
    for (int i = 0; i < elementsGroupList.length; i++) {
      ModbusResponseCode responseCode = await retrySinglePackage(
        request: ModbusElementsGroup(elementsGroupList[i]['group']).getWriteRequest(elementsGroupList[i]['data'], rawValue: true),
        packageIndex: i,
      );
      if (responseCode != ModbusResponseCode.requestSucceed) {
        returnEntity.status = -3;
        returnEntity.message = responseCode.name;
        return returnEntity;
      }
      resultArr.addAll(ModbusElementsGroup(elementsGroupList[i]['group']).map((item) => item.value));
      // 多包连续发送返回错误码的概率30%-50%, 每包延迟发送，单包错误码概率降低到5%以下
      await Future.delayed(const Duration(milliseconds: 2));
    }
    returnEntity.data = resultArr.join(',');
    return returnEntity;
  }
}
