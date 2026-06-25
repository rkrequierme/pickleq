import 'player.dart';

class MatchModel {
  final int? id;
  final int courtId;
  final String type; // 'singles', 'doubles'
  final DateTime startedAt;
  final DateTime? endedAt;
  final int? durationSeconds;
  final String status; // 'active', 'completed'
  final List<Player> players;
  final String? courtName;

  MatchModel({
    this.id,
    required this.courtId,
    required this.type,
    required this.startedAt,
    this.endedAt,
    this.durationSeconds,
    required this.status,
    this.players = const [],
    this.courtName,
  });

  MatchModel copyWith({
    int? id,
    int? courtId,
    String? type,
    DateTime? startedAt,
    DateTime? endedAt,
    int? durationSeconds,
    String? status,
    List<Player>? players,
    String? courtName,
  }) {
    return MatchModel(
      id: id ?? this.id,
      courtId: courtId ?? this.courtId,
      type: type ?? this.type,
      startedAt: startedAt ?? this.startedAt,
      endedAt: endedAt ?? this.endedAt,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      status: status ?? this.status,
      players: players ?? this.players,
      courtName: courtName ?? this.courtName,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'court_id': courtId,
      'type': type,
      'started_at': startedAt.toIso8601String(),
      'ended_at': endedAt?.toIso8601String(),
      'duration_seconds': durationSeconds,
      'status': status,
    };
  }

  factory MatchModel.fromMap(Map<String, dynamic> map, {List<Player> players = const [], String? courtName}) {
    return MatchModel(
      id: map['id'] as int?,
      courtId: map['court_id'] as int,
      type: map['type'] as String,
      startedAt: DateTime.parse(map['started_at'] as String),
      endedAt: map['ended_at'] != null ? DateTime.parse(map['ended_at'] as String) : null,
      durationSeconds: map['duration_seconds'] as int?,
      status: map['status'] as String,
      players: players,
      courtName: courtName,
    );
  }

  @override
  String toString() {
    return 'MatchModel(id: $id, courtId: $courtId, type: $type, startedAt: $startedAt, endedAt: $endedAt, status: $status, playersCount: ${players.length})';
  }
}
