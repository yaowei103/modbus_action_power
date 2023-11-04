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
  double? resolution;
  double? min;
  double? max;
  String? dafaultVal;
  List<String?>? functionCode;

  ExcelInfor({
    this.meaning,
    this.type,
    this.unit,
    this.resolution,
    this.min,
    this.max,
    this.dafaultVal,
    this.functionCode,
  });

  ExcelInfor.copy(ExcelInfor obj)
      : meaning = obj.meaning,
        type = obj.type,
        unit = obj.unit,
        resolution = obj.resolution,
        min = obj.min,
        max = obj.max,
        dafaultVal = obj.dafaultVal,
        functionCode = obj.functionCode;

  static getAddressFromDt(dt, i) {
    return getValueFromDt(dt, i, '寄存器地址');
  }

  static getMeaningFromDt(dt, i) {
    return getValueFromDt(dt, i, '含义');
  }

  static getTypeFromDt(dt, i) {
    return getValueFromDt(dt, i, '类型');
  }

  static getUnitFromDt(dt, i) {
    return getValueFromDt(dt, i, '单位');
  }

  static getResolutionFromDt(dt, i) {
    return getValueFromDt(dt, i, '分辨率');
  }

  static getMinFromDt(dt, i) {
    return getValueFromDt(dt, i, '最小值');
  }

  static getMaxFromDt(dt, i) {
    return getValueFromDt(dt, i, '最大值');
  }

  static getDefaultValFromDt(dt, i) {
    return getValueFromDt(dt, i, '默认值');
  }

  static getValueFromDt(dt, int i, String columnName) {
    List columns = dt.rows[1];
    int index = columns.indexWhere((e) => e.contains(columnName));
    // 不存在column时，无穷小，无穷大，或者null
    double? nullValue;
    if (columnName.contains('最小值')) {
      nullValue = double.negativeInfinity;
    } else if (columnName.contains('最大值')) {
      nullValue = double.infinity;
    } else {
      nullValue = null;
    }
    // 存在column
    if (index >= 0 && index <= columns.length - 1) {
      var val = dt.rows[i][index];
      if (columnName.contains('最小值') || columnName.contains('最大值')) {
        return val?.toDouble();
      } else if (columnName.contains('分辨率')) {
        return val != null ? val.toDouble() : 1.0;
      } else {
        return val?.toString();
      }
    } else {
      return nullValue;
    }
  }
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
