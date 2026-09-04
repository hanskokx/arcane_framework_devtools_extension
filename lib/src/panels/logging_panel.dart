import "dart:async";

import "package:arcane_framework/arcane_framework.dart";
import "package:arcane_framework_devtools_extension/src/common/shared_widgets.dart";
import "package:flutter/material.dart";

class LoggingPanel extends StatefulWidget {
  const LoggingPanel({super.key});

  @override
  State<LoggingPanel> createState() => _LoggingPanelState();
}

class _LoggingPanelState extends State<LoggingPanel> {
  final List<_LogEntry> _entries = [];
  StreamSubscription<String>? _subscription;
  Level _minLevel = Level.debug;
  String _searchQuery = "";
  final ScrollController _scrollController = ScrollController();
  bool _autoScroll = true;

  @override
  void initState() {
    super.initState();
    _subscription = Arcane.logger.logStream.listen((message) {
      final entry = _LogEntry(
        timestamp: DateTime.now(),
        message: message,
      );
      setState(() => _entries.add(entry));
      if (_autoScroll && _scrollController.hasClients) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_scrollController.hasClients) {
            _scrollController.jumpTo(
              _scrollController.position.maxScrollExtent,
            );
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  List<_LogEntry> get _filteredEntries {
    return _entries.where((entry) {
      if (_searchQuery.isNotEmpty &&
          !entry.message.toLowerCase().contains(
                _searchQuery.toLowerCase(),
              )) {
        return false;
      }
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredEntries;
    return Column(
      children: [
        _LogToolbar(
          minLevel: _minLevel,
          searchQuery: _searchQuery,
          autoScroll: _autoScroll,
          entryCount: filtered.length,
          onLevelChanged: (level) => setState(() => _minLevel = level),
          onSearchChanged: (query) => setState(() => _searchQuery = query),
          onAutoScrollChanged: (value) => setState(() => _autoScroll = value),
          onClear: () => setState(() => _entries.clear()),
        ),
        Expanded(
          child: filtered.isEmpty
              ? const EmptyState(
                  message: "No log entries yet.\n"
                      "Logs from Arcane.log(...) will appear here.",
                )
              : ListView.builder(
                  controller: _scrollController,
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final entry = filtered[index];
                    return _LogEntryTile(entry: entry);
                  },
                ),
        ),
      ],
    );
  }
}

class _LogEntry {
  _LogEntry({required this.timestamp, required this.message});

  final DateTime timestamp;
  final String message;
}

class _LogToolbar extends StatelessWidget {
  const _LogToolbar({
    required this.minLevel,
    required this.searchQuery,
    required this.autoScroll,
    required this.entryCount,
    required this.onLevelChanged,
    required this.onSearchChanged,
    required this.onAutoScrollChanged,
    required this.onClear,
  });

  final Level minLevel;
  final String searchQuery;
  final bool autoScroll;
  final int entryCount;
  final ValueChanged<Level> onLevelChanged;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<bool> onAutoScrollChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          children: [
            SizedBox(
              width: 100,
              child: DropdownButton<Level>(
                value: minLevel,
                isDense: true,
                underline: const SizedBox.shrink(),
                items: const [
                  DropdownMenuItem(value: Level.debug, child: Text("Debug")),
                  DropdownMenuItem(value: Level.info, child: Text("Info")),
                  DropdownMenuItem(
                    value: Level.warning,
                    child: Text("Warning"),
                  ),
                  DropdownMenuItem(value: Level.error, child: Text("Error")),
                  DropdownMenuItem(value: Level.fatal, child: Text("Fatal")),
                ],
                onChanged: (level) {
                  if (level != null) onLevelChanged(level);
                },
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: SizedBox(
                height: 32,
                child: TextField(
                  decoration: InputDecoration(
                    hintText: "Search logs...",
                    prefixIcon: const Icon(Icons.search, size: 16),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  onChanged: onSearchChanged,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              "$entryCount entries",
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: Icon(
                autoScroll ? Icons.vertical_align_bottom : Icons.pause,
                size: 16,
              ),
              tooltip: autoScroll ? "Auto-scroll on" : "Auto-scroll off",
              onPressed: () => onAutoScrollChanged(!autoScroll),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, size: 16),
              tooltip: "Clear logs",
              onPressed: onClear,
            ),
          ],
        ),
      ),
    );
  }
}

class _LogEntryTile extends StatelessWidget {
  const _LogEntryTile({required this.entry});

  final _LogEntry entry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).dividerColor.withValues(alpha: 0.3),
          ),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _formatTime(entry.timestamp),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontFamily: "monospace",
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              entry.message,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontFamily: "monospace",
                  ),
              softWrap: true,
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    return "${time.hour.toString().padLeft(2, "0")}:"
        "${time.minute.toString().padLeft(2, "0")}:"
        "${time.second.toString().padLeft(2, "0")}."
        "${time.millisecond.toString().padLeft(3, "0")}";
  }
}
