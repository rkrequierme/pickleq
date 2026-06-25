class Player {
  final int? id;
  final String name;
  final String status; // 'waiting', 'playing', 'absent', 'inactive'
  final DateTime? queueJoinedAt;
  final int? queuePosition;
  final DateTime createdAt;
  final String skillLevel; // 'beginner', 'intermediate', 'advanced'

  Player({
    this.id,
    required this.name,
    required this.status,
    this.queueJoinedAt,
    this.queuePosition,
    required this.createdAt,
    this.skillLevel = 'intermediate',
  });

  Player copyWith({
    int? id,
    String? name,
    String? status,
    DateTime? queueJoinedAt,
    int? queuePosition,
    DateTime? createdAt,
    String? skillLevel,
  }) {
    return Player(
      id: id ?? this.id,
      name: name ?? this.name,
      status: status ?? this.status,
      queueJoinedAt: queueJoinedAt ?? this.queueJoinedAt,
      queuePosition: queuePosition ?? this.queuePosition,
      createdAt: createdAt ?? this.createdAt,
      skillLevel: skillLevel ?? this.skillLevel,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'status': status,
      'queue_joined_at': queueJoinedAt?.toIso8601String(),
      'queue_position': queuePosition,
      'created_at': createdAt.toIso8601String(),
      'skill_level': skillLevel,
    };
  }

  factory Player.fromMap(Map<String, dynamic> map) {
    return Player(
      id: map['id'] as int?,
      name: map['name'] as String,
      status: map['status'] as String,
      queueJoinedAt: map['queue_joined_at'] != null
          ? DateTime.parse(map['queue_joined_at'] as String)
          : null,
      queuePosition: map['queue_position'] as int?,
      createdAt: DateTime.parse(map['created_at'] as String),
      skillLevel: (map['skill_level'] as String?) ?? 'intermediate',
    );
  }

  @override
  String toString() {
    return 'Player(id: $id, name: $name, status: $status, skillLevel: $skillLevel, queuePosition: $queuePosition)';
  }
}
