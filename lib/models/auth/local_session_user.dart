import 'package:firebase_auth/firebase_auth.dart' as auth;

class LocalSessionUser {
  const LocalSessionUser({
    required this.id,
    required this.email,
    required this.displayName,
    required this.photoUrl,
    required this.isAnonymous,
  });

  final String id;
  final String email;
  final String displayName;
  final String photoUrl;
  final bool isAnonymous;

  String get uid => id;
  bool get isGuest => isAnonymous;

  String? get photoURL => photoUrl.isEmpty ? null : photoUrl;

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'displayName': displayName,
        'photoUrl': photoUrl,
        'isAnonymous': isAnonymous,
      };

  factory LocalSessionUser.fromJson(Map<String, dynamic> json) {
    return LocalSessionUser(
      id: json['id']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      displayName: json['displayName']?.toString() ?? '',
      photoUrl: json['photoUrl']?.toString() ?? '',
      isAnonymous: json['isAnonymous'] == true,
    );
  }

  factory LocalSessionUser.fromFirebaseUser(auth.User user) {
    return LocalSessionUser(
      id: user.uid,
      email: user.email ?? '',
      displayName: user.displayName?.trim().isNotEmpty == true
          ? user.displayName!.trim()
          : (user.email?.split('@').first.trim().isNotEmpty == true
              ? user.email!.split('@').first.trim()
              : (user.isAnonymous ? 'Guest Adventurer' : 'Apapane User')),
      photoUrl: user.photoURL ?? '',
      isAnonymous: user.isAnonymous,
    );
  }

  LocalSessionUser copyWith({
    String? id,
    String? email,
    String? displayName,
    String? photoUrl,
    bool? isAnonymous,
  }) {
    return LocalSessionUser(
      id: id ?? this.id,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      isAnonymous: isAnonymous ?? this.isAnonymous,
    );
  }
}
