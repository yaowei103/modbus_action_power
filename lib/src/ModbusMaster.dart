import 'dart:typed_data';

// import 'package:excel/excel.dart';
import 'package:modbus_action_power/src/IModbus.dart';
import 'package:modbus_action_power/entity/ReturnEntity.dart';
import 'package:modbus_action_power/utils/Utils.dart';
import '../packages/modbus_client/modbus_client.dart';
import '../packages/modbus_client_serial/modbus_client_serial.dart';

class ModbusMaster extends IModbus {
  /// init master之前，调用Files.copyFileToSupportDir,将modbus协议文件copy到supportDir，
  /// 然后直接从getApplicationSupportDirectory目录读取
  @override
  Future<ReturnEntity> initMaster(String filePathStr) async {
    var stopwatchInit = Stopwatch()..start();
    var returnEntity = ReturnEntity();
    filePath = filePathStr;
    fileName = filePathStr.split('/').last;
    // var readComFileResult = await readComFileInfo();
    var readComFileResult = await readComFileInfo1();
    if (readComFileResult.status != 0) {
      Utils.log(readComFileResult.message);
      return readComFileResult;
    }
    modbusClientRtu = ModbusClientSerialRtu(
      portName: '/dev/${infoRTU.portNames[0]}', //'ttyS3',
      unitId: 1,
      connectionMode: ModbusConnectionMode.autoConnectAndKeepConnected, // 必须要长连，否则如果报故障的时候，会发生03重查导致异常退出
      baudRate: infoRTU.baudRates[0],
      dataBits: SerialDataBits.bits8,
      stopBits: infoRTU.stopBits[0],
      parity: infoRTU.parities[0],
      flowControl: SerialFlowControl.none,
      responseTimeout: Duration(milliseconds: int.parse(infoRTU.timeout)),
    );
    modbusClientRtu.connect();
    Utils.log('init modbus done!, time: ${(stopwatchInit..stop()).elapsedMilliseconds}');

    return returnEntity;
  }

  @override
  Future<ReturnEntity> getRegister({required String index, required String startRegAddr, required String dataCount}) async {
    // excelInfoAll[99999999] = ExcelInfo(
    //   meaning: '无此地址',
    //   type: 'int16',
    // );
    var returnEntity = ReturnEntity();
    ReturnEntity<List<Map<String, dynamic>>?> getRequestList = Utils.getElementsGroup(
      startRegAddr,
      excelInfoAll,
      dataCount: int.parse(dataCount),
    );
    if (getRequestList.status != 0) {
      return getRequestList;
    }
    // modbusClientRtu.connect();
    if (modbusClientRtu.isConnected) {
      returnEntity = await getRequest03(elementsGroupList: getRequestList.data!);
    } else {
      returnEntity.status = -1;
      returnEntity.message = 'not connected or register element group is empty';
    }
    // modbusClientRtu.disconnect();
    return returnEntity;
  }

  @override
  Future<ReturnEntity> setRegister({required String index, required String startRegAddr, required String serializableDat}) async {
    var returnEntity = ReturnEntity();
    List<String> reqArr = serializableDat.split(',').toList();

    ReturnEntity<List<Map<String, dynamic>>?> getRequestList = Utils.getElementsGroup(
      startRegAddr,
      excelInfoAll,
      serializableDat: reqArr,
    );
    if (getRequestList.status != 0) {
      return getRequestList;
    }
    // modbusClientRtu.connect();
    if (modbusClientRtu.isConnected) {
      returnEntity = await (reqArr.length == 1
          ? setRequest06(
              elementsGroupList: getRequestList.data!,
              serializableDat: serializableDat,
            )
          : setRequest10(
              elementsGroupList: getRequestList.data!,
              serializableDat: serializableDat,
            ));
    } else {
      returnEntity.status = -3;
      returnEntity.message = 'not connected or register element group is empty';
    }
    // modbusClientRtu.disconnect();
    return returnEntity;
  }

  // @param objectName 对象名称
  @override
  Future<ReturnEntity> get2bRegister({required String objectName}) async {
    var returnEntity = ReturnEntity();
    // modbusClientRtu.connect();
    if (excelInfo2BName[objectName] == null) {
      returnEntity.status = -1;
      returnEntity.message = 'there is no this config in excel: $objectName';
      return returnEntity;
    }
    if (modbusClientRtu.isConnected) {
      (int, int) excelConfig = excelInfo2BName[objectName]!;
      returnEntity = retryGet2bRequest(
        deviceId: 2,
        objectId: excelConfig.$1,
        length: excelConfig.$2,
      );
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
    // modbusClientRtu.disconnect();
    return returnEntity;
  }

  // Future<ReturnEntity> readFile({
  //   required List<ReadFileInfo> readFileInfoList,
  //   required int index,
  // }) {}
}
