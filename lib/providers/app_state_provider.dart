import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/player.dart';
import '../models/court.dart';
import '../models/match.dart';
import '../models/session.dart';
import '../services/db_helper.dart';
import '../services/rotation_engine.dart';

class AppStateProvider extends ChangeNotifier {
  final DBHelper _dbHelper = DBHelper();

  // Loading and authentication
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _isAuthenticated = false;
  bool get isAuthenticated => _isAuthenticated;

  String? _currentAdmin;
  String? get currentAdmin => _currentAdmin;

  // Domain data cache
  List<Player> _allPlayers = [];
  List<Player> get allPlayers => _allPlayers;

  List<Player> _waitingQueue = [];
  List<Player> get waitingQueue => _waitingQueue;

  List<Court> _courts = [];
  List<Court> get courts => _courts;

  List<MatchModel> _activeMatches = [];
  List<MatchModel> get activeMatches => _activeMatches;

  List<MatchModel> _completedMatches = [];
  List<MatchModel> get completedMatches => _completedMatches;

  Session? _activeSession;
  Session? get activeSession => _activeSession;

  // Initialize and load all data
  Future<void> init() async {
    _isLoading = true;
    notifyListeners();

    try {
      await loadSession();
      await loadPlayers();
      await loadCourts();
      await loadMatches();
    } catch (e) {
      debugPrint("Error initializing AppStateProvider: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // --- AUTHENTICATION ---

  Future<bool> login(String username, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      final success = await _dbHelper.authenticateAdmin(username, password);
      if (success) {
        _isAuthenticated = true;
        _currentAdmin = username;
        await init(); // Load everything upon login
        return true;
      }
      return false;
    } catch (e) {
      debugPrint("Login error: $e");
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void logout() {
    _isAuthenticated = false;
    _currentAdmin = null;
    _waitingQueue.clear();
    _allPlayers.clear();
    _courts.clear();
    _activeMatches.clear();
    _completedMatches.clear();
    _activeSession = null;
    notifyListeners();
  }

  Future<void> changePassword(String newPassword) async {
    if (_currentAdmin == null) return;
    await _dbHelper.updateAdminPassword(_currentAdmin!, newPassword);
  }

  // --- SESSIONS ---

  Future<void> loadSession() async {
    _activeSession = await _dbHelper.getActiveSession();
    notifyListeners();
  }

  Future<void> startNewSession() async {
    if (_activeSession != null) return;
    
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    await _dbHelper.startSession(today);
    await loadSession();
    await loadPlayers(); // Re-loads status of players
  }

  Future<void> endCurrentSession() async {
    if (_activeSession == null) return;

    await _dbHelper.closeSession(_activeSession!.id!);
    _activeSession = null;
    
    // Clear and reload all data to register reset states
    await init();
  }

  // --- PLAYERS & QUEUE ---

  Future<void> loadPlayers() async {
    _allPlayers = await _dbHelper.getAllPlayers();
    
    // Waiting queue is sorted by RotationEngine
    final rawWaiting = await _dbHelper.getWaitingQueue();
    _waitingQueue = RotationEngine.sortQueue(rawWaiting);
    notifyListeners();
  }

  Future<bool> registerPlayer(String name, [String skillLevel = 'intermediate']) async {
    if (name.trim().isEmpty) return false;

    // Check if player name already exists
    final nameLower = name.trim().toLowerCase();
    if (_allPlayers.any((p) => p.name.toLowerCase() == nameLower)) {
      return false;
    }

    try {
      // Find current max queue position
      int nextPos = 0;
      if (_waitingQueue.isNotEmpty) {
        nextPos = _waitingQueue.map((p) => p.queuePosition ?? 0).reduce((a, b) => a > b ? a : b) + 1;
      }

      final newPlayer = Player(
        name: name.trim(),
        status: _activeSession != null ? 'waiting' : 'inactive',
        queueJoinedAt: _activeSession != null ? DateTime.now() : null,
        queuePosition: _activeSession != null ? nextPos : null,
        createdAt: DateTime.now(),
        skillLevel: skillLevel,
      );

      await _dbHelper.insertPlayer(newPlayer);
      await loadPlayers();
      return true;
    } catch (e) {
      debugPrint("Error registering player: $e");
      return false;
    }
  }

  Future<void> removePlayer(int id) async {
    await _dbHelper.deletePlayer(id);
    await loadPlayers();
  }

  // Skip absent players (moves them to the end of the queue)
  Future<void> skipPlayer(int id) async {
    final idx = _waitingQueue.indexWhere((p) => p.id == id);
    if (idx == -1) return;

    final player = _waitingQueue[idx];
    
    // Calculate new position at the end of the queue
    int nextPos = 0;
    if (_waitingQueue.isNotEmpty) {
      nextPos = _waitingQueue.map((p) => p.queuePosition ?? 0).reduce((a, b) => a > b ? a : b) + 1;
    }

    final updated = player.copyWith(
      queueJoinedAt: DateTime.now(),
      queuePosition: nextPos,
    );

    await _dbHelper.updatePlayer(updated);
    await loadPlayers();
  }

  // Change player status (waiting/absent/inactive)
  Future<void> changePlayerStatus(int id, String newStatus) async {
    final playerIdx = _allPlayers.indexWhere((p) => p.id == id);
    if (playerIdx == -1) return;

    final player = _allPlayers[playerIdx];

    DateTime? queueTime;
    int? queuePos;

    if (newStatus == 'waiting') {
      queueTime = DateTime.now();
      int nextPos = 0;
      if (_waitingQueue.isNotEmpty) {
        nextPos = _waitingQueue.map((p) => p.queuePosition ?? 0).reduce((a, b) => a > b ? a : b) + 1;
      }
      queuePos = nextPos;
    }

    final updated = player.copyWith(
      status: newStatus,
      queueJoinedAt: queueTime,
      queuePosition: queuePos,
    );

    await _dbHelper.updatePlayer(updated);
    await loadPlayers();
  }

  // Manual reordering: move up (index - 1)
  Future<void> movePlayerUp(int index) async {
    if (index <= 0 || index >= _waitingQueue.length) return;

    // Swap positions
    final p1 = _waitingQueue[index];
    final p2 = _waitingQueue[index - 1];

    final pos1 = p1.queuePosition ?? index;
    final pos2 = p2.queuePosition ?? (index - 1);

    final updated1 = p1.copyWith(queuePosition: pos2);
    final updated2 = p2.copyWith(queuePosition: pos1);

    await _dbHelper.updatePlayer(updated1);
    await _dbHelper.updatePlayer(updated2);

    await loadPlayers();
  }

  // Manual reordering: move down (index + 1)
  Future<void> movePlayerDown(int index) async {
    if (index < 0 || index >= _waitingQueue.length - 1) return;

    // Swap positions
    final p1 = _waitingQueue[index];
    final p2 = _waitingQueue[index + 1];

    final pos1 = p1.queuePosition ?? index;
    final pos2 = p2.queuePosition ?? (index + 1);

    final updated1 = p1.copyWith(queuePosition: pos2);
    final updated2 = p2.copyWith(queuePosition: pos1);

    await _dbHelper.updatePlayer(updated1);
    await _dbHelper.updatePlayer(updated2);

    await loadPlayers();
  }

  // --- COURTS ---

  Future<void> loadCourts() async {
    _courts = await _dbHelper.getAllCourts();
    notifyListeners();
  }

  Future<bool> registerCourt(String name, int number) async {
    if (name.trim().isEmpty) return false;
    if (_courts.any((c) => c.number == number)) return false;

    try {
      final newCourt = Court(
        name: name.trim(),
        number: number,
        status: 'available',
      );
      await _dbHelper.insertCourt(newCourt);
      await loadCourts();
      return true;
    } catch (e) {
      debugPrint("Error registering court: $e");
      return false;
    }
  }

  Future<void> updateCourtStatus(int id, String status) async {
    final idx = _courts.indexWhere((c) => c.id == id);
    if (idx == -1) return;

    // If court status changes to maintenance, check if there's an active match on it
    if (status == 'maintenance') {
      final activeMatchIdx = _activeMatches.indexWhere((m) => m.courtId == id);
      if (activeMatchIdx != -1) {
        // Stop the active match first!
        final activeMatch = _activeMatches[activeMatchIdx];
        await finishMatch(
          activeMatch.id!,
          id,
          activeMatch.players,
          DateTime.now().difference(activeMatch.startedAt).inSeconds,
        );
      }
    }

    final updated = _courts[idx].copyWith(status: status);
    await _dbHelper.updateCourt(updated);
    await loadCourts();
  }

  Future<void> deleteCourt(int id) async {
    // End active matches on this court if any
    final activeMatchIdx = _activeMatches.indexWhere((m) => m.courtId == id);
    if (activeMatchIdx != -1) {
      final activeMatch = _activeMatches[activeMatchIdx];
      await finishMatch(
        activeMatch.id!,
        id,
        activeMatch.players,
        DateTime.now().difference(activeMatch.startedAt).inSeconds,
      );
    }

    await _dbHelper.deleteCourt(id);
    await loadCourts();
  }

  // --- MATCHES & MATCH CREATION ---

  Future<void> loadMatches() async {
    _activeMatches = await _dbHelper.getActiveMatches();
    _completedMatches = await _dbHelper.getMatchHistory();
    notifyListeners();
  }

  /// Suggests the next players based on the fair rotation algorithm
  List<Player> getSuggestedPlayers(bool isDoubles) {
    return RotationEngine.recommendPlayers(
      waitingQueue: _waitingQueue,
      isDoubles: isDoubles,
    );
  }

  Future<void> createAndStartMatch({
    required int courtId,
    required String type,
    required List<Player> selectedPlayers,
  }) async {
    final shuffledPlayers = List<Player>.from(selectedPlayers)..shuffle();

    final match = MatchModel(
      courtId: courtId,
      type: type,
      startedAt: DateTime.now(),
      status: 'active',
    );

    await _dbHelper.startMatch(match, shuffledPlayers);
    
    // Reload state
    await loadMatches();
    await loadPlayers();
    await loadCourts();
  }

  Future<void> finishMatch(
    int matchId,
    int courtId,
    List<Player> matchPlayers,
    int durationSeconds,
  ) async {
    await _dbHelper.endMatch(matchId, courtId, matchPlayers, durationSeconds);
    
    // Reload state
    await loadMatches();
    await loadPlayers();
    await loadCourts();
  }

  // --- REPORTS DATA RETRIEVAL (Active Session / Date) ---
  
  Future<List<Map<String, dynamic>>> getAttendanceReport() async {
    final dateStr = _activeSession?.date ?? DateFormat('yyyy-MM-dd').format(DateTime.now());
    return await _dbHelper.getDailyAttendanceReport(dateStr);
  }

  Future<List<Map<String, dynamic>>> getCourtUtilizationStats() async {
    final dateStr = _activeSession?.date ?? DateFormat('yyyy-MM-dd').format(DateTime.now());
    return await _dbHelper.getCourtUtilizationStats(dateStr);
  }

  Future<List<Map<String, dynamic>>> getQueueActivityReport() async {
    final dateStr = _activeSession?.date ?? DateFormat('yyyy-MM-dd').format(DateTime.now());
    return await _dbHelper.getQueueActivityReport(dateStr);
  }
}
