import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_blue/flutter_blue.dart';

import 'package:flutter_blue/gen/flutterblue.pb.dart' as proto;

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'BLE Demo',
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
        home: MyHomePage(title: 'Flutter BLE Demo'),
      );
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;
  final FlutterBlue flutterBlue = FlutterBlue.instance;
  final devicesList = <BluetoothDevice>[];
  final connectedDevicesList = <BluetoothDevice>[];
  final readValues = <Guid, List<int>>{};

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final _writeController = TextEditingController();
  BluetoothDevice? _connectedDevice;
  List<BluetoothService>? _services;

  _addDeviceTolist(final BluetoothDevice device) {
    if (!widget.devicesList.contains(device)) {
      setState(() {
        widget.devicesList.add(device);
      });
    }
  }

  _addConnectedDeviceTolist(final BluetoothDevice device) {
    if (!widget.connectedDevicesList.contains(device)) {
      setState(() {
        widget.connectedDevicesList.add(device);
      });
    }
  }

  @override
  void initState() {
    super.initState();
    // widget.flutterBlue.connectedDevices
    //     .asStream()
    //     .listen((List<BluetoothDevice> devices) {
    //   for (BluetoothDevice device in devices) {
    //     _addConnectedDeviceTolist(device);
    //   }
    //   // var p = proto.BluetoothDevice.create()
    //   //   ..name = 'Mi Smart Band 6'
    //   //   ..remoteId = 'AB2FA54A-C3C8-ED16-1C69-46DDA1915544'
    //   //   ..type = proto.BluetoothDevice_Type.LE;
    //   // print(p.toString());
    //   // BluetoothDevice dummy = BluetoothDevice.fromProto(p);

    //   // _addConnectedDeviceTolist(dummy);
    // });
    widget.flutterBlue.scanResults.listen((List<ScanResult> results) {
      for (ScanResult result in results) {
        _addConnectedDeviceTolist(result.device);
      }
    });
    widget.flutterBlue.startScan();

    // BluetoothDevice.fromProto(Proto)
    // _addDeviceTolist()
  }

  ListView _buildListViewOfDevices() {
    List<Container> containers = <Container>[];
    for (BluetoothDevice device in widget.connectedDevicesList) {
      if (device.name.contains('')) {
        print('name: ${device.name}');
        print('name: ${device.id}');
        print('name: ${device.type}');
        print('name: ${device.toString()}');
        containers.add(
          Container(
            height: 150,
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Column(
                    children: <Widget>[
                      Text(
                          device.name == '' ? '(unknown device)' : device.name),
                      Text(device.id.toString()),
                    ],
                  ),
                ),
                TextButton(
                  child: const Text(
                    'Connect',
                    style: TextStyle(color: Colors.black),
                  ),
                  onPressed: () async {
                    widget.flutterBlue.stopScan();
                    try {
                      print('1: ${device.name}');
                      print('1: ${device.type}');
                      print('1: ${device.id}');
                      await device.connect();
                      print('111');
                    } catch (e) {
                      print('2');
                      print(e);
                      print('222');
                    }
                    // finally {
                    //   print('3');
                    //   _services = await device.discoverServices();
                    //   print('333');
                    // }
                    print('544455');
                    setState(() {
                      _connectedDevice = device;
                    });
                  },
                ),
                TextButton(
                  child: const Text(
                    'DisConnect',
                    style: TextStyle(color: Colors.black),
                  ),
                  onPressed: () async {
                    widget.flutterBlue.stopScan();
                    try {
                      print('11');
                      await device.disconnect();
                      print('111');
                    } catch (e) {
                      print('2');
                      print(e);
                      print('222');
                    }
                    print('544455');
                    setState(() {
                      _connectedDevice = null;
                    });
                  },
                ),
              ],
            ),
          ),
        );
      } else {
        print('아님');
      }
    }

    return ListView(
      padding: const EdgeInsets.all(8),
      children: <Widget>[
        ...containers,
      ],
    );
  }

  List<ButtonTheme> _buildReadWriteNotifyButton(
      BluetoothCharacteristic characteristic) {
    List<ButtonTheme> buttons = <ButtonTheme>[];

    if (characteristic.properties.read) {
      buttons.add(
        ButtonTheme(
          minWidth: 10,
          height: 20,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: RaisedButton(
              color: Colors.blue,
              child: Text('READ', style: TextStyle(color: Colors.white)),
              onPressed: () async {
                var sub = characteristic.value.listen((value) {
                  setState(() {
                    widget.readValues[characteristic.uuid] = value;
                    print('오오: ${value}');
                  });
                });
                await characteristic.read();
                sub.cancel();
              },
            ),
          ),
        ),
      );
    }
    if (characteristic.properties.write) {
      buttons.add(
        ButtonTheme(
          minWidth: 10,
          height: 20,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: RaisedButton(
              child: Text('WRITE', style: TextStyle(color: Colors.white)),
              onPressed: () async {
                await showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: Text("Write"),
                        content: Row(
                          children: <Widget>[
                            Expanded(
                              child: TextField(
                                controller: _writeController,
                              ),
                            ),
                          ],
                        ),
                        actions: <Widget>[
                          FlatButton(
                            child: Text("Send"),
                            onPressed: () {
                              characteristic.write(
                                  utf8.encode(_writeController.value.text));
                              Navigator.pop(context);
                            },
                          ),
                          FlatButton(
                            child: Text("Cancel"),
                            onPressed: () {
                              Navigator.pop(context);
                            },
                          ),
                        ],
                      );
                    });
              },
            ),
          ),
        ),
      );
    }
    if (characteristic.properties.notify) {
      buttons.add(
        ButtonTheme(
          minWidth: 10,
          height: 20,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: RaisedButton(
              child: Text('NOTIFY', style: TextStyle(color: Colors.white)),
              onPressed: () async {
                characteristic.value.listen((value) {
                  widget.readValues[characteristic.uuid] = value;
                  print('아아아: ${value}');
                  setState(() {});
                });
                await characteristic.setNotifyValue(true);
              },
            ),
          ),
        ),
      );
    }

    return buttons;
  }

  ListView _buildConnectDeviceView() {
    List<Container> containers = <Container>[];

    for (BluetoothService service in _services!) {
      List<Widget> characteristicsWidget = <Widget>[];

      for (BluetoothCharacteristic characteristic in service.characteristics) {
        characteristicsWidget.add(
          Align(
            alignment: Alignment.centerLeft,
            child: Column(
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Text(characteristic.uuid.toString(),
                        style: TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
                Row(
                  children: <Widget>[
                    ..._buildReadWriteNotifyButton(characteristic),
                  ],
                ),
                Row(
                  children: <Widget>[
                    Text('Value: ' +
                        widget.readValues[characteristic.uuid].toString()),
                  ],
                ),
                Divider(),
              ],
            ),
          ),
        );
      }
      containers.add(
        Container(
          child: ExpansionTile(
              title: Text(service.uuid.toString()),
              children: characteristicsWidget),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(8),
      children: <Widget>[
        ...containers,
      ],
    );
  }

  ListView _buildView() {
    if (_connectedDevice != null) {
      return _buildConnectDeviceView();
    }
    return _buildListViewOfDevices();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: Text(widget.title),
        ),
        body: _buildView(),
      );
}



/// 
/// mi fit 앱 다운로드
/// 밴드 연결
/// 검색 가능 ON -> 이거 해야 bluetooth 검색 가능
/// 
/// 
/// 미밴드6(한규) - 2DA091D2-B5C3-08E3-00FC-0D47624C8247
/// uuid: 00002a37-0000-1000-8000-00805f9b34fb value: {length = 2, bytes = 0x0041}
/// uuid: 00002a37-0000-1000-8000-00805f9b34fb value: {length = 2, bytes = 0x0048}
/// 
/// 미밴드4 - 6452AA43-7BF2-B727-9CAC-26CDB2FC0A44
/// uuid: 00002a37-0000-1000-8000-00805f9b34fb value: {length = 2, bytes = 0x0041}
/// uuid: 00002a37-0000-1000-8000-00805f9b34fb value: {length = 2, bytes = 0x0048}
/// 
/// 미밴드6(한규) - 
/// 
/// 
/// Connect 해서 기기랑 연결하고, 더 이상 필요없으면 disconnect 꼭 해주기
/// 
/// 180d -> 심박 데이터 sercice id
/// 
