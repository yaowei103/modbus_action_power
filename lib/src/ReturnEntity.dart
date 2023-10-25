class ReturnEntity {
  late int status;
  late String message;
  late String data;
}

class DeviceComInfo {
  late int port;
  late String ip;
  late String COM;
}

class WriteFileInfo {
  late int fileNum;
  late int recordNum;
  late String recordData;
  int setDatLength = 0;
}

class ReadFileInfo {
  late int fileNum;
  late int recordNum;
  late int recordLength;
}

class ExcelInfor {
  late String meaning;
  late String type;
  late String unit;
  String resolution = "1";
  late double min;
  late double max;
  late String dafaultVal;
}

class WriteFileSendInfo {
  late int fileNum;
  late int recordNum;
  late List<int> recordData;
}

class ReadFileSendInfo {
  late int fileNum;
  late int recordNum;
  late int recordLength;
}

class ReadFileGetInfo {
  late int fileNum;
  late int recordNum;
  late List<int> recordData;
}

class ReturnRegisterInfo {
  int readDatNum = 0;
  int readRegNum = 0;
  List<String> resolution = [];
  List<String> type = [];
  List<int> reabuf03 = [];
  List<bool> reabuf01 = [];
}

class ReturnSetRegisterInfo {
  List<int> reabuf10 = [];
  List<bool> reabuf0F = [];
}
