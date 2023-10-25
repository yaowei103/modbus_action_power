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
          child: Column(
            children: [
              ElevatedButton(
                onPressed: () {
                  initModbus();
                },
                child: const Text('init modbus'),
              )
            ],
          ),
        ),
      ),
    );
  }
}
