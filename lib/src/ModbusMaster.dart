import 'dart:io';

// import 'package:excel/excel.dart';
import 'package:intl/intl.dart';
import 'package:modbus_action_power/src/IModbus.dart';
import 'package:modbus_action_power/src/ReturnEntity.dart';
import 'package:spreadsheet_decoder/spreadsheet_decoder.dart';
import 'package:modbus_action_power/utils/Utils.dart';
import '../packages/modbus_client/modbus_client.dart';
import '../packages/modbus_client_serial/modbus_client_serial.dart';

import 'Files.dart';

class ModbusMaster extends IModbus {
  /// 地址为Key值，其他信息为字典的Value
  // 写文件字典信息
  Map<String, ExcelInfor> writefileInfo = {};
  // 读文件字典信息
  Map<String, ExcelInfor> readfileInfo = {};
  // 03功能码加载信息
  Map<int, ExcelInfor> _ExcelInfor03 = {};
  // 06功能码加载信息
  Map<int, ExcelInfor> _ExcelInfor06 = {};
  // 10功能码加载信息
  Map<int, ExcelInfor> _ExcelInfor10 = {};
  // 01功能码加载信息
  Map<int, ExcelInfor> _ExcelInfor01 = {};
  // 05功能码加载信息
  Map<int, ExcelInfor> _ExcelInfor05 = {};
  // 04功能码加载信息
  Map<int, ExcelInfor> _ExcelInfor04 = {};
  // 0F功能码加载信息
  Map<int, ExcelInfor> _ExcelInfor0F = {};
  // 02功能码加载信息
  Map<int, ExcelInfor> _ExcelInfor02 = {};

  /// 含义名称加载信息
  late ModbusClientSerialRtu modbusClientTest;
  Map<String, int> _ExcelInforName = {};
  Map<String, (int, int)> _ExcelInfor2BName = {};
  Map<int, (String, int, int)> _TcpSet = {};
  Map<int, (int, SerialPort)> _RtuSet = {};

  Map<int, ModbusClientSerialRtu> _client = {};
  Map<int, ModbusClientSerialRtu> _tcpclient = {};
  late ModbusClientSerialRtu _rtuclient;

  ModbusMasterType _masterType = ModbusMasterType.RTU;
  String? ipAddress;
  int? port;
  int readTimeout = 1000;
  int writeTimeout = 1000;
  final int sendOrReadMax = 100;
  final int sendOrReadCoilsMax = 800;
  int unitIdentifier = 1;
  String cRCType = "大端";
  String dataType = "大端";
  String regType = "大端";
  bool cRCTypeFlag = false;
  bool dataTypeFlag = false;
  bool regTypeFlag = false;
  (bool, bool, bool)? tuple;

  SerialPort serialPortRtu = SerialPort();
  List<int> rtu_unitIdentifier = [];
  List<String> portnames = [];
  int retransmissionsNum = 3;
  // EasyModbus.ModbusClient modbusClient = EasyModbus.ModbusClient();
  Map<int, bool> connected = {};
  String protocol = ""; //协议文件全路径
  String toFilePath = "";

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

  static int comIndex = 0;

  /// 重写后新增 start
  late Map<int, ExcelInfor> excelInfoAll;
  late ModbusClientSerialRtu modbusClientRtu;
  String filePath = 'assets/ppmDCModbus2.xlsx';

  Future<ReturnEntity> initMaster() async {
    var returnEntity = ReturnEntity();
    var readComFileResult = await readComFileInfo(filePath);
    if (readComFileResult.status != 0) {
      return readComFileResult;
    }
    modbusClientRtu = ModbusClientSerialRtu(
      portName: '/dev/${_RtuSet[0]!.$2.portName}', //'ttyS3',
      unitId: 1,
      baudRate: SerialBaudRate.b1000000,
      dataBits: SerialDataBits.bits8,
      stopBits: SerialStopBits.one,
      parity: SerialParity.none,
      flowControl: SerialFlowControl.none,
      responseTimeout: const Duration(milliseconds: 2000),
    );
    modbusClientRtu.connect();

    if (!modbusClientRtu.isConnected) {
      print('----init error, disConnected-----');
      returnEntity.status = -1;
      returnEntity.message = 'init connect error';
    } else {
      print('----init success, connected success----');
    }
    return returnEntity;
  }

  /// 重写后新增 end

  /// 加载协议
  /// <param name="protocol">协议文件全路径</param>
  @override
  Future<ReturnEntity> readComFileInfo(String protocol1) async {
    protocol = protocol1;
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
      returnEntity = await Files.copyFileToLocal(protocol, toFilePath); //协议文件备份
      if (returnEntity.status != 0) {
        return returnEntity;
      }
      // Excel.CreateWorkbook(toFilePath, 1);//调用FILEIO组件
      toFilePath = returnEntity.data!;
      ModbusClientSerialRtu modbusClient2 = ModbusClientSerialRtu(portName: "COM2", unitId: 1);
      modbusClientTest = ModbusClientSerialRtu(portName: "COM2", unitId: 1);

      // TODO:读取协议文件，并检查协议文件正确性
      // #region
      var bytes = File(toFilePath).readAsBytesSync();
      var excel = SpreadsheetDecoder.decodeBytes(bytes);
      List<String> list = excel.tables.keys.toList(); //获取协议所有页签
      //获取通信对象及通信规约类型
      if (list.contains("Modbus-TCP")) {
        // _masterType = ModbusMasterType.TCP;
        // var dt = Excel.ImportToTable(list.IndexOf("Modbus-TCP"), 3, 12);
        // string[] Ip = dt.rows[0][1].toString().Split(',');//字符串数据包转存入数组strArray
        // string[] Ports = dt.rows[1][1].toString().Split(',');//字符串数据包转存入数组strArray
        // string[] Id = dt.rows[2][1].toString().Split(',');//字符串数据包转存入数组strArray
        // Tuple<string, int, byte> tcp_tuple = null;
        // for (int i = 0; i < Ip.Length; i++)
        // {
        //   tcp_tuple = new Tuple<string, int, byte>(Ip[i], int.parse(Ports[i]), (byte)(int.parse(Id[i])));
        //
        //   _TcpSet.Add(i, tcp_tuple);
        // }
        // RetransmissionsNum = int.parse(dt.rows[3][1]);
        // readTimeout = int.parse(dt.rows[4][1]);
        // writeTimeout = int.parse(dt.rows[4][1]);
        // CRCType = dt.rows[6][1].toString();
        // DataType = dt.rows[7][1].toString();
        // RegType = dt.rows[8][1].toString();
        // if (CRCType.contains("大端"))
        // {
        //   CRCTypeFlag = true;
        // }
        // else
        // {
        //   CRCTypeFlag = false;
        // }
        // if (DataType.contains("小端"))
        // {
        //   DataTypeFlag = true;
        // }
        // else
        // {
        //   DataTypeFlag = false;
        // }
        // if (RegType.contains("小端"))
        // {
        //   RegTypeFlag = true;
        // }
        // else
        // {
        //   RegTypeFlag = false;
        // }
        // tuple = new Tuple<bool, bool, bool>(CRCTypeFlag, DataTypeFlag, RegTypeFlag);
      } else if (list.contains("Modbus-RTU")) {
        _masterType = ModbusMasterType.RTU;
        var dt = excel.tables['Modbus-RTU']!;
        List<String> com = dt.rows[3][1].toString().split(','); //字符串数据包转存入数组strArray
        List<String> baudRate = dt.rows[4][1].toString().split(','); //字符串数据包转存入数组strArray
        List<String> stopBit = dt.rows[5][1].toString().split(','); //字符串数据包转存入数组strArray
        List<String> paritys = dt.rows[6][1].toString().split(','); //字符串数据包转存入数组strArray
        List<String> id = dt.rows[7][1].toString().split(','); //字符串数据包转存入数组strArray

        for (int i = 0; i < com.length; i++) {
          // SerialPort serialport = new SerialPort();
          SerialStopBits stopBits = SerialStopBits.one;
          SerialParity parity = SerialParity.even;
          late (int, SerialPort) rtuTuple;
          // serialport.portName = com[i];
          // serialport.baudRate = int.parse(baudRate[i]);
          if (i == 0) {
            retransmissionsNum = int.parse(dt.rows[8][1].toString());
          }
          // serialport.ReadTimeout = int.parse(dt.rows[6][1].toString());
          // serialport.WriteTimeout = int.parse(dt.rows[6][1].toString());
          int stopBittemp = int.parse(stopBit[i]);

          switch (stopBittemp) {
            case 1:
              stopBits = SerialStopBits.one;
              break;
            case 2:
              stopBits = SerialStopBits.two;
              break;
            case 0:
              stopBits = SerialStopBits.none;
              break;
          }
          int parityTemp = int.parse(paritys[i]);
          switch (parityTemp) {
            case 1:
              parity = SerialParity.odd;
              break;
            case 2:
              parity = SerialParity.even;
              break;
            case 0:
              parity = SerialParity.none;
              break;
          }
          SerialPort serialport = SerialPort(
            portName: com[i],
            baudRate: int.parse(baudRate[i]),
            parity: parity,
            stopBits: stopBits,
            readTimeout: int.parse(dt.rows[9][1].toString()),
            writeTimeout: int.parse(dt.rows[9][1].toString()),
          );
          rtu_unitIdentifier.add(int.parse(id[i]));
          rtuTuple = (int.parse(id[i]), serialport);
          _RtuSet[i] = rtuTuple;
        }
        cRCType = dt.rows[11][1].toString();
        dataType = dt.rows[12][1].toString();
        regType = dt.rows[13][1].toString();
        // if (cRCType.contains("大端")) {
        //   cRCTypeFlag = true;
        // } else {
        //   cRCTypeFlag = false;
        // }
        cRCTypeFlag = cRCType.contains("大端");
        // if (dataType.contains("小端")) {
        //   dataTypeFlag = true;
        // } else {
        //   dataTypeFlag = false;
        // }
        dataTypeFlag = dataType.contains("小端");
        // if (regType.contains("小端")) {
        //   regTypeFlag = true;
        // } else {
        //   regTypeFlag = false;
        // }
        regTypeFlag = regType.contains("小端");
        tuple = (cRCTypeFlag, dataTypeFlag, regTypeFlag);
      }
      //int[] ErrorCode = { -16449008, -16449007 };
      //将各个sheet数据加载到对应字典中，key为地址
      for (int pagenum = 0; pagenum < list.length; pagenum++) {
        keyType = 0;
        pageNum = pagenum;
        pageName = list[pagenum];
        if (list[pagenum].contains("Modbus-TCP") ||
            list[pagenum].contains("Modbus-RTU") ||
            list[pagenum].contains("TCP通讯设置") ||
            list[pagenum].contains("RTU通讯设置") ||
            list[pagenum].contains("大小端配置") ||
            list[pagenum].contains("设备信息")) {
          //不加载这些sheet信息
          continue;
        } else {
          List<String> rowString = excel.tables[pageName]!.rows[0].map((e) => e.toString()).toList(); //读取本Sheet页首行信息，从而得到它支持的功能码
          String char = '码';
          List<String> sArray = rowString[0].split(char); // 一定是单引
          String functionCode = sArray.last.toLowerCase(); //得到功能码信息
          Stopwatch sw = Stopwatch();
          sw.start();
          // todo 这里是读的sheet表格的全部，从第一行开始
          var dt = excel.tables[pageName]!; // Excel.ImportToTable(pagenum, 2, 0);//读取本Sheet页第二行至末尾数据信息表
          sw.stop();
          print("Work done! Used time: ${sw.elapsedMicroseconds}ms.");
          //03功能码有可能有两种表格：1--仅支持03；2--支持03+10
          if (functionCode.contains("0x03") && !functionCode.contains("0x10")) {
            //仅支持03功能码
            Map<int, ExcelInfor> tempDictionary = {}; //中转字典，放重复区信息
            int tempNum = 0;
            int key = 0;
            bool tempflag = false; //是否位于重复区段
            for (int i = 2; i < dt.rows.length; i++) {
              rowNum = i;
              if (dt.rows[i][0].toString().contains("重复数据区开始")) {
                tempflag = true;
                tempNum = int.parse(dt.rows[i][1].toString());
                key = int.parse(dt.rows[i + 1][0].toString());
                continue;
              }
              if (dt.rows[i][0].toString().contains("重复数据区结束")) {
                if (tempflag) {
                  int numtemp = key;
                  ExcelInfor excelInfor2 = ExcelInfor();
                  for (int w = 0; w < tempNum; w++) {
                    for (int j = key; j < tempDictionary.keys.length + key; j++) {
                      // tempDictionary.TryGetValue(j, out excelInfor2);
                      excelInfor2 = tempDictionary[j] ?? ExcelInfor();
                      String? type = excelInfor2.type;
                      String? name = "";
                      if (excelInfor2.meaning == "null") {
                        name = excelInfor2.meaning;
                      } else {
                        name = "${excelInfor2.meaning}_${w + 1}";
                      }
                      double max = excelInfor2.max;
                      double min = excelInfor2.min;
                      ExcelInfor excelInfor1 = ExcelInfor();
                      excelInfor1.max = max;
                      excelInfor1.meaning = name;
                      excelInfor1.min = min;
                      excelInfor1.type = type;
                      excelInfor1.resolution = excelInfor2.resolution;
                      _ExcelInfor03[numtemp++] = excelInfor1;
                    }
                  }
                }
                tempflag = false;
                tempDictionary.clear();
                continue;
              }
              ExcelInfor excelInfor = ExcelInfor();
              if (dt.rows[i][0].toString() != "" && !dt.rows[i][0].toString().contains("重复数据区开始") && !tempflag) {
                excelInfor.meaning = dt.rows[i][2].toString();
                excelInfor.min = 0;
                excelInfor.max = 12;
                if (dt.rows[i][5].toString() == "null") {
                  excelInfor.resolution = "1";
                } else {
                  excelInfor.resolution = dt.rows[i][5].toString();
                }
                excelInfor.type = dt.rows[i][3].toString();
                if (i > 0 && excelInfor.type == "null") {
                  if ((dt.rows[i - 1][3].toString().contains("int32") || dt.rows[i - 1][3].toString().contains("float"))) {
                    _ExcelInfor03[int.parse('${dt.rows[i][0] ?? '0'}')] = excelInfor;
                  } else if (dt.rows[i - 1][3].toString().contains("double") ||
                      dt.rows[i - 2][3].toString().contains("double") ||
                      dt.rows[i - 3][3].toString().contains("double")) {
                    _ExcelInfor03[int.parse('${dt.rows[i][0] ?? '0'}')] = excelInfor;
                  } else {
                    returnEntity.status = -16449008 + pagenum;
                    returnEntity.message = "协议加载失败,${"${list[pagenum]}_${i + 2}行_寄存器地址:_${dt.rows[i][0]}"}数据类型有误";
                  }
                } else {
                  var ifInt32Orfloat = (excelInfor.type?.contains("int32") ?? false) || (excelInfor.type?.contains("float") ?? false);
                  var ifRepeatPart = dt.rows[i + 1][2].toString() == "null" && !dt.rows[i + 1][0].toString().contains("重复数据区开始");
                  if ((ifInt32Orfloat && ifRepeatPart) || (excelInfor.type?.contains("int16") ?? false)) {
                    _ExcelInfor03[int.parse('${dt.rows[i][0] ?? '0'}')] = excelInfor;
                  } else if ((excelInfor.type?.contains("double") ?? false) &&
                      dt.rows[i + 1][2].toString() == "null" &&
                      dt.rows[i + 2][2].toString() == "null" &&
                      dt.rows[i + 3][2].toString() == "null") {
                    _ExcelInfor03[int.parse('${dt.rows[i][0] ?? '0'}')] = excelInfor;
                  } else {
                    returnEntity.status = -16449008 + pagenum;
                    returnEntity.message = "协议加载失败,${"${list[pagenum]}_${i + 2}行_寄存器地址:_${dt.rows[i][0]}"}数据类型有误";
                  }
                }
              }
              if (tempflag) {
                excelInfor.meaning = dt.rows[i][2].toString();
                excelInfor.type = dt.rows[i][3].toString();
                if (dt.rows[i][5].toString() == "null") {
                  excelInfor.resolution = "1";
                } else {
                  excelInfor.resolution = dt.rows[i][5].toString();
                }
                if (rowNum == 194) {
                  print('----error: ${dt.rows[i][0]}');
                }
                if (i > 0 && excelInfor.type == "null") {
                  if (dt.rows[i - 1][3].toString().contains("int32") || dt.rows[i - 1][3].toString().contains("float")) {
                    tempDictionary[int.parse('${dt.rows[i][0] ?? '0'}')] = excelInfor;
                  } else if (dt.rows[i - 1][3].toString().contains("double") ||
                      dt.rows[i - 2][3].toString().contains("double") ||
                      dt.rows[i - 3][3].toString().contains("double")) {
                    tempDictionary[int.parse('${dt.rows[i][0] ?? '0'}')] = excelInfor;
                  } else {
                    returnEntity.status = -16449008 + pagenum;
                    returnEntity.message = "协议加载失败,${"${list[pagenum]}_${i + 2}行_寄存器地址:_${dt.rows[i][0]}"}数据类型有误";
                  }
                } else {
                  if ((((excelInfor.type?.contains("int32") ?? false) || (excelInfor.type?.contains("float") ?? false)) &&
                          (dt.rows[i + 1][2].toString() == "null" && !dt.rows[i + 1][0].toString().contains("重复数据区开始"))) ||
                      (excelInfor.type?.contains("int16") ?? false)) {
                    tempDictionary[int.parse('${dt.rows[i][0] ?? '0'}')] = excelInfor;
                  } else if ((excelInfor.type?.contains("double") ?? false) &&
                      dt.rows[i + 1][2].toString() == "null" &&
                      dt.rows[i + 2][2].toString() == "null" &&
                      dt.rows[i + 3][2].toString() == "null") {
                    tempDictionary[int.parse((dt.rows[i][0]).toString())] = excelInfor;
                  } else {
                    returnEntity.status = -16449008 + pagenum;
                    returnEntity.message = "协议加载失败,${"${list[pagenum]}_${i + 2}行_寄存器地址:_${dt.rows[i][0]}"}数据类型有误";
                  }
                }
              }
            }
          }
          if (functionCode.contains("0x03") && functionCode.contains("0x10")) {
            Map<int, ExcelInfor> tempDictionary = {};
            int tempNum = 0;
            int key = 0;
            bool tempflag = false; // 重复数据
            for (int i = 2; i < dt.rows.length; i++) {
              rowNum = i;
              if (dt.rows[i][0].toString().contains("重复数据区开始")) {
                tempflag = true;
                tempNum = int.parse(dt.rows[i][1].toString());
                key = int.parse(dt.rows[i + 1][0].toString());
                continue;
              }
              if (dt.rows[i][0].toString().contains("重复数据区结束")) {
                if (tempflag) {
                  int numtemp = key;
                  ExcelInfor excelInfor2 = ExcelInfor();
                  for (int w = 0; w < tempNum; w++) {
                    for (int j = key; j < tempDictionary.keys.length + key; j++) {
                      // tempDictionary.TryGetValue(j, out excelInfor2);
                      excelInfor2 = tempDictionary[j]!;
                      String? type = excelInfor2.type;
                      String? name = "";
                      if (excelInfor2.meaning == "null") {
                        name = excelInfor2.meaning;
                      } else {
                        name = "${excelInfor2.meaning}_${w + 1}";
                      }
                      double max = excelInfor2.max;
                      double min = excelInfor2.min;

                      ExcelInfor excelInfor1 = ExcelInfor();
                      excelInfor1.max = max;
                      excelInfor1.meaning = name;
                      excelInfor1.min = min;
                      excelInfor1.resolution = excelInfor2.resolution;
                      excelInfor1.type = type;
                      _ExcelInfor03[numtemp++] = excelInfor1;
                    }
                  }
                }
                tempflag = false;
                tempDictionary.clear();
                continue;
              }
              ExcelInfor excelInfor = ExcelInfor();
              if (dt.rows[i][0].toString() != "" && !dt.rows[i][0].toString().contains("重复数据区开始") && !tempflag) {
                excelInfor.meaning = dt.rows[i][2].toString();
                excelInfor.type = dt.rows[i][3].toString();
                if (dt.rows[i][5].toString() == "null") {
                  excelInfor.resolution = "1";
                } else {
                  excelInfor.resolution = dt.rows[i][5].toString();
                }
                if (i > 0 && excelInfor.type == "null") {
                  if (dt.rows[i - 1][3].toString().contains("int32") || dt.rows[i - 1][3].toString().contains("float")) {
                    _ExcelInfor03[int.parse('${dt.rows[i][0] ?? '0'}')] = excelInfor;
                  } else if (dt.rows[i - 1][3].toString().contains("double") ||
                      dt.rows[i - 2][3].toString().contains("double") ||
                      dt.rows[i - 3][3].toString().contains("double")) {
                    _ExcelInfor03[int.parse('${dt.rows[i][0] ?? '0'}')] = excelInfor;
                  } else {
                    returnEntity.status = -16449008 + pagenum;
                    returnEntity.message = "协议加载失败,${"${list[pagenum]}_${i + 2}行_寄存器地址:_${dt.rows[i][0]}"}数据类型有误";
                  }
                } else {
                  if (dt.rows[i][6].toString() == "null") {
                    if (dt.rows[i][3].toString() == "int32") {
                      excelInfor.min = intMinValue * double.parse(excelInfor.resolution!);
                    } else if (dt.rows[i][3].toString() == "uint32") {
                      excelInfor.min = 0;
                    } else if (dt.rows[i][3].toString() == "int16") {
                      excelInfor.min = shortMinValue * double.parse(excelInfor.resolution!);
                    } else if (dt.rows[i][3].toString() == "uint16") {
                      excelInfor.min = 0;
                    } else if (dt.rows[i][3].toString() == "float") {
                      excelInfor.min = floatMinValue * double.parse(excelInfor.resolution!);
                    } else if (dt.rows[i][3].toString() == "double") {
                      excelInfor.min = doubleMinValue * double.parse(excelInfor.resolution!);
                    }
                  } else {
                    excelInfor.min = double.parse(dt.rows[i][6].toString());
                  }
                  if (dt.rows[i][7].toString() == "null") {
                    if (dt.rows[i][3].toString() == ("int32")) {
                      excelInfor.max = intMaxValue * double.parse(excelInfor.resolution!);
                    } else if (dt.rows[i][3].toString() == ("uint32")) {
                      excelInfor.max = uint32MaxValue * double.parse(excelInfor.resolution!);
                    } else if (dt.rows[i][3].toString() == ("int16")) {
                      excelInfor.max = shortMaxValue * double.parse(excelInfor.resolution!);
                    } else if (dt.rows[i][3].toString() == ("uint16")) {
                      excelInfor.max = uint16MaxValue * double.parse(excelInfor.resolution!);
                    } else if (dt.rows[i][3].toString() == ("float")) {
                      excelInfor.max = floatMaxValue * double.parse(excelInfor.resolution!);
                    } else if (dt.rows[i][3].toString() == ("double")) {
                      excelInfor.max = doubleMaxValue * double.parse(excelInfor.resolution!);
                    }
                  } else {
                    excelInfor.max = double.parse(dt.rows[i][7].toString());
                  }
                  if ((((excelInfor.type?.contains("int32") ?? false) || (excelInfor.type?.contains("float") ?? false)) &&
                          (dt.rows[i + 1][2].toString() == "null" && !dt.rows[i + 1][0].toString().contains("重复数据区开始"))) ||
                      (excelInfor.type?.contains("int16") ?? false)) {
                    _ExcelInfor03[int.parse('${dt.rows[i][0] ?? '0'}')] = excelInfor;
                  } else if ((excelInfor.type?.contains("double") ?? false) &&
                      dt.rows[i + 1][2].toString() == "null" &&
                      dt.rows[i + 2][2].toString() == "null" &&
                      dt.rows[i + 3][2].toString() == "null") {
                    _ExcelInfor03[int.parse('${dt.rows[i][0] ?? '0'}')] = excelInfor;
                  } else {
                    returnEntity.status = -16449008 + pagenum;
                    returnEntity.message = "协议加载失败,${"${list[pagenum]}_${i + 2}行_寄存器地址:_${dt.rows[i][0]}"}数据类型有误";
                  }
                }
              }
              if (tempflag) {
                excelInfor.meaning = dt.rows[i][2].toString();
                excelInfor.type = dt.rows[i][3].toString();
                if (dt.rows[i][5].toString() == "null") {
                  excelInfor.resolution = "1";
                } else {
                  excelInfor.resolution = dt.rows[i][5].toString();
                }
                if (i > 0 && excelInfor.type == "null") {
                  if (dt.rows[i - 1][3].toString().contains("int32") || dt.rows[i - 1][3].toString().contains("float")) {
                    tempDictionary[int.parse('${dt.rows[i][0] ?? '0'}')] = excelInfor;
                  } else if (dt.rows[i - 1][3].toString().contains("double") ||
                      dt.rows[i - 2][3].toString().contains("double") ||
                      dt.rows[i - 3][3].toString().contains("double")) {
                    tempDictionary[int.parse('${dt.rows[i][0] ?? '0'}')] = excelInfor;
                  } else {
                    returnEntity.status = -16449008 + pagenum;
                    returnEntity.message = "协议加载失败,${"${list[pagenum]}_${i + 2}行_寄存器地址:_${dt.rows[i][0]}"}数据类型有误";
                  }
                } else {
                  if (dt.rows[i][6].toString() == "null") {
                    if (dt.rows[i][3].toString() == ("int32")) {
                      excelInfor.min = intMinValue * double.parse(excelInfor.resolution!);
                    } else if (dt.rows[i][3].toString() == ("uint32")) {
                      excelInfor.min = 0;
                    } else if (dt.rows[i][3].toString() == ("int16")) {
                      excelInfor.min = shortMinValue * double.parse(excelInfor.resolution!);
                    } else if (dt.rows[i][3].toString() == ("uint16")) {
                      excelInfor.min = 0;
                    } else if (dt.rows[i][3].toString() == ("float")) {
                      excelInfor.min = floatMinValue * double.parse(excelInfor.resolution!);
                    } else if (dt.rows[i][3].toString() == ("double")) {
                      excelInfor.min = doubleMinValue * double.parse(excelInfor.resolution!);
                    }
                  } else {
                    excelInfor.min = double.parse(dt.rows[i][6].toString());
                  }
                  if (dt.rows[i][7].toString() == "null") {
                    if (dt.rows[i][3].toString() == ("int32")) {
                      excelInfor.max = intMaxValue * double.parse(excelInfor.resolution!);
                    } else if (dt.rows[i][3].toString() == ("uint32")) {
                      excelInfor.max = uint32MaxValue * double.parse(excelInfor.resolution!);
                    } else if (dt.rows[i][3].toString() == ("int16")) {
                      excelInfor.max = shortMaxValue * double.parse(excelInfor.resolution!);
                    } else if (dt.rows[i][3].toString() == ("uint16")) {
                      excelInfor.max = ushortMaxValue * double.parse(excelInfor.resolution!);
                    } else if (dt.rows[i][3].toString() == ("float")) {
                      excelInfor.max = floatMaxValue * double.parse(excelInfor.resolution!);
                    } else if (dt.rows[i][3].toString() == ("double")) {
                      excelInfor.max = doubleMaxValue * double.parse(excelInfor.resolution!);
                    }
                  } else {
                    excelInfor.max = double.parse(dt.rows[i][7].toString());
                  }
                  if ((((excelInfor.type?.contains("int32") ?? false) || (excelInfor.type?.contains("float") ?? false)) &&
                          (dt.rows[i + 1][2].toString() == "null" && !dt.rows[i + 1][0].toString().contains("重复数据区开始"))) ||
                      (excelInfor.type?.contains("int16") ?? false)) {
                    tempDictionary[int.parse('${dt.rows[i][0] ?? '0'}')] = excelInfor;
                  } else if ((excelInfor.type?.contains("double") ?? false) &&
                      dt.rows[i + 1][2].toString() == "null" &&
                      dt.rows[i + 2][2].toString() == "null" &&
                      dt.rows[i + 3][2].toString() == "null") {
                    tempDictionary[int.parse('${dt.rows[i][0] ?? '0'}')] = excelInfor;
                  } else {
                    returnEntity.status = -16449008 + pagenum;
                    returnEntity.message = "协议加载失败,${"${list[pagenum]}_${i + 2}行_寄存器地址:_${dt.rows[i][0]}"}数据类型有误";
                  }
                }
              }
            }
          }
          if (functionCode.contains("0x10")) {
            Map<int, ExcelInfor> tempDictionary = {};
            int tempNum = 0;
            int key = 0;
            bool tempflag = false;
            for (int i = 2; i < dt.rows.length; i++) {
              rowNum = i;
              if (dt.rows[i][0].toString().contains("重复数据区开始")) {
                tempflag = true;
                tempNum = int.parse(dt.rows[i][1].toString());
                key = int.parse(dt.rows[i + 1][0].toString());
                continue;
              }
              if (dt.rows[i][0].toString().contains("重复数据区结束")) {
                if (tempflag) {
                  int numtemp = key;
                  ExcelInfor excelInfor = ExcelInfor();
                  for (int w = 0; w < tempNum; w++) {
                    for (int j = key; j < tempDictionary.keys.length + key; j++) {
                      // tempDictionary.TryGetValue(j, out excelInfor);
                      excelInfor = tempDictionary[j] ?? ExcelInfor();
                      String? type = excelInfor.type;
                      String? name = "";
                      if (excelInfor.meaning == "null") {
                        name = excelInfor.meaning;
                      } else {
                        name = "${excelInfor.meaning}_${w + 1}";
                      }
                      double max = excelInfor.max;
                      double min = excelInfor.min;

                      ExcelInfor excelInfor2 = ExcelInfor();
                      excelInfor2.max = max;
                      excelInfor2.meaning = name;
                      excelInfor2.min = min;
                      excelInfor2.resolution = excelInfor.resolution;
                      excelInfor2.type = type;
                      excelInfor2.dafaultVal = excelInfor.dafaultVal; //默认值 GP20230807add
                      _ExcelInfor10[numtemp++] = excelInfor2;
                    }
                  }
                }
                tempflag = false;
                tempDictionary.clear();
                continue;
              }
              if (dt.rows[i][0].toString() == "null") {
                break;
              } else if (!dt.rows[i][0].toString().contains("重复数据区开始") && !tempflag) {
                ExcelInfor excelInfor = new ExcelInfor();
                excelInfor.meaning = dt.rows[i][2].toString();
                if (dt.rows[i][5].toString() == "null") {
                  excelInfor.resolution = "1";
                } else {
                  excelInfor.resolution = dt.rows[i][5].toString();
                }
                excelInfor.type = dt.rows[i][3].toString();
                excelInfor.dafaultVal = dt.rows[i][8].toString(); //默认值 GP20230807add
                if (i > 0 && excelInfor.type == "null") {
                  if (dt.rows[i - 1][3].toString().contains("int32") || dt.rows[i - 1][3].toString().contains("float")) {
                    _ExcelInfor10[int.parse('${dt.rows[i][0] ?? '0'}')] = excelInfor;
                  } else if (dt.rows[i - 1][3].toString().contains("double") ||
                      dt.rows[i - 2][3].toString().contains("double") ||
                      dt.rows[i - 3][3].toString().contains("double")) {
                    _ExcelInfor10[int.parse('${dt.rows[i][0] ?? '0'}')] = excelInfor;
                  } else {
                    returnEntity.status = -16449008 + pagenum;
                    returnEntity.message = "协议加载失败,${"${list[pagenum]}_${i + 2}行_寄存器地址:_${dt.rows[i][0]}"}数据类型有误";
                  }
                } else {
                  if (dt.rows[i][6].toString() == "null") {
                    if (dt.rows[i][3].toString() == ("int32")) {
                      excelInfor.min = intMinValue * double.parse(excelInfor.resolution!);
                    } else if (dt.rows[i][3].toString() == ("uint32")) {
                      excelInfor.min = 0;
                    } else if (dt.rows[i][3].toString() == ("int16")) {
                      excelInfor.min = shortMinValue * double.parse(excelInfor.resolution!);
                    } else if (dt.rows[i][3].toString() == ("uint16")) {
                      excelInfor.min = 0;
                    } else if (dt.rows[i][3].toString() == ("float")) {
                      excelInfor.min = floatMinValue * double.parse(excelInfor.resolution!);
                    } else if (dt.rows[i][3].toString() == ("double")) {
                      excelInfor.min = doubleMinValue * double.parse(excelInfor.resolution!);
                    }
                  } else {
                    //最小值
                    excelInfor.min = double.parse(dt.rows[i][6].toString());
                  }
                  if (dt.rows[i][7].toString() == "null") {
                    if (dt.rows[i][3].toString() == ("int32")) {
                      excelInfor.max = intMaxValue * double.parse(excelInfor.resolution!);
                    } else if (dt.rows[i][3].toString() == ("uint32")) {
                      excelInfor.max = uint32MaxValue * double.parse(excelInfor.resolution!);
                    } else if (dt.rows[i][3].toString() == ("int16")) {
                      excelInfor.max = shortMaxValue * double.parse(excelInfor.resolution!);
                    } else if (dt.rows[i][3].toString() == ("uint16")) {
                      excelInfor.max = ushortMaxValue * double.parse(excelInfor.resolution!);
                    } else if (dt.rows[i][3].toString() == ("float")) {
                      excelInfor.max = floatMaxValue * double.parse(excelInfor.resolution!);
                    } else if (dt.rows[i][3].toString() == ("double")) {
                      excelInfor.max = doubleMaxValue * double.parse(excelInfor.resolution!);
                    }
                  } else {
                    //最大值
                    excelInfor.max = double.parse(dt.rows[i][7].toString());
                  }

                  if ((((excelInfor.type?.contains("int32") ?? false) || (excelInfor.type?.contains("float") ?? false)) &&
                          (dt.rows[i + 1][2].toString() == "null" && !dt.rows[i + 1][0].toString().contains("重复数据区开始"))) ||
                      (excelInfor.type?.contains("int16") ?? false)) {
                    _ExcelInfor10[int.parse('${dt.rows[i][0] ?? '0'}')] = excelInfor;
                  } else if ((excelInfor.type?.contains("double") ?? false) &&
                      dt.rows[i + 1][2].toString() == "null" &&
                      dt.rows[i + 2][2].toString() == "null" &&
                      dt.rows[i + 3][2].toString() == "null") {
                    _ExcelInfor10[int.parse('${dt.rows[i][0] ?? '0'}')] = excelInfor;
                  } else {
                    returnEntity.status = -16449008 + pagenum;
                    returnEntity.message = "协议加载失败,${"${list[pagenum]}_${i + 2}行_寄存器地址:_${dt.rows[i][0]}"}数据类型有误";
                  }
                }
              }
              ExcelInfor excelInfor1 = ExcelInfor();
              if (tempflag) {
                excelInfor1.meaning = dt.rows[i][2].toString();
                excelInfor1.type = dt.rows[i][3].toString();

                excelInfor1.dafaultVal = dt.rows[i][8].toString(); //默认值 GP20230807add

                if (dt.rows[i][5].toString() == "null") {
                  excelInfor1.resolution = "1";
                } else {
                  excelInfor1.resolution = dt.rows[i][5].toString();
                }
                if (i > 0 && excelInfor1.type == "null") {
                  if (dt.rows[i - 1][3].toString().contains("int32") || dt.rows[i - 1][3].toString().contains("float")) {
                    tempDictionary[int.parse('${dt.rows[i][0] ?? '0'}')] = excelInfor1;
                  } else if (dt.rows[i - 1][3].toString().contains("double") ||
                      dt.rows[i - 2][3].toString().contains("double") ||
                      dt.rows[i - 3][3].toString().contains("double")) {
                    tempDictionary[int.parse('${dt.rows[i][0] ?? '0'}')] = excelInfor1;
                  } else {
                    returnEntity.status = -16449008 + pagenum;
                    returnEntity.message = "协议加载失败,${"${list[pagenum]}_${i + 2}行_寄存器地址:_${dt.rows[i][0]}"}数据类型有误";
                  }
                } else {
                  if (dt.rows[i][6].toString() == "null") {
                    if (dt.rows[i][3].toString() == ("int32")) {
                      excelInfor1.min = intMinValue * double.parse(excelInfor1.resolution!);
                    } else if (dt.rows[i][3].toString() == ("uint32")) {
                      excelInfor1.min = 0;
                    } else if (dt.rows[i][3].toString() == ("int16")) {
                      excelInfor1.min = shortMinValue * double.parse(excelInfor1.resolution!);
                    } else if (dt.rows[i][3].toString() == ("uint16")) {
                      excelInfor1.min = 0;
                    } else if (dt.rows[i][3].toString() == ("float")) {
                      excelInfor1.min = floatMinValue * double.parse(excelInfor1.resolution!);
                    } else if (dt.rows[i][3].toString() == ("double")) {
                      excelInfor1.min = doubleMinValue * double.parse(excelInfor1.resolution!);
                    }
                  } else {
                    excelInfor1.min = double.parse(dt.rows[i][6].toString());
                  }
                  if (dt.rows[i][7].toString() == "null") {
                    if (dt.rows[i][3].toString() == ("int32")) {
                      excelInfor1.max = intMaxValue * double.parse(excelInfor1.resolution!);
                    } else if (dt.rows[i][3].toString() == ("uint32")) {
                      excelInfor1.max = uint32MaxValue * double.parse(excelInfor1.resolution!);
                    } else if (dt.rows[i][3].toString() == ("int16")) {
                      excelInfor1.max = shortMaxValue * double.parse(excelInfor1.resolution!);
                    } else if (dt.rows[i][3].toString() == ("uint16")) {
                      excelInfor1.max = ushortMaxValue * double.parse(excelInfor1.resolution!);
                    } else if (dt.rows[i][3].toString() == ("float")) {
                      excelInfor1.max = floatMaxValue * double.parse(excelInfor1.resolution!);
                    } else if (dt.rows[i][3].toString() == ("double")) {
                      excelInfor1.max = doubleMaxValue * double.parse(excelInfor1.resolution!);
                    }
                  } else {
                    excelInfor1.max = double.parse(dt.rows[i][7].toString());
                  }

                  if ((((excelInfor1.type?.contains("int32") ?? false) || (excelInfor1.type?.contains("float") ?? false)) &&
                          (dt.rows[i + 1][2].toString() == "null" && !dt.rows[i + 1][0].toString().contains("重复数据区开始"))) ||
                      (excelInfor1.type?.contains("int16") ?? false)) {
                    tempDictionary[int.parse('${dt.rows[i][0] ?? '0'}')] = excelInfor1;
                  } else if ((excelInfor1.type?.contains("double") ?? false) &&
                      dt.rows[i + 1][2].toString() == "null" &&
                      dt.rows[i + 2][2].toString() == "null" &&
                      dt.rows[i + 3][2].toString() == "null") {
                    tempDictionary[int.parse('${dt.rows[i][0] ?? '0'}')] = excelInfor1;
                  } else {
                    returnEntity.status = -16449008 + pagenum;
                    returnEntity.message = "协议加载失败,${"${list[pagenum]}_${i + 2}行_寄存器地址:_${dt.rows[i][0]}"}数据类型有误";
                  }
                }
              }
            }
          } else if (functionCode.contains("0x06")) {
            // returnEntity = add_ExcelInfor(dt, list, pagenum, "0x06");
          }
          // #region GP05019文件功能码新增

          // #endregion
          //GP0327新增04功能码

          if (returnEntity.status != 0) {
            //有告警信息
            // Excel.Close();//关闭EXCEL
            return returnEntity;
          }
        }
      }
      //将各个sheet数据加载到对应字典中，key为含义
      for (int pagenum = 0; pagenum < list.length; pagenum++) {
        keyType = 1;
        pagenum = pagenum;
        pageName = list[pagenum];
        if (list[pagenum].contains("Modbus-TCP") ||
            list[pagenum].contains("Modbus-RTU") ||
            list[pagenum].contains("TCP通讯设置") ||
            list[pagenum].contains("RTU通讯设置") ||
            list[pagenum].contains("大小端配置") ||
            list[pagenum].contains("设备信息") ||
            list[pagenum].contains("波形重现") ||
            list[pagenum].contains("其他")) {
          continue;
        } else {
          List<String> rowString = excel.tables[pageName]!.rows[0].map((e) => e.toString()).toList();
          String char = '码';
          List<String> sArray = rowString[0].split(char); // 一定是单引
          String functionCode = sArray[sArray.length - 1];
          if (!functionCode.contains("0x14") && !functionCode.contains("0x15")) {
            Map<int, ExcelInfor> tempDictionary = {};
            int tempNum = 0;
            int key = 0;
            bool tempflag = false;
            // var dt = Excel.ImportToTable(pagenum, 2, 0);
            var dt = excel.tables[pageName]!;
            for (int i = 2; i < dt.rows.length; i++) {
              rowNum = i;
              ExcelInfor excelInfor1 = ExcelInfor();
              Map<int, ExcelInfor> _ExcelInforTemp = {};
              if (dt.rows[i][0].toString().contains("重复数据区结束")) {
                if (tempflag) {
                  int numtemp = key;
                  ExcelInfor excelInfor = ExcelInfor();
                  for (int w = 0; w < tempNum; w++) {
                    for (int j = key; j < tempDictionary.keys.length + key; j++) {
                      // tempDictionary.TryGetValue(j, out excelInfor);
                      excelInfor = tempDictionary[j]!;
                      String? type = excelInfor.type;
                      String? name = "";
                      if (excelInfor.meaning == "null") {
                        name = excelInfor.meaning;
                      } else {
                        name = "${excelInfor.meaning}_${w + 1}";
                      }
                      double max = excelInfor.max;
                      double min = excelInfor.min;

                      ExcelInfor excelInfor2 = ExcelInfor();
                      excelInfor2.max = max;
                      excelInfor2.meaning = name;
                      excelInfor2.min = min;
                      excelInfor2.resolution = excelInfor.resolution;
                      excelInfor2.type = type;
                      _ExcelInforTemp[numtemp++] = excelInfor2;
                    }
                  }

                  for (int w = key; w < _ExcelInforTemp.keys.length + key; w++) {
                    // _ExcelInforTemp.TryGetValue(w, out excelInfor);
                    excelInfor = _ExcelInforTemp[w]!;
                    String? name = excelInfor.meaning;
                    if (name == null || name.contains("预留") || name.contains("保留")) {
                    } else {
                      _ExcelInforName[name] = w;
                    }
                  }
                }
                tempflag = false;
                tempDictionary.clear();
                _ExcelInforTemp.clear();
                continue;
              }
              if (tempflag) {
                excelInfor1.meaning = dt.rows[i][2].toString();
                excelInfor1.type = dt.rows[i][3].toString();
                if (dt.rows[i][5].toString() == "null") {
                  excelInfor1.resolution = "1";
                } else {
                  excelInfor1.resolution = dt.rows[i][5].toString();
                }
                if (i > 0 && excelInfor1.type == "null") {
                  if (dt.rows[i - 1][3].toString().contains("int32") || dt.rows[i - 1][3].toString().contains("float")) {
                    tempDictionary[int.parse('${dt.rows[i][0] ?? '0'}')] = excelInfor1;
                  } else if (dt.rows[i - 1][3].toString().contains("double") ||
                      dt.rows[i - 2][3].toString().contains("double") ||
                      dt.rows[i - 3][3].toString().contains("double")) {
                    tempDictionary[int.parse('${dt.rows[i][0] ?? '0'}')] = excelInfor1;
                  } else {
                    returnEntity.status = -16449008 + pagenum;
                    returnEntity.message = "协议加载失败,${"${list[pagenum]}_${i + 2}行_寄存器地址:_${dt.rows[i][0]}"}数据类型有误";
                  }
                } else {
                  tempDictionary[int.parse('${dt.rows[i][0] ?? '0'}')] = excelInfor1;
                }
              }
              if (dt.rows[i][0].toString().contains("重复数据区开始")) {
                tempflag = true;
                tempNum = int.parse(dt.rows[i][1].toString());
                key = int.parse(dt.rows[i + 1][0].toString());
                continue;
              } else if (!tempflag) {
                if (dt.rows[i][0].toString() == "null" || dt.rows[i][2].toString().contains("预留") || dt.rows[i][2].toString().contains("保留")) {
                } else {
                  int value = int.parse('${dt.rows[i][0] ?? '0'}');
                  if (dt.rows[i][2].toString() != "") {
                    _ExcelInforName[dt.rows[i][2].toString()] = value;
                  }
                }
              }
            }
          }
        }
        if (returnEntity.status != 0) //有告警信息
        {
          // Excel.Close();//关闭EXCEL
          return returnEntity;
        }
      }
      //加载设备信息页内容
      if (list.contains("设备信息")) {
        var dt = excel.tables["设备信息"]!;
        for (int i = 0; i < dt.rows.length; i++) {
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
                _ExcelInfor2BName[dt.rows[i][1].toString()] = tempinfoname;
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
      // 合并所有excel
      excelInfoAll = {
        ..._ExcelInfor03,
        ..._ExcelInfor06,
        ..._ExcelInfor10,
      };
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
  Future<ReturnEntity> getRegister({required int index, required int startRegAddr, required int dataCount}) async {
    var returnEntity = ReturnEntity();
    List<ModbusElementsGroup> getRequestList = Utils.getElementsGroup(startRegAddr, dataCount, excelInfoAll);

    if (modbusClientRtu.isConnected) {
      List resultArr = await retrySend(getRequestList);
      returnEntity.data = resultArr.join(',');
    } else {
      returnEntity.status = -1;
      returnEntity.message = 'not connected or register element group is empty';
    }
    return returnEntity;
  }

  retrySend(List<ModbusElementsGroup> elementsGroupList, [int? tryTimes]) async {
    List resultArr = [];
    int maxTry = tryTimes ?? 0;
    for (int i = 0; i < elementsGroupList.length; i++) {
      await modbusClientRtu.send(elementsGroupList[i].getReadRequest());
      resultArr.addAll(elementsGroupList[i].map((item) => item.value));
    }
    if (resultArr.contains(null) || maxTry < 5) {
      maxTry += 1;
      resultArr = [];
      return await retrySend(elementsGroupList, maxTry);
    } else {
      return resultArr;
    }
  }

  @override
  Future<ReturnEntity> getRegisterByName({required int index, required String startRegName, required int dataCount}) {
    // TODO: implement getRegisterByName
    throw UnimplementedError();
  }

  @override
  Future<ReturnEntity> setRegister({required int index, required int startRegAddr, required String serializableDat, int setDatLength = 0}) async {
    var returnEntity = ReturnEntity();
    List serializableDatArr = serializableDat.split(',');
    List<ModbusElementsGroup> getRequestList = Utils.getElementsGroup(startRegAddr, serializableDatArr.length, excelInfoAll);

    if (modbusClientRtu.isConnected) {
      List resultArr = await retrySend(getRequestList);
      returnEntity.data = resultArr.join(',');
    } else {
      returnEntity.status = -1;
      returnEntity.message = 'not connected or register element group is empty';
    }
    return returnEntity;
  }

  @override
  Future<ReturnEntity> setRegisterByName({required int index, required String startRegName, required String serializableDat, int setDatLength = 0}) {
    // TODO: implement setRegisterByName
    throw UnimplementedError();
  }
}
