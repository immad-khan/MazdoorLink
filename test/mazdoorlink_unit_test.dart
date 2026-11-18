import 'dart:math';
import 'package:flutter_test/flutter_test.dart';

// ── Pure Logic Classes for Unit Testing (MazdoorLink Core Engines) ──

/// 1. Financial & Commission Engine
class CommissionCalculator {
  static const double platformRate = 0.02; // 2% commission

  static double calculateCommission(double jobPrice) {
    if (jobPrice <= 0) return 0.0;
    return double.parse((jobPrice * platformRate).toStringAsFixed(2));
  }

  static double calculateWorkerEarnings(double jobPrice) {
    final commission = calculateCommission(jobPrice);
    return jobPrice - commission;
  }
}

/// 2. Worker Wallet & Deposit Engine
class WalletManager {
  static const double minimumDepositThreshold = 200.0;

  static Map<String, dynamic> deductCommission({
    required double currentBalance,
    required double commissionAmount,
  }) {
    final newBalance = currentBalance - commissionAmount;
    final status = newBalance < 0
        ? 'Negative'
        : newBalance < minimumDepositThreshold
            ? 'Low Balance'
            : 'Active';

    return {
      'newBalance': double.parse(newBalance.toStringAsFixed(2)),
      'status': status,
      'canAcceptJobs': newBalance >= minimumDepositThreshold,
    };
  }
}

/// 3. Geolocation & Haversine Distance Engine
class LocationCalculator {
  static const double earthRadiusKm = 6371.0;

  static double calculateDistanceKm({
    required double lat1,
    required double lon1,
    required double lat2,
    required double lon2,
  }) {
    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);

    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadians(lat1)) *
            cos(_toRadians(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);

    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return double.parse((earthRadiusKm * c).toStringAsFixed(2));
  }

  static double _toRadians(double degrees) => degrees * (pi / 180.0);

  static List<Map<String, dynamic>> filterNearbyWorkers({
    required double customerLat,
    required double customerLon,
    required double maxRadiusKm,
    required List<Map<String, dynamic>> workers,
  }) {
    return workers.where((worker) {
      final double wLat = worker['latitude'];
      final double wLon = worker['longitude'];
      final distance = calculateDistanceKm(
        lat1: customerLat,
        lon1: customerLon,
        lat2: wLat,
        lon2: wLon,
      );
      return distance <= maxRadiusKm;
    }).toList();
  }
}

/// 4. Job PIN Security Engine
class JobSecurityValidator {
  static bool validatePin({required String enteredPin, required String actualPin}) {
    if (enteredPin.trim().length != 4) return false;
    return enteredPin.trim() == actualPin.trim();
  }
}

/// 5. Dispute & Complaint Classifier
class ComplaintClassifier {
  static String assignPriority({
    required double claimAmount,
    required String category,
  }) {
    if (claimAmount > 0) return 'High';
    if (category == 'worker_issue' || category == 'price_issue') return 'High';
    return 'Medium';
  }
}

/// 6. Worker Rating Aggregator
class RatingCalculator {
  static double computeAverageRating(List<int> ratings) {
    if (ratings.isEmpty) return 0.0;
    final sum = ratings.fold<int>(0, (acc, r) => acc + r);
    final avg = sum / ratings.length;
    return double.parse(avg.toStringAsFixed(2));
  }
}

/// 7. Platform Analytics Date Window Classifier
class AnalyticsPeriodChecker {
  static bool isWithinPeriod(DateTime timestamp, String period, DateTime referenceNow) {
    switch (period) {
      case 'Today':
        return timestamp.year == referenceNow.year &&
            timestamp.month == referenceNow.month &&
            timestamp.day == referenceNow.day;
      case 'This Week':
        final startOfWeek = referenceNow.subtract(Duration(days: referenceNow.weekday - 1));
        final zeroStart = DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);
        return timestamp.isAfter(zeroStart) || timestamp.isAtSameMomentAs(zeroStart);
      case 'This Month':
        return timestamp.year == referenceNow.year && timestamp.month == referenceNow.month;
      case 'All Time':
      default:
        return true;
    }
  }
}

/// 8. Bilingual Translation & Locale Resolver
class BilingualResolver {
  static String resolve(String english, String urdu, {required bool isUrdu}) {
    if (isUrdu && urdu.trim().isNotEmpty) {
      return urdu;
    }
    return english;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// UNIT TEST SUITE EXECUTION
// ─────────────────────────────────────────────────────────────────────────────

void main() {
  group('MazdoorLink Unit Test Suite', () {
    // ── Test 1 ──
    test('1. Commission: 2% deduction calculated accurately on completed job', () {
      const jobPrice = 8000.0;
      final commission = CommissionCalculator.calculateCommission(jobPrice);
      final netWorkerEarnings = CommissionCalculator.calculateWorkerEarnings(jobPrice);

      expect(commission, equals(160.0));
      expect(netWorkerEarnings, equals(7840.0));
      print("  \x1B[32m✔ PASS\x1B[0m: 1. Commission: 2% deduction calculated accurately on completed job");
    });

    // ── Test 2 ──
    test('2. Wallet: Worker balance correctly updated after commission deduction', () {
      final result = WalletManager.deductCommission(
        currentBalance: 1000.0,
        commissionAmount: 160.0,
      );

      expect(result['newBalance'], equals(840.0));
      expect(result['status'], equals('Active'));
      expect(result['canAcceptJobs'], isTrue);
      print("  \x1B[32m✔ PASS\x1B[0m: 2. Wallet: Worker balance correctly updated after commission deduction");
    });

    // ── Test 3 ──
    test('3. Security Deposit: Low balance detected when funds drop below Rs 200 threshold', () {
      final lowBalanceResult = WalletManager.deductCommission(
        currentBalance: 250.0,
        commissionAmount: 100.0, // Remaining: 150 < 200 threshold
      );

      expect(lowBalanceResult['newBalance'], equals(150.0));
      expect(lowBalanceResult['status'], equals('Low Balance'));
      expect(lowBalanceResult['canAcceptJobs'], isFalse);
      print("  \x1B[32m✔ PASS\x1B[0m: 3. Security Deposit: Low balance detected when funds drop below Rs 200 threshold");
    });

    // ── Test 4 ──
    test('4. Location: Haversine formula correctly computes distance between coordinates', () {
      // Point A: DHA Phase 2 Islamabad (33.5255, 73.1534)
      // Point B: Blue Area Islamabad (33.7128, 73.0673)
      final distance = LocationCalculator.calculateDistanceKm(
        lat1: 33.5255,
        lon1: 73.1534,
        lat2: 33.7128,
        lon2: 73.0673,
      );

      // Distance should be approximately 22.2 km (+/- 1 km)
      expect(distance, inInclusiveRange(21.0, 23.5));
      print("  \x1B[32m✔ PASS\x1B[0m: 4. Location: Haversine formula correctly computes distance between coordinates");
    });

    // ── Test 5 ──
    test('5. Job Dispatch: Workers outside service radius are filtered out', () {
      const customerLat = 33.5255;
      const customerLon = 73.1534;
      const maxRadiusKm = 10.0;

      final candidateWorkers = [
        {'id': 'worker_nearby', 'latitude': 33.5400, 'longitude': 73.1600}, // ~1.7 km (Within)
        {'id': 'worker_far', 'latitude': 33.7200, 'longitude': 73.0600},    // ~23 km (Outside)
      ];

      final filtered = LocationCalculator.filterNearbyWorkers(
        customerLat: customerLat,
        customerLon: customerLon,
        maxRadiusKm: maxRadiusKm,
        workers: candidateWorkers,
      );

      expect(filtered.length, equals(1));
      expect(filtered.first['id'], equals('worker_nearby'));
      print("  \x1B[32m✔ PASS\x1B[0m: 5. Job Dispatch: Workers outside service radius are filtered out");
    });

    // ── Test 6 ──
    test('6. Security PIN: 4-digit verification PIN validates correctly upon arrival', () {
      const validPin = '4829';

      expect(JobSecurityValidator.validatePin(enteredPin: '4829', actualPin: validPin), isTrue);
      expect(JobSecurityValidator.validatePin(enteredPin: '1234', actualPin: validPin), isFalse);
      expect(JobSecurityValidator.validatePin(enteredPin: '482', actualPin: validPin), isFalse);
      print("  \x1B[32m✔ PASS\x1B[0m: 6. Security PIN: 4-digit verification PIN validates correctly upon arrival");
    });

    // ── Test 7 ──
    test('7. Complaints: High priority assigned to disputed payments with claim amount', () {
      final highPriority = ComplaintClassifier.assignPriority(
        claimAmount: 1500.0,
        category: 'price_issue',
      );
      final mediumPriority = ComplaintClassifier.assignPriority(
        claimAmount: 0.0,
        category: 'schedule_change',
      );

      expect(highPriority, equals('High'));
      expect(mediumPriority, equals('Medium'));
      print("  \x1B[32m✔ PASS\x1B[0m: 7. Complaints: High priority assigned to disputed payments with claim amount");
    });

    // ── Test 8 ──
    test('8. Ratings: Worker star rating average calculated accurately', () {
      final ratings = [5, 4, 5, 3, 5]; // Sum: 22, Count: 5 -> 4.40
      final average = RatingCalculator.computeAverageRating(ratings);

      expect(average, equals(4.40));
      print("  \x1B[32m✔ PASS\x1B[0m: 8. Ratings: Worker star rating average calculated accurately");
    });

    // ── Test 9 ──
    test('9. Analytics: In-memory period filter correctly includes Today and excludes old orders', () {
      final now = DateTime(2026, 11, 18, 14, 30);
      final todayJob = DateTime(2026, 11, 18, 10, 00);
      final lastMonthJob = DateTime(2026, 10, 5, 12, 00);

      expect(AnalyticsPeriodChecker.isWithinPeriod(todayJob, 'Today', now), isTrue);
      expect(AnalyticsPeriodChecker.isWithinPeriod(todayJob, 'This Month', now), isTrue);
      expect(AnalyticsPeriodChecker.isWithinPeriod(lastMonthJob, 'Today', now), isFalse);
      expect(AnalyticsPeriodChecker.isWithinPeriod(lastMonthJob, 'All Time', now), isTrue);
      print("  \x1B[32m✔ PASS\x1B[0m: 9. Analytics: In-memory period filter correctly includes Today and excludes old orders");
    });

    // ── Test 10 ──
    test('10. Localization: Bilingual resolver returns Urdu when locale is Urdu', () {
      final urduOutput = BilingualResolver.resolve('Electrician', 'الیکٹریشن', isUrdu: true);
      final englishOutput = BilingualResolver.resolve('Electrician', 'الیکٹریشن', isUrdu: false);

      expect(urduOutput, equals('الیکٹریشن'));
      expect(englishOutput, equals('Electrician'));
      print("  \x1B[32m✔ PASS\x1B[0m: 10. Localization: Bilingual resolver returns Urdu when locale is Urdu");
    });
  });
}
