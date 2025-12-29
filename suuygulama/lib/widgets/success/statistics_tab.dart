import 'package:flutter/material.dart';
import '../../screens/history_screen.dart';

/// Statistics tab content for SuccessScreen.
/// This is essentially a wrapper around HistoryScreen with the insight button.
class StatisticsTab extends StatelessWidget {
  final Widget? lightbulbButton;

  const StatisticsTab({
    super.key,
    this.lightbulbButton,
  });

  @override
  Widget build(BuildContext context) {
    return HistoryScreen(
      hideAppBar: true,
      lightbulbButton: lightbulbButton,
    );
  }
}

