import 'dart:math';

import 'package:capsule2024/service/notification/notification_service.dart';
import 'package:latlong2/latlong.dart';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:maps_launcher/maps_launcher.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'package:ndialog/ndialog.dart';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:capsule2024/widget/leveling_bubble.dart';

class MQTTClient extends StatefulWidget {
  const MQTTClient({Key? key}) : super(key: key);

  @override
  _MQTTClientState createState() => _MQTTClientState();
}

class _MQTTClientState extends State<MQTTClient> {
  final String _localServer = '192.168.3.1';
  final String _remoteServer = '192.168.255.6';
  String _server = '192.168.3.1';
  String statusText = "Status Text";
  double _routerTemperature = 0.0;
  double voltage = 0.0;
  bool isConnected = false;
  String doorStatus = "Closed";
  TextEditingController idTextController = TextEditingController();
  bool _digitalInputState = false;
  bool _isolatedInputState = false;
  bool _inputPowerState = false;
  double _analogInValue = 0.0;
  bool _outputPowerState = false;
  bool _outputState = false;
  bool _relayState = false;
  final LatLng _capsuleLocation = LatLng(0.0, 0.0);

  MqttServerClient client = MqttServerClient('192.168.3.1', '');
  String _user = "";
  String _pass = "";

  final NotificationService _notificationService = NotificationService();

  @override
  void initState() {
    super.initState();
    _loadParams();
    _notificationService.init();
  }

  @override
  void dispose() {
    idTextController.dispose();
    super.dispose();
  }

  //Loading counter value on start
  void _loadParams() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    _user = prefs.getString('user') ?? "";
    _pass = prefs.getString('pass') ?? "";
  }

  //Incrementing counter after click
  void _saveParams() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString('user', _user);
    prefs.setString('pass', _pass);
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
              //Padding(
              //    padding: const EdgeInsets.only(right: 20),
              //    child: GestureDetector(
              //        onTap: () {}, child: const Icon(Icons.settings)))
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
                              "Voltage batterie: " +
                                  _analogInValue.toString() +
                                  "V",
                              style: const TextStyle(
                                  fontSize: 30, color: Colors.white),
                            ),
                          ),
                        ),
                        // Using Curves.bounceIn
                        Container(
                          width: double.infinity,
                          height: 100,
                          color: Colors.transparent,
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              "Input power: " + _outputPowerState.toString(),
                              style: const TextStyle(
                                  fontSize: 30, color: Colors.white),
                            ),
                          ),
                        ),
                        Container(
                          width: double.infinity,
                          height: 100,
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              "Portes: " +
                                  (_digitalInputState ? "ouvertes" : "fermées"),
                              style: const TextStyle(
                                  fontSize: 30, color: Colors.white),
                            ),
                          ),
                        ),
                        Container(
                          width: double.infinity,
                          height: 100,
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              "Isolated input: " +
                                  (_isolatedInputState ? "high" : "low"),
                              style: const TextStyle(
                                  fontSize: 30, color: Colors.white),
                            ),
                          ),
                        ), // Using Curves.elasticInOut
                        Column(
                          children: <Widget>[
                            ListTile(
                              title: Text(
                                'Relay',
                                style: Theme.of(context)
                                    .textTheme
                                    .subtitle1
                                    ?.copyWith(color: Colors.white),
                              ),
                              leading: Switch(
                                value: _relayState,
                                activeColor: const Color(0xFF6200EE),
                                onChanged: (bool value) {
                                  setRelay(value);
                                  setState(() {
                                    _relayState = value;
                                  });
                                },
                              ),
                            ),
                            ListTile(
                              title: Text(
                                'Output1',
                                style: Theme.of(context)
                                    .textTheme
                                    .subtitle1
                                    ?.copyWith(color: Colors.white),
                              ),
                              leading: Switch(
                                value: _outputState,
                                activeColor: const Color(0xFF6200EE),
                                onChanged: (bool value) {
                                  setOutput1(value);
                                  setState(() {
                                    _outputState = value;
                                  });
                                },
                              ),
                            ),
                            ListTile(
                              title: Text(
                                'OutputPower',
                                style: Theme.of(context)
                                    .textTheme
                                    .subtitle1
                                    ?.copyWith(color: Colors.white),
                              ),
                              leading: Switch(
                                value: _outputPowerState,
                                activeColor: const Color(0xFF6200EE),
                                onChanged: (bool value) {
                                  setOutputPower(value);
                                  setState(() {
                                    _outputPowerState = value;
                                  });
                                },
                              ),
                            ),
                          ],
                        )
                      ],
                    ),
                    Stack(children: <Widget>[
                      FlutterMap(
                        options: MapOptions(
                          center: _capsuleLocation,
                          zoom: 13.0,
                        ),
                        layers: [
                          TileLayerOptions(
                            urlTemplate:
                                "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
                            subdomains: ['a', 'b', 'c'],
                            attributionBuilder: (_) {
                              return const Text("© OpenStreetMap contributors");
                            },
                          ),
                          MarkerLayerOptions(
                            markers: [
                              Marker(
                                width: 150.0,
                                height: 150.0,
                                point: _capsuleLocation,
                                rotate: false,
                                builder: (ctx) => const Icon(
                                  Icons.gps_fixed,
                                  color: Colors.lightBlue,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      Align(
                          alignment: Alignment.bottomCenter,
                          child: FloatingActionButton.extended(
                              label:
                                  const Text('Trajet vers Capsule'), // <-- Text
                              backgroundColor: Colors.white,
                              icon: const Icon(
                                Icons.near_me,
                                size: 24.0,
                              ),
                              onPressed: () {
                                MapsLauncher.launchCoordinates(
                                    _capsuleLocation.latitude,
                                    _capsuleLocation.longitude,
                                    'Capsule est ici');
                              })),
                    ]),
                    // align it to the bottom center, you can try different options too (e.g topLeft,centerLeft)
                    Center(
                      child: TweenAnimationBuilder(
                        duration: const Duration(seconds: 1),
                        tween: Tween(
                            begin: (Random().nextDouble() - 0.5) *
                                Random().nextDouble(),
                            end: (Random().nextDouble() - 0.5) *
                                Random().nextDouble()),
                        curve: Curves.linear,
                        builder: (BuildContext context, dynamic value,
                            Widget? child) {
                          return CustomPaint(
                            painter: LevelingBubble(
                                levelingBubbleX: value, levelingBubbleY: value),
                          );
                        },
                      ),
                    ),
                  ],
                )
              : Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      const Text(
                        "Identifiant et mot de passe",
                        style: TextStyle(fontSize: 20),
                      ),
                      Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 16),
                          child: TextFormField(
                            obscureText: false,
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              labelText: 'Utilisateur',
                            ),
                            initialValue: _user,
                            onChanged: (String user) {
                              setState(() {
                                _user = user;
                              });
                              _saveParams();
                            },
                          )),
                      Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 16),
                          child: TextFormField(
                            obscureText: true,
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              labelText: 'Mot de passe',
                            ),
                            initialValue: _pass,
                            onChanged: (String pass) {
                              setState(() {
                                _pass = pass;
                              });
                              _saveParams();
                            },
                          )),
                      FloatingActionButton.extended(
                        label: const Text('Connect'), // <-- Text
                        backgroundColor: Colors.white,
                        icon: const Icon(
                          Icons.cloud_rounded,
                          size: 24.0,
                        ),
                        onPressed: _connect,
                      ),
                    ],
                  ),
                ),
        ));
  }

  _connect() async {
    // Check that the credentials are not empty
    if (_user.isEmpty || _pass.isEmpty) {
      showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Erreur'),
              content: const Text(
                  'Veuillez entrer un identifiant et un mot de passe.'),
              actions: <Widget>[
                TextButton(
                  child: const Text('OK'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
              ],
            );
          });
      return;
    }
    // Check that the MQTT host is reachable locally
    bool mqttAvailable = false;
    await Socket.connect(_localServer, 1883,
            timeout: const Duration(seconds: 5))
        .then((socket) {
      mqttAvailable = true;
      _server = _localServer;
      print("success");
      socket.destroy();
    }).catchError((error) {
      print("Exception on Socket " + error.toString());
    }).showProgressDialog(context,
            message: const Text("Connexion"),
            title: const Text("Tentative de connexion à Capsule en local"),
            dismissable: false,
            blur: 0);

    // If the MQTT host is not reachable locally, try to connect remotely
    if (!mqttAvailable) {
      await Socket.connect(_remoteServer, 1883,
              timeout: const Duration(seconds: 5))
          .then((socket) {
        mqttAvailable = true;
        _server = _remoteServer;
        print("success remotly");
        socket.destroy();
      }).catchError((error) {
        print("Exception on Socket " + error.toString());
      }).showProgressDialog(context,
              message: const Text("Connexion"),
              title: const Text("Tentative de connexion à Capsule en remote"),
              dismissable: false,
              blur: 0);
      if (!mqttAvailable) {
        // Display an error dialog
        showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: const Text('Erreur'),
                content: const Text(
                    'Capsule est injoignable, veuillez vérifier votre connexion au réseau CapsulePrivate et votre VPN.'),
                actions: <Widget>[
                  TextButton(
                    child: const Text('OK'),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  ),
                ],
              );
            });
        return;
      }
    }

    ProgressDialog progressDialog = ProgressDialog(
      context,
      blur: 0,
      dialogTransitionType: DialogTransitionType.Shrink,
      dismissable: true,
      message: const Text("Please Wait, Connecting to Capsule..."),
      title: const Text("Connecting"),
    );
    progressDialog.setLoadingWidget(const CircularProgressIndicator(
      valueColor: AlwaysStoppedAnimation(Colors.white),
    ));
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
    client.server = _server;
    client.keepAlivePeriod = 20;
    client.port = 1883;
    client.secure = false;
    client.onConnected = onConnected;
    client.onDisconnected = onDisconnected;
    client.pongCallback = pong;

    final MqttConnectMessage connMess = MqttConnectMessage()
        .withClientIdentifier(_user)
        .startClean()
        .authenticateAs(_user, _pass);
    client.connectionMessage = connMess;

    await client.connect();
    if (client.connectionStatus!.state == MqttConnectionState.connected) {
      print("Connected to " + client.server + "!");
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Connection impossible"),
          duration: Duration(milliseconds: 800),
        ),
      );
      return false;
    }

    const responseTopic = 'response';
    client.subscribe(responseTopic, MqttQos.atMostOnce);
    const analogTopic = 'router/1114481305/analog';
    client.subscribe(analogTopic, MqttQos.atMostOnce);
    const digital1Topic = 'router/1114481305/digital1'; // Doors
    client.subscribe(digital1Topic, MqttQos.atMostOnce);
    const digital2Topic = 'router/1114481305/digital2';
    client.subscribe(digital2Topic, MqttQos.atMostOnce);
    const din3Topic = 'router/1114481305/pin3';
    client.subscribe(din3Topic, MqttQos.atMostOnce);
    const outPowerTopic = 'router/1114481305/pin4';
    client.subscribe(outPowerTopic, MqttQos.atMostOnce);
    const temperatureTopic = 'router/1114481305/temperature';
    client.subscribe(temperatureTopic, MqttQos.atMostOnce);
    const gpsLatTopic = 'router/gps/lat';
    client.subscribe(gpsLatTopic, MqttQos.atMostOnce);
    const gpsLonTopic = 'router/gps/lon';
    client.subscribe(gpsLonTopic, MqttQos.atMostOnce);
    const notificationTopic = 'notifications/#';
    client.subscribe(notificationTopic, MqttQos.atMostOnce);

    client.updates!.listen((List<MqttReceivedMessage<MqttMessage?>>? c) {
      final recMess = c![0].payload as MqttPublishMessage;
      final pt =
          MqttPublishPayload.bytesToStringAsString(recMess.payload.message);
      switch (c[0].topic) {
        case responseTopic:
          // Split the payload by space
          List<String> response = pt.split(' ');
          // TODO Handle the errors
          switch (response[0]) {
            // Is the new Relay state is received ?
            case '10':
              if (response[1] == "OK") print('Relay state received');
              break;
            // Is the new Output state is received ?
            case '11':
              if (response[1] == "OK") print('Output state received');
              break;
            // Is the new Output power state is received ?
            case '12':
              if (response[1] == "OK") print('Output power state received');
              //setState(() {
              //  _values[0] = int.parse(response[2]) == 1 ? true : false;
              //});
              break;
            case '13':
              if (response[1] == "OK") {
                setState(() {
                  _relayState = int.parse(response[2]) == 1 ? true : false;
                });
              } else {
                // Inverse the state after the request failed
                _relayState = !_relayState;
              }
              break;
            case '14':
              if (response[1] == "OK") {
                setState(() {
                  _outputState = int.parse(response[2]) == 1 ? true : false;
                });
              }
              break;
          }
          break;
        case temperatureTopic:
          setState(() {
            _routerTemperature = double.parse(pt);
          });
          break;
        case analogTopic:
          setState(() {
            _analogInValue = double.parse(pt);
          });
          break;
        case digital1Topic:
          setState(() {
            _digitalInputState = pt == '1' ? true : false;
          });
          break;
        case digital2Topic:
          setState(() {
            _isolatedInputState = pt == '1' ? true : false;
          });
          break;
        case din3Topic:
          setState(() {
            _inputPowerState = pt == '1' ? true : false;
          });
          break;
        case outPowerTopic:
          setState(() {
            _outputPowerState = pt == '1' ? true : false;
          });
          break;
        case gpsLatTopic:
          setState(() {
            _capsuleLocation.latitude = double.parse(pt);
          });
          break;
        case gpsLonTopic:
          setState(() {
            _capsuleLocation.longitude = double.parse(pt);
          });
          break;
        default:
          //print('EXAMPLE::Change notification:: topic is <${c[0].topic}>, payload is <-- $pt -->');
          break;
      }
      if (c[0].topic.contains('notifications')) {
        String title = c[0].topic.substring(c[0].topic.indexOf('/') + 1);
        _notificationService.showNotification(title, pt);
      }
    });

    client.published!.listen((MqttPublishMessage message) {});

    initPeriodicTopics();
    return true;
  }

  void setRelay(bool state) {
    client.publishMessage(
        "request",
        MqttQos.exactlyOnce,
        MqttClientPayloadBuilder()
            .addString("0 10 0 " +
                _server +
                " 502 5 1 6 203 " +
                (state ? 1 : 0).toString())
            .payload!);
  }

  void setOutput1(bool state) {
    client.publishMessage(
        "request",
        MqttQos.exactlyOnce,
        MqttClientPayloadBuilder()
            .addString("0 11 0 " +
                _server +
                " 502 5 1 6 202 " +
                (state ? 1 : 0).toString())
            .payload!);
  }

  void setOutputPower(bool state) {
    client.publishMessage(
        "request",
        MqttQos.exactlyOnce,
        MqttClientPayloadBuilder()
            .addString("0 12 0 " +
                _server +
                " 502 5 1 6 326 " +
                (state ? 1 : 0).toString())
            .payload!);
  }

  void initPeriodicTopics() {
    // Start the async function to retrieve the iostates
    Timer.periodic(const Duration(milliseconds: 1500), (timer) {
      // If the client is not connected anymore, stop the timer
      if (!isConnected) {
        timer.cancel();
        return;
      }
      client.publishMessage("router/get", MqttQos.exactlyOnce,
          MqttClientPayloadBuilder().addString("analog").payload!);
      client.publishMessage("router/get", MqttQos.exactlyOnce,
          MqttClientPayloadBuilder().addString("digital1").payload!);
      client.publishMessage("router/get", MqttQos.exactlyOnce,
          MqttClientPayloadBuilder().addString("digital2").payload!);
      client.publishMessage("router/get", MqttQos.exactlyOnce,
          MqttClientPayloadBuilder().addString("pin3").payload!);
      client.publishMessage("router/get", MqttQos.exactlyOnce,
          MqttClientPayloadBuilder().addString("pin4").payload!);
      client.publishMessage("router/get", MqttQos.exactlyOnce,
          MqttClientPayloadBuilder().addString("uptime").payload!);
      client.publishMessage(
          "request",
          MqttQos.exactlyOnce,
          MqttClientPayloadBuilder()
              .addString("0 13 0 " + _server + " 502 5 1 3 203 1")
              .payload!);
      client.publishMessage(
          "request",
          MqttQos.exactlyOnce,
          MqttClientPayloadBuilder()
              .addString("0 14 0 " + _server + " 502 5 1 3 202 1")
              .payload!);
    });
    Timer.periodic(const Duration(seconds: 2000), (timer) {
      // If the client is not connected anymore, stop the timer
      if (!isConnected) {
        timer.cancel();
        return;
      }
      client.publishMessage("router/get", MqttQos.exactlyOnce,
          MqttClientPayloadBuilder().addString("temperature").payload!);
      client.publishMessage("router/get", MqttQos.exactlyOnce,
          MqttClientPayloadBuilder().addString("operator").payload!);
      client.publishMessage("router/get", MqttQos.exactlyOnce,
          MqttClientPayloadBuilder().addString("signal").payload!);
      client.publishMessage("router/get", MqttQos.exactlyOnce,
          MqttClientPayloadBuilder().addString("network").payload!);
      client.publishMessage("router/get", MqttQos.exactlyOnce,
          MqttClientPayloadBuilder().addString("connection").payload!);
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
              .addString("0 10 0 " + _server + " 502 5 1 3 326 1")
              .payload!);
    });
  }

  void setStatus(String content) {
    setState(() {
      statusText = content;
    });
  }

  void onConnected() {
    setStatus("Client connection was successful");
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Connecté au serveur: " + _server),
        duration: const Duration(milliseconds: 800),
      ),
    );
  }

  void onDisconnected() {
    setStatus("Client Disconnected");
    isConnected = false;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Disconnected"),
        duration: Duration(milliseconds: 800),
      ),
    );
  }

  void pong() {
    print('Ping response client callback invoked');
  }
}
