import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_card.dart';

class CourtView extends StatefulWidget {
  const CourtView({super.key});

  @override
  State<CourtView> createState() => _CourtViewState();
}

class _CourtViewState extends State<CourtView> {
  final _nameController = TextEditingController();
  final _numberController = TextEditingController();
  String? _errorText;

  @override
  void dispose() {
    _nameController.dispose();
    _numberController.dispose();
    super.dispose();
  }

  Future<void> _addCourt(AppStateProvider appState) async {
    final name = _nameController.text.trim();
    final numberStr = _numberController.text.trim();
    if (name.isEmpty || numberStr.isEmpty) return;

    final number = int.tryParse(numberStr);
    if (number == null || number <= 0) {
      setState(() {
        _errorText = "Please enter a valid positive court number.";
      });
      return;
    }

    setState(() {
      _errorText = null;
    });

    final success = await appState.registerCourt(name, number);
    if (success) {
      _nameController.clear();
      _numberController.clear();
    } else {
      setState(() {
        _errorText = "Failed to add. Court number might already exist.";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppStateProvider>(context);

    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left Column: Add New Court
          Expanded(
            flex: 1,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "ADD COURT",
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
                        "Register New Court",
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _numberController,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(color: AppTheme.textPrimary),
                        decoration: const InputDecoration(
                          labelText: "Court Number",
                          hintText: "e.g. 5",
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _nameController,
                        style: const TextStyle(color: AppTheme.textPrimary),
                        decoration: const InputDecoration(
                          labelText: "Court Name",
                          hintText: "e.g. Court 5",
                        ),
                      ),
                      if (_errorText != null) ...[
                        const SizedBox(height: 12),
                        Text(
                          _errorText!,
                          style: const TextStyle(color: AppTheme.coralRed, fontSize: 12),
                        ),
                      ],
                      const SizedBox(height: 20),
                      ElevatedButton.icon(
                        onPressed: () => _addCourt(appState),
                        icon: const Icon(Icons.add_box, size: 18),
                        label: const Text("REGISTER COURT"),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 24),
          // Right Column: Courts List & Toggles
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "COURT DIRECTORY & CONTROL",
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
                  child: appState.courts.isEmpty
                      ? GlassCard(
                          child: const Center(
                            child: Text(
                              "No courts registered.",
                              style: TextStyle(color: AppTheme.textSecondary),
                            ),
                          ),
                        )
                      : ListView.builder(
                          itemCount: appState.courts.length,
                          itemBuilder: (context, index) {
                            final court = appState.courts[index];
                            
                            Color statusColor;
                            IconData statusIcon;

                            if (court.status == 'available') {
                              statusColor = const Color(0xFF00FF85);
                              statusIcon = Icons.check_circle;
                            } else if (court.status == 'occupied') {
                              statusColor = AppTheme.electricTeal;
                              statusIcon = Icons.sports_tennis;
                            } else {
                              statusColor = AppTheme.coralRed;
                              statusIcon = Icons.build;
                            }

                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              decoration: AppTheme.glassCard(
                                color: AppTheme.slateCard,
                                radius: 12,
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: statusColor.withOpacity(0.08),
                                        shape: BoxShape.circle,
                                        border: Border.all(color: statusColor.withOpacity(0.2)),
                                      ),
                                      child: Icon(statusIcon, color: statusColor, size: 20),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            court.name,
                                            style: const TextStyle(
                                              fontFamily: 'Outfit',
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: AppTheme.textPrimary,
                                            ),
                                          ),
                                          Text(
                                            "Status: ${court.status.toUpperCase()}",
                                            style: TextStyle(
                                              fontFamily: 'Inter',
                                              fontSize: 12,
                                              color: statusColor,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    // Control Toggles
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        // Set Available
                                        if (court.status != 'available')
                                          TextButton.icon(
                                            onPressed: () {
                                              appState.updateCourtStatus(court.id!, 'available');
                                            },
                                            icon: const Icon(Icons.check, size: 14),
                                            label: const Text("AVAILABLE"),
                                            style: TextButton.styleFrom(
                                              foregroundColor: const Color(0xFF00FF85),
                                            ),
                                          ),
                                        // Set Maintenance
                                        if (court.status != 'maintenance')
                                          TextButton.icon(
                                            onPressed: () {
                                              _showMaintenanceConfirm(context, appState, court.id!);
                                            },
                                            icon: const Icon(Icons.build, size: 14),
                                            label: const Text("MAINTENANCE"),
                                            style: TextButton.styleFrom(
                                              foregroundColor: AppTheme.coralRed,
                                            ),
                                          ),
                                        const SizedBox(width: 8),
                                        // Delete Court
                                        IconButton(
                                          icon: const Icon(Icons.delete_outline, size: 18, color: AppTheme.textSecondary),
                                          tooltip: 'Delete Court',
                                          onPressed: () {
                                            _showDeleteConfirm(context, appState, court.id!);
                                          },
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
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

  void _showMaintenanceConfirm(BuildContext context, AppStateProvider appState, int courtId) {
    // Check if court has active match
    final activeMatchIdx = appState.activeMatches.indexWhere((m) => m.courtId == courtId);
    final hasActiveMatch = activeMatchIdx != -1;

    if (!hasActiveMatch) {
      appState.updateCourtStatus(courtId, 'maintenance');
      return;
    }

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Set Court to Maintenance"),
          content: const Text(
            "This court currently has an active match. Setting it to maintenance will immediately complete the match and move the players to the back of the queue. Do you want to proceed?",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("CANCEL", style: TextStyle(color: AppTheme.textSecondary)),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                appState.updateCourtStatus(courtId, 'maintenance');
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.coralRed),
              child: const Text("CONFIRM & CLOSE GAME", style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  void _showDeleteConfirm(BuildContext context, AppStateProvider appState, int courtId) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Delete Court"),
          content: const Text(
            "Are you sure you want to permanently delete this court? This action cannot be undone.",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("CANCEL", style: TextStyle(color: AppTheme.textSecondary)),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                appState.deleteCourt(courtId);
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.coralRed),
              child: const Text("DELETE", style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }
}
