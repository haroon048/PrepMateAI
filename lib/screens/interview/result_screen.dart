import 'package:flutter/material.dart';

import '../../constants/app_colors.dart';
import '../../constants/app_typography.dart';
import '../../models/evaluation_model.dart';
import '../../services/firestore_service.dart';
import '../../utils/app_page_route.dart';
import '../../widgets/custom_button.dart';
import '../main_shell_screen.dart';
import 'setup_interview_screen.dart';

class ResultScreen extends StatefulWidget {
  const ResultScreen({
    super.key,
    required this.evaluation,
    required this.role,
    required this.experienceLevel,
  });

  final EvaluationResultModel evaluation;
  final String role;
  final String experienceLevel;

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  bool _isSaved = false;

  @override
  void initState() {
    super.initState();
    _saveResult();
  }

  Future<void> _saveResult() async {
    try {
      await FirestoreService().saveInterview(
        role: widget.role,
        experienceLevel: widget.experienceLevel,
        evaluation: widget.evaluation,
      );
      if (mounted) setState(() => _isSaved = true);
    } catch (_) {
      // A history write must not prevent the user from seeing feedback.
    }
  }

  Color get _scoreColor {
    if (widget.evaluation.overallScore >= 75) return AppColors.success;
    if (widget.evaluation.overallScore >= 50) return AppColors.warning;
    return AppColors.error;
  }

  @override
  Widget build(BuildContext context) {
    final evaluation = widget.evaluation;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Feedback'),
        automaticallyImplyLeading: false,
        actions: [
          if (_isSaved)
            const Padding(
              padding: EdgeInsets.only(right: 16),
              child: Icon(Icons.cloud_done_outlined, color: AppColors.primary),
            ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primary, AppColors.primaryDark],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                children: [
                  Text(
                    widget.role,
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                  const SizedBox(height: 12),
                  TweenAnimationBuilder<int>(
                    tween: IntTween(begin: 0, end: evaluation.overallScore),
                    duration: const Duration(milliseconds: 850),
                    curve: Curves.easeOutCubic,
                    builder: (context, score, _) => Text(
                      '$score%',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 52,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const Text(
                    'Overall interview score',
                    style: TextStyle(color: Colors.white70),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    evaluation.overallFeedback,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white, height: 1.4),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            _InsightSection(
              title: 'What you did well',
              icon: Icons.check_circle_outline,
              color: AppColors.success,
              items: evaluation.strengths,
              emptyMessage: 'No strengths were returned for this session.',
            ),
            const SizedBox(height: 20),
            _InsightSection(
              title: 'Focus for next time',
              icon: Icons.tips_and_updates_outlined,
              color: AppColors.secondary,
              items: evaluation.areasToImprove,
              emptyMessage: 'No improvement areas were returned for this session.',
            ),
            const SizedBox(height: 24),
            Text('Question-by-question feedback', style: AppTypography.sectionHeading),
            const SizedBox(height: 10),
            if (evaluation.questionFeedbacks.isEmpty)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('Detailed question feedback was not returned.'),
                ),
              )
            else
              ...evaluation.questionFeedbacks.asMap().entries.map(
                (entry) => _FeedbackTile(
                  number: entry.key + 1,
                  feedback: entry.value,
                  scoreColor: _scoreColor,
                ),
              ),
            const SizedBox(height: 20),
            CustomButton(
              text: 'Practice Again',
              icon: Icons.refresh_rounded,
              onPressed: () => Navigator.pushReplacement(
                context,
                AppPageRoute(builder: (_) => const SetupInterviewScreen()),
              ),
            ),
            const SizedBox(height: 12),
            CustomButton(
              text: 'Back to Dashboard',
              isOutlined: true,
              icon: Icons.home_outlined,
              onPressed: () => Navigator.of(context).pushAndRemoveUntil(
                AppPageRoute(builder: (_) => const MainShellScreen()),
                (route) => false,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InsightSection extends StatelessWidget {
  const _InsightSection({
    required this.title,
    required this.icon,
    required this.color,
    required this.items,
    required this.emptyMessage,
  });

  final String title;
  final IconData icon;
  final Color color;
  final List<String> items;
  final String emptyMessage;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: AppTypography.sectionHeading),
        const SizedBox(height: 8),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: items.isEmpty
                ? Text(emptyMessage, style: AppTypography.caption)
                : Column(
                    children: items
                        .map(
                          (item) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(icon, color: color, size: 20),
                                const SizedBox(width: 10),
                                Expanded(child: Text(item)),
                              ],
                            ),
                          ),
                        )
                        .toList(),
                  ),
          ),
        ),
      ],
    );
  }
}

class _FeedbackTile extends StatelessWidget {
  const _FeedbackTile({
    required this.number,
    required this.feedback,
    required this.scoreColor,
  });

  final int number;
  final FeedbackItem feedback;
  final Color scoreColor;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ExpansionTile(
        title: Text('Question $number'),
        subtitle: Text(
          '${feedback.score}/10 score',
          style: TextStyle(color: scoreColor, fontWeight: FontWeight.w600),
        ),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: [
          _FeedbackText('Question', feedback.question),
          _FeedbackText('Your answer', feedback.userAnswer),
          _FeedbackText('AI feedback', feedback.feedback),
          _FeedbackText('Suggested answer', feedback.sampleAnswer),
        ],
      ),
    );
  }
}

class _FeedbackText extends StatelessWidget {
  const _FeedbackText(this.label, this.value);

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
