/// Local avatar asset paths (also stored in `users.avatar_url` after onboarding).
class AvatarAssets {
  static const String defaultAvatar = 'assets/avatars/default.png';
  static const String male = 'assets/avatars/male.png';
  static const String female = 'assets/avatars/female.png';

  static String assetPathForGender(String? gender) {
    switch (gender) {
      case 'male':
        return male;
      case 'female':
        return female;
      default:
        return defaultAvatar;
    }
  }
}
