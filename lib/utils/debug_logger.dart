import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class DebugLogger {
  static final ValueNotifier<List<String>> logs = ValueNotifier([]);

  static void print(String message, {int? wrapWidth}) {
    // Send to standard console
    debugPrintSynchronously(message, wrapWidth: wrapWidth);
    
    // Add to on-screen console
    final currentLogs = List<String>.from(logs.value);
    final timestamp = DateTime.now().toIso8601String().split('T').last.split('.').first;
    currentLogs.add('[$timestamp] $message');
    // Keep only last 100 logs to prevent memory issues
    if (currentLogs.length > 100) {
      currentLogs.removeAt(0);
    }
    logs.value = currentLogs;
  }
}

class DebugConsoleWidget extends StatelessWidget {
  const DebugConsoleWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: Colors.black87,
        border: Border(top: BorderSide(color: Colors.grey.shade800)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            color: Colors.black,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'DEBUG CONSOLE',
                  style: TextStyle(
                    color: Colors.green,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                InkWell(
                  onTap: () => DebugLogger.logs.value = [],
                  child: const Text(
                    'CLEAR',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ValueListenableBuilder<List<String>>(
              valueListenable: DebugLogger.logs,
              builder: (context, logList, _) {
                if (logList.isEmpty) {
                  return const Center(
                    child: Text(
                      'No logs yet.',
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  );
                }
                return ListView.builder(
                  reverse: true, // Auto-scroll to bottom behavior (newest at bottom when reversed list)
                  padding: const EdgeInsets.all(8),
                  itemCount: logList.length,
                  itemBuilder: (context, index) {
                    // Reverse the index so newest logs appear at the bottom when reversed
                    final log = logList[logList.length - 1 - index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        log,
                        style: const TextStyle(
                          color: Colors.greenAccent,
                          fontFamily: 'monospace',
                          fontSize: 11,
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
