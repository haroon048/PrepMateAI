import 'package:flutter/material.dart';

import '../../constants/app_colors.dart';
import '../../constants/app_typography.dart';
import '../../services/gemini_service.dart';
import '../../utils/app_page_route.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import 'active_interview_screen.dart';

class SetupInterviewScreen extends StatefulWidget {
  const SetupInterviewScreen({super.key, this.initialRole});

  final String? initialRole;

  @override
  State<SetupInterviewScreen> createState() => _SetupInterviewScreenState();
}

class _SetupInterviewScreenState extends State<SetupInterviewScreen> {
  final _formKey = GlobalKey<FormState>();
  final _roleController = TextEditingController();

  bool _isLoading = false;
  String _experienceLevel = 'Mid-Level';
  int _questionCount = 5;

  final List<String> _levels = [
    'Junior / Entry Level',
    'Mid-Level',
    'Senior Level',
    'Lead / Management',
  ];
  final List<int> _counts = [3, 5, 10];

  @override
  void dispose() {
    _roleController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _roleController.text = widget.initialRole ?? '';
  }

  Future<void> _startInterview() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final geminiService = GeminiService();
      final questions = await geminiService.generateQuestions(
        role: _roleController.text.trim(),
        experienceLevel: _experienceLevel,
        count: _questionCount,
      );

      if (questions.isNotEmpty && mounted) {
        Navigator.pushReplacement(
          context,
          AppPageRoute(
            builder: (_) => ActiveInterviewScreen(
              questions: questions,
              role: _roleController.text.trim(),
              experienceLevel: _experienceLevel,
            ),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Setup Mock Interview')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Customize Your Session',
                  style: AppTypography.displayHeading,
                ),
                const SizedBox(height: 6),
                Text(
                  'Specify the role and difficulty level to generate targeted AI interview questions.',
                  style: AppTypography.subHeading,
                ),
                const SizedBox(height: 28),

                // Job Role Field
                CustomTextField(
                  label: 'Target Job Role / Title',
                  hint: 'e.g. Flutter Developer, Data Analyst',
                  controller: _roleController,
                  prefixIcon: Icons.work_outline,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a job role';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // Experience Level Dropdown
                const Text(
                  'Experience Level',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: _experienceLevel,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(
                      Icons.bar_chart_outlined,
                      color: AppColors.primary,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                  ),
                  items: _levels.map((level) {
                    return DropdownMenuItem(value: level, child: Text(level));
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _experienceLevel = value;
                      });
                    }
                  },
                ),
                const SizedBox(height: 20),

                // Number of Questions Selection
                const Text(
                  'Number of Questions',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
                const SizedBox(height: 10),
                Row(
                  children: _counts.map((count) {
                    final isSelected = _questionCount == count;
                    return Expanded(
                      child: Container(
                        margin: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Center(child: Text('$count Questions')),
                          selected: isSelected,
                          selectedColor: AppColors.primary,
                          labelStyle: TextStyle(
                            color: isSelected ? Colors.white : Colors.black87,
                            fontWeight: FontWeight.w600,
                          ),
                          onSelected: (selected) {
                            if (selected) {
                              setState(() {
                                _questionCount = count;
                              });
                            }
                          },
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 36),

                // Generate Button
                CustomButton(
                  text: 'Generate AI Questions',
                  isLoading: _isLoading,
                  onPressed: _startInterview,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
