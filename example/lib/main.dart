import 'package:flutter/material.dart';
import 'package:modbus_action_power/modbus_action_power.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final _modbusActionPowerPlugin = ModbusActionPower();
  String getTypeResultData = '';
  int getTime = 0;
  String setTypeResultData = '';
  int setTime = 0;

  @override
  void initState() {
    super.initState();
    _modbusActionPowerPlugin.initModbus();
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
              Column(
                children: [
                  const Text('test'),
                  ElevatedButton(
                    onPressed: () {
                      _modbusActionPowerPlugin.initModbus();
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
                    onPressed: () async {
                      final reqStopwatch = Stopwatch()..start();
                      var res = await _modbusActionPowerPlugin.getData(startRegAddr: '3072', dataCount: '54');
                      setState(() {
                        getTime = reqStopwatch.elapsedMilliseconds;
                        getTypeResultData = res;
                      });
                    },
                    child: const Text('getData'),
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      final reqStopwatch = Stopwatch()..start();
                      var res = await _modbusActionPowerPlugin.setData(startRegAddr: '3072', serializableDat: '50.001');
                      setState(() {
                        setTime = reqStopwatch.elapsedMilliseconds;
                        setTypeResultData = res;
                      });
                    },
                    child: const Text('setData-single'),
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      final reqStopwatch = Stopwatch()..start();
                      var res = await _modbusActionPowerPlugin.setData(startRegAddr: '3072', serializableDat: '50.4,50.5');
                      setState(() {
                        setTime = reqStopwatch.elapsedMilliseconds;
                        setTypeResultData = res;
                      });
                    },
                    child: const Text('setData-multiple'),
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      final reqStopwatch = Stopwatch()..start();
                      var res = await _modbusActionPowerPlugin.get2bData(objectName: '监控软件版本');
                      setState(() {
                        getTime = reqStopwatch.elapsedMilliseconds;
                        getTypeResultData = res;
                      });
                    },
                    child: const Text('get2BData'),
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      final reqStopwatch = Stopwatch()..start();
                      var res = await _modbusActionPowerPlugin.getData(startRegAddr: '24576', dataCount: '4096');
                      setState(() {
                        getTime = reqStopwatch.elapsedMilliseconds;
                        getTypeResultData = res;
                      });
                    },
                    child: const Text('自定义波形24576-4096'),
                  ),
                ],
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
