import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

import '../../core/platform/alert_sounds.dart';

/// Plays alerts with one reused player instead of one per bloc.
class AudioAlertSounds implements AlertSounds {
  final _player = AudioPlayer()..setReleaseMode(ReleaseMode.stop);

  @override
  Future<void> play(AlertSound sound) async {
    try {
      await _player.stop();
      await _player.play(AssetSource('sounds/${sound.file}'));
    } catch (e) {
      // A missing audio device must never block a sale.
      debugPrint('Alert sound failed: $e');
    }
  }
}
