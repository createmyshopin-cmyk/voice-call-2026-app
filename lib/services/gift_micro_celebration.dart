import 'package:flutter/services.dart';

import '../config/gift_engagement_config.dart';

class GiftMicroCelebration {
  GiftMicroCelebration._();

  static Future<void> onGiftSent({bool respectMute = true}) async {
    if (!GiftEngagementConfig.enableMicroCelebrations) return;

    await HapticFeedback.lightImpact();

    if (GiftEngagementConfig.enableGiftSound && !respectMute) {
      SystemSound.play(SystemSoundType.click);
    }
  }
}
