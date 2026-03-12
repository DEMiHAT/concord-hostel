import 'dart:math';

/// QR Generation Service for CONCORD Gate Pass System.
///
/// Handles:
/// - Structured QR payload encoding/decoding
/// - Time-based rotating tokens for anti-screenshot protection
/// - Pass data validation on scan
class QrGenerationService {
  static const String _prefix = 'CONCORD';
  static const String _version = 'V2';
  static const int _tokenRotationSeconds = 30;

  /// Generate the QR data string for a given pass.
  ///
  /// Format: `CONCORD:V2:passId:studentId:state:timestamp:token`
  /// The token rotates every [_tokenRotationSeconds] seconds.
  static String generateQrData({
    required String passId,
    required String studentId,
    required String stateValue,
  }) {
    final now = DateTime.now();
    final epoch = now.millisecondsSinceEpoch;
    final token = _generateRotatingToken(passId, studentId, epoch);

    return [
      _prefix,
      _version,
      passId,
      studentId,
      stateValue,
      epoch.toString(),
      token,
    ].join(':');
  }

  /// Parse and validate a QR data string.
  /// Returns a [QrScanResult] with the parsed data or an error.
  static QrScanResult parseQrData(String rawData) {
    try {
      final parts = rawData.split(':');

      // V1 legacy format: HAILMARY:passId:studentId:state
      if (parts.length == 4 && parts[0] == 'HAILMARY') {
        return QrScanResult(
          isValid: true,
          passId: parts[1],
          studentId: parts[2],
          stateValue: parts[3],
          isLegacy: true,
        );
      }

      // V2 format: CONCORD:V2:passId:studentId:state:timestamp:token
      if (parts.length < 7 || parts[0] != _prefix || parts[1] != _version) {
        return QrScanResult(
          isValid: false,
          error: 'Invalid QR format',
        );
      }

      final passId = parts[2];
      final studentId = parts[3];
      final stateValue = parts[4];
      final timestamp = int.tryParse(parts[5]) ?? 0;
      final token = parts[6];

      // Validate token freshness (allow 2 rotation windows of slack)
      final now = DateTime.now().millisecondsSinceEpoch;
      final age = (now - timestamp).abs();
      final maxAge = _tokenRotationSeconds * 2 * 1000; // 2 windows in ms

      if (age > maxAge) {
        return QrScanResult(
          isValid: false,
          passId: passId,
          studentId: studentId,
          stateValue: stateValue,
          error: 'QR code has expired — student must refresh their pass',
          isExpiredToken: true,
        );
      }

      // Validate token
      final expectedToken = _generateRotatingToken(passId, studentId, timestamp);
      if (token != expectedToken) {
        return QrScanResult(
          isValid: false,
          passId: passId,
          studentId: studentId,
          error: 'Invalid QR token — possible screenshot or tampered code',
        );
      }

      return QrScanResult(
        isValid: true,
        passId: passId,
        studentId: studentId,
        stateValue: stateValue,
        generatedAt: DateTime.fromMillisecondsSinceEpoch(timestamp),
      );
    } catch (e) {
      return QrScanResult(
        isValid: false,
        error: 'Failed to parse QR data: $e',
      );
    }
  }

  /// Generate a rotating token based on pass data and current time window.
  static String _generateRotatingToken(
      String passId, String studentId, int epochMs) {
    // Floor to the nearest rotation window
    final window = epochMs ~/ (_tokenRotationSeconds * 1000);
    final payload = '$passId|$studentId|$window|CONCORD_SECRET';

    // Simple hash — in production, use HMAC-SHA256
    var hash = 0;
    for (var i = 0; i < payload.length; i++) {
      hash = ((hash << 5) - hash + payload.codeUnitAt(i)) & 0xFFFFFFFF;
    }

    // Convert to base36 for compact representation
    return hash.toRadixString(36).padLeft(8, '0').substring(0, 8);
  }

  /// Get the number of seconds until the current QR token expires.
  static int secondsUntilTokenExpiry() {
    final now = DateTime.now().millisecondsSinceEpoch;
    final windowMs = _tokenRotationSeconds * 1000;
    final elapsed = now % windowMs;
    return ((windowMs - elapsed) / 1000).ceil();
  }

  /// Generate a unique pass ID.
  static String generatePassId() {
    final now = DateTime.now();
    final random = Random();
    final suffix = random.nextInt(9999).toString().padLeft(4, '0');
    return 'QP${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}_$suffix';
  }

  /// Generate a compact verification code for display (human-readable).
  /// This is shown alongside the QR for manual verification by security.
  static String generateVerificationCode(String passId, String studentId) {
    final payload = '$passId|$studentId|VERIFY';
    var hash = 0;
    for (var i = 0; i < payload.length; i++) {
      hash = ((hash << 5) - hash + payload.codeUnitAt(i)) & 0xFFFFFFFF;
    }
    // Create a 6-char alphanumeric code
    return hash.toRadixString(36).toUpperCase().padLeft(6, '0').substring(0, 6);
  }
}

/// Result of parsing a QR code scan.
class QrScanResult {
  final bool isValid;
  final String? passId;
  final String? studentId;
  final String? stateValue;
  final String? error;
  final bool isLegacy;
  final bool isExpiredToken;
  final DateTime? generatedAt;

  QrScanResult({
    required this.isValid,
    this.passId,
    this.studentId,
    this.stateValue,
    this.error,
    this.isLegacy = false,
    this.isExpiredToken = false,
    this.generatedAt,
  });
}
