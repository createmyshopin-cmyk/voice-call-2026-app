class Creator {
  final String id;
  final String name;
  final String avatar;
  final bool isOnline;
  final String? lastSeenAt;
  final String lastSeenLabel;
  final bool isNew;
  final bool isVoiceAvailable;
  final bool isChatAvailable;
  final String voicePrice;
  final String chatPrice;
  final String language;
  final List<String> languages;
  final String gender;
  final int ratePerMinute;
  final double rating;
  final int totalCalls;
  final double? responseRate;
  final String? createdAt;

  const Creator({
    required this.id,
    required this.name,
    required this.avatar,
    required this.isOnline,
    this.lastSeenAt,
    this.lastSeenLabel = 'Offline',
    this.isNew = false,
    this.isVoiceAvailable = true,
    this.isChatAvailable = true,
    this.voicePrice = '10/min',
    this.chatPrice = '60/min',
    this.language = 'Malayalam',
    this.languages = const ['Malayalam'],
    this.gender = 'Female',
    this.ratePerMinute = 10,
    this.rating = 0,
    this.totalCalls = 0,
    this.responseRate,
    this.createdAt,
  });

  int get videoRatePerMinute => ratePerMinute * 2;

  String get languagesLabel =>
      languages.isNotEmpty ? languages.join(', ') : language;

  String get languagesLabelBullet =>
      languages.isNotEmpty ? languages.join(' • ') : language;

  String get firstName {
    final parts = name.trim().split(RegExp(r'\s+'));
    return parts.isNotEmpty ? parts.first : name;
  }

  Creator copyWith({
    String? id,
    String? name,
    String? avatar,
    bool? isOnline,
    String? lastSeenAt,
    String? lastSeenLabel,
    bool? isNew,
    bool? isVoiceAvailable,
    bool? isChatAvailable,
    String? voicePrice,
    String? chatPrice,
    String? language,
    List<String>? languages,
    String? gender,
    int? ratePerMinute,
    double? rating,
    int? totalCalls,
    double? responseRate,
    String? createdAt,
  }) {
    return Creator(
      id: id ?? this.id,
      name: name ?? this.name,
      avatar: avatar ?? this.avatar,
      isOnline: isOnline ?? this.isOnline,
      lastSeenAt: lastSeenAt ?? this.lastSeenAt,
      lastSeenLabel: lastSeenLabel ?? this.lastSeenLabel,
      isNew: isNew ?? this.isNew,
      isVoiceAvailable: isVoiceAvailable ?? this.isVoiceAvailable,
      isChatAvailable: isChatAvailable ?? this.isChatAvailable,
      voicePrice: voicePrice ?? this.voicePrice,
      chatPrice: chatPrice ?? this.chatPrice,
      language: language ?? this.language,
      languages: languages ?? this.languages,
      gender: gender ?? this.gender,
      ratePerMinute: ratePerMinute ?? this.ratePerMinute,
      rating: rating ?? this.rating,
      totalCalls: totalCalls ?? this.totalCalls,
      responseRate: responseRate ?? this.responseRate,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  static String presenceLabel({required bool isOnline, String? lastSeenAt}) {
    if (isOnline) return 'Online';
    if (lastSeenAt == null || lastSeenAt.isEmpty) return 'Offline';
    return 'Offline';
  }

  static List<String> _parseLanguages(Map<String, dynamic> json) {
    final raw = json['languages'];
    if (raw is List) {
      return raw.map((e) => e.toString()).where((s) => s.isNotEmpty).toList();
    }
    if (raw is String && raw.isNotEmpty) {
      return raw.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
    }
    final single = json['language'] as String?;
    if (single != null && single.isNotEmpty) return [single];
    return const ['Malayalam'];
  }

  factory Creator.fromApiJson(Map<String, dynamic> json) {
    final rate = json['ratePerMinute'] as int? ?? 10;
    final name = (json['fullName'] as String? ??
            json['full_name'] as String? ??
            json['name'] as String? ??
            'Creator')
        .trim();
    final langs = _parseLanguages(json);
    return Creator(
      id: json['id'] as String,
      name: name,
      avatar: json['profileImage'] as String? ??
          json['avatar'] as String? ??
          'https://i.pravatar.cc/150?u=$name',
      isOnline: json['isOnline'] as bool? ?? false,
      lastSeenAt: json['lastSeenAt'] as String?,
      lastSeenLabel: json['lastSeenLabel'] as String? ??
          ((json['isOnline'] as bool? ?? false) ? 'Online' : 'Offline'),
      isNew: json['isNew'] as bool? ?? false,
      isVoiceAvailable: json['isVoiceAvailable'] as bool? ?? true,
      isChatAvailable: json['isChatAvailable'] as bool? ?? true,
      voicePrice: '$rate/min',
      chatPrice: '60/min',
      language: langs.first,
      languages: langs,
      gender: json['gender'] as String? ?? 'Female',
      ratePerMinute: rate,
      rating: (json['rating'] as num?)?.toDouble() ?? 0,
      totalCalls: json['completedCalls'] as int? ??
          json['totalCalls'] as int? ??
          0,
      responseRate: (json['responseRate'] as num?)?.toDouble(),
      createdAt: json['createdAt'] as String?,
    );
  }

  Map<String, dynamic> toUserCardMap() => {
        'id': id,
        'name': name,
        'avatar': avatar,
        'isOnline': isOnline,
        'lastSeenAt': lastSeenAt,
        'lastSeenLabel': lastSeenLabel,
        'isNew': isNew,
        'isVoiceAvailable': isVoiceAvailable,
        'isChatAvailable': isChatAvailable,
        'voicePrice': voicePrice,
        'chatPrice': chatPrice,
        'language': language,
        'languages': languages,
        'gender': gender,
        'ratePerMinute': ratePerMinute,
        'rating': rating,
        'totalCalls': totalCalls,
        'responseRate': responseRate,
      };
}
