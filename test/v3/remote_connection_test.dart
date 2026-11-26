import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:xplayer/providers/remote_provider.dart';
import 'package:xplayer/services/remote/remote_protocol.dart';

void main() {
  test('握手后才连接成功；发送实际消息，断连后停止发送', () async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final accepted = Completer<WebSocket>();
    final received = Completer<List<Map<String, dynamic>>>();
    final messages = <Map<String, dynamic>>[];
    final subscription = server.listen((request) async {
      final socket = await WebSocketTransformer.upgrade(request);
      accepted.complete(socket);
      socket.listen((value) {
        messages.add(jsonDecode(value as String) as Map<String, dynamic>);
        if (messages.length == 2) received.complete(messages);
      });
    });
    final remote = RemoteProvider();
    addTearDown(() async {
      await remote.disconnect();
      remote.dispose();
      await subscription.cancel();
      await server.close(force: true);
    });
    expect(await remote.sendKey('up'), isFalse);
    final connecting = remote.connect(
      RemoteDeviceInfo(
        id: 'test',
        name: '测试电视',
        host: '127.0.0.1',
        port: server.port,
      ),
    );
    expect(remote.isConnected, isFalse);
    await connecting;
    expect(remote.isConnected, isTrue);
    expect(remote.isConnecting, isFalse);
    expect(await remote.sendKey('up'), isTrue);
    expect(await remote.sendText('节目单地址'), isTrue);
    final content = await received.future.timeout(const Duration(seconds: 3));
    expect(content[0]['payload'], {'key': 'up'});
    expect(content[1]['payload'], {'text': '节目单地址'});
    final lost = Completer<void>();
    remote.addListener(() {
      if (!remote.isConnected && !lost.isCompleted) lost.complete();
    });
    await (await accepted.future).close();
    await lost.future.timeout(const Duration(seconds: 3));
    expect(remote.current, isNull);
    expect(await remote.sendKey('enter'), isFalse);
  });
  test('握手失败不留下虚假连接状态', () async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final subscription = server.listen((request) {
      request.response.statusCode = 404;
      request.response.close();
    });
    final remote = RemoteProvider();
    addTearDown(() async {
      remote.dispose();
      await subscription.cancel();
      await server.close(force: true);
    });
    await remote.connect(
      RemoteDeviceInfo(
        id: 'bad',
        name: '错误设备',
        host: '127.0.0.1',
        port: server.port,
      ),
    );
    expect(remote.isConnected, isFalse);
    expect(remote.isConnecting, isFalse);
    expect(remote.connectionError, isNotNull);
  });
}
