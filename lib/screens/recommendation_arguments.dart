import 'issue_selection_screen.dart';

class RecommendationArguments {
  final List<IssueItem> selectedIssues;
  final String categoryKey;

  RecommendationArguments({required this.selectedIssues, required this.categoryKey});
}
