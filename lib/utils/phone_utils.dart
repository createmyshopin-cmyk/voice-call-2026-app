/// Normalizes user input to E.164 (default country: India +91).
String toE164Phone(String input, {String defaultCountryCode = '91'}) {
  final digits = input.replaceAll(RegExp(r'\D'), '');
  if (digits.isEmpty) {
    throw FormatException('Phone number is required');
  }
  if (digits.startsWith(defaultCountryCode) && digits.length >= 12) {
    return '+$digits';
  }
  if (digits.length == 10) {
    return '+$defaultCountryCode$digits';
  }
  if (input.trim().startsWith('+')) {
    return '+${digits}';
  }
  throw FormatException('Enter a valid 10-digit mobile number');
}

String formatPhoneForDisplay(String e164) {
  final digits = e164.replaceAll(RegExp(r'\D'), '');
  if (digits.length >= 12 && digits.startsWith('91')) {
    final local = digits.substring(2);
    return '+91 $local';
  }
  return e164;
}
