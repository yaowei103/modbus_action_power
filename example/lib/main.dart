import 'package:flutter/material.dart';
import 'package:modbus_action_power/modbus_action_power.dart';

import 'data.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late ModbusActionPower _modbusActionPowerPlugin;
  late ModbusActionPower _modbusActionPowerPlugin485;
  String getTypeResultData = '';
  int getTime = 0;
  String setTypeResultData = '';
  int setTime = 0;
  bool initDone = false;

  String filePath = 'assets/pre20Modbus.xlsx'; //'assets/ppmDCModbus.xlsx';
  String filePath485 = 'assets/DisplayControl.xlsx';

  @override
  void initState() {
    super.initState();
    init();
  }

  init() async {
    await ModbusFiles.copyFileToSupportDir([filePath, filePath485]);
    _modbusActionPowerPlugin = ModbusActionPower(filePath: filePath);
    await _modbusActionPowerPlugin.initDone();
    _modbusActionPowerPlugin485 = ModbusActionPower(filePath: filePath485);
    await _modbusActionPowerPlugin485.initDone();
    setState(() {
      initDone = true;
      getTypeResultData = 'init done';
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Plugin example app'),
        ),
        body: SingleChildScrollView(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 400,
                padding: const EdgeInsets.all(5),
                child: Wrap(
                  spacing: 3,
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        init();
                      },
                      child: const Text('init modbus'),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        _modbusActionPowerPlugin.disConnect();
                      },
                      child: const Text('disConnect'),
                    ),
                    ElevatedButton(
                      onPressed: initDone
                          ? () async {
                              final reqStopwatch = Stopwatch()..start();
                              // await _modbusActionPowerPlugin.getData(startRegAddr: '304', dataCount: '21');
                              // await _modbusActionPowerPlugin.getData(startRegAddr: '256', dataCount: '18');
                              // await _modbusActionPowerPlugin.getData(startRegAddr: '0', dataCount: '6');
                              var res = await _modbusActionPowerPlugin.getData(startRegAddr: '256', dataCount: '18'); // 3072_54
                              setState(() {
                                getTime = reqStopwatch.elapsedMilliseconds;
                                getTypeResultData = res.status == 0 ? res.data : res.message;
                              });
                            }
                          : null,
                      child: const Text('getData'),
                    ),
                    ElevatedButton(
                      onPressed: initDone
                          ? () async {
                              final reqStopwatch = Stopwatch()..start();
                              var res = await _modbusActionPowerPlugin.setData(startRegAddr: '3072', serializableDat: '50.001');
                              setState(() {
                                setTime = reqStopwatch.elapsedMilliseconds;
                                setTypeResultData = res.status == 0 ? res.data : res.message;
                              });
                            }
                          : null,
                      child: const Text('setData-single'),
                    ),
                    ElevatedButton(
                      onPressed: initDone
                          ? () async {
                              final reqStopwatch = Stopwatch()..start();
                              var res = await _modbusActionPowerPlugin.setData(
                                startRegAddr: '3072',
                                serializableDat: setData3072,
                              );
                              setState(() {
                                setTime = reqStopwatch.elapsedMilliseconds;
                                setTypeResultData = res.status == 0 ? res.data : res.message;
                              });
                            }
                          : null,
                      child: const Text('setData-multiple'),
                    ),
                    ElevatedButton(
                      onPressed: initDone
                          ? () async {
                              final reqStopwatch = Stopwatch()..start();
                              var res = await _modbusActionPowerPlugin.get2bData(objectName: '监控软件版本');
                              setState(() {
                                getTime = reqStopwatch.elapsedMilliseconds;
                                getTypeResultData = res.status == 0 ? res.data : res.message;
                              });
                            }
                          : null,
                      child: const Text('get2BData'),
                    ),
                    ElevatedButton(
                      onPressed: initDone
                          ? () async {
                              final reqStopwatch = Stopwatch()..start();
                              var res = await _modbusActionPowerPlugin.getData(
                                startRegAddr: '24576',
                                dataCount: '4096',
                              );
                              setState(() {
                                getTime = reqStopwatch.elapsedMilliseconds;
                                getTypeResultData = res.status == 0 ? res.data : res.message;
                              });
                            }
                          : null,
                      child: const Text('get自定义波形24576-4096'),
                    ),
                    ElevatedButton(
                      onPressed: initDone
                          ? () async {
                              final reqStopwatch = Stopwatch()..start();
                              var res = await _modbusActionPowerPlugin.setData(
                                startRegAddr: '24576',
                                serializableDat: customWaveList.join(','),
                              );
                              setState(() {
                                setTime = reqStopwatch.elapsedMilliseconds;
                                setTypeResultData = res.status == 0 ? res.data : res.message;
                              });
                            }
                          : null,
                      child: const Text('set自定义波形24576-4096'),
                    ),
                    ElevatedButton(
                      onPressed: initDone
                          ? () async {
                              final reqStopwatch = Stopwatch()..start();
                              var res = await _modbusActionPowerPlugin.getData(
                                startRegAddr: '31488',
                                dataCount: '1024',
                              );
                              setState(() {
                                getTime = reqStopwatch.elapsedMilliseconds;
                                getTypeResultData = res.status == 0 ? res.data : res.message;
                              });
                            }
                          : null,
                      child: const Text('get自定义曲线31488_1024'),
                    ),
                    ElevatedButton(
                      onPressed: initDone
                          ? () async {
                              final reqStopwatch = Stopwatch()..start();
                              var res = await _modbusActionPowerPlugin.setData(
                                startRegAddr: '31488',
                                serializableDat: customCurveList.join(','),
                              );
                              setState(() {
                                setTime = reqStopwatch.elapsedMilliseconds;
                                setTypeResultData = res.status == 0 ? res.data : res.message;
                              });
                            }
                          : null,
                      child: const Text('set自定义曲线31488-1024'),
                    ),
                    ElevatedButton(
                      onPressed: initDone
                          ? () async {
                              final reqStopwatch = Stopwatch()..start();
                              var res = await _modbusActionPowerPlugin485.getData(startRegAddr: '0', dataCount: '6');
                              setState(() {
                                getTime = reqStopwatch.elapsedMilliseconds;
                                getTypeResultData = res.status == 0 ? res.data : res.message;
                              });
                            }
                          : null,
                      child: const Text('get485'),
                    ),
                    ElevatedButton(
                      onPressed: initDone
                          ? () async {
                              final reqStopwatch = Stopwatch()..start();
                              var res = await _modbusActionPowerPlugin485.setData(startRegAddr: '2304', serializableDat: '1');
                              setState(() {
                                setTime = reqStopwatch.elapsedMilliseconds;
                                setTypeResultData = res.status == 0 ? res.data : res.message;
                              });
                            }
                          : null,
                      child: const Text('set485-1'),
                    ),
                    ElevatedButton(
                      onPressed: initDone
                          ? () async {
                              final reqStopwatch = Stopwatch()..start();
                              var res = await _modbusActionPowerPlugin485.setData(startRegAddr: '2304', serializableDat: '0');
                              setState(() {
                                setTime = reqStopwatch.elapsedMilliseconds;
                                setTypeResultData = res.status == 0 ? res.data : res.message;
                              });
                            }
                          : null,
                      child: const Text('set485-0'),
                    ),
                    const Divider(),
                    // 异常01 不合法功能码
                    // 异常02 不合法数据地址
                    // 异常03 不合法数据
                    // 异常05 CRC校验错误
                    // 异常07 拒绝访问
                    ElevatedButton(
                      onPressed: () async {
                        final reqStopwatch = Stopwatch()..start();
                        var res = await _modbusActionPowerPlugin.getData(startRegAddr: '999999', dataCount: '1');
                        setState(() {
                          getTime = reqStopwatch.elapsedMilliseconds;
                          getTypeResultData = res.status == 0 ? res.data : res.message;
                        });
                      },
                      child: const Text('未配置地址'),
                    ),
                    ElevatedButton(
                      onPressed: () async {
                        final reqStopwatch = Stopwatch()..start();
                        // 配合注释使用 ModbusMaster getRegister方法第一行注释使用
                        var res = await _modbusActionPowerPlugin.getData(startRegAddr: '99999999', dataCount: '1');
                        setState(() {
                          getTime = reqStopwatch.elapsedMilliseconds;
                          getTypeResultData = res.status == 0 ? res.data : res.message;
                        });
                      },
                      child: const Text('地址有误'),
                    ),
                    ElevatedButton(
                      onPressed: () async {
                        final reqStopwatch = Stopwatch()..start();
                        var res = await _modbusActionPowerPlugin.setData(startRegAddr: '3072', serializableDat: '999999');
                        setState(() {
                          setTime = reqStopwatch.elapsedMilliseconds;
                          setTypeResultData = res.status == 0 ? res.data : res.message;
                        });
                      },
                      child: const Text('数据错误'),
                    ),
                    ElevatedButton(
                      onPressed: initDone
                          ? () async {
                              final reqStopwatch = Stopwatch()..start();
                              var res = await _modbusActionPowerPlugin.setData(startRegAddr: '13322', serializableDat: '0,0,0.0500000,1.0,1.0,0,50,0,0,0,0,0');
                              setState(() {
                                setTime = reqStopwatch.elapsedMilliseconds;
                                setTypeResultData = res.status == 0 ? res.data : res.message;
                              });
                            }
                          : null,
                      child: const Text('set-13322'),
                    ),
                  ],
                ),
              ),
              Container(
                width: 400,
                color: Colors.grey,
                child: Column(
                  children: [Text('get 结果: $getTime'), Text(getTypeResultData)],
                ),
              ),
              Container(
                width: 400,
                color: Colors.blueGrey,
                child: Column(
                  children: [
                    Text('set 结果：$setTime'),
                    Text(setTypeResultData),
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
