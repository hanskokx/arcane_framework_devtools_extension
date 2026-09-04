import "dart:async";
import "dart:js_interop";

import "package:arcane_framework/arcane_framework.dart";
import "package:arcane_framework_devtools_extension/src/common/shared_widgets.dart";
import "package:flutter/material.dart";
import "package:web/web.dart" as web;

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
  bool _showMetadata = false;
  LoggingInterface? _selectedInterface;

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

  void _downloadLogs() {
    final filtered = _filteredEntries;
    if (filtered.isEmpty) {
      return;
    }
    final buffer = StringBuffer();
    for (final entry in filtered) {
      buffer.writeln(
        "[${_formatFullTimestamp(entry.timestamp)}] ${entry.message}",
      );
    }
    final timestamp = DateTime.now()
        .toIso8601String()
        .replaceAll(":", "-")
        .replaceAll(".", "-");
    downloadTextFile(
      content: buffer.toString(),
      filename: "arcane-logs-$timestamp.txt",
    );
  }

  String _formatFullTimestamp(DateTime time) {
    return "${time.year.toString().padLeft(4, "0")}-"
        "${time.month.toString().padLeft(2, "0")}-"
        "${time.day.toString().padLeft(2, "0")} "
        "${time.hour.toString().padLeft(2, "0")}:"
        "${time.minute.toString().padLeft(2, "0")}:"
        "${time.second.toString().padLeft(2, "0")}."
        "${time.millisecond.toString().padLeft(3, "0")}";
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredEntries;
    final interfaces = Arcane.logger.interfaces;
    final metadata = Arcane.logger.additionalMetadata;
    return Column(
      children: [
        if (interfaces.isNotEmpty || metadata.isNotEmpty)
          _LoggerInfoSection(
            interfaces: interfaces,
            metadata: metadata,
            selectedInterface: _selectedInterface,
            showMetadata: _showMetadata,
            onInterfaceSelected: (iface) {
              setState(() {
                _selectedInterface = _selectedInterface == iface ? null : iface;
              });
            },
            onToggleMetadata: () {
              setState(() => _showMetadata = !_showMetadata);
            },
          ),
        _LogToolbar(
          minLevel: _minLevel,
          searchQuery: _searchQuery,
          autoScroll: _autoScroll,
          entryCount: filtered.length,
          onLevelChanged: (level) => setState(() => _minLevel = level),
          onSearchChanged: (query) => setState(() => _searchQuery = query),
          onAutoScrollChanged: (value) => setState(() => _autoScroll = value),
          onClear: () => setState(() => _entries.clear()),
          onDownload: _downloadLogs,
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

class _LoggerInfoSection extends StatelessWidget {
  const _LoggerInfoSection({
    required this.interfaces,
    required this.metadata,
    required this.selectedInterface,
    required this.showMetadata,
    required this.onInterfaceSelected,
    required this.onToggleMetadata,
  });

  final List<LoggingInterface> interfaces;
  final Map<String, String> metadata;
  final LoggingInterface? selectedInterface;
  final bool showMetadata;
  final ValueChanged<LoggingInterface> onInterfaceSelected;
  final VoidCallback onToggleMetadata;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (interfaces.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Text(
                "Registered Interfaces",
                style: theme.textTheme.titleSmall?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          if (interfaces.isNotEmpty)
            ...interfaces.map(
              (iface) => _InterfaceTile(
                interface: iface,
                isSelected: selectedInterface == iface,
                onTap: () => onInterfaceSelected(iface),
              ),
            ),
          if (selectedInterface != null)
            _InterfaceDetailCard(interface: selectedInterface!),
          if (metadata.isNotEmpty) ...[
            InkWell(
              onTap: onToggleMetadata,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                child: Row(
                  children: [
                    Icon(
                      showMetadata ? Icons.expand_more : Icons.chevron_right,
                      size: 16,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      "Persistent Metadata (${metadata.length})",
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (showMetadata)
              ...metadata.entries.map(
                (entry) => Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 2,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          entry.key,
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Flexible(
                        child: Text(
                          entry.value,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
          if (interfaces.isNotEmpty || metadata.isNotEmpty)
            const Divider(height: 1),
        ],
      ),
    );
  }
}

class _InterfaceTile extends StatelessWidget {
  const _InterfaceTile({
    required this.interface,
    required this.isSelected,
    required this.onTap,
  });

  final LoggingInterface interface;
  final bool isSelected;
  final VoidCallback onTap;

  String get _interfaceName {
    if (interface is LoggerName) {
      return (interface as LoggerName).name;
    }
    return interface.runtimeType.toString();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: isSelected
          ? theme.colorScheme.primaryContainer.withValues(alpha: 0.3)
          : null,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Icon(
                Icons.circle,
                size: 8,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _interfaceName,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Text(
                interface.runtimeType.toString(),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                isSelected ? Icons.expand_less : Icons.chevron_right,
                size: 16,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InterfaceDetailCard extends StatelessWidget {
  const _InterfaceDetailCard({required this.interface});

  final LoggingInterface interface;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final typeName = interface.runtimeType.toString();
    final name =
        interface is LoggerName ? (interface as LoggerName).name : "(no name)";
    final isInitializable = interface is LoggingInitializable;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _DetailRow(label: "Type", value: typeName),
          _DetailRow(label: "Name", value: name),
          _DetailRow(
            label: "Initializable",
            value: isInitializable ? "Yes" : "No",
          ),
          if (isInitializable)
            _DetailRow(
              label: "Initialized",
              value: (interface as LoggingInitializable).initialized
                  ? "Yes"
                  : "No",
            ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
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
    required this.onDownload,
  });

  final Level minLevel;
  final String searchQuery;
  final bool autoScroll;
  final int entryCount;
  final ValueChanged<Level> onLevelChanged;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<bool> onAutoScrollChanged;
  final VoidCallback onClear;
  final VoidCallback onDownload;

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
            IconButton(
              icon: const Icon(Icons.download_outlined, size: 16),
              tooltip: "Download logs",
              onPressed: onDownload,
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

/// Triggers a browser download of [content] as [filename].
///
/// Intended for web (DevTools extension) builds. Wraps the text in a [Blob],
/// creates an object URL, and programmatically clicks an anchor element.
void downloadTextFile({
  required String content,
  required String filename,
}) {
  final blob = web.Blob(
    [content.toJS].toJS,
    web.BlobPropertyBag(type: "text/plain"),
  );
  final url = web.URL.createObjectURL(blob);
  final anchor = web.HTMLAnchorElement()
    ..href = url
    ..download = filename;
  final body = web.document.body;
  if (body == null) {
    web.URL.revokeObjectURL(url);
    return;
  }
  body.appendChild(anchor);
  anchor.click();
  body.removeChild(anchor);
  web.URL.revokeObjectURL(url);
}
