/// Postal code utilities for travel time estimation.
///
/// Korean postal codes are 5 digits. The first 3 digits identify the region:
/// - Same first 3 digits → same district (~15min)
/// - Adjacent codes (within ±5) → neighboring district (~30min)
/// - Distant codes → far away (~45min+)

/// Estimate travel time between two postal codes.
///
/// Returns suggested travel time in minutes, or null if estimation is not possible.
int? estimateTravelTime(String? fromPostalCode, String? toPostalCode) {
  if (fromPostalCode == null || toPostalCode == null) return null;

  final from = _parsePrefix(fromPostalCode);
  final to = _parsePrefix(toPostalCode);
  if (from == null || to == null) return null;

  final diff = (from - to).abs();

  if (diff == 0) return 15; // Same district
  if (diff <= 5) return 30; // Adjacent district
  if (diff <= 15) return 45; // Nearby region
  return 60; // Far away
}

/// Get a human-readable description of the travel estimate.
///
/// Example: "이동시간 제안: 약 20분 (강남구 → 서초구)"
String? travelTimeDescription({
  required String? fromPostalCode,
  required String? toPostalCode,
  String? fromDistrict,
  String? toDistrict,
}) {
  final minutes = estimateTravelTime(fromPostalCode, toPostalCode);
  if (minutes == null) return null;

  final fromLabel = fromDistrict ?? _postalPrefix(fromPostalCode);
  final toLabel = toDistrict ?? _postalPrefix(toPostalCode);

  if (fromLabel != null && toLabel != null) {
    return '이동시간 제안: 약 $minutes분 ($fromLabel → $toLabel)';
  }
  return '이동시간 제안: 약 $minutes분';
}

/// Check if a postal code is in valid Korean 5-digit format.
bool isValidPostalCode(String? code) {
  if (code == null) return false;
  final cleaned = code.replaceAll('-', '').trim();
  return RegExp(r'^\d{5}$').hasMatch(cleaned);
}

/// Extract district name from an address string.
///
/// Expects format like "서울시 강남구 ..." → returns "강남구"
String? extractDistrict(String? address) {
  if (address == null || address.isEmpty) return null;

  final guMatch = RegExp(r'(\S+[구군시])').firstMatch(address);
  if (guMatch != null) return guMatch.group(1);
  return null;
}

int? _parsePrefix(String? code) {
  if (code == null) return null;
  final cleaned = code.replaceAll('-', '').trim();
  if (cleaned.length < 3) return null;
  return int.tryParse(cleaned.substring(0, 3));
}

String? _postalPrefix(String? code) {
  if (code == null) return null;
  final cleaned = code.replaceAll('-', '').trim();
  if (cleaned.length >= 3) return cleaned.substring(0, 3);
  return null;
}
