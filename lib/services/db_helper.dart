import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../models/player.dart';
import '../models/court.dart';
import '../models/match.dart';
import '../models/session.dart';

class DBHelper {
  static final DBHelper _instance = DBHelper._internal();
  factory DBHelper() => _instance;
  DBHelper._internal();

  Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDatabase();
    return _db!;
  }

  String hashPassword(String password) {
    final bytes = utf8.encode(password);
    return sha256.convert(bytes).toString();
  }

  Future<Database> _initDatabase() async {
    // Initialize FFI for Windows desktop
    if (Platform.isWindows || Platform.isLinux) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    final docsDir = await getApplicationDocumentsDirectory();
    final dbDir = Directory(p.join(docsDir.path, 'pickleq'));
    await dbDir.create(recursive: true);
    final dbPath = p.join(dbDir.path, 'pickleq.db');

    return await openDatabase(
      dbPath,
      version: 1,
      onCreate: (db, version) async {
        // Admins table
        await db.execute('''
          CREATE TABLE admins (
            username TEXT PRIMARY KEY,
            password_hash TEXT NOT NULL
          )
        ''');

        // Players table
        await db.execute('''
          CREATE TABLE players (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL UNIQUE,
            status TEXT NOT NULL, -- 'waiting', 'playing', 'absent', 'inactive'
            queue_joined_at TEXT, -- ISO8601 timestamp
            queue_position INTEGER, -- position order in queue
            created_at TEXT NOT NULL
          )
        ''');

        // Courts table
        await db.execute('''
          CREATE TABLE courts (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            number INTEGER NOT NULL UNIQUE,
            name TEXT NOT NULL,
            status TEXT NOT NULL -- 'available', 'occupied', 'maintenance'
          )
        ''');

        // Matches table
        await db.execute('''
          CREATE TABLE matches (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            court_id INTEGER NOT NULL,
            type TEXT NOT NULL, -- 'singles', 'doubles'
            started_at TEXT NOT NULL,
            ended_at TEXT,
            duration_seconds INTEGER,
            status TEXT NOT NULL, -- 'active', 'completed'
            FOREIGN KEY (court_id) REFERENCES courts (id)
          )
        ''');

        // Match players junction table
        await db.execute('''
          CREATE TABLE match_players (
            match_id INTEGER NOT NULL,
            player_id INTEGER NOT NULL,
            PRIMARY KEY (match_id, player_id),
            FOREIGN KEY (match_id) REFERENCES matches (id) ON DELETE CASCADE,
            FOREIGN KEY (player_id) REFERENCES players (id) ON DELETE CASCADE
          )
        ''');

        // Sessions table
        await db.execute('''
          CREATE TABLE sessions (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            date TEXT NOT NULL UNIQUE, -- YYYY-MM-DD
            started_at TEXT NOT NULL,
            ended_at TEXT,
            is_closed INTEGER DEFAULT 0 -- 0 = active, 1 = closed
          )
        ''');

        // Seed default administrator
        final defaultPasswordHash = hashPassword('admin123');
        await db.insert('admins', {
          'username': 'admin',
          'password_hash': defaultPasswordHash,
        });

        // Seed 4 initial courts
        for (int i = 1; i <= 4; i++) {
          await db.insert('courts', {
            'number': i,
            'name': 'Court $i',
            'status': 'available',
          });
        }
      },
    );
  }

  // --- ADMIN OPERATIONS ---
  
  Future<bool> authenticateAdmin(String username, String password) async {
    final db = await database;
    final hashed = hashPassword(password);
    final results = await db.query(
      'admins',
      where: 'username = ? AND password_hash = ?',
      whereArgs: [username, hashed],
    );
    return results.isNotEmpty;
  }

  Future<void> updateAdminPassword(String username, String newPassword) async {
    final db = await database;
    final hashed = hashPassword(newPassword);
    await db.update(
      'admins',
      {'password_hash': hashed},
      where: 'username = ?',
      whereArgs: [username],
    );
  }

  // --- PLAYER OPERATIONS ---

  Future<int> insertPlayer(Player player) async {
    final db = await database;
    return await db.insert('players', player.toMap());
  }

  Future<int> updatePlayer(Player player) async {
    final db = await database;
    return await db.update(
      'players',
      player.toMap(),
      where: 'id = ?',
      whereArgs: [player.id],
    );
  }

  Future<int> deletePlayer(int id) async {
    final db = await database;
    return await db.delete(
      'players',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<Player>> getAllPlayers() async {
    final db = await database;
    final maps = await db.query('players', orderBy: 'name ASC');
    return List.generate(maps.length, (i) => Player.fromMap(maps[i]));
  }

  Future<List<Player>> getWaitingQueue() async {
    final db = await database;
    final maps = await db.query(
      'players',
      where: 'status = ?',
      whereArgs: ['waiting'],
      orderBy: 'queue_position ASC, queue_joined_at ASC',
    );
    return List.generate(maps.length, (i) => Player.fromMap(maps[i]));
  }

  // Helper to re-evaluate and save player queue positions sequentially
  Future<void> saveQueueOrder(List<Player> queue) async {
    final db = await database;
    final batch = db.batch();
    for (int i = 0; i < queue.length; i++) {
      batch.update(
        'players',
        {'queue_position': i},
        where: 'id = ?',
        whereArgs: [queue[i].id],
      );
    }
    await batch.commit(noResult: true);
  }

  // --- COURT OPERATIONS ---

  Future<int> insertCourt(Court court) async {
    final db = await database;
    return await db.insert('courts', court.toMap());
  }

  Future<int> updateCourt(Court court) async {
    final db = await database;
    return await db.update(
      'courts',
      court.toMap(),
      where: 'id = ?',
      whereArgs: [court.id],
    );
  }

  Future<int> deleteCourt(int id) async {
    final db = await database;
    return await db.delete(
      'courts',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<Court>> getAllCourts() async {
    final db = await database;
    final maps = await db.query('courts', orderBy: 'number ASC');
    return List.generate(maps.length, (i) => Court.fromMap(maps[i]));
  }

  // --- MATCH OPERATIONS ---

  Future<int> startMatch(MatchModel match, List<Player> players) async {
    final db = await database;
    
    // Use transaction to ensure consistency
    return await db.transaction<int>((txn) async {
      // 1. Insert the match
      final matchId = await txn.insert('matches', match.toMap());

      // 2. Insert match players
      for (final player in players) {
        await txn.insert('match_players', {
          'match_id': matchId,
          'player_id': player.id,
        });

        // Update player status to 'playing'
        await txn.update(
          'players',
          {'status': 'playing', 'queue_position': null, 'queue_joined_at': null},
          where: 'id = ?',
          whereArgs: [player.id],
        );
      }

      // 3. Update court status to 'occupied'
      await txn.update(
        'courts',
        {'status': 'occupied'},
        where: 'id = ?',
        whereArgs: [match.courtId],
      );

      return matchId;
    });
  }

  Future<void> endMatch(int matchId, int courtId, List<Player> players, int durationSeconds) async {
    final db = await database;

    await db.transaction((txn) async {
      final nowStr = DateTime.now().toIso8601String();

      // 1. Update the match to completed
      await txn.update(
        'matches',
        {
          'status': 'completed',
          'ended_at': nowStr,
          'duration_seconds': durationSeconds,
        },
        where: 'id = ?',
        whereArgs: [matchId],
      );

      // 2. Reset court to available
      await txn.update(
        'courts',
        {'status': 'available'},
        where: 'id = ?',
        whereArgs: [courtId],
      );

      // 3. Move players back to queue (fair rotation)
      // Find current max queue position
      final List<Map<String, dynamic>> maxPosResult = await txn.rawQuery(
        'SELECT MAX(queue_position) as max_pos FROM players WHERE status = ?',
        ['waiting'],
      );
      int nextPos = 0;
      if (maxPosResult.isNotEmpty && maxPosResult.first['max_pos'] != null) {
        nextPos = (maxPosResult.first['max_pos'] as int) + 1;
      }

      for (int i = 0; i < players.length; i++) {
        final player = players[i];
        
        // Wait, what if we also increment their games_played count?
        // Since we don't have games_played in players table (we store it in matches/match_players history),
        // we can count games dynamically from match history to generate reports, which is cleaner and less denormalized!
        
        await txn.update(
          'players',
          {
            'status': 'waiting',
            'queue_joined_at': nowStr,
            'queue_position': nextPos + i,
          },
          where: 'id = ?',
          whereArgs: [player.id],
        );
      }
    });
  }

  Future<List<MatchModel>> getActiveMatches() async {
    final db = await database;
    
    final matchMaps = await db.query(
      'matches',
      where: 'status = ?',
      whereArgs: ['active'],
      orderBy: 'started_at ASC',
    );

    List<MatchModel> activeMatches = [];

    for (final map in matchMaps) {
      final matchId = map['id'] as int;
      final courtId = map['court_id'] as int;

      // Get court name
      final courtResults = await db.query(
        'courts',
        columns: ['name'],
        where: 'id = ?',
        whereArgs: [courtId],
      );
      final courtName = courtResults.isNotEmpty ? courtResults.first['name'] as String : 'Unknown Court';

      // Get players
      final playerResults = await db.rawQuery('''
        SELECT p.* FROM players p
        INNER JOIN match_players mp ON p.id = mp.player_id
        WHERE mp.match_id = ?
      ''', [matchId]);

      final players = List.generate(playerResults.length, (i) => Player.fromMap(playerResults[i]));

      activeMatches.add(MatchModel.fromMap(
        map,
        players: players,
        courtName: courtName,
      ));
    }

    return activeMatches;
  }

  Future<List<MatchModel>> getMatchHistory() async {
    final db = await database;
    
    final matchMaps = await db.query(
      'matches',
      where: 'status = ?',
      whereArgs: ['completed'],
      orderBy: 'ended_at DESC',
    );

    List<MatchModel> matches = [];

    for (final map in matchMaps) {
      final matchId = map['id'] as int;
      final courtId = map['court_id'] as int;

      // Get court name
      final courtResults = await db.query(
        'courts',
        columns: ['name'],
        where: 'id = ?',
        whereArgs: [courtId],
      );
      final courtName = courtResults.isNotEmpty ? courtResults.first['name'] as String : 'Unknown Court';

      // Get players
      final playerResults = await db.rawQuery('''
        SELECT p.* FROM players p
        INNER JOIN match_players mp ON p.id = mp.player_id
        WHERE mp.match_id = ?
      ''', [matchId]);

      final players = List.generate(playerResults.length, (i) => Player.fromMap(playerResults[i]));

      matches.add(MatchModel.fromMap(
        map,
        players: players,
        courtName: courtName,
      ));
    }

    return matches;
  }

  // --- SESSION OPERATIONS ---

  Future<Session?> getActiveSession() async {
    final db = await database;
    final results = await db.query(
      'sessions',
      where: 'is_closed = ?',
      whereArgs: [0],
    );
    if (results.isEmpty) return null;
    return Session.fromMap(results.first);
  }

  Future<int> startSession(String date) async {
    final db = await database;
    final nowStr = DateTime.now().toIso8601String();
    
    return await db.insert('sessions', {
      'date': date,
      'started_at': nowStr,
      'is_closed': 0,
    });
  }

  Future<void> closeSession(int sessionId) async {
    final db = await database;
    final nowStr = DateTime.now().toIso8601String();
    
    await db.transaction((txn) async {
      // 1. Update session to closed
      await txn.update(
        'sessions',
        {
          'is_closed': 1,
          'ended_at': nowStr,
        },
        where: 'id = ?',
        whereArgs: [sessionId],
      );

      // 2. Put all active matches to completed (if any) and reset court/player statuses
      final activeMatches = await txn.query('matches', where: 'status = ?', whereArgs: ['active']);
      for (final matchMap in activeMatches) {
        final matchId = matchMap['id'] as int;
        final courtId = matchMap['court_id'] as int;

        // Fetch duration
        final start = DateTime.parse(matchMap['started_at'] as String);
        final elapsedSeconds = DateTime.now().difference(start).inSeconds;

        await txn.update(
          'matches',
          {
            'status': 'completed',
            'ended_at': nowStr,
            'duration_seconds': elapsedSeconds,
          },
          where: 'id = ?',
          whereArgs: [matchId],
        );

        await txn.update(
          'courts',
          {'status': 'available'},
          where: 'id = ?',
          whereArgs: [courtId],
        );
      }

      // 3. Reset all players to 'inactive' and clear queue states
      await txn.update('players', {
        'status': 'inactive',
        'queue_joined_at': null,
        'queue_position': null,
      });
    });
  }

  // --- REPORT QUERIES ---

  // Attendance Report (players who checked in or played games today)
  Future<List<Map<String, dynamic>>> getDailyAttendanceReport(String date) async {
    final db = await database;
    // Get players who joined the queue today or played in a match today
    final results = await db.rawQuery('''
      SELECT DISTINCT p.id, p.name, p.status, p.created_at,
             (SELECT COUNT(*) FROM match_players mp 
              INNER JOIN matches m ON mp.match_id = m.id 
              WHERE mp.player_id = p.id AND m.status = 'completed' AND m.ended_at LIKE ?) as games_played
      FROM players p
      LEFT JOIN match_players mp ON p.id = mp.player_id
      LEFT JOIN matches m ON mp.match_id = m.id
      WHERE p.created_at LIKE ? OR m.ended_at LIKE ? OR p.status IN ('waiting', 'playing')
    ''', ['$date%', '$date%', '$date%']);
    
    return results;
  }

  // Court Utilization Statistics
  Future<List<Map<String, dynamic>>> getCourtUtilizationStats(String date) async {
    final db = await database;
    
    final results = await db.rawQuery('''
      SELECT c.id, c.name, c.number,
             COUNT(m.id) as total_matches,
             SUM(COALESCE(m.duration_seconds, 0)) as total_duration_seconds
      FROM courts c
      LEFT JOIN matches m ON c.id = m.court_id AND m.status = 'completed' AND m.ended_at LIKE ?
      GROUP BY c.id
    ''', ['$date%']);

    return results;
  }

  // Queue Activity report (Average wait time per hour)
  Future<List<Map<String, dynamic>>> getQueueActivityReport(String date) async {
    final db = await database;
    
    // Return the list of matches completed today, with start time, end time, and duration
    final results = await db.query(
      'matches',
      where: "status = 'completed' AND ended_at LIKE ?",
      whereArgs: ['$date%'],
      orderBy: 'started_at ASC',
    );
    
    return results;
  }
}
