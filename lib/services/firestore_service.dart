
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/evaluation_model.dart';

class FirestoreService {
  FirestoreService({FirebaseFirestore? firestore, FirebaseAuth? auth})
      : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  Future<void> saveInterview({
    required String role,
    required String experienceLevel,
    required EvaluationResultModel evaluation,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return;

    await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('interviews')
        .add({
          'role': role,
          'experienceLevel': experienceLevel,
          'overallScore': evaluation.overallScore,
          'overallFeedback': evaluation.overallFeedback,
          'strengths': evaluation.strengths,
          'areasToImprove': evaluation.areasToImprove,
          'questionFeedbacks': evaluation.questionFeedbacks
              .map(
                (item) => {
                  'questionId': item.questionId,
                  'question': item.question,
                  'userAnswer': item.userAnswer,
                  'score': item.score,
                  'feedback': item.feedback,
                  'sampleAnswer': item.sampleAnswer,
                },
              )
              .toList(),
          'completedAt': FieldValue.serverTimestamp(),
        });
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> watchInterviews() {
    final user = _auth.currentUser;
    if (user == null) return const Stream.empty();

    return _firestore
        .collection('users')
        .doc(user.uid)
        .collection('interviews')
        .orderBy('completedAt', descending: true)
        .snapshots();
  }
}
