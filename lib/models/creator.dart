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
  final String gender;

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
    this.gender = 'Female',
  });

  factory Creator.fromApiJson(Map<String, dynamic> json) {
    final rate = json['ratePerMinute'] as int? ?? 10;
    final name = json['name'] as String? ?? 'Creator';
    return Creator(
      id: json['id'] as String,
      name: name,
      avatar: json['profileImage'] as String? ?? 'https://i.pravatar.cc/150?u=$name',
      isOnline: json['isOnline'] as bool? ?? false,
      lastSeenAt: json['lastSeenAt'] as String?,
      lastSeenLabel: json['lastSeenLabel'] as String? ??
          ((json['isOnline'] as bool? ?? false) ? 'Online' : 'Offline'),
      isNew: json['isNew'] as bool? ?? false,
      isVoiceAvailable: json['isVoiceAvailable'] as bool? ?? true,
      isChatAvailable: json['isChatAvailable'] as bool? ?? true,
      voicePrice: '$rate/min',
      chatPrice: '60/min',
      language: json['language'] as String? ?? 'Malayalam',
      gender: json['gender'] as String? ?? 'Female',
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
        'gender': gender,
      };
}
