import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

import '../entity/ReturnEntity.dart';

class Files {
  static Future<ReturnEntity> copyFileToLocal(String fromFilePath, String toFilePath) async {
    ReturnEntity returnEntity = ReturnEntity();
    try {
      if (File(toFilePath).existsSync()) {
        File(toFilePath).deleteSync();
      }
      var data = await rootBundle.load(fromFilePath);
      var fileName = toFilePath.split('/')[1]; // 备份文件名
      Directory internalDir = await getApplicationSupportDirectory();
      String dir = internalDir.path;
      File file = File('$dir/$fileName');
      await file.writeAsBytes(data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes));
      bool fileExist = await file.exists();
      if (fileExist) {
        returnEntity.status = 0;
        returnEntity.data = file.path;
        return returnEntity;
      }
      returnEntity.status = -16449012;
      returnEntity.message = "源文件不存在，文件路径：$fromFilePath";
      return returnEntity;
    } catch (ex) {
      returnEntity.status = -16449011;
      returnEntity.message = "协议备份失败:$ex";
      return returnEntity;
    }
  }

  /// <summary>
  /// 拷贝文件
  /// </summary>
  /// <param name="fromFilePath">文件的路径</param>
  /// <param name="toFilePath">文件要拷贝到的路径</param>
  static ReturnEntity copyFile(String fromFilePath, String toFilePath) {
    ReturnEntity returnEntity = ReturnEntity();
    try {
      if (File(fromFilePath).existsSync()) {
        if (File(toFilePath).existsSync()) {
          File(toFilePath).deleteSync();
        }
        File(fromFilePath).copySync(toFilePath);
        return returnEntity;
      }
      returnEntity.status = -16449012;
      returnEntity.message = "源文件不存在，文件路径：$fromFilePath";
      return returnEntity;
    } catch (ex) {
      returnEntity.status = -16449011;
      returnEntity.message = "协议备份失败:$ex";
      return returnEntity;
    }
  }

  // #region 文件删除
  /// <summary>
  /// 删除文件操作
  /// </summary>
  /// <param name="filePath">文件路径</param>
  static ReturnEntity DeleteFile(String filePath) {
    ReturnEntity returnEntity = ReturnEntity();
    try {
      String destinationFile = filePath;
      //如果文件存在，删除文件
      if (File(destinationFile).existsSync()) {
        File(destinationFile).deleteSync();
        return returnEntity;
      }
      returnEntity.status = -16449009;
      returnEntity.message = "文件不存在，文件路径：$destinationFile";
      return returnEntity;
    } catch (ex) {
      returnEntity.status = -16449009;
      returnEntity.message = ex.toString();
      return returnEntity;
    }
  }
  // #endregion

  // modbus配置文件写入 getApplicationSupportDirectory
  static Future copyFileToSupportDir(List<String> filePaths) async {
    for (String filePath in filePaths) {
      String fileName = filePath.split('/').last;
      var data = await rootBundle.load(filePath);
      Directory internalDir = await getApplicationSupportDirectory();
      String dir = internalDir.path;
      File file = File('$dir/$fileName');
      await file.writeAsBytes(data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes));
    }
  }
}
