import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart Ordering',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(title: 'Smart Ordering'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  MqttServerClient client = MqttServerClient.withPort(
    '202.148.1.57',
    'flutter_client',
    1883,
  );

  String status = "Not Connected";
  List orders = [];

  Future<MqttServerClient> connect() async {
    client.logging(on: true);
    client.onConnected = () {
      setState(() {
        status = "Connected";
      });
      print('Connected');
    };
    client.onDisconnected = () {
      setState(() {
        status = "Disconnected";
      });
      print('Disconnected');
    };
    client.onUnsubscribed = (String topic) {
      print('Unsubscribed topic: $topic');
    };
    client.onSubscribed = (String topic) {
      print('Subscribed topic: $topic');
    };
    client.onSubscribeFail = (String topic) {
      print('Failed to subscribe $topic');
    };
    client.pongCallback = () {
      print('Ping response client callback invoked');
    };

    final connMessage = MqttConnectMessage().authenticateAs(
      'app-smartorderingsystem',
      'G4zwVj1B1qmTDR2V0oY7y2YVqUUe6o',
    );
    // .keepAliveFor(60)
    // .withWillTopic('willtopic')
    // .withWillMessage('Will message')
    // .startClean()
    // .withWillQos(MqttQos.atLeastOnce);
    client.connectionMessage = connMessage;
    try {
      await client.connect();
    } catch (e) {
      print('Exception: $e');
      client.disconnect();
    }

    subscribe();

    client.updates.listen((List<MqttReceivedMessage<MqttMessage>> c) {
      final MqttPublishMessage message = c[0].payload;
      final payload =
          MqttPublishPayload.bytesToStringAsString(message.payload.message);

      var decodedPayload = json.decode(payload);

      setState(() {
        orders.add(decodedPayload["payload"]["menu"]);
      });
      print('Received message:$payload from topic: ${c[0].topic}');
    });

    return client;
  }

  void subscribe() {
    client.subscribe("01ESP32Subscribe", MqttQos.atLeastOnce);
  }

  void publish() {
    const pubTopic = '01ESP32Publish';
    final builder = MqttClientPayloadBuilder();
    builder.addString(json.encode({
      "payload": {"status": "OK"}
    }));
    client.publishMessage(pubTopic, MqttQos.atLeastOnce, builder.payload);
  }

  void unsubscribe() {
    client.unsubscribe('topic/test');
  }

  void disconnect() {
    client.disconnect();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Container(
        padding: EdgeInsets.all(25.0),
        child: ListView(
          children: [
            ElevatedButton(
              onPressed: () {
                connect();
              },
              child: Text("Connect"),
            ),
            SizedBox(height: 20),
            Text("Status : $status"),
            SizedBox(height: 20),
            Text("Daftar Pesanan: ", style: TextStyle(fontSize: 22.5)),
            orders.length == 0
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: 15),
                      Text("Anda belum memiliki pesanan"),
                    ],
                  )
                : Container(),
            ListView.builder(
              shrinkWrap: true,
              itemCount: orders.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text('Nama Pesanan: ${orders[index]}'),
                  subtitle: Text('tap untuk mengonfirmasi'),
                  onTap: () {
                    publish();
                    setState(() {
                      orders.removeAt(index);
                    });
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
