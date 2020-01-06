import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_txplayer/ftxplayer.dart';


void main() {
  const MethodChannel channel = MethodChannel('flutter_txplayer');

  setUp(() {
    channel.setMockMethodCallHandler((MethodCall methodCall) async {
      return '42';
    });
  });

  tearDown(() {
    channel.setMockMethodCallHandler(null);
  });

  test('getPlatformVersion', () async {
    expect(await FTXPlayerPlugin.sdkVersion, '42');
  });
}
