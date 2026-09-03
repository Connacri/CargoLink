import 'package:flutter_test/flutter_test.dart';

import 'package:cargolink/data/models/referral_models.dart';

void main() {
  group('ReferralTier', () {
    test('fromValue maps known values', () {
      expect(ReferralTier.fromValue('bronze'), ReferralTier.bronze);
      expect(ReferralTier.fromValue('argent'), ReferralTier.argent);
      expect(ReferralTier.fromValue('or'), ReferralTier.or);
      expect(ReferralTier.fromValue('platine'), ReferralTier.platine);
    });

    test('fromValue unknown defaults to bronze', () {
      expect(ReferralTier.fromValue(null), ReferralTier.bronze);
      expect(ReferralTier.fromValue('xxx'), ReferralTier.bronze);
    });

    test('next chains correctly and ends at platine', () {
      expect(ReferralTier.bronze.next, ReferralTier.argent);
      expect(ReferralTier.argent.next, ReferralTier.or);
      expect(ReferralTier.or.next, ReferralTier.platine);
      expect(ReferralTier.platine.next, isNull);
    });

    test('thresholds are correct', () {
      expect(ReferralTier.bronze.minQualified, 0);
      expect(ReferralTier.argent.minQualified, 3);
      expect(ReferralTier.or.minQualified, 10);
      expect(ReferralTier.platine.minQualified, 25);
    });
  });

  group('ReferralStats tier progression', () {
    ReferralStats stats({required ReferralTier tier, required int qualified}) {
      return ReferralStats(
        code: 'ABC12345',
        filleulsCount: qualified,
        qualifiedFilleuls: qualified,
        totalPaid: 0,
        totalPending: 0,
        tier: tier,
      );
    }

    test('bronze with 1 qualified needs 2 more for argent', () {
      final s = stats(tier: ReferralTier.bronze, qualified: 1);
      expect(s.hasNextTier, isTrue);
      expect(s.nextTierProgress, 2);
      expect(s.nextTierFraction, 1 / 3);
      expect(s.rewardPerQualified, 50);
    });

    test('bronze with 3 qualified reaches argent transition fraction 1.0', () {
      final s = stats(tier: ReferralTier.bronze, qualified: 3);
      expect(s.nextTierFraction, 1.0);
      expect(s.nextTierProgress, 0);
    });

    test('platine has no next tier and fraction 1.0', () {
      final s = stats(tier: ReferralTier.platine, qualified: 30);
      expect(s.hasNextTier, isFalse);
      expect(s.nextTierFraction, 1.0);
      expect(s.rewardPerQualified, 150);
    });

    test('argent reward is 75 per qualified', () {
      final s = stats(tier: ReferralTier.argent, qualified: 5);
      expect(s.rewardPerQualified, 75);
    });
  });
}
