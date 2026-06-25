import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state_provider.dart';
import '../models/player.dart';
import '../models/court.dart';
import '../models/match.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_card.dart';

class MatchView extends StatefulWidget {
  const MatchView({super.key});

  @override
  State<MatchView> createState() => _MatchViewState();
}

class _MatchViewState extends State<MatchView> {
  Widget _buildSkillBadge(String skillLevel) {
    Color badgeColor;
    String label;
    if (skillLevel == 'beginner') {
      badgeColor = Colors.blue;
      label = "BEG";
    } else if (skillLevel == 'advanced') {
      badgeColor = Colors.orange;
      label = "ADV";
    } else {
      badgeColor = Colors.green;
      label = "INT";
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: badgeColor.withOpacity(0.12),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: badgeColor.withOpacity(0.25), width: 1),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 8,
          fontWeight: FontWeight.bold,
          color: badgeColor,
        ),
      ),
    );
  }

  Widget _buildPlayerTeamItem(Player player) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        children: [
          const Icon(Icons.person, size: 14, color: AppTheme.textSecondary),
          const SizedBox(width: 8),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    player.name,
                    style: const TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 6),
                _buildSkillBadge(player.skillLevel),
              ],
            ),
          ),
        ],
      ),
    );
  }

  bool _isDoubles = true; // Default to doubles (4 players)
  int? _selectedCourtId;
  List<Player> _selectedPlayers = [];
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // Periodically update active match timer displays
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {});
      }
    });

    // Run post frame callback to auto-populate suggestions
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _autoPopulateSuggestions();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _autoPopulateSuggestions() {
    final appState = Provider.of<AppStateProvider>(context, listen: false);
    final suggestions = appState.getSuggestedPlayers(_isDoubles);
    final availableCourts = appState.courts.where((c) => c.status == 'available').toList();

    setState(() {
      _selectedPlayers = List<Player>.from(suggestions);
      if (availableCourts.isNotEmpty && _selectedCourtId == null) {
        _selectedCourtId = availableCourts.first.id;
      }
    });
  }

  String _formatElapsedTime(DateTime startedAt) {
    final diff = DateTime.now().difference(startedAt);
    final minutes = diff.inMinutes;
    final seconds = diff.inSeconds % 60;
    return "${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}";
  }

  void _togglePlayerSelection(Player player) {
    setState(() {
      if (_selectedPlayers.any((p) => p.id == player.id)) {
        _selectedPlayers.removeWhere((p) => p.id == player.id);
      } else {
        final requiredCount = _isDoubles ? 4 : 2;
        if (_selectedPlayers.length < requiredCount) {
          _selectedPlayers.add(player);
        } else {
          // If list is full, swap out the last player
          _selectedPlayers.removeLast();
          _selectedPlayers.add(player);
        }
      }
    });
  }

  Future<void> _startMatch(AppStateProvider appState) async {
    final requiredCount = _isDoubles ? 4 : 2;
    if (_selectedPlayers.length != requiredCount) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Please select exactly $requiredCount players for a ${_isDoubles ? 'doubles' : 'singles'} match.")),
      );
      return;
    }
    if (_selectedCourtId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select an available court.")),
      );
      return;
    }

    await appState.createAndStartMatch(
      courtId: _selectedCourtId!,
      type: _isDoubles ? 'doubles' : 'singles',
      selectedPlayers: _selectedPlayers,
    );

    // Reset selection state
    setState(() {
      _selectedPlayers.clear();
      _selectedCourtId = null;
    });

    _autoPopulateSuggestions();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Match started successfully!"),
        backgroundColor: Color(0xFF00FF85),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppStateProvider>(context);
    final availableCourts = appState.courts.where((c) => c.status == 'available').toList();
    final requiredCount = _isDoubles ? 4 : 2;
    final recommendedPlayers = appState.getSuggestedPlayers(_isDoubles);

    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left Column: Match Creator Panel
          Expanded(
            flex: 4,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "MATCH CREATOR & SCHEDULER",
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textSecondary,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: GlassCard(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Step 1: Match Type Selection
                          const Text(
                            "1. Select Match Format",
                            style: TextStyle(fontFamily: 'Outfit', fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: InkWell(
                                  onTap: () {
                                    setState(() {
                                      _isDoubles = false;
                                      _selectedPlayers.clear();
                                    });
                                    _autoPopulateSuggestions();
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                    decoration: BoxDecoration(
                                      color: !_isDoubles
                                          ? AppTheme.neonLime.withOpacity(0.08)
                                          : Colors.transparent,
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color: !_isDoubles ? AppTheme.neonLime : AppTheme.borderMuted,
                                        width: 1,
                                      ),
                                    ),
                                    alignment: Alignment.center,
                                    child: Text(
                                      "SINGLES (2 Players)",
                                      style: TextStyle(
                                        fontFamily: 'Outfit',
                                        fontWeight: FontWeight.bold,
                                        color: !_isDoubles ? AppTheme.neonLime : AppTheme.textSecondary,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: InkWell(
                                  onTap: () {
                                    setState(() {
                                      _isDoubles = true;
                                      _selectedPlayers.clear();
                                    });
                                    _autoPopulateSuggestions();
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                    decoration: BoxDecoration(
                                      color: _isDoubles
                                          ? AppTheme.neonLime.withOpacity(0.08)
                                          : Colors.transparent,
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color: _isDoubles ? AppTheme.neonLime : AppTheme.borderMuted,
                                        width: 1,
                                      ),
                                    ),
                                    alignment: Alignment.center,
                                    child: Text(
                                      "DOUBLES (4 Players)",
                                      style: TextStyle(
                                        fontFamily: 'Outfit',
                                        fontWeight: FontWeight.bold,
                                        color: _isDoubles ? AppTheme.neonLime : AppTheme.textSecondary,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),

                          // Step 2: Assign Court
                          const Text(
                            "2. Assign Available Court",
                            style: TextStyle(fontFamily: 'Outfit', fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 12),
                          if (availableCourts.isEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              decoration: BoxDecoration(
                                color: AppTheme.coralRed.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: AppTheme.coralRed.withOpacity(0.3)),
                              ),
                              child: const Row(
                                children: [
                                  Icon(Icons.warning_amber_rounded, color: AppTheme.coralRed, size: 16),
                                  SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      "All courts are currently occupied or in maintenance.",
                                      style: TextStyle(color: AppTheme.coralRed, fontSize: 13),
                                    ),
                                  ),
                                ],
                              ),
                            )
                          else
                            DropdownButtonFormField<int>(
                              value: _selectedCourtId,
                              items: availableCourts.map((c) {
                                return DropdownMenuItem<int>(
                                  value: c.id,
                                  child: Text(
                                    c.name,
                                    style: const TextStyle(color: AppTheme.textPrimary, fontFamily: 'Outfit'),
                                  ),
                                );
                              }).toList(),
                              onChanged: (val) {
                                setState(() {
                                  _selectedCourtId = val;
                                });
                              },
                              decoration: const InputDecoration(labelText: "Choose Court"),
                            ),
                          const SizedBox(height: 24),

                          // Step 3: Select Players (Recommends longest waiting)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "3. Select Players ($_selectedPlayersCount/$requiredCount)",
                                style: const TextStyle(
                                  fontFamily: 'Outfit',
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                              TextButton.icon(
                                onPressed: _autoPopulateSuggestions,
                                icon: const Icon(Icons.refresh, size: 14),
                                label: const Text("AUTO-RECOMMEND"),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          if (appState.waitingQueue.isEmpty)
                            const Center(
                              child: Padding(
                                padding: EdgeInsets.symmetric(vertical: 24.0),
                                child: Text(
                                  "Queue is empty. Register players first.",
                                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                                ),
                              ),
                            )
                          else
                            ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: appState.waitingQueue.length,
                              itemBuilder: (context, index) {
                                final player = appState.waitingQueue[index];
                                final isSelected = _selectedPlayers.any((p) => p.id == player.id);
                                final isRecommendation = recommendedPlayers.any((p) => p.id == player.id);

                                return CheckboxListTile(
                                  value: isSelected,
                                  activeColor: AppTheme.neonLime,
                                  checkColor: Colors.black,
                                  title: Row(
                                    children: [
                                      Expanded(
                                        child: Row(
                                          children: [
                                            Text(
                                              player.name,
                                              style: TextStyle(
                                                color: isSelected ? AppTheme.textPrimary : AppTheme.textSecondary,
                                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                                fontFamily: 'Outfit',
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            _buildSkillBadge(player.skillLevel),
                                          ],
                                        ),
                                      ),
                                      if (isRecommendation) ...[
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: AppTheme.neonLime.withOpacity(0.12),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: const Text(
                                            "RECOMMENDED",
                                            style: TextStyle(
                                              fontSize: 8,
                                              fontWeight: FontWeight.bold,
                                              color: AppTheme.neonLime,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                  subtitle: Text(
                                    "Waiting position #${index + 1}",
                                    style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary, fontFamily: 'Inter'),
                                  ),
                                  onChanged: (val) => _togglePlayerSelection(player),
                                );
                              },
                            ),
                          const SizedBox(height: 32),

                          // Start Match Button
                          ElevatedButton(
                            onPressed: (availableCourts.isNotEmpty && _selectedPlayers.length == requiredCount)
                                ? () => _startMatch(appState)
                                : null,
                            style: ElevatedButton.styleFrom(
                              minimumSize: const Size.fromHeight(52),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.flash_on, size: 18),
                                const SizedBox(width: 8),
                                Text("LAUNCH MATCH (${_isDoubles ? 'DOUBLES' : 'SINGLES'})"),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 24),
          // Right Column: Active Ongoing Matches Grid
          Expanded(
            flex: 5,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "ACTIVE ONGOING GAMES (${appState.activeMatches.length})",
                  style: const TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textSecondary,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: appState.activeMatches.isEmpty
                      ? GlassCard(
                          child: const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.sports_tennis, color: AppTheme.textSecondary, size: 36),
                                SizedBox(height: 16),
                                Text(
                                  "No games in progress",
                                  style: TextStyle(
                                    fontFamily: 'Outfit',
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                    color: AppTheme.textPrimary,
                                  ),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  "Create a match on the left to start checking court activity.",
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    color: AppTheme.textSecondary,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      : GridView.builder(
                          itemCount: appState.activeMatches.length,
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                            childAspectRatio: 1.15,
                          ),
                          itemBuilder: (context, index) {
                            final match = appState.activeMatches[index];
                            final elapsedTime = _formatElapsedTime(match.startedAt);

                            return GlassCard(
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        match.courtName ?? "Court ${match.courtId}",
                                        style: const TextStyle(
                                          fontFamily: 'Outfit',
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: AppTheme.textPrimary,
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: AppTheme.electricTeal.withOpacity(0.08),
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(color: AppTheme.electricTeal.withOpacity(0.2)),
                                        ),
                                        child: Text(
                                          match.type.toUpperCase(),
                                          style: const TextStyle(
                                            fontFamily: 'Outfit',
                                            fontSize: 9,
                                            fontWeight: FontWeight.bold,
                                            color: AppTheme.electricTeal,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  Expanded(
                                    child: match.players.length == 4
                                        ? Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              _buildPlayerTeamItem(match.players[0]),
                                              _buildPlayerTeamItem(match.players[1]),
                                              const Padding(
                                                padding: EdgeInsets.symmetric(vertical: 4.0),
                                                child: Center(
                                                  child: Text(
                                                    "— VS —",
                                                    style: TextStyle(
                                                      fontFamily: 'Outfit',
                                                      fontSize: 10,
                                                      fontWeight: FontWeight.bold,
                                                      color: AppTheme.neonLime,
                                                      letterSpacing: 1.5,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              _buildPlayerTeamItem(match.players[2]),
                                              _buildPlayerTeamItem(match.players[3]),
                                            ],
                                          )
                                        : match.players.length == 2
                                            ? Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  _buildPlayerTeamItem(match.players[0]),
                                                  const Padding(
                                                    padding: EdgeInsets.symmetric(vertical: 4.0),
                                                    child: Center(
                                                      child: Text(
                                                        "— VS —",
                                                        style: TextStyle(
                                                          fontFamily: 'Outfit',
                                                          fontSize: 10,
                                                          fontWeight: FontWeight.bold,
                                                          color: AppTheme.neonLime,
                                                          letterSpacing: 1.5,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                  _buildPlayerTeamItem(match.players[1]),
                                                ],
                                              )
                                            : ListView.builder(
                                                shrinkWrap: true,
                                                physics: const NeverScrollableScrollPhysics(),
                                                itemCount: match.players.length,
                                                itemBuilder: (context, pIdx) {
                                                  return _buildPlayerTeamItem(match.players[pIdx]);
                                                },
                                              ),
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          const Icon(Icons.timer_outlined, size: 14, color: AppTheme.neonLime),
                                          const SizedBox(width: 6),
                                          Text(
                                            elapsedTime,
                                            style: const TextStyle(
                                              fontFamily: 'Outfit',
                                              fontSize: 15,
                                              fontWeight: FontWeight.bold,
                                              color: AppTheme.neonLime,
                                            ),
                                          ),
                                        ],
                                      ),
                                      ElevatedButton(
                                        onPressed: () {
                                          _showEndMatchConfirm(context, appState, match);
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AppTheme.coralRed,
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                        ),
                                        child: const Text("END GAME"),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  int get _selectedPlayersCount => _selectedPlayers.length;

  void _showEndMatchConfirm(BuildContext context, AppStateProvider appState, MatchModel match) {
    final elapsedSec = DateTime.now().difference(match.startedAt).inSeconds;
    
    // Formatting duration display
    final min = elapsedSec ~/ 60;
    final sec = elapsedSec % 60;
    final timeStr = "$min min $sec sec";

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("End Match"),
          content: Text(
            "Are you sure you want to end this game on ${match.courtName}?\n\nDuration: $timeStr\n\nEnding the match will automatically move all participating players to the back of the waiting queue according to the fair rotation system.",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("CANCEL", style: TextStyle(color: AppTheme.textSecondary)),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                appState.finishMatch(
                  match.id!,
                  match.courtId,
                  match.players,
                  elapsedSec,
                );
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.neonLime, foregroundColor: Colors.black),
              child: const Text("END & ROTATE PLAYERS"),
            ),
          ],
        );
      },
    );
  }
}
