class Player {
  final int? id;
  final String name;
  final String status; // 'waiting', 'playing', 'absent', 'inactive'
  final DateTime? queueJoinedAt;
  final int? queuePosition;
  final DateTime createdAt;

  Player({
    this.id,
    required this.name,
    required this.status,
    this.queueJoinedAt,
    this.queuePosition,
    required this.createdAt,
  });

  Player copyWith({
    int? id,
    String? name,
    String? status,
    DateTime? queueJoinedAt,
    int? queuePosition,
    DateTime? createdAt,
  }) {
    return Player(
      id: id ?? this.id,
      name: name ?? this.name,
      status: status ?? this.status,
      queueJoinedAt: queueJoinedAt ?? this.queueJoinedAt,
      queuePosition: queuePosition ?? this.queuePosition,
      createdAt: createdAt ?? this.createdAt,
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
    );
  }

  @override
  String toString() {
    return 'Player(id: $id, name: $name, status: $status, queueJoinedAt: $queueJoinedAt, queuePosition: $queuePosition)';
  }
}
