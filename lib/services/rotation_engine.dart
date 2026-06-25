import '../models/player.dart';

class RotationEngine {
  /// Sorts players waiting in the queue based on their priority:
  /// 1. `queuePosition` ascending (so lower position plays first)
  /// 2. `queueJoinedAt` ascending (so earlier join time plays first)
  static List<Player> sortQueue(List<Player> players) {
    final waiting = players.where((p) => p.status == 'waiting').toList();
    
    waiting.sort((a, b) {
      // Both have queue positions
      if (a.queuePosition != null && b.queuePosition != null) {
        final posComp = a.queuePosition!.compareTo(b.queuePosition!);
        if (posComp != 0) return posComp;
      }
      // One has queue position, it goes first
      else if (a.queuePosition != null) {
        return -1;
      } else if (b.queuePosition != null) {
        return 1;
      }
      
      // Fallback to queue joined time
      if (a.queueJoinedAt != null && b.queueJoinedAt != null) {
        return a.queueJoinedAt!.compareTo(b.queueJoinedAt!);
      } else if (a.queueJoinedAt != null) {
        return -1;
      } else if (b.queueJoinedAt != null) {
        return 1;
      }
      
      // Ultimate fallback: created time
      return a.createdAt.compareTo(b.createdAt);
    });

    return waiting;
  }

  /// Recommends the next set of players for a match.
  /// Balances based on skill level:
  /// 1. Identifies the anchor (longest-waiting player in the queue).
  /// 2. Prioritizes players of the EXACT SAME skill level.
  /// 3. If needed, prioritizes players of ADJACENT skill levels.
  /// 4. Falls back to wait-time order if not enough players are found.
  static List<Player> recommendPlayers({
    required List<Player> waitingQueue,
    required bool isDoubles,
  }) {
    final sorted = sortQueue(waitingQueue);
    if (sorted.isEmpty) return [];

    final countRequired = isDoubles ? 4 : 2;
    if (sorted.length <= countRequired) {
      return List<Player>.from(sorted);
    }

    final recommendations = <Player>[];
    final anchor = sorted[0];
    recommendations.add(anchor);

    // List of remaining players to choose from
    final remaining = List<Player>.from(sorted.sublist(1));

    // Pass 1: Match exact skill level (Beginner with Beginner, etc.)
    final exactMatches = remaining.where((p) => p.skillLevel == anchor.skillLevel).toList();
    for (final p in exactMatches) {
      if (recommendations.length < countRequired) {
        recommendations.add(p);
        remaining.remove(p);
      }
    }

    // Pass 2: Match adjacent skill levels if still needed
    if (recommendations.length < countRequired) {
      List<String> adjacentLevels;
      if (anchor.skillLevel == 'beginner') {
        adjacentLevels = ['intermediate'];
      } else if (anchor.skillLevel == 'advanced') {
        adjacentLevels = ['intermediate'];
      } else {
        // Intermediate can match with beginner or advanced
        adjacentLevels = ['beginner', 'advanced'];
      }

      final adjacentMatches = remaining.where((p) => adjacentLevels.contains(p.skillLevel)).toList();
      for (final p in adjacentMatches) {
        if (recommendations.length < countRequired) {
          recommendations.add(p);
          remaining.remove(p);
        }
      }
    }

    // Pass 3: Fallback to absolute wait time
    if (recommendations.length < countRequired) {
      for (final p in List<Player>.from(remaining)) {
        if (recommendations.length < countRequired) {
          recommendations.add(p);
          remaining.remove(p);
        }
      }
    }

    return recommendations;
  }
}
