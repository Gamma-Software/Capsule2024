/////////////////////////////////////////////////////////////////
/*
  AWS IoT | Flutter MQTT Client App [Full Version]
  Video Tutorial: https://youtu.be/aY7i0xnQW54
  Created by Eric N. (ThatProject)
*/
/////////////////////////////////////////////////////////////////

import 'package:flutter/material.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'package:ndialog/ndialog.dart';
import 'dart:async';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Capsule 2024',
      themeMode: ThemeMode.dark,
      darkTheme: ThemeData.dark(),
      home: MQTTClient(),
    );
  }
}

class MQTTClient extends StatefulWidget {
  const MQTTClient({Key? key}) : super(key: key);

  @override
  _MQTTClientState createState() => _MQTTClientState();
}

class _MQTTClientState extends State<MQTTClient> {
  String statusText = "Status Text";
  double voltage = 0.0;
  bool isConnected = false;
  String doorStatus = "Closed";
  TextEditingController idTextController = TextEditingController();
  List<bool> _values = [false, false, false, false, false];

  final MqttServerClient client = MqttServerClient('192.168.3.1', '');

  @override
  void dispose() {
    idTextController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
        length: 3,
        child: Scaffold(
          appBar: AppBar(
            title: const Text("Capsule 2024"),
            actions: <Widget>[
              Padding(
                  padding: const EdgeInsets.only(right: 20),
                  child: GestureDetector(
                      onTap: !isConnected ? _connect : _disconnect,
                      child: Icon(
                        !isConnected ? Icons.cloud_off : Icons.cloud_rounded,
                      ))),
              Padding(
                  padding: const EdgeInsets.only(right: 20),
                  child: GestureDetector(
                      onTap: () {
                        print("settings");
                      },
                      child: Icon(Icons.settings)))
            ],
            bottom: isConnected
                ? const TabBar(
                    tabs: [
                      Tab(icon: Icon(Icons.directions_car)),
                      Tab(icon: Icon(Icons.launch_outlined)),
                      Tab(icon: Icon(Icons.monitor)),
                    ],
                  )
                : null,
          ),
          body: isConnected
              ? TabBarView(
                  children: [
                    Column(
                      children: [
                        // Using Curves.bounceIn
                        Container(
                          width: double.infinity,
                          height: 100,
                          color: Colors.transparent,
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              "Battery Voltage: " + voltage.toString() + "V",
                              style: const TextStyle(
                                  fontSize: 30, color: Colors.white),
                            ),
                          ),
                        ), // Using Curves.elasticInOut
                        Container(
                          width: double.infinity,
                          height: 100,
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              "Door Status: " + doorStatus,
                              style: const TextStyle(
                                  fontSize: 30, color: Colors.white),
                            ),
                          ),
                        ), // Using Curves.elasticInOut
                        Column(
                          children: <Widget>[
                            for (int i = 0; i <= 4; i++)
                              ListTile(
                                title: Text(
                                  'Switch ${i + 1}',
                                  style: Theme.of(context)
                                      .textTheme
                                      .subtitle1
                                      ?.copyWith(
                                          color: i == 4
                                              ? Colors.white38
                                              : Colors.white),
                                ),
                                leading: Switch(
                                  value: _values[i],
                                  activeColor: Color(0xFF6200EE),
                                  onChanged: (bool value) {
                                    client.publishMessage(
                                        "request",
                                        MqttQos.exactlyOnce,
                                        MqttClientPayloadBuilder()
                                            .addString(
                                                "0 10 0 192.168.3.1 502 5 1 6 326 " +
                                                    (value ? "1" : "0"))
                                            .payload!);
                                    setState(() {
                                      _values[i] = value;
                                    });
                                  },
                                ),
                              ),
                          ],
                        )
                      ],
                    ),
                    Center(child: Text("Transit")),
                    Center(child: Text("Bike"))
                  ],
                )
              : Container(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        Text(
                          "Connect to the server to see the app",
                          style: TextStyle(fontSize: 20),
                        ),
                        FloatingActionButton.extended(
                          label: Text('Connect'), // <-- Text
                          backgroundColor: Colors.white,
                          icon: Icon(
                            Icons.cloud_rounded,
                            size: 24.0,
                          ),
                          onPressed: _connect,
                        ),
                      ],
                    ),
                  ),
                ),
        ));
  }

  _connect() async {
    ProgressDialog progressDialog = ProgressDialog(context,
        blur: 0,
        dialogTransitionType: DialogTransitionType.Shrink,
        dismissable: false);
    progressDialog.setLoadingWidget(const CircularProgressIndicator(
      valueColor: AlwaysStoppedAnimation(Colors.red),
    ));
    progressDialog
        .setMessage(const Text("Please Wait, Connecting MQTT Broker"));
    progressDialog.setTitle(const Text("Connecting"));
    progressDialog.show();

    isConnected = await mqttConnect("androidapp");
    progressDialog.dismiss();
  }

  _disconnect() {
    client.disconnect();
  }

  Future<bool> mqttConnect(String uniqueId) async {
    setStatus("Connecting MQTT Broker");

    // After adding your certificates to the pubspec.yaml, you can use Security Context.
    //
    // ByteData rootCA = await rootBundle.load('assets/certs/RootCA.pem');
    // ByteData deviceCert =
    //     await rootBundle.load('assets/certs/DeviceCertificate.crt');
    // ByteData privateKey = await rootBundle.load('assets/certs/Private.key');
    //
    // SecurityContext context = SecurityContext.defaultContext;
    // context.setClientAuthoritiesBytes(rootCA.buffer.asUint8List());
    // context.useCertificateChainBytes(deviceCert.buffer.asUint8List());
    // context.usePrivateKeyBytes(privateKey.buffer.asUint8List());
    //
    // client.securityContext = context;

    client.logging(on: true);
    client.keepAlivePeriod = 20;
    client.port = 1883;
    client.secure = false;
    client.onConnected = onConnected;
    client.onDisconnected = onDisconnected;
    client.pongCallback = pong;

    final MqttConnectMessage connMess =
        MqttConnectMessage().withClientIdentifier(uniqueId).startClean();
    client.connectionMessage = connMess;

    await client.connect();
    if (client.connectionStatus!.state == MqttConnectionState.connected) {
      print("Connected to " + client.server + "!");
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Failed to connect"),
          duration: Duration(milliseconds: 400),
        ),
      );
      return false;
    }

    const batteryVoltageTopic = 'router/1114481305/analog';
    client.subscribe(batteryVoltageTopic, MqttQos.atMostOnce);
    const responseTopic = 'response';
    client.subscribe(responseTopic, MqttQos.atMostOnce);

    client.updates!.listen((List<MqttReceivedMessage<MqttMessage?>>? c) {
      final recMess = c![0].payload as MqttPublishMessage;
      final pt =
          MqttPublishPayload.bytesToStringAsString(recMess.payload.message);
      switch (c[0].topic) {
        case batteryVoltageTopic:
          setState(() {
            voltage = double.parse(pt);
          });
          break;
        case responseTopic:
          // Split the payload by space
          List<String> response = pt.split(' ');
          // TODO Handle the errors
          switch (response[0]) {
            case '10':
              setState(() {
                _values[0] = int.parse(response[2]) == 1 ? true : false;
              });
              break;
          }
          break;
        default:
          break;
      }
      print(
          'EXAMPLE::Change notification:: topic is <${c[0].topic}>, payload is <-- $pt -->');
      print('');
    });

    client.published!.listen((MqttPublishMessage message) {
      print(
          'EXAMPLE::Published notification:: topic is ${message.variableHeader!.topicName}, with Qos ${message.header!.qos}');
    });

    /// Lets publish to our topic
    /// Use the payload builder rather than a raw buffer
    /// Our known topic to publish to
    const pubTopic = 'request';
    final requestOutput4Change = MqttClientPayloadBuilder();
    requestOutput4Change.addString('0 65442 0 192.168.3.1 502 5 1 6 326 1');

    return true;
  }

  void setStatus(String content) {
    setState(() {
      statusText = content;
    });
  }

  void onConnected() {
    setStatus("Client connection was successful");
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Connected"),
        duration: Duration(milliseconds: 400),
      ),
    );
    // Start the async function to retrieve the battery voltage
    Timer.periodic(const Duration(seconds: 1), (timer) {
      // If the client is not connected anymore, stop the timer
      if (!isConnected) {
        timer.cancel();
        return;
      }
      client.publishMessage("router/get", MqttQos.exactlyOnce,
          MqttClientPayloadBuilder().addString("analog").payload!);
      print("Publishing Message");
    });
    Timer.periodic(const Duration(seconds: 1), (timer) {
      // If the client is not connected anymore, stop the timer
      if (!isConnected) {
        timer.cancel();
        return;
      }
      client.publishMessage(
          "request",
          MqttQos.exactlyOnce,
          MqttClientPayloadBuilder()
              .addString("0 10 0 192.168.3.1 502 5 1 3 326 1")
              .payload!);
    });
  }

  void onDisconnected() {
    setStatus("Client Disconnected");
    isConnected = false;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Disconnected"),
        duration: Duration(milliseconds: 400),
      ),
    );
  }

  void pong() {
    print('Ping response client callback invoked');
  }
}
