import 'issue_selection_screen.dart';

class RecommendationArguments {
  final List<IssueItem> selectedIssues;
  final String categoryKey;
  final String paymentMethod;
  final double? customerLatitude;
  final double? customerLongitude;

  RecommendationArguments({
    required this.selectedIssues,
    required this.categoryKey,
    this.paymentMethod = 'Cash',
    this.customerLatitude,
    this.customerLongitude,
  });
}
