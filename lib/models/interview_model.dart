class QuestionModel {
  final int id;
  final String question;
  final String category; // e.g. Technical, Behavioral, Situational

  QuestionModel({
    required this.id,
    required this.question,
    required this.category,
  });

  factory QuestionModel.fromJson(Map<String, dynamic> json) {
    return QuestionModel(
      id: json['id'] ?? 1,
      question: json['question'] ?? '',
      category: json['category'] ?? 'General',
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'question': question, 'category': category};
  }
}
