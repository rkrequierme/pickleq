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
  /// For singles, returns 2 players.
  /// For doubles, returns 4 players.
  /// If there aren't enough players, returns as many as available.
  static List<Player> recommendPlayers({
    required List<Player> waitingQueue,
    required bool isDoubles,
  }) {
    final sorted = sortQueue(waitingQueue);
    final count = isDoubles ? 4 : 2;
    if (sorted.length <= count) {
      return List<Player>.from(sorted);
    }
    return sorted.sublist(0, count);
  }
}
