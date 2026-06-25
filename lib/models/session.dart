class Session {
  final int? id;
  final String date; // YYYY-MM-DD
  final DateTime startedAt;
  final DateTime? endedAt;
  final bool isClosed;

  Session({
    this.id,
    required this.date,
    required this.startedAt,
    this.endedAt,
    required this.isClosed,
  });

  Session copyWith({
    int? id,
    String? date,
    DateTime? startedAt,
    DateTime? endedAt,
    bool? isClosed,
  }) {
    return Session(
      id: id ?? this.id,
      date: date ?? this.date,
      startedAt: startedAt ?? this.startedAt,
      endedAt: endedAt ?? this.endedAt,
      isClosed: isClosed ?? this.isClosed,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date,
      'started_at': startedAt.toIso8601String(),
      'ended_at': endedAt?.toIso8601String(),
      'is_closed': isClosed ? 1 : 0,
    };
  }

  factory Session.fromMap(Map<String, dynamic> map) {
    return Session(
      id: map['id'] as int?,
      date: map['date'] as String,
      startedAt: DateTime.parse(map['started_at'] as String),
      endedAt: map['ended_at'] != null ? DateTime.parse(map['ended_at'] as String) : null,
      isClosed: (map['is_closed'] as int) == 1,
    );
  }

  @override
  String toString() {
    return 'Session(id: $id, date: $date, startedAt: $startedAt, endedAt: $endedAt, isClosed: $isClosed)';
  }
}
