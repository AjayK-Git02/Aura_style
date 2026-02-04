class UserProfile {
  final String id;
  final String email;
  final String? fullName;
  final String? avatarUrl;
  final String? tryonBodyPhotoUrl;
  final String? zodiacSign;
  final DateTime? birthDate;
  final String? bodyType;
  final List<String> stylePreferences;
  final bool onboardingCompleted;
  final DateTime createdAt;
  final DateTime updatedAt;

  final String? gender; // 'male' or 'female'

  UserProfile({
    required this.id,
    required this.email,
    this.fullName,
    this.gender,
    this.avatarUrl,
    this.tryonBodyPhotoUrl,
    this.zodiacSign,
    this.birthDate,
    this.bodyType,
    this.stylePreferences = const [],
    required this.onboardingCompleted,
    required this.createdAt,
    required this.updatedAt,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String,
      email: json['email'] as String,
      fullName: json['full_name'] as String?,
      gender: json['gender'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      tryonBodyPhotoUrl: json['tryon_body_photo_url'] as String?,
      zodiacSign: json['zodiac_sign'] as String?,
      birthDate: json['birth_date'] != null
          ? DateTime.parse(json['birth_date'] as String)
          : null,
      bodyType: json['body_type'] as String?,
      stylePreferences: json['style_preferences'] != null
          ? List<String>.from(json['style_preferences'] as List)
          : [],
      onboardingCompleted: json['onboarding_completed'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'full_name': fullName,
      'gender': gender,
      'avatar_url': avatarUrl,
      'tryon_body_photo_url': tryonBodyPhotoUrl,
      'zodiac_sign': zodiacSign,
      'birth_date': birthDate?.toIso8601String(),
      'body_type': bodyType,
      'style_preferences': stylePreferences,
      'onboarding_completed': onboardingCompleted,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  UserProfile copyWith({
    String? id,
    String? email,
    String? fullName,
    String? gender,
    String? avatarUrl,
    String? tryonBodyPhotoUrl,
    String? zodiacSign,
    DateTime? birthDate,
    String? bodyType,
    List<String>? stylePreferences,
    bool? onboardingCompleted,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserProfile(
      id: id ?? this.id,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      gender: gender ?? this.gender,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      tryonBodyPhotoUrl: tryonBodyPhotoUrl ?? this.tryonBodyPhotoUrl,
      zodiacSign: zodiacSign ?? this.zodiacSign,
      birthDate: birthDate ?? this.birthDate,
      bodyType: bodyType ?? this.bodyType,
      stylePreferences: stylePreferences ?? this.stylePreferences,
      onboardingCompleted: onboardingCompleted ?? this.onboardingCompleted,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
