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

  Future<MqttServerClient> connect() async {
    client.logging(on: true);
    client.onConnected = () {
      print('Connected');
    };
    client.onDisconnected = () {
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

    client.updates.listen((List<MqttReceivedMessage<MqttMessage>> c) {
      final MqttPublishMessage message = c[0].payload;
      final payload =
          MqttPublishPayload.bytesToStringAsString(message.payload.message);

      print('Received message:$payload from topic: ${c[0].topic}>');
    });

    return client;
  }

  void subscribe() {
    client.subscribe("topic/test", MqttQos.atLeastOnce);
  }

  void publish() {
    const pubTopic = 'topic/test';
    final builder = MqttClientPayloadBuilder();
    builder.addString('Hello MQTT');
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
      body: Center(
        child: Column(
          children: [
            ElevatedButton(
              onPressed: () {
                connect();
              },
              child: Text("Connect"),
            ),
          ],
        ),
      ),
    );
  }
}
