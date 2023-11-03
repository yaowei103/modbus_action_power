import '../packages/modbus_client_serial/modbus_client_serial.dart';

import '../entity/ReturnEntity.dart';

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
  /// 使用寄存器地址下发数据
  ///
  /// index 设备索引号，0起始
  /// startRegAddr 更新寄存器起始地址
  /// serializableDat 待更新寄存器数据，数据以‘,’分割
  /// SetDatLength 下发数据长度，下发默认值时使用
  Future<ReturnEntity> setRegister({
    required String index,
    required String startRegAddr,
    required String serializableDat,
    int setDatLength = 0,
  });

  /// 通过寄存器名称设置设备规定寄存器对应的实际物理量
  ///
  /// index 设备索引号
  /// startRegName 更新寄存器起始含义
  /// serializableDat 待更新寄存器数据，数据以‘,’分割
  /// SetDatLength 下发数据长度，下发默认值时使用
  Future<ReturnEntity> setRegisterByName({
    required String index,
    required String startRegName,
    required String serializableDat,
    int setDatLength = 0,
  });

  /// 通过寄存器地址从设备读取规定寄存器对应的实际物理量
  ///
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
  Future<ReturnEntity> getRegisterByName({
    required String index,
    required String startRegName,
    required String dataCount,
  });

//   // 添加寄存器地址
//   ReturnEntity addRegister(int index, String data);

  /// 加载协议
  ///
  /// protocol 协议文件全路径
  Future<ReturnEntity> readComFileInfo(String protocol);

  // 注销接口
  // 总线监测事件接口
  // 从站更新寄存器事件通知
  late void Function(Object) receiveDataChanged;
  late void Function(Object) sendDataChanged;
}
