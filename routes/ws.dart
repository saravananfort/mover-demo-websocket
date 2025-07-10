import 'dart:async';
import 'dart:convert';
import 'package:dart_frog/dart_frog.dart';
import 'package:dart_frog_web_socket/dart_frog_web_socket.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

final List<WebSocketChannel> clients = [];
Timer? _timer;
int _index = 0;

final List<Map<String, double>> latLngList = [
  {'lat': 22.57732, 'lng': 88.43431},
  {'lat': 22.57728, 'lng': 88.43421},
  {'lat': 22.57729, 'lng': 88.43416},
  {'lat': 22.57742, 'lng': 88.43389},
  {'lat': 22.57725, 'lng': 88.43379},
  {'lat': 22.57679, 'lng': 88.4348},
  {'lat': 22.57636, 'lng': 88.43569},
  {'lat': 22.57588, 'lng': 88.43678},
  {'lat': 22.57581, 'lng': 88.43674},
  {'lat': 22.57597, 'lng': 88.43639},
  {'lat': 22.57615, 'lng': 88.436},
  {'lat': 22.5763, 'lng': 88.43566},
  {'lat': 22.57706, 'lng': 88.43401},
  {'lat': 22.57736, 'lng': 88.43335},
  {'lat': 22.5765, 'lng': 88.43291},
  {'lat': 22.57557, 'lng': 88.43243},
];

FutureOr<Response> onRequest(RequestContext context) {
  return webSocketHandler((WebSocketChannel channel, String? protocol) {
    clients.add(channel);
    print('Client connected');

    // Start timer only once when first client connects
    _timer ??= Timer.periodic(const Duration(seconds: 50), (timer) {
        if (clients.isEmpty) {
          return;
        }

        final current = latLngList[_index % latLngList.length];
        print("_index: $_index, latLngList.length: ${latLngList.length},  _index % latLngList.length: ${_index % latLngList.length} ");
        _index++;

        final now = DateTime.now().toUtc();
        final serverTime = now.toIso8601String();
        final deviceTime =
            now.subtract(const Duration(seconds: 180)).toIso8601String();

        final payload = {
          'positions': [
            {
              'id': 34300138,
              'attributes': {
                'batteryLevel': 100.0,
                'distance': 3.84,
                'totalDistance': 807229.88,
                'motion': false,
              },
              'deviceId': 516189,
              'type': null,
              'protocol': 'osmand',
              'serverTime': serverTime,
              'deviceTime': deviceTime,
              'fixTime': deviceTime,
              'outdated': false,
              'valid': true,
              'latitude': current['lat'],
              'longitude': current['lng'],
              'altitude': -30.8,
              'speed': 0.0,
              'course': 0.0,
              'address': null,
              'accuracy': 41.32,
              'network': null,
            }
          ],
        };

        final jsonString = jsonEncode(payload);
        for (final client in clients) {
          client.sink.add(jsonString);
        }
        print('Broadcast sent to ${clients.length} clients');
      });

    channel.stream.listen(
      (message) {
        print('Received from client: $message');
      },
      onDone: () {
        clients.remove(channel);
        print('Client disconnected');
        if (clients.isEmpty) {
          _timer?.cancel();
          _timer = null;
          print('Timer stopped, no clients connected');
        }
      },
    );
  })(context);
}
