import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_card.dart';
import '../widgets/queue_list_tile.dart';

class QueueView extends StatefulWidget {
  const QueueView({super.key});

  @override
  State<QueueView> createState() => _QueueViewState();
}

class _QueueViewState extends State<QueueView> {
  final _nameController = TextEditingController();
  final _scrollController = ScrollController();
  String? _errorText;

  @override
  void dispose() {
    _nameController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _addPlayer(AppStateProvider appState) async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    setState(() {
      _errorText = null;
    });

    // Check duplicate in memory first for quick warning
    final exists = appState.allPlayers.any(
      (p) => p.name.toLowerCase() == name.toLowerCase(),
    );

    if (exists) {
      final existingPlayer = appState.allPlayers.firstWhere(
        (p) => p.name.toLowerCase() == name.toLowerCase(),
      );
      
      if (existingPlayer.status == 'waiting' || existingPlayer.status == 'playing') {
        setState(() {
          _errorText = "'$name' is already active in the system.";
        });
        return;
      }
      
      // If player exists but is inactive/absent, re-activate them to waiting
      await appState.changePlayerStatus(existingPlayer.id!, 'waiting');
      _nameController.clear();
      _scrollToBottom();
      return;
    }

    final success = await appState.registerPlayer(name);
    if (success) {
      _nameController.clear();
      _scrollToBottom();
    } else {
      setState(() {
        _errorText = "Failed to add player. Name might be taken.";
      });
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppStateProvider>(context);

    // Filter absent/inactive players
    final inactivePlayers = appState.allPlayers
        .where((p) => p.status == 'inactive' || p.status == 'absent')
        .toList();

    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left Column: Player Registration & Quick-Add Inactive Players
          Expanded(
            flex: 1,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "PLAYER REGISTRATION",
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textSecondary,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 16),
                GlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        "Register New Player",
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _nameController,
                        style: const TextStyle(color: AppTheme.textPrimary),
                        decoration: InputDecoration(
                          labelText: "Player Full Name",
                          hintText: "e.g. John Doe",
                          errorText: _errorText,
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () => _nameController.clear(),
                          ),
                        ),
                        onSubmitted: (_) => _addPlayer(appState),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: () => _addPlayer(appState),
                        icon: const Icon(Icons.person_add_alt_1, size: 18),
                        label: const Text("ADD TO QUEUE"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.neonLime,
                          foregroundColor: Colors.black,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  "INACTIVE / ABSENT REGISTRY",
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
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: inactivePlayers.isEmpty
                        ? const Center(
                            child: Text(
                              "No inactive players in database.",
                              style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                              textAlign: TextAlign.center,
                            ),
                          )
                        : ListView.separated(
                            itemCount: inactivePlayers.length,
                            separatorBuilder: (context, idx) => const Divider(height: 8, color: AppTheme.borderMuted),
                            itemBuilder: (context, idx) {
                              final player = inactivePlayers[idx];
                              return Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          player.name,
                                          style: const TextStyle(
                                            fontFamily: 'Outfit',
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color: AppTheme.textPrimary,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        Text(
                                          player.status.toUpperCase(),
                                          style: TextStyle(
                                            fontFamily: 'Inter',
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: player.status == 'absent'
                                                ? AppTheme.coralRed
                                                : AppTheme.textSecondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      // Re-add Button
                                      IconButton(
                                        icon: const Icon(Icons.add_circle_outline, size: 18, color: AppTheme.neonLime),
                                        tooltip: 'Check In / Add to Queue',
                                        onPressed: () {
                                          appState.changePlayerStatus(player.id!, 'waiting');
                                        },
                                      ),
                                      // Delete Button
                                      IconButton(
                                        icon: const Icon(Icons.delete_forever, size: 18, color: AppTheme.coralRed),
                                        tooltip: 'Delete Player Permanently',
                                        onPressed: () {
                                          appState.removePlayer(player.id!);
                                        },
                                      ),
                                    ],
                                  )
                                ],
                              );
                            },
                          ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 24),
          // Right Column: Active Waiting Queue List
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "ACTIVE WAITING QUEUE (${appState.waitingQueue.length})",
                      style: const TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textSecondary,
                        letterSpacing: 1.2,
                      ),
                    ),
                    if (appState.waitingQueue.isNotEmpty)
                      TextButton.icon(
                        onPressed: () {
                          // Skip all/re-evaluate
                          _showClearQueueConfirm(context, appState);
                        },
                        icon: const Icon(Icons.clear_all, size: 16),
                        label: const Text("CLEAR QUEUE"),
                        style: TextButton.styleFrom(foregroundColor: AppTheme.coralRed),
                      )
                  ],
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: appState.waitingQueue.isEmpty
                      ? GlassCard(
                          child: const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.hourglass_empty, color: AppTheme.textSecondary, size: 36),
                                SizedBox(height: 16),
                                Text(
                                  "Queue is empty",
                                  style: TextStyle(
                                    fontFamily: 'Outfit',
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                    color: AppTheme.textPrimary,
                                  ),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  "Registered players will appear here in chronological order.",
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
                      : ListView.builder(
                          controller: _scrollController,
                          itemCount: appState.waitingQueue.length,
                          itemBuilder: (context, index) {
                            final player = appState.waitingQueue[index];
                            return QueueListTile(
                              player: player,
                              index: index,
                              onSkip: () => appState.skipPlayer(player.id!),
                              onRemove: () {
                                // Mark as absent rather than delete
                                appState.changePlayerStatus(player.id!, 'absent');
                              },
                              onMoveUp: index > 0
                                  ? () => appState.movePlayerUp(index)
                                  : null,
                              onMoveDown: index < appState.waitingQueue.length - 1
                                  ? () => appState.movePlayerDown(index)
                                  : null,
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

  void _showClearQueueConfirm(BuildContext context, AppStateProvider appState) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Clear Active Queue"),
          content: const Text("Do you want to clear all players currently waiting in the queue? They will be marked as inactive but kept in the player registry."),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("CANCEL", style: TextStyle(color: AppTheme.textSecondary)),
            ),
            ElevatedButton(
              onPressed: () {
                for (final player in appState.waitingQueue) {
                  appState.changePlayerStatus(player.id!, 'inactive');
                }
                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.coralRed),
              child: const Text("CLEAR ALL", style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }
}
