import 'package:spreadsheet_decoder/spreadsheet_decoder.dart';

import '../packages/modbus_client_serial/modbus_client_serial.dart';

class InfoRTU {
  String protocol = '';
  List<String> portNames = [];
  List<SerialBaudRate> baudRates = [];
  List<SerialStopBits> stopBits = [];
  List<SerialParity> parities = [];
  List<String> ids = [];
  String connectCount = '';
  String timeout = '';
  String cRCType = '';
  String dataType = '';
  String regType = '';

  InfoRTU({
    required this.protocol,
    required this.portNames,
    required this.baudRates,
    required this.stopBits,
    required this.parities,
    required this.ids,
    required this.connectCount,
    required this.timeout,
    required this.cRCType,
    required this.dataType,
    required this.regType,
  });

  InfoRTU.fromDataTable(SpreadsheetTable dt) {
    protocol = dt.rows[2][1].toString();
    portNames = dt.rows[3][1].toString().split(',');
    baudRates = dt.rows[4][1].toString().split(',').map((e) {
      late SerialBaudRate baudRate;
      switch (e) {
        case '200':
          baudRate = SerialBaudRate.b200;
          break;
        case '300':
          baudRate = SerialBaudRate.b300;
          break;
        case '600':
          baudRate = SerialBaudRate.b600;
          break;
        case '1200':
          baudRate = SerialBaudRate.b1200;
          break;
        case '1800':
          baudRate = SerialBaudRate.b1800;
          break;
        case '2400':
          baudRate = SerialBaudRate.b2400;
          break;
        case '4800':
          baudRate = SerialBaudRate.b4800;
          break;
        case '9600':
          baudRate = SerialBaudRate.b9600;
          break;
        case '19200':
          baudRate = SerialBaudRate.b19200;
          break;
        case '28800':
          baudRate = SerialBaudRate.b28800;
          break;
        case '38400':
          baudRate = SerialBaudRate.b38400;
          break;
        case '57600':
          baudRate = SerialBaudRate.b57600;
          break;
        case '76800':
          baudRate = SerialBaudRate.b76800;
          break;
        case '115200':
          baudRate = SerialBaudRate.b115200;
          break;
        case '230400':
          baudRate = SerialBaudRate.b230400;
          break;
        case '460800':
          baudRate = SerialBaudRate.b460800;
          break;
        case '576000':
          baudRate = SerialBaudRate.b576000;
          break;
        case '921600':
          baudRate = SerialBaudRate.b921600;
          break;
        case '1000000':
          baudRate = SerialBaudRate.b1000000;
          break;
      }
      return baudRate;
    }).toList();
    stopBits = dt.rows[5][1].toString().split(',').map((e) {
      late SerialStopBits stopBit;
      switch (e) {
        case '1':
          stopBit = SerialStopBits.one;
          break;
        case '2':
          stopBit = SerialStopBits.two;
          break;
        case '0':
          stopBit = SerialStopBits.none;
          break;
      }
      return stopBit;
    }).toList();
    parities = dt.rows[6][1].toString().split(',').map((e) {
      late SerialParity parity;
      switch (e) {
        case '1':
          parity = SerialParity.odd;
          break;
        case '2':
          parity = SerialParity.even;
          break;
        case '0':
          parity = SerialParity.none;
          break;
      }
      return parity;
    }).toList();
    ids = dt.rows[7][1].toString().split(',');
    connectCount = dt.rows[8][1].toString();
    timeout = dt.rows[9][1].toString();
    cRCType = dt.rows[11][1].toString();
    dataType = dt.rows[12][1].toString();
    regType = dt.rows[13][1].toString();
  }
}
