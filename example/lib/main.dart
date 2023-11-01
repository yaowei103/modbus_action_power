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

  @override
  void initState() {
    super.initState();
  }

  initModbus() {
    _modbusActionPowerPlugin.initModbus();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Plugin example app'),
        ),
        body: Center(
          child: Row(
            children: [
              Column(
                children: [
                  const Text('program'),
                  ElevatedButton(
                    onPressed: () {
                      initModbus();
                    },
                    child: const Text('init modbus'),
                  ),
                ],
              ),
              const Divider(
                color: Colors.grey, // 分割线的颜色
                thickness: 1.0, // 分割线的厚度
                height: double.infinity,
              ),
              Column(
                children: [
                  const Text('test'),
                  ElevatedButton(
                    onPressed: () {
                      _modbusActionPowerPlugin.testInit();
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
                    onPressed: () {
                      _modbusActionPowerPlugin.getData();
                    },
                    child: const Text('getData'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      _modbusActionPowerPlugin.getDataFloat();
                    },
                    child: const Text('getDataFloat'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      _modbusActionPowerPlugin.setData();
                    },
                    child: const Text('setData'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
