import 'package:flutter/services.dart';

class Helpers {
  Helpers._();

  static Future<void> triggerHapticLight() async {
    await HapticFeedback.lightImpact();
  }

  static Future<void> triggerHapticMedium() async {
    await HapticFeedback.mediumImpact();
  }

  static Future<void> triggerHapticSuccess() async {
    await HapticFeedback.vibrate();
    await Future.delayed(const Duration(milliseconds: 100));
    await HapticFeedback.vibrate();
  }

  static Future<void> triggerHapticError() async {
    await HapticFeedback.heavyImpact();
    await Future.delayed(const Duration(milliseconds: 150));
    await HapticFeedback.heavyImpact();
  }

  // Generates a mockable static Google Maps URL for Hargeisa, Somaliland
  static String getStaticMapUrl(double latitude, double longitude, {int zoom = 15, String apiKey = ''}) {
    if (apiKey.isEmpty) {
      // Return a simulated image source or blank to indicate we will use a fallback widget
      return '';
    }
    return 'https://maps.googleapis.com/maps/api/staticmap?center=$latitude,$longitude&zoom=$zoom&size=600x300&markers=color:red%7C$latitude,$longitude&key=$apiKey';
  }

  // Generates a cache-busted URL for network images (like avatars) to resolve local caching issues.
  // Appends the last updated timestamp as a query parameter.
  static String getCacheBustedUrl(String? url, DateTime? updatedAt) {
    if (url == null || url.isEmpty) return '';
    final timestamp = updatedAt?.millisecondsSinceEpoch ?? DateTime.now().millisecondsSinceEpoch;
    final separator = url.contains('?') ? '&' : '?';
    return '$url${separator}t=$timestamp';
  }
}
