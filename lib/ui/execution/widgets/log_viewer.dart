import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../execution/log_line.dart';
import '../../shell/app_theme.dart';

class LogViewer extends StatefulWidget {
  final List<LogLine> logs;
  final bool autoScroll;

  const LogViewer({
    super.key,
    required this.logs,
    this.autoScroll = true,
  });

  @override
  State<LogViewer> createState() => _LogViewerState();
}

class _LogViewerState extends State<LogViewer> {
  final ScrollController _scroll = ScrollController();
  bool _userScrolled = false;

  @override
  void didUpdateWidget(LogViewer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.autoScroll &&
        !_userScrolled &&
        widget.logs.length != oldWidget.logs.length) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scroll.hasClients) {
          _scroll.jumpTo(_scroll.position.maxScrollExtent);
        }
      });
    }
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  Color _colorFor(LogLevel level) {
    switch (level) {
      case LogLevel.error:
        return AppTheme.logError;
      case LogLevel.warning:
        return AppTheme.logWarning;
      case LogLevel.success:
        return AppTheme.logSuccess;
      case LogLevel.debug:
        return AppTheme.logDebug;
      case LogLevel.info:
        return AppTheme.logInfo;
    }
  }

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollNotification>(
      onNotification: (n) {
        if (n is UserScrollNotification && !_userScrolled) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) setState(() => _userScrolled = true);
          });
        }
        return false;
      },
      child: Container(
        color: const Color(0xFF0D1117),
        child: Stack(
          children: [
            SelectionArea(
              child: ListView.builder(
                controller: _scroll,
                padding: const EdgeInsets.all(12),
                itemCount: widget.logs.length,
                itemBuilder: (_, i) {
                  final line = widget.logs[i];
                  return _LogLineWidget(
                      line: line, color: _colorFor(line.level));
                },
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: Row(
                children: [
                  if (_userScrolled)
                    _ToolbarButton(
                      icon: Icons.arrow_downward,
                      tooltip: 'Scroll to bottom',
                      onTap: () {
                        setState(() => _userScrolled = false);
                        _scroll.jumpTo(_scroll.position.maxScrollExtent);
                      },
                    ),
                  const SizedBox(width: 4),
                  _ToolbarButton(
                    icon: Icons.copy,
                    tooltip: 'Copy all logs',
                    onTap: () {
                      final text = widget.logs
                          .map((l) => l.toString())
                          .join('\n');
                      Clipboard.setData(ClipboardData(text: text));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Logs copied to clipboard'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LogLineWidget extends StatelessWidget {
  final LogLine line;
  final Color color;

  const _LogLineWidget({required this.line, required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${_time(line.timestamp)} ',
            style: const TextStyle(
              color: Color(0xFF8B949E),
              fontSize: 11,
              fontFamily: 'monospace',
            ),
          ),
          Expanded(
            child: Text(
              line.message,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontFamily: 'monospace',
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _time(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    final s = dt.second.toString().padLeft(2, '0');
    return '$h:$m:$s';
  }
}

class _ToolbarButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  const _ToolbarButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(4),
        child: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: const Color(0xFF21262D),
            borderRadius: BorderRadius.circular(4),
            border: const Border.fromBorderSide(
                BorderSide(color: Color(0xFF30363D))),
          ),
          child: Icon(icon, size: 14, color: const Color(0xFF8B949E)),
        ),
      ),
    );
  }
}
