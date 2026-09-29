import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../constants/app_colors.dart';
import '../../models/evaluation_model.dart';
import '../../models/interview_model.dart';
import '../../services/gemini_service.dart';
import 'result_screen.dart';

class ActiveInterviewScreen extends StatefulWidget {
  final String role;
  final String experienceLevel;
  final List<QuestionModel> questions;

  const ActiveInterviewScreen({
    super.key,
    required this.role,
    required this.experienceLevel,
    required this.questions,
  });

  @override
  State<ActiveInterviewScreen> createState() => _ActiveInterviewScreenState();
}

class _ActiveInterviewScreenState extends State<ActiveInterviewScreen> {
  int _currentIndex = 0;
  final Map<int, String> _userAnswers = {};
  final TextEditingController _answerController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadCurrentAnswer();
  }

  void _loadCurrentAnswer() {
    _answerController.text = _userAnswers[_currentIndex] ?? '';
  }

  void _saveCurrentAnswer() {
    _userAnswers[_currentIndex] = _answerController.text.trim();
  }

  void _nextQuestion() {
    _saveCurrentAnswer();
    if (_currentIndex < widget.questions.length - 1) {
      setState(() {
        _currentIndex++;
        _loadCurrentAnswer();
      });
    }
  }

  void _previousQuestion() {
    _saveCurrentAnswer();
    if (_currentIndex > 0) {
      setState(() {
        _currentIndex--;
        _loadCurrentAnswer();
      });
    }
  }

  Future<void> _finishInterview() async {
    _saveCurrentAnswer();

    // Check if at least one question is answered
    bool hasAnswer = _userAnswers.values.any((ans) => ans.isNotEmpty);
    if (!hasAnswer) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please answer at least one question before submitting.',
          ),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Show Loading Dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Analyzing responses & saving results...'),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      final geminiService = GeminiService();
      final evaluation = await geminiService.evaluateInterview(
        role: widget.role,
        experienceLevel: widget.experienceLevel,
        questions: widget.questions,
        userAnswers: _userAnswers,
      );

      // Save to Firestore
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('interviews')
            .add({
              'role': widget.role,
              'experienceLevel': widget.experienceLevel,
              'overallScore': evaluation.overallScore,
              'overallFeedback': evaluation.overallFeedback,
              'createdAt': FieldValue.serverTimestamp(),
            });
      }

      if (!mounted) return;
      Navigator.pop(context); // Close loading dialog

      // Navigate to Result Screen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => ResultScreen(
            evaluation: evaluation,
            role: widget.role,
            experienceLevel: '',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // Close dialog on error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Evaluation Error: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  void dispose() {
    _answerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentQuestion = widget.questions[_currentIndex];
    final isLastQuestion = _currentIndex == widget.questions.length - 1;

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.role} Interview'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Progress Indicator
            LinearProgressIndicator(
              value: (_currentIndex + 1) / widget.questions.length,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
            const SizedBox(height: 16),

            // Header Info
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Question ${_currentIndex + 1} of ${widget.questions.length}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Chip(
                  label: Text(
                    currentQuestion.category,
                    style: const TextStyle(fontSize: 12),
                  ),
                  backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Question Card
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  currentQuestion.question,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Answer Input Box
            Expanded(
              child: TextField(
                controller: _answerController,
                maxLines: null,
                expands: true,
                textAlignVertical: TextAlignVertical.top,
                decoration: InputDecoration(
                  hintText: 'Type your answer here in detail...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppColors.primary, width: 2),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Bottom Navigation Buttons
            Row(
              children: [
                if (_currentIndex > 0)
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _previousQuestion,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text('Previous'),
                    ),
                  ),
                if (_currentIndex > 0) const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: isLastQuestion
                        ? _finishInterview
                        : _nextQuestion,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: Text(
                      isLastQuestion ? 'Submit Interview' : 'Next Question',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
