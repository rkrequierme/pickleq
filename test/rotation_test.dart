import 'package:flutter_test/flutter_test.dart';
import 'package:pickleq/models/player.dart';
import 'package:pickleq/services/rotation_engine.dart';

void main() {
  group('RotationEngine Tests', () {
    final now = DateTime.now();
    
    final player1 = Player(
      id: 1,
      name: 'Player 1',
      status: 'waiting',
      queueJoinedAt: now.subtract(const Duration(minutes: 10)),
      queuePosition: 0,
      createdAt: now,
    );

    final player2 = Player(
      id: 2,
      name: 'Player 2',
      status: 'waiting',
      queueJoinedAt: now.subtract(const Duration(minutes: 5)),
      queuePosition: 1,
      createdAt: now,
    );

    final player3 = Player(
      id: 3,
      name: 'Player 3',
      status: 'waiting',
      queueJoinedAt: now.subtract(const Duration(minutes: 15)),
      queuePosition: 2,
      createdAt: now,
    );

    final player4 = Player(
      id: 4,
      name: 'Player 4',
      status: 'inactive', // Should be excluded from waiting queue sorting
      queueJoinedAt: now.subtract(const Duration(minutes: 20)),
      queuePosition: null,
      createdAt: now,
    );

    test('sortQueue handles priority and filters waiting status', () {
      final input = [player3, player4, player2, player1];
      final sorted = RotationEngine.sortQueue(input);

      expect(sorted.length, 3);
      // player1 has queuePosition 0, should be first
      expect(sorted[0].id, 1);
      // player2 has queuePosition 1, should be second
      expect(sorted[1].id, 2);
      // player3 has queuePosition 2, should be third
      expect(sorted[2].id, 3);
    });

    test('recommendPlayers for singles (2 players)', () {
      final input = [player3, player2, player1];
      final recommended = RotationEngine.recommendPlayers(
        waitingQueue: input,
        isDoubles: false,
      );

      expect(recommended.length, 2);
      expect(recommended[0].id, 1);
      expect(recommended[1].id, 2);
    });

    test('recommendPlayers for doubles (4 players) with insufficient waiting count', () {
      final input = [player3, player2, player1];
      final recommended = RotationEngine.recommendPlayers(
        waitingQueue: input,
        isDoubles: true,
      );

      // Should return all 3 waiting since there are less than 4 players
      expect(recommended.length, 3);
      expect(recommended[0].id, 1);
      expect(recommended[1].id, 2);
      expect(recommended[2].id, 3);
    });
  });
}
