class QuestionModel {
  final int questionNumber;
  final String questionText;
  final String contextOrHint;

  QuestionModel({
    required this.questionNumber,
    required this.questionText,
    this.contextOrHint = '',
  });

  Map<String, dynamic> toMap() {
    return {
      'questionNumber': questionNumber,
      'questionText': questionText,
      'contextOrHint': contextOrHint,
    };
  }

  factory QuestionModel.fromMap(Map<String, dynamic> map) {
    return QuestionModel(
      questionNumber: map['questionNumber'] ?? 1,
      questionText: map['questionText'] ?? '',
      contextOrHint: map['contextOrHint'] ?? '',
    );
  }
}
