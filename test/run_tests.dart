import 'dart:math';

// Re-using the test engines
class CommissionCalculator {
  static const double platformRate = 0.02;
  static double calculateCommission(double jobPrice) =>
      jobPrice <= 0 ? 0.0 : double.parse((jobPrice * platformRate).toStringAsFixed(2));
  static double calculateWorkerEarnings(double jobPrice) =>
      jobPrice - calculateCommission(jobPrice);
}

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

class LocationCalculator {
  static const double earthRadiusKm = 6371.0;
  static double calculateDistanceKm({
    required double lat1,
    required double lon1,
    required double lat2,
    required double lon2,
  }) {
    final dLat = (lat2 - lat1) * (pi / 180.0);
    final dLon = (lon2 - lon1) * (pi / 180.0);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1 * (pi / 180.0)) * cos(lat2 * (pi / 180.0)) * sin(dLon / 2) * sin(dLon / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return double.parse((earthRadiusKm * c).toStringAsFixed(2));
  }
}

class JobSecurityValidator {
  static bool validatePin({required String enteredPin, required String actualPin}) =>
      enteredPin.trim().length == 4 && enteredPin.trim() == actualPin.trim();
}

class ComplaintClassifier {
  static String assignPriority({required double claimAmount, required String category}) {
    if (claimAmount > 0 || category == 'price_issue' || category == 'worker_issue') return 'High';
    return 'Medium';
  }
}

class RatingCalculator {
  static double computeAverageRating(List<int> ratings) {
    if (ratings.isEmpty) return 0.0;
    return double.parse((ratings.reduce((a, b) => a + b) / ratings.length).toStringAsFixed(2));
  }
}

class AnalyticsPeriodChecker {
  static bool isWithinPeriod(DateTime timestamp, String period, DateTime referenceNow) {
    switch (period) {
      case 'Today':
        return timestamp.year == referenceNow.year &&
            timestamp.month == referenceNow.month &&
            timestamp.day == referenceNow.day;
      case 'This Month':
        return timestamp.year == referenceNow.year && timestamp.month == referenceNow.month;
      case 'All Time':
      default:
        return true;
    }
  }
}

class BilingualResolver {
  static String resolve(String english, String urdu, {required bool isUrdu}) =>
      (isUrdu && urdu.trim().isNotEmpty) ? urdu : english;
}

void main() {
  final stopwatch = Stopwatch()..start();

  final tests = [
    {
      'name': 'commission: 2% platform fee calculated accurately on completed job',
      'fn': () => CommissionCalculator.calculateCommission(8000.0) == 160.0 &&
          CommissionCalculator.calculateWorkerEarnings(8000.0) == 7840.0,
    },
    {
      'name': 'wallet: worker balance deducted and status set to Active',
      'fn': () {
        final res = WalletManager.deductCommission(currentBalance: 1000.0, commissionAmount: 160.0);
        return res['newBalance'] == 840.0 && res['status'] == 'Active' && res['canAcceptJobs'] == true;
      },
    },
    {
      'name': 'deposit: low balance flag triggered when wallet drops below Rs 200',
      'fn': () {
        final res = WalletManager.deductCommission(currentBalance: 250.0, commissionAmount: 100.0);
        return res['newBalance'] == 150.0 && res['status'] == 'Low Balance' && res['canAcceptJobs'] == false;
      },
    },
    {
      'name': 'location: Haversine distance calculated accurately (~22km between coordinates)',
      'fn': () {
        final d = LocationCalculator.calculateDistanceKm(lat1: 33.5255, lon1: 73.1534, lat2: 33.7128, lon2: 73.0673);
        return d >= 21.0 && d <= 23.5;
      },
    },
    {
      'name': 'security pin: 4-digit arrival verification code validates correctly',
      'fn': () => JobSecurityValidator.validatePin(enteredPin: '4829', actualPin: '4829') == true &&
          JobSecurityValidator.validatePin(enteredPin: '9999', actualPin: '4829') == false,
    },
    {
      'name': 'complaints: high priority assigned to financial disputes and damage claims',
      'fn': () => ComplaintClassifier.assignPriority(claimAmount: 1500.0, category: 'price_issue') == 'High' &&
          ComplaintClassifier.assignPriority(claimAmount: 0.0, category: 'personal_reason') == 'Medium',
    },
    {
      'name': 'ratings: worker star rating average aggregated correctly (4.40 stars)',
      'fn': () => RatingCalculator.computeAverageRating([5, 4, 5, 3, 5]) == 4.40,
    },
    {
      'name': 'analytics: date filter correctly validates Today vs previous months',
      'fn': () {
        final now = DateTime(2026, 11, 18, 14, 30);
        final today = DateTime(2026, 11, 18, 10, 00);
        final old = DateTime(2026, 10, 5, 12, 00);
        return AnalyticsPeriodChecker.isWithinPeriod(today, 'Today', now) == true &&
            AnalyticsPeriodChecker.isWithinPeriod(old, 'Today', now) == false;
      },
    },
    {
      'name': 'localization: bilingual resolver dynamically displays Urdu when active',
      'fn': () => BilingualResolver.resolve('Electrician', 'الیکٹریشن', isUrdu: true) == 'الیکٹریشن' &&
          BilingualResolver.resolve('Electrician', 'الیکٹریشن', isUrdu: false) == 'Electrician',
    },
  ];

  int passed = 0;
  int failed = 0;

  print('');
  print('================ MazdoorLink Test Runner ================');
  for (int i = 0; i < tests.length; i++) {
    final t = tests[i];
    final testSw = Stopwatch()..start();
    final bool ok = (t['fn'] as bool Function())();
    testSw.stop();
    final ms = (testSw.elapsedMicroseconds / 1000).toStringAsFixed(2);

    if (ok) {
      passed++;
      print('  \x1B[32m✔\x1B[0m ${t['name']} (${ms}ms)');
    } else {
      failed++;
      print('  \x1B[31m✖\x1B[0m ${t['name']} (${ms}ms)');
    }
  }

  stopwatch.stop();
  final totalMs = (stopwatch.elapsedMicroseconds / 1000).toStringAsFixed(2);

  print('');
  print('  \x1B[36mi\x1B[0m tests ${tests.length}');
  print('  \x1B[36mi\x1B[0m suites 1');
  print('  \x1B[32mi pass $passed\x1B[0m');
  print('  \x1B[36mi\x1B[0m fail $failed');
  print('  \x1B[36mi\x1B[0m cancelled 0');
  print('  \x1B[36mi\x1B[0m skipped 0');
  print('  \x1B[36mi\x1B[0m todo 0');
  print('  \x1B[36mi\x1B[0m duration_ms $totalMs');
  print('=========================================================');
  print('');
}
