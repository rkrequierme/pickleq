import 'dart:convert';
import 'dart:io' show Platform, Directory;
import 'package:flutter/foundation.dart';
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

  bool isWebOverride = false;
  bool get isWeb => kIsWeb || isWebOverride;

  Database? _db;

  // --- WEB DEMO IN-MEMORY STORAGE ---
  static final List<Map<String, dynamic>> _webAdmins = [
    {
      'username': 'admin',
      'password_hash': '240be518fabd2724ddb6f04eeb1da5967448d7e831c08c8fa822809f74c720a9', // admin123 hash
    }
  ];

  static final List<Player> _webPlayers = [];

  static final List<Court> _webCourts = [
    Court(id: 1, number: 1, name: 'Court 1', status: 'available'),
    Court(id: 2, number: 2, name: 'Court 2', status: 'available'),
    Court(id: 3, number: 3, name: 'Court 3', status: 'available'),
    Court(id: 4, number: 4, name: 'Court 4', status: 'available'),
  ];

  static final List<MatchModel> _webMatches = [];
  static Session? _webActiveSession;
  static final List<Session> _webSessions = [];

  Future<Database> get database async {
    if (isWeb) {
      throw UnsupportedError("Cannot access SQLite database on web. Use web-in-memory fallback.");
    }
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
    if (!isWeb) {
      if (Platform.isWindows || Platform.isLinux) {
        sqfliteFfiInit();
        databaseFactory = databaseFactoryFfi;
      }
    }

    final docsDir = await getApplicationDocumentsDirectory();
    final dbDir = Directory(p.join(docsDir.path, 'pickleq'));
    await dbDir.create(recursive: true);
    final dbPath = p.join(dbDir.path, 'pickleq.db');

    return await openDatabase(
      dbPath,
      version: 3,
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
            created_at TEXT NOT NULL,
            skill_level TEXT NOT NULL DEFAULT 'intermediate'
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
            player_index INTEGER DEFAULT 0,
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
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          try {
            await db.execute("ALTER TABLE players ADD COLUMN skill_level TEXT NOT NULL DEFAULT 'intermediate'");
          } catch (e) {
            debugPrint("Column skill_level already exists or failed to alter: $e");
          }
        }
        if (oldVersion < 3) {
          try {
            await db.execute("ALTER TABLE match_players ADD COLUMN player_index INTEGER DEFAULT 0");
          } catch (e) {
            debugPrint("Column player_index already exists or failed to alter: $e");
          }
        }
      },
    );
  }

  // --- ADMIN OPERATIONS ---
  
  Future<bool> authenticateAdmin(String username, String password) async {
    final hashed = hashPassword(password);
    if (isWeb) {
      return _webAdmins.any((admin) =>
          admin['username'].toString().toLowerCase() == username.trim().toLowerCase() &&
          admin['password_hash'] == hashed);
    }
    
    final db = await database;
    final results = await db.query(
      'admins',
      where: 'username = ? AND password_hash = ?',
      whereArgs: [username, hashed],
    );
    return results.isNotEmpty;
  }

  Future<void> updateAdminPassword(String username, String newPassword) async {
    final hashed = hashPassword(newPassword);
    if (isWeb) {
      final idx = _webAdmins.indexWhere((admin) => admin['username'] == username);
      if (idx != -1) {
        _webAdmins[idx]['password_hash'] = hashed;
      }
      return;
    }

    final db = await database;
    await db.update(
      'admins',
      {'password_hash': hashed},
      where: 'username = ?',
      whereArgs: [username],
    );
  }

  // --- PLAYER OPERATIONS ---

  Future<int> insertPlayer(Player player) async {
    if (isWeb) {
      int maxId = 0;
      for (final p in _webPlayers) {
        if ((p.id ?? 0) > maxId) maxId = p.id!;
      }
      final newId = maxId + 1;
      final inserted = player.copyWith(id: newId);
      _webPlayers.add(inserted);
      return newId;
    }

    final db = await database;
    return await db.insert('players', player.toMap());
  }

  Future<int> updatePlayer(Player player) async {
    if (isWeb) {
      final idx = _webPlayers.indexWhere((p) => p.id == player.id || p.name == player.name);
      if (idx != -1) {
        _webPlayers[idx] = player;
      }
      return 1;
    }

    final db = await database;
    return await db.update(
      'players',
      player.toMap(),
      where: 'id = ?',
      whereArgs: [player.id],
    );
  }

  Future<int> deletePlayer(int id) async {
    if (isWeb) {
      _webPlayers.removeWhere((p) => p.id == id);
      return 1;
    }

    final db = await database;
    return await db.delete(
      'players',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<Player>> getAllPlayers() async {
    if (isWeb) {
      final list = List<Player>.from(_webPlayers);
      list.sort((a, b) => a.name.compareTo(b.name));
      return list;
    }

    final db = await database;
    final maps = await db.query('players', orderBy: 'name ASC');
    return List.generate(maps.length, (i) => Player.fromMap(maps[i]));
  }

  Future<List<Player>> getWaitingQueue() async {
    if (isWeb) {
      final waiting = _webPlayers.where((p) => p.status == 'waiting').toList();
      waiting.sort((a, b) {
        if (a.queuePosition != null && b.queuePosition != null) {
          final posComp = a.queuePosition!.compareTo(b.queuePosition!);
          if (posComp != 0) return posComp;
        } else if (a.queuePosition != null) {
          return -1;
        } else if (b.queuePosition != null) {
          return 1;
        }

        if (a.queueJoinedAt != null && b.queueJoinedAt != null) {
          return a.queueJoinedAt!.compareTo(b.queueJoinedAt!);
        } else if (a.queueJoinedAt != null) {
          return -1;
        } else if (b.queueJoinedAt != null) {
          return 1;
        }
        return a.createdAt.compareTo(b.createdAt);
      });
      return waiting;
    }

    final db = await database;
    final maps = await db.query(
      'players',
      where: 'status = ?',
      whereArgs: ['waiting'],
      orderBy: 'queue_position ASC, queue_joined_at ASC',
    );
    return List.generate(maps.length, (i) => Player.fromMap(maps[i]));
  }

  Future<void> saveQueueOrder(List<Player> queue) async {
    if (isWeb) {
      for (int i = 0; i < queue.length; i++) {
        final idx = _webPlayers.indexWhere((p) => p.id == queue[i].id || p.name == queue[i].name);
        if (idx != -1) {
          _webPlayers[idx] = _webPlayers[idx].copyWith(queuePosition: i);
        }
      }
      return;
    }

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
    if (isWeb) {
      int maxId = 0;
      for (final c in _webCourts) {
        if ((c.id ?? 0) > maxId) maxId = c.id!;
      }
      final newId = maxId + 1;
      final inserted = court.copyWith(id: newId);
      _webCourts.add(inserted);
      return newId;
    }

    final db = await database;
    return await db.insert('courts', court.toMap());
  }

  Future<int> updateCourt(Court court) async {
    if (isWeb) {
      final idx = _webCourts.indexWhere((c) => c.id == court.id);
      if (idx != -1) {
        _webCourts[idx] = court;
      }
      return 1;
    }

    final db = await database;
    return await db.update(
      'courts',
      court.toMap(),
      where: 'id = ?',
      whereArgs: [court.id],
    );
  }

  Future<int> deleteCourt(int id) async {
    if (isWeb) {
      _webCourts.removeWhere((c) => c.id == id);
      return 1;
    }

    final db = await database;
    return await db.delete(
      'courts',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<Court>> getAllCourts() async {
    if (isWeb) {
      final list = List<Court>.from(_webCourts);
      list.sort((a, b) => a.number.compareTo(b.number));
      return list;
    }

    final db = await database;
    final maps = await db.query('courts', orderBy: 'number ASC');
    return List.generate(maps.length, (i) => Court.fromMap(maps[i]));
  }

  // --- MATCH OPERATIONS ---

  Future<int> startMatch(MatchModel match, List<Player> players) async {
    if (isWeb) {
      int maxId = 0;
      for (final m in _webMatches) {
        if ((m.id ?? 0) > maxId) maxId = m.id!;
      }
      final newMatchId = maxId + 1;

      // Update player states in memory (Fallback match on ID or Name)
      final updatedPlayers = <Player>[];
      for (final player in players) {
        final idx = _webPlayers.indexWhere((p) => p.id == player.id || p.name == player.name);
        if (idx != -1) {
          _webPlayers[idx] = _webPlayers[idx].copyWith(
            status: 'playing',
            queuePosition: null,
            queueJoinedAt: null,
          );
          updatedPlayers.add(_webPlayers[idx]);
        } else {
          updatedPlayers.add(player);
        }
      }

      // Update court status in memory
      final courtIdx = _webCourts.indexWhere((c) => c.id == match.courtId);
      if (courtIdx != -1) {
        _webCourts[courtIdx] = _webCourts[courtIdx].copyWith(status: 'occupied');
      }

      final insertedMatch = match.copyWith(
        id: newMatchId,
        players: updatedPlayers,
        courtName: courtIdx != -1 ? _webCourts[courtIdx].name : 'Court ${match.courtId}',
      );
      _webMatches.add(insertedMatch);
      return newMatchId;
    }

    final db = await database;
    return await db.transaction<int>((txn) async {
      final matchId = await txn.insert('matches', match.toMap());

      for (int i = 0; i < players.length; i++) {
        final player = players[i];
        await txn.insert('match_players', {
          'match_id': matchId,
          'player_id': player.id,
          'player_index': i,
        });

        // Update with ID or Name fallback to ensure updates happen
        await txn.update(
          'players',
          {'status': 'playing', 'queue_position': null, 'queue_joined_at': null},
          where: 'id = ? OR name = ?',
          whereArgs: [player.id, player.name],
        );
      }

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
    if (isWeb) {
      final courtIdx = _webCourts.indexWhere((c) => c.id == courtId);
      if (courtIdx != -1) {
        _webCourts[courtIdx] = _webCourts[courtIdx].copyWith(status: 'available');
      }

      final waiting = _webPlayers.where((p) => p.status == 'waiting').toList();
      int nextPos = 0;
      if (waiting.isNotEmpty) {
        int maxPos = 0;
        for (final p in waiting) {
          if ((p.queuePosition ?? 0) > maxPos) maxPos = p.queuePosition!;
        }
        nextPos = maxPos + 1;
      }

      // Fallback matching by ID or Name
      final updatedPlayers = <Player>[];
      for (int i = 0; i < players.length; i++) {
        final player = players[i];
        final pIdx = _webPlayers.indexWhere((x) => x.id == player.id || x.name == player.name);
        if (pIdx != -1) {
          _webPlayers[pIdx] = _webPlayers[pIdx].copyWith(
            status: 'waiting',
            queueJoinedAt: DateTime.now(),
            queuePosition: nextPos + i,
          );
          updatedPlayers.add(_webPlayers[pIdx]);
        } else {
          updatedPlayers.add(player);
        }
      }

      final matchIdx = _webMatches.indexWhere((m) => m.id == matchId);
      if (matchIdx != -1) {
        _webMatches[matchIdx] = _webMatches[matchIdx].copyWith(
          status: 'completed',
          endedAt: DateTime.now(),
          durationSeconds: durationSeconds,
          players: updatedPlayers,
        );
      }
      return;
    }

    final db = await database;
    await db.transaction((txn) async {
      final nowStr = DateTime.now().toIso8601String();

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

      await txn.update(
        'courts',
        {'status': 'available'},
        where: 'id = ?',
        whereArgs: [courtId],
      );

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
        await txn.update(
          'players',
          {
            'status': 'waiting',
            'queue_joined_at': nowStr,
            'queue_position': nextPos + i,
          },
          where: 'id = ? OR name = ?',
          whereArgs: [player.id, player.name],
        );
      }
    });
  }

  Future<List<MatchModel>> getActiveMatches() async {
    if (isWeb) {
      return _webMatches.where((m) => m.status == 'active').toList();
    }

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

      final courtResults = await db.query(
        'courts',
        columns: ['name'],
        where: 'id = ?',
        whereArgs: [courtId],
      );
      final courtName = courtResults.isNotEmpty ? courtResults.first['name'] as String : 'Unknown Court';

      final playerResults = await db.rawQuery('''
        SELECT p.* FROM players p
        INNER JOIN match_players mp ON p.id = mp.player_id
        WHERE mp.match_id = ?
        ORDER BY mp.player_index ASC
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
    if (isWeb) {
      final list = _webMatches.where((m) => m.status == 'completed').toList();
      list.sort((a, b) => b.endedAt!.compareTo(a.endedAt!));
      return list;
    }

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

      final courtResults = await db.query(
        'courts',
        columns: ['name'],
        where: 'id = ?',
        whereArgs: [courtId],
      );
      final courtName = courtResults.isNotEmpty ? courtResults.first['name'] as String : 'Unknown Court';

      final playerResults = await db.rawQuery('''
        SELECT p.* FROM players p
        INNER JOIN match_players mp ON p.id = mp.player_id
        WHERE mp.match_id = ?
        ORDER BY mp.player_index ASC
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
    if (isWeb) {
      return _webActiveSession;
    }

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
    if (isWeb) {
      int maxId = 0;
      for (final s in _webSessions) {
        if ((s.id ?? 0) > maxId) maxId = s.id!;
      }
      final newId = maxId + 1;
      
      final session = Session(
        id: newId,
        date: date,
        startedAt: DateTime.now(),
        isClosed: false,
      );
      _webSessions.add(session);
      _webActiveSession = session;

      // Make all registered players active waiting
      for (int i = 0; i < _webPlayers.length; i++) {
        _webPlayers[i] = _webPlayers[i].copyWith(
          status: 'waiting',
          queueJoinedAt: DateTime.now(),
          queuePosition: i,
        );
      }
      return newId;
    }

    final db = await database;
    final nowStr = DateTime.now().toIso8601String();
    
    return await db.insert('sessions', {
      'date': date,
      'started_at': nowStr,
      'is_closed': 0,
    });
  }

  Future<void> closeSession(int sessionId) async {
    if (isWeb) {
      if (_webActiveSession != null && _webActiveSession!.id == sessionId) {
        final idx = _webSessions.indexWhere((s) => s.id == sessionId);
        if (idx != -1) {
          _webSessions[idx] = _webSessions[idx].copyWith(
            isClosed: true,
            endedAt: DateTime.now(),
          );
        }
        _webActiveSession = null;
      }

      final active = _webMatches.where((m) => m.status == 'active').toList();
      for (final m in active) {
        final elapsedSeconds = DateTime.now().difference(m.startedAt).inSeconds;
        await endMatch(m.id!, m.courtId, m.players, elapsedSeconds);
      }

      for (int i = 0; i < _webPlayers.length; i++) {
        _webPlayers[i] = _webPlayers[i].copyWith(
          status: 'inactive',
          queueJoinedAt: null,
          queuePosition: null,
        );
      }
      return;
    }

    final db = await database;
    final nowStr = DateTime.now().toIso8601String();
    
    await db.transaction((txn) async {
      await txn.update(
        'sessions',
        {
          'is_closed': 1,
          'ended_at': nowStr,
        },
        where: 'id = ?',
        whereArgs: [sessionId],
      );

      final activeMatches = await txn.query('matches', where: 'status = ?', whereArgs: ['active']);
      for (final matchMap in activeMatches) {
        final matchId = matchMap['id'] as int;
        final courtId = matchMap['court_id'] as int;

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

      await txn.update('players', {
        'status': 'inactive',
        'queue_joined_at': null,
        'queue_position': null,
      });
    });
  }

  // --- REPORT QUERIES ---

  Future<List<Map<String, dynamic>>> getDailyAttendanceReport(String date) async {
    if (isWeb) {
      return _webPlayers.map((player) {
        final gamesPlayed = _webMatches.where((m) {
          return m.status == 'completed' && m.players.any((p) => p.id == player.id);
        }).length;

        return {
          'id': player.id,
          'name': player.name,
          'status': player.status,
          'created_at': player.createdAt.toIso8601String(),
          'games_played': gamesPlayed,
          'skill_level': player.skillLevel,
        };
      }).toList();
    }

    final db = await database;
    final results = await db.rawQuery('''
      SELECT DISTINCT p.id, p.name, p.status, p.created_at, p.skill_level,
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

  Future<List<Map<String, dynamic>>> getCourtUtilizationStats(String date) async {
    if (isWeb) {
      return _webCourts.map((court) {
        final courtMatches = _webMatches.where((m) => m.courtId == court.id && m.status == 'completed').toList();
        final totalDuration = courtMatches.fold<int>(0, (sum, m) => sum + (m.durationSeconds ?? 0));
        return {
          'id': court.id,
          'name': court.name,
          'number': court.number,
          'total_matches': courtMatches.length,
          'total_duration_seconds': totalDuration,
        };
      }).toList();
    }

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

  Future<List<Map<String, dynamic>>> getQueueActivityReport(String date) async {
    if (isWeb) {
      return _webMatches.where((m) => m.status == 'completed').map((m) {
        return {
          'id': m.id,
          'court_id': m.courtId,
          'type': m.type,
          'started_at': m.startedAt.toIso8601String(),
          'ended_at': m.endedAt?.toIso8601String(),
          'duration_seconds': m.durationSeconds,
          'status': m.status,
        };
      }).toList();
    }

    final db = await database;
    final results = await db.query(
      'matches',
      where: "status = 'completed' AND ended_at LIKE ?",
      whereArgs: ['$date%'],
      orderBy: 'started_at ASC',
    );
    
    return results;
  }
}
