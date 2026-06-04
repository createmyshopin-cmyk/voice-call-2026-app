import 'package:flutter/foundation.dart' show debugPrint, kIsWeb;
import 'package:flutter_ringtone_player/flutter_ringtone_player.dart';

/// Plays a looping incoming-call ringtone (system ringtone on Android/iOS).
class IncomingCallRingtone {
  IncomingCallRingtone._();

  static final FlutterRingtonePlayer _player = FlutterRingtonePlayer();
  static int _playCount = 0;

  static Future<void> start() async {
    if (kIsWeb) return;
    _playCount++;
    if (_playCount > 1) return;

    try {
      // asAlarm: true can crash some emulators; standard ringtone loop is enough.
      await _player.playRingtone(
        looping: true,
        volume: 1.0,
        asAlarm: false,
      );
    } catch (e) {
      debugPrint('IncomingCallRingtone.start: $e');
      _playCount = 0;
    }
  }

  static Future<void> stop() async {
    if (kIsWeb) return;
    if (_playCount <= 0) return;
    _playCount = 0;

    try {
      await _player.stop();
    } catch (e) {
      debugPrint('IncomingCallRingtone.stop: $e');
    }
  }
}
