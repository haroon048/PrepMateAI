class EvaluationModel {
  final int score; // 0 to 100
  final String strengths;
  final String improvements;
  final String idealAnswer;

  EvaluationModel({
    required this.score,
    required this.strengths,
    required this.improvements,
    required this.idealAnswer,
  });

  Map<String, dynamic> toMap() {
    return {
      'score': score,
      'strengths': strengths,
      'improvements': improvements,
      'idealAnswer': idealAnswer,
    };
  }

  factory EvaluationModel.fromMap(Map<String, dynamic> map) {
    return EvaluationModel(
      score: map['score'] ?? 0,
      strengths: map['strengths'] ?? '',
      improvements: map['improvements'] ?? '',
      idealAnswer: map['idealAnswer'] ?? '',
    );
  }
}

class FeedbackItem {
  final int questionId;
  final String question;
  final String userAnswer;
  final int score; // 1 to 10
  final String feedback;
  final String sampleAnswer;

  FeedbackItem({
    required this.questionId,
    required this.question,
    required this.userAnswer,
    required this.score,
    required this.feedback,
    required this.sampleAnswer,
  });

  factory FeedbackItem.fromJson(Map<String, dynamic> json) {
    return FeedbackItem(
      questionId: json['questionId'] ?? 1,
      question: json['question'] ?? '',
      userAnswer: json['userAnswer'] ?? '',
      score: json['score'] ?? 0,
      feedback: json['feedback'] ?? '',
      sampleAnswer: json['sampleAnswer'] ?? '',
    );
  }
}

class EvaluationResultModel {
  final int overallScore; // percentage 0-100
  final String overallFeedback;
  final List<String> strengths;
  final List<String> areasToImprove;
  final List<FeedbackItem> questionFeedbacks;

  EvaluationResultModel({
    required this.overallScore,
    required this.overallFeedback,
    required this.strengths,
    required this.areasToImprove,
    required this.questionFeedbacks,
  });

  factory EvaluationResultModel.fromJson(Map<String, dynamic> json) {
    return EvaluationResultModel(
      overallScore: json['overallScore'] ?? 0,
      overallFeedback: json['overallFeedback'] ?? '',
      strengths: List<String>.from(json['strengths'] ?? []),
      areasToImprove: List<String>.from(json['areasToImprove'] ?? []),
      questionFeedbacks: (json['questionFeedbacks'] as List? ?? [])
          .map((e) => FeedbackItem.fromJson(e))
          .toList(),
    );
  }
}
