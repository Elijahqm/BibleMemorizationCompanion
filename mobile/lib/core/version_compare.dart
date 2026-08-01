/// Compares dotted version strings (`"1.2.3"`), the format used by both
/// `AppConfig.appVersion` and the catalog's `minAppVersion`/`version` fields.
///
/// Missing or non-numeric segments are treated as `0`, so `"1.2"` and
/// `"1.2.0"` compare equal.
class VersionCompare {
  const VersionCompare._();

  static List<int> _segments(String version) =>
      version.split('.').map((part) => int.tryParse(part) ?? 0).toList();

  /// -1 if [a] < [b], 0 if equal, 1 if [a] > [b].
  static int compare(String a, String b) {
    final segmentsA = _segments(a);
    final segmentsB = _segments(b);
    final length = segmentsA.length > segmentsB.length
        ? segmentsA.length
        : segmentsB.length;

    for (var i = 0; i < length; i++) {
      final valueA = i < segmentsA.length ? segmentsA[i] : 0;
      final valueB = i < segmentsB.length ? segmentsB[i] : 0;
      if (valueA != valueB) return valueA.compareTo(valueB);
    }
    return 0;
  }

  static bool isAtLeast(String version, String minVersion) =>
      compare(version, minVersion) >= 0;
}
