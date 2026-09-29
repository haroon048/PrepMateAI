import 'evaluation_model.dart';
import 'question_model.dart';

class QAPair {
  final QuestionModel question;
  final String userAnswer;
  final EvaluationModel evaluation;

  QAPair({
    required this.question,
    required this.userAnswer,
    required this.evaluation,
  });

  Map<String, dynamic> toMap() {
    return {
      'question': question.toMap(),
      'userAnswer': userAnswer,
      'evaluation': evaluation.toMap(),
    };
  }

  factory QAPair.fromMap(Map<String, dynamic> map) {
    return QAPair(
      question: QuestionModel.fromMap(
        Map<String, dynamic>.from(map['question'] ?? {}),
      ),
      userAnswer: map['userAnswer'] ?? '',
      evaluation: EvaluationModel.fromMap(
        Map<String, dynamic>.from(map['evaluation'] ?? {}),
      ),
    );
  }
}

class InterviewSessionModel {
  final String interviewId;
  final String userId;
  final String category;
  final String difficulty;
  final int totalQuestions;
  final double overallScore;
  final DateTime completedAt;
  final List<QAPair> qaPairs;

  InterviewSessionModel({
    required this.interviewId,
    required this.userId,
    required this.category,
    required this.difficulty,
    required this.totalQuestions,
    required this.overallScore,
    required this.completedAt,
    required this.qaPairs,
  });

  Map<String, dynamic> toMap() {
    return {
      'interviewId': interviewId,
      'userId': userId,
      'category': category,
      'difficulty': difficulty,
      'totalQuestions': totalQuestions,
      'overallScore': overallScore,
      'completedAt': completedAt.toIso8601String(),
      'qaPairs': qaPairs.map((pair) => pair.toMap()).toList(),
    };
  }

  factory InterviewSessionModel.fromMap(Map<String, dynamic> map) {
    return InterviewSessionModel(
      interviewId: map['interviewId'] ?? '',
      userId: map['userId'] ?? '',
      category: map['category'] ?? '',
      difficulty: map['difficulty'] ?? '',
      totalQuestions: map['totalQuestions'] ?? 0,
      overallScore: (map['overallScore'] ?? 0.0).toDouble(),
      completedAt: map['completedAt'] != null
          ? DateTime.parse(map['completedAt'])
          : DateTime.now(),
      qaPairs:
          (map['qaPairs'] as List<dynamic>?)
              ?.map((item) => QAPair.fromMap(Map<String, dynamic>.from(item)))
              .toList() ??
          [],
    );
  }
}
