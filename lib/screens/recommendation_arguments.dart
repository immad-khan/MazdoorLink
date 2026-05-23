import 'package:service_frontend/app_theme.dart';
import '../app_state.dart';
import 'issue_selection_screen.dart';
import '../data/mock_data.dart';
import 'package:flutter/material.dart';

class RecommendationArguments {
  final List<IssueItem> selectedIssues;
  final String categoryKey;

  RecommendationArguments({required this.selectedIssues, required this.categoryKey});
}
