/// A/B-ready toggles for gift engagement features.
/// Wire to remote config later — do not hardcode behavior in widgets.
class GiftEngagementConfig {
  GiftEngagementConfig._();

  static bool enableGiftCombo = true;
  static bool enableGiftStreak = true;
  static bool enableMilestones = true;
  static bool enableEmotionalRecharge = true;
  static bool enablePremiumAnimations = true;
  static bool enableMicroCelebrations = true;
  static bool enableCreatorInsights = true;

  /// Haptic + optional sound on send (sound off by default).
  static bool enableGiftSound = false;

  static int comboWindowSeconds = 10;
  static int comboAnimationMs = 3000;
  static int milestoneCelebrationMs = 2000;
  static int premiumAnimationMs = 3000;
  static int maxSimultaneousEffects = 5;

  /// Gifts at or above this coin cost use premium moment animation.
  static int premiumCoinThreshold = 500;

  static const giftMilestones = [1, 5, 10, 25, 50, 100];

  static void applyRemoteFlags(Map<String, dynamic>? flags) {
    if (flags == null) return;
    enableGiftCombo = flags['giftCombo'] as bool? ?? enableGiftCombo;
    enableGiftStreak = flags['giftStreak'] as bool? ?? enableGiftStreak;
    enableMilestones = flags['giftMilestones'] as bool? ?? enableMilestones;
    enableEmotionalRecharge =
        flags['emotionalRecharge'] as bool? ?? enableEmotionalRecharge;
    enablePremiumAnimations =
        flags['premiumAnimations'] as bool? ?? enablePremiumAnimations;
    enableMicroCelebrations =
        flags['microCelebrations'] as bool? ?? enableMicroCelebrations;
    enableCreatorInsights =
        flags['creatorInsights'] as bool? ?? enableCreatorInsights;
    enableGiftSound = flags['giftSound'] as bool? ?? enableGiftSound;
  }
}
