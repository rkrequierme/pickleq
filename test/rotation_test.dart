import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pickleq/models/player.dart';
import 'package:pickleq/services/rotation_engine.dart';
import 'package:pickleq/services/db_helper.dart';
import 'package:pickleq/providers/app_state_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Set mock for path provider
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
    const MethodChannel('plugins.flutter.io/path_provider'),
    (MethodCall methodCall) async {
      final tempDir = Directory.systemTemp.createTempSync('pickleq_test_');
      return tempDir.path;
    },
  );

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

    test('recommendPlayers prioritizes identical skill levels first, then adjacent, then others', () {
      final anchor = Player(
        id: 10,
        name: 'Anchor Beg',
        status: 'waiting',
        queueJoinedAt: now.subtract(const Duration(minutes: 10)),
        queuePosition: 0,
        createdAt: now,
        skillLevel: 'beginner',
      );

      final otherBeg = Player(
        id: 11,
        name: 'Other Beg',
        status: 'waiting',
        queueJoinedAt: now.subtract(const Duration(minutes: 9)),
        queuePosition: 1,
        createdAt: now,
        skillLevel: 'beginner',
      );

      final inter1 = Player(
        id: 12,
        name: 'Inter 1',
        status: 'waiting',
        queueJoinedAt: now.subtract(const Duration(minutes: 8)),
        queuePosition: 2,
        createdAt: now,
        skillLevel: 'intermediate',
      );

      final adv1 = Player(
        id: 13,
        name: 'Adv 1',
        status: 'waiting',
        queueJoinedAt: now.subtract(const Duration(minutes: 7)),
        queuePosition: 3,
        createdAt: now,
        skillLevel: 'advanced',
      );

      final inter2 = Player(
        id: 14,
        name: 'Inter 2',
        status: 'waiting',
        queueJoinedAt: now.subtract(const Duration(minutes: 6)),
        queuePosition: 4,
        createdAt: now,
        skillLevel: 'intermediate',
      );

      final queue = [anchor, otherBeg, inter1, adv1, inter2];
      final recommended = RotationEngine.recommendPlayers(
        waitingQueue: queue,
        isDoubles: true,
      );

      expect(recommended.length, 4);
      expect(recommended[0].id, 10); // Anchor Beg
      expect(recommended[1].id, 11); // Other Beg (Exact Match)
      expect(recommended[2].id, 12); // Inter 1 (Adjacent Match)
      expect(recommended[3].id, 14); // Inter 2 (Adjacent Match)
      expect(recommended.any((p) => p.id == 13), isFalse); // Advanced player Adv 1 excluded
    });
  });

  group('DBHelper and AppState Match Start/End State Transitions', () {
    late AppStateProvider appState;

    setUp(() async {
      if (Platform.isWindows || Platform.isLinux) {
        sqfliteFfiInit();
        databaseFactory = databaseFactoryFfi;
      }
      appState = AppStateProvider();
      await appState.startNewSession(); // This ensures session is started and triggers init
      await appState.init();
    });

    test('Starting and ending matches successfully moves players back to waiting status', () async {
      // Clean players database for test execution
      final db = await DBHelper().database;
      await db.delete('players');
      await db.delete('matches');
      await db.delete('match_players');

      // Register two players
      final p1Registered = await appState.registerPlayer('Test Player 1', 'beginner');
      final p2Registered = await appState.registerPlayer('Test Player 2', 'intermediate');

      expect(p1Registered, isTrue);
      expect(p2Registered, isTrue);

      // Verify they are both in waiting queue
      expect(appState.waitingQueue.length, 2);
      expect(appState.waitingQueue[0].name, 'Test Player 1');
      expect(appState.waitingQueue[1].name, 'Test Player 2');
      expect(appState.waitingQueue[0].status, 'waiting');
      expect(appState.waitingQueue[1].status, 'waiting');

      // Get court id to start the match (there are 4 courts seeded on onCreate)
      final availableCourts = appState.courts.where((c) => c.status == 'available').toList();
      expect(availableCourts.isNotEmpty, isTrue);
      final testCourt = availableCourts.first;

      // Start match
      final matchPlayers = List<Player>.from(appState.waitingQueue);
      await appState.createAndStartMatch(
        courtId: testCourt.id!,
        type: 'singles',
        selectedPlayers: matchPlayers,
      );

      // Verify they are no longer in waiting queue (status playing)
      expect(appState.waitingQueue.isEmpty, isTrue);
      expect(appState.activeMatches.length, 1);
      expect(appState.activeMatches.first.players.length, 2);
      expect(appState.activeMatches.first.players[0].status, 'playing');
      expect(appState.activeMatches.first.players[1].status, 'playing');

      // End match
      final activeMatch = appState.activeMatches.first;
      await appState.finishMatch(
        activeMatch.id!,
        activeMatch.courtId,
        activeMatch.players,
        60,
      );

      // Verify players return to the waiting queue (status waiting)
      expect(appState.activeMatches.isEmpty, isTrue);
      expect(appState.waitingQueue.length, 2);
      expect(appState.waitingQueue[0].status, 'waiting');
      expect(appState.waitingQueue[1].status, 'waiting');
    });
  });

  group('DBHelper and AppState Match Start/End State Transitions (Web Fallback)', () {
    late AppStateProvider appState;

    setUp(() async {
      DBHelper().isWebOverride = true;
      appState = AppStateProvider();
      await appState.startNewSession(); // triggers init
      await appState.init();
    });

    tearDown(() {
      DBHelper().isWebOverride = false;
    });

    test('Starting and ending matches successfully moves players back to waiting status on Web', () async {
      // Clear web list directly
      final all = await appState.allPlayers;
      for (final p in all) {
        await appState.removePlayer(p.id!);
      }
      
      // Register two players
      final p1Registered = await appState.registerPlayer('Test Web Player 1', 'beginner');
      final p2Registered = await appState.registerPlayer('Test Web Player 2', 'intermediate');

      expect(p1Registered, isTrue);
      expect(p2Registered, isTrue);

      // Verify they are both in waiting queue
      expect(appState.waitingQueue.length, 2);
      expect(appState.waitingQueue[0].name, 'Test Web Player 1');
      expect(appState.waitingQueue[1].name, 'Test Web Player 2');
      expect(appState.waitingQueue[0].status, 'waiting');
      expect(appState.waitingQueue[1].status, 'waiting');

      // Get court id to start the match (seeded 4 courts)
      final availableCourts = appState.courts.where((c) => c.status == 'available').toList();
      expect(availableCourts.isNotEmpty, isTrue);
      final testCourt = availableCourts.first;

      // Start match
      final matchPlayers = List<Player>.from(appState.waitingQueue);
      await appState.createAndStartMatch(
        courtId: testCourt.id!,
        type: 'singles',
        selectedPlayers: matchPlayers,
      );

      // Verify they are no longer in waiting queue (status playing)
      expect(appState.waitingQueue.isEmpty, isTrue);
      expect(appState.activeMatches.length, 1);
      expect(appState.activeMatches.first.players.length, 2);
      expect(appState.activeMatches.first.players[0].status, 'playing');
      expect(appState.activeMatches.first.players[1].status, 'playing');

      // End match
      final activeMatch = appState.activeMatches.first;
      await appState.finishMatch(
        activeMatch.id!,
        activeMatch.courtId,
        activeMatch.players,
        60,
      );

      // Verify players return to the waiting queue (status waiting)
      expect(appState.activeMatches.isEmpty, isTrue);
      expect(appState.waitingQueue.length, 2);
      expect(appState.waitingQueue[0].status, 'waiting');
      expect(appState.waitingQueue[1].status, 'waiting');
    });
  });
}
