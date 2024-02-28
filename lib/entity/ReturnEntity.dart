class ReturnEntity<T> {
  int? status;
  String? message;
  T? data;
  ReturnEntity({
    this.status = 0,
    this.message = '',
    this.data,
  });

  @override
  toString() {
    return '''{
      'status': $status,
      message: $message,
      data: $data,
    }''';
  }

  toJson() {
    return {
      'status': status,
      'message': message,
      'data': data,
    };
  }

  ReturnEntity.fromJson(json) {
    status = json['status'];
    message = json['message'];
    data = json['data'];
  }
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

class ExcelInfo {
  /// 意义
  String? meaning;

  /// 类型
  String? type;

  /// 单位
  String? unit;

  /// 精度
  double? resolution;

  /// 最小值
  double? min;

  /// 最大值
  double? max;

  /// 默认值
  String? defaultVal;

  /// 功能码
  List<String>? functionCode;

  /// 文件号
  int? fileNum;

  /// 记录号
  int? recordNum;

  ExcelInfo({
    this.meaning,
    this.type,
    this.unit,
    this.resolution,
    this.min,
    this.max,
    this.defaultVal,
    this.functionCode,
    this.fileNum,
    this.recordNum,
  });

  ExcelInfo.copy(ExcelInfo obj)
      : meaning = obj.meaning,
        type = obj.type,
        unit = obj.unit,
        resolution = obj.resolution,
        min = obj.min,
        max = obj.max,
        defaultVal = obj.defaultVal,
        functionCode = obj.functionCode,
        fileNum = obj.fileNum,
        recordNum = obj.recordNum;

  int getSize() {
    if (type == 'float' || type == 'uint32') {
      return 2;
    } else {
      return 1;
    }
  }

  static getAddressFromDt(dt, i) {
    return getValueFromDt(dt, i, '寄存器地址');
  }

  static getFileNameFromDt(dt, i) {
    return getValueFromDt(dt, i, '文件名');
  }

  static getFileRecordNumberFromDt(dt, i) {
    return getValueFromDt(dt, i, '记录号');
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
        return val != null ? double.parse(val.toString()) : nullValue;
      } else if (columnName.contains('分辨率')) {
        return val != null ? double.parse(val.toString()) : 1.0;
      } else {
        return val?.toString();
      }
    } else {
      return nullValue;
    }
  }
}

class WriteFileRequest {
  int? fileNum;
  int? recordNum;
  List<int>? recordData;

  WriteFileRequest({
    this.fileNum,
    this.recordNum,
    this.recordData,
  });
}

/// 0x14读文件请求
/// fileNum 文件号
/// recordNum 记录号
/// dataLength 读多少条数据
class ReadFileRequest {
  int? fileNum;
  int? recordNum;
  int? dataLength;

  ReadFileRequest({
    this.fileNum,
    this.recordNum,
    this.dataLength,
  });
}

/// 将ReadFileRequest 转换成ReadFileInfo
/// 包含了每一个record的数据字节数
class ReadFileInfo {
  int? fileNum;
  int? recordNum;
  int? recordLength;
  List<int>? dataSizes;

  ReadFileInfo({
    this.fileNum,
    this.recordNum,
    this.recordLength,
    this.dataSizes,
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
