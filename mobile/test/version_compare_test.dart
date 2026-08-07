import 'package:bible_memorization_companion_mobile/core/version_compare.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('compares dotted version strings numerically, not lexically', () {
    expect(VersionCompare.compare('1.9.0', '1.10.0'), lessThan(0));
    expect(VersionCompare.compare('2.0.0', '1.10.0'), greaterThan(0));
    expect(VersionCompare.compare('1.2.3', '1.2.3'), 0);
  });

  test('treats missing segments as zero', () {
    expect(VersionCompare.compare('1.2', '1.2.0'), 0);
    expect(VersionCompare.compare('1.2.1', '1.2'), greaterThan(0));
  });

  test('isAtLeast', () {
    expect(VersionCompare.isAtLeast('1.2.0', '1.2.0'), isTrue);
    expect(VersionCompare.isAtLeast('1.3.0', '1.2.0'), isTrue);
    expect(VersionCompare.isAtLeast('1.1.9', '1.2.0'), isFalse);
  });
}
