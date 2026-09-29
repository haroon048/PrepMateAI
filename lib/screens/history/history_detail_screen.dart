
import 'package:flutter/material.dart';

import '../../constants/app_colors.dart';
import '../../constants/app_typography.dart';

class HistoryDetailScreen extends StatelessWidget {
  const HistoryDetailScreen({
    super.key,
    required this.session,
    required this.title,
  });

  final Map<String, dynamic> session;
  final String title;

  @override
  Widget build(BuildContext context) {
    final feedback = List<Map<String, dynamic>>.from(
      (session['questionFeedbacks'] as List? ?? []).map(
        (item) => Map<String, dynamic>.from(item as Map),
      ),
    );

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text('Question feedback', style: AppTypography.displayHeading),
          const SizedBox(height: 6),
          Text(
            session['overallFeedback'] as String? ?? '',
            style: AppTypography.subHeading,
          ),
          const SizedBox(height: 20),
          if (feedback.isEmpty)
            const Text('Detailed feedback was not saved for this session.')
          else
            ...feedback.asMap().entries.map(
              (entry) => Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ExpansionTile(
                  title: Text('Question ${entry.key + 1}'),
                  subtitle: Text(
                    '${(entry.value['score'] as num? ?? 0).toInt()}/10 score',
                    style: const TextStyle(color: AppColors.primary),
                  ),
                  childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  children: [
                    _DetailText('Question', entry.value['question'] as String? ?? ''),
                    _DetailText('Your answer', entry.value['userAnswer'] as String? ?? ''),
                    _DetailText('AI feedback', entry.value['feedback'] as String? ?? ''),
                    _DetailText('Suggested answer', entry.value['sampleAnswer'] as String? ?? ''),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _DetailText extends StatelessWidget {
  const _DetailText(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTypography.caption),
          const SizedBox(height: 3),
          Text(value.isEmpty ? 'Not available' : value),
        ],
      ),
    );
  }
}
