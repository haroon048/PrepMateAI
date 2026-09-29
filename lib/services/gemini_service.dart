import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/evaluation_model.dart';
import '../models/interview_model.dart';

class GeminiService {
  const GeminiService();

  static const String _apiKey = String.fromEnvironment('GEMINI_API_KEY');

  // Prefer current text models, while discovering the models actually enabled
  // for the configured API key before making a generation request.
  static const List<String> _preferredModels = [
    'gemini-3.5-flash-lite',
    'gemini-3.8-flash',
    'gemini-2.5-flash',
    'gemini-2.5-flash-lite',
  ];

  Future<List<QuestionModel>> generateQuestions({
    required String role,
    required String experienceLevel,
    required int count,
  }) async {
    final prompt =
        '''
You are an expert technical interviewer. Generate exactly $count mock interview questions for a "$role" position at "$experienceLevel" level.

Return only a JSON array. Each item must contain:
- "id": integer starting at 1
- "question": string
- "category": string, such as "Technical", "Behavioral", or "Problem Solving"
''';

    return _sendRequest(
      prompt: prompt,
      parser: (rawText) {
        final decoded = jsonDecode(rawText);
        if (decoded is! List) {
          throw const FormatException('Gemini did not return a JSON array.');
        }
        return decoded
            .map(
              (item) => QuestionModel.fromJson(
                Map<String, dynamic>.from(item as Map),
              ),
            )
            .toList();
      },
    );
  }

  Future<EvaluationResultModel> evaluateInterview({
    required String role,
    required String experienceLevel,
    required List<QuestionModel> questions,
    required Map<int, String> userAnswers,
  }) async {
    final qaPairs = <Map<String, dynamic>>[
      for (var index = 0; index < questions.length; index++)
        {
          'questionId': questions[index].id,
          'question': questions[index].question,
          'userAnswer': userAnswers[index] ?? 'No answer provided.',
        },
    ];

    final prompt =
        '''
You are an expert technical interviewer evaluating a mock interview for a "$role" position at "$experienceLevel" level.

Questions and candidate answers:
${jsonEncode(qaPairs)}

Return only a JSON object with this exact shape:
{
  "overallScore": 85,
  "overallFeedback": "Overall assessment",
  "strengths": ["Strength"],
  "areasToImprove": ["Improvement"],
  "questionFeedbacks": [
    {
      "questionId": 1,
      "question": "Question text",
      "userAnswer": "Candidate answer",
      "score": 8,
      "feedback": "Feedback",
      "sampleAnswer": "Ideal answer"
    }
  ]
}
''';

    return _sendRequest(
      prompt: prompt,
      parser: (rawText) {
        final decoded = jsonDecode(rawText);
        if (decoded is! Map) {
          throw const FormatException('Gemini did not return a JSON object.');
        }
        return EvaluationResultModel.fromJson(
          Map<String, dynamic>.from(decoded),
        );
      },
    );
  }

  Future<T> _sendRequest<T>({
    required String prompt,
    required T Function(String rawText) parser,
  }) async {
    _ensureApiKey();
    final models = await _availableTextModels();
    String? lastUnavailableModel;

    for (final model in models) {
      for (var attempt = 1; attempt <= 3; attempt++) {
        try {
          final response = await http
              .post(
                Uri.https(
                  'generativelanguage.googleapis.com',
                  '/v1beta/models/$model:generateContent',
                  {'key': _apiKey},
                ),
                headers: const {'Content-Type': 'application/json'},
                body: jsonEncode({
                  'contents': [
                    {
                      'parts': [
                        {'text': prompt},
                      ],
                    },
                  ],
                  'generationConfig': {'responseMimeType': 'application/json'},
                }),
              )
              .timeout(const Duration(seconds: 45));

          if (response.statusCode == 200) {
            return parser(_responseText(response.body));
          }

          if (response.statusCode == 404) {
            lastUnavailableModel = model;
            break;
          }

          if ((response.statusCode == 429 || response.statusCode == 503) &&
              attempt < 3) {
            await Future<void>.delayed(Duration(seconds: attempt * 2));
            continue;
          }

          throw StateError(_apiErrorMessage(response.statusCode));
        } on TimeoutException {
          if (attempt == 3) {
            lastUnavailableModel = '$model timed out';
          } else {
            await Future<void>.delayed(Duration(seconds: attempt * 2));
          }
        }
      }
    }

    throw StateError(
      lastUnavailableModel == null
          ? 'Gemini could not generate a response. Please try again.'
          : 'No available Gemini model could complete this request. Please try again later.',
    );
  }

  Future<List<String>> _availableTextModels() async {
    final response = await http
        .get(
          Uri.https('generativelanguage.googleapis.com', '/v1beta/models', {
            'key': _apiKey,
            'pageSize': '100',
          }),
        )
        .timeout(const Duration(seconds: 30));

    if (response.statusCode != 200) {
      throw StateError(_apiErrorMessage(response.statusCode));
    }

    final decoded = jsonDecode(response.body);
    final rawModels = decoded is Map ? decoded['models'] : null;
    if (rawModels is! List) {
      throw const FormatException('Gemini returned an invalid model list.');
    }

    final available = <String>[];
    for (final rawModel in rawModels) {
      if (rawModel is! Map) continue;
      final name = rawModel['name'];
      final methods = rawModel['supportedGenerationMethods'];
      if (name is! String ||
          methods is! List ||
          !methods.contains('generateContent')) {
        continue;
      }

      final model = name.replaceFirst(RegExp(r'^models/'), '');
      final isTextModel =
          model.startsWith('gemini-') &&
          !model.contains('-image') &&
          !model.contains('-tts') &&
          !model.contains('-live');
      if (isTextModel) available.add(model);
    }

    final ordered = <String>[
      ..._preferredModels.where(available.contains),
      ...available.where((model) => !_preferredModels.contains(model)),
    ];
    if (ordered.isEmpty) {
      throw StateError(
        'No text Gemini model is enabled for this API key. Check the API key project and its quota.',
      );
    }
    return ordered;
  }

  String _responseText(String responseBody) {
    final decoded = jsonDecode(responseBody);
    final candidates = decoded is Map ? decoded['candidates'] : null;
    if (candidates is! List || candidates.isEmpty) {
      throw const FormatException('Gemini returned an empty response.');
    }

    final candidate = candidates.first;
    final content = candidate is Map ? candidate['content'] : null;
    final parts = content is Map ? content['parts'] : null;
    final firstPart = parts is List && parts.isNotEmpty ? parts.first : null;
    final text = firstPart is Map ? firstPart['text'] : null;
    if (text is! String || text.trim().isEmpty) {
      throw const FormatException('Gemini returned no text response.');
    }

    return text
        .trim()
        .replaceFirst(RegExp(r'^```(?:json)?\s*'), '')
        .replaceFirst(RegExp(r'\s*```$'), '')
        .trim();
  }

  void _ensureApiKey() {
    if (_apiKey.isEmpty) {
      throw StateError(
        'Gemini API key is missing. Run Flutter with '
        '--dart-define-from-file=gemini.env.json.',
      );
    }
  }

  String _apiErrorMessage(int statusCode) {
    switch (statusCode) {
      case 400:
        return 'Gemini rejected the request. Please try again.';
      case 401:
      case 403:
        return 'Gemini API key is invalid, restricted, or has no project access.';
      case 429:
        return 'Gemini request limit reached. Please wait and try again.';
      case 503:
        return 'Gemini is temporarily busy. Please try again shortly.';
      default:
        return 'Gemini request failed (HTTP $statusCode). Please try again.';
    }
  }
}
