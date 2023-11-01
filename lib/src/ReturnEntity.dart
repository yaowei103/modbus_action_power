class ReturnEntity {
  int? status;
  String? message;
  String? data;
  ReturnEntity({
    this.status = 0,
    this.message = '',
    this.data = '',
  });
}

class DeviceComInfo {
  int? port;
  String? ip;
  String? COM;

  DeviceComInfo({
    this.port,
    this.ip,
    this.COM,
  });
}

class WriteFileInfo {
  int? fileNum;
  int? recordNum;
  String? recordData;
  int? setDatLength;

  WriteFileInfo({
    this.fileNum,
    this.recordNum,
    this.recordData,
    this.setDatLength = 0,
  });
}

class ReadFileInfo {
  int? fileNum;
  int? recordNum;
  int? recordLength;

  ReadFileInfo({
    this.fileNum,
    this.recordNum,
    this.recordLength,
  });
}

class ExcelInfor {
  String? meaning;
  String? type;
  String? unit;
  String? resolution;
  double min;
  double max;
  String? dafaultVal;

  ExcelInfor({
    this.meaning,
    this.type,
    this.unit,
    this.resolution,
    this.min = 0,
    this.max = 0,
    this.dafaultVal,
  });
}

class WriteFileSendInfo {
  int? fileNum;
  int? recordNum;
  List<int>? recordData;

  WriteFileSendInfo({
    this.fileNum,
    this.recordNum,
    this.recordData,
  });
}

class ReadFileSendInfo {
  int? fileNum;
  int? recordNum;
  int? recordLength;

  ReadFileSendInfo({
    this.fileNum,
    this.recordNum,
    this.recordLength,
  });
}

class ReadFileGetInfo {
  int? fileNum;
  int? recordNum;
  List<int>? recordData;

  ReadFileGetInfo({
    this.fileNum,
    this.recordNum,
    this.recordData,
  });
}

class ReturnRegisterInfo {
  int? readDatNum;
  int? readRegNum;
  List<String>? resolution;
  List<String>? type;
  List<int>? reabuf03;
  List<bool>? reabuf01;

  ReturnRegisterInfo({
    this.readDatNum = 0,
    this.readRegNum = 0,
    this.resolution = const [],
    this.type = const [],
    this.reabuf03 = const [],
    this.reabuf01 = const [],
  });
}

class ReturnSetRegisterInfo {
  List<int>? reabuf10;
  List<bool>? reabuf0F;

  ReturnSetRegisterInfo({
    this.reabuf10 = const [],
    this.reabuf0F = const [],
  });
}
