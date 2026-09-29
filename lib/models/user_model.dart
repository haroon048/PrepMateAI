class UserModel {
  final String uid;
  final String email;
  final String displayName;
  final String? photoUrl;
  final DateTime? createdAt;

  UserModel({
    required this.uid,
    required this.email,
    required this.displayName,
    this.photoUrl,
    this.createdAt,
  });

  // Map se UserModel banane ke liye (Firestore data conversion)
  factory UserModel.fromMap(Map<String, dynamic> map, String documentId) {
    return UserModel(
      uid: documentId,
      email: map['email'] ?? '',
      displayName: map['name'] ?? map['displayName'] ?? 'User',
      photoUrl: map['photoUrl'],
      createdAt: map['createdAt'] != null
          ? (map['createdAt'] as dynamic).toDate()
          : null,
    );
  }

  // UserModel ko Map mein convert karne ke liye
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'name': displayName,
      'photoUrl': photoUrl,
      'createdAt': createdAt,
    };
  }
}
