import 'package:flutter/material.dart';
import '../models/api_request.dart';
import '../models/api_response.dart';
import '../models/collection_item.dart';
import '../services/http_client_service.dart';
import 'method_chip.dart';
import 'status_badge.dart';

class RunResult {
  final ApiRequest request;
  final ApiResponse response;

  RunResult({required this.request, required this.response});
}

class RunnerDialog extends StatefulWidget {
  final CollectionItem collection;
  final Map<String, String> variables;

  const RunnerDialog({
    super.key,
    required this.collection,
    required this.variables,
  });

  @override
  State<RunnerDialog> createState() => _RunnerDialogState();
}

class _RunnerDialogState extends State<RunnerDialog> {
  bool _isRunning = false;
  int _currentIndex = 0;
  final List<RunResult> _results = [];
  late List<ApiRequest> _requestsToRun;
  final Stopwatch _totalStopwatch = Stopwatch();

  @override
  void initState() {
    super.initState();
    _requestsToRun = _collectAllRequests(widget.collection);
  }

  List<ApiRequest> _collectAllRequests(CollectionItem item) {
    final list = <ApiRequest>[];
    if (item.type == CollectionItemType.request && item.request != null) {
      list.add(item.request!);
    }
    for (final child in item.children) {
      list.addAll(_collectAllRequests(child));
    }
    return list;
  }

  Future<void> _startRun() async {
    if (_isRunning || _requestsToRun.isEmpty) return;

    setState(() {
      _isRunning = true;
      _currentIndex = 0;
      _results.clear();
      _totalStopwatch.reset();
      _totalStopwatch.start();
    });

    for (int i = 0; i < _requestsToRun.length; i++) {
      if (!_isRunning) break; // cancelled
      setState(() => _currentIndex = i);

      final req = _requestsToRun[i];
      final resp = await HttpClientService.executeRequest(
        req,
        variables: widget.variables,
      );

      _results.add(RunResult(request: req, response: resp));
      if (mounted) setState(() {});
    }

    _totalStopwatch.stop();
    if (mounted) {
      setState(() {
        _isRunning = false;
        _currentIndex = _requestsToRun.length;
      });
    }
  }

  void _cancelRun() {
    setState(() => _isRunning = false);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);

    final totalReqs = _requestsToRun.length;
    final completedReqs = _results.length;
    final progress = totalReqs > 0 ? (completedReqs / totalReqs) : 0.0;

    int totalAssertions = 0;
    int passedAssertions = 0;
    for (final r in _results) {
      totalAssertions += r.response.assertionResults.length;
      passedAssertions +=
          r.response.assertionResults.where((a) => a.passed).length;
    }

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 780, maxHeight: 620),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.playlist_play, size: 22),
                      const SizedBox(width: 8),
                      Text(
                        'Collection Runner: ${widget.collection.name}',
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 18),
                    onPressed: () {
                      _cancelRun();
                      Navigator.pop(context);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Control & Progress Bar
              Row(
                children: [
                  if (!_isRunning && completedReqs == 0)
                    ElevatedButton.icon(
                      onPressed: _requestsToRun.isNotEmpty ? _startRun : null,
                      icon: const Icon(Icons.play_arrow, size: 16),
                      label: Text('Run $totalReqs Requests'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).primaryColor,
                        foregroundColor: Colors.white,
                      ),
                    )
                  else if (_isRunning)
                    ElevatedButton.icon(
                      onPressed: _cancelRun,
                      icon: const Icon(Icons.stop, size: 16),
                      label: const Text('Cancel Run'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        foregroundColor: Colors.white,
                      ),
                    )
                  else
                    ElevatedButton.icon(
                      onPressed: _startRun,
                      icon: const Icon(Icons.replay, size: 16),
                      label: const Text('Rerun Collection'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).primaryColor,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: progress,
                            minHeight: 8,
                            backgroundColor: isDark
                                ? const Color(0xFF1E293B)
                                : const Color(0xFFE2E8F0),
                            color: Theme.of(context).primaryColor,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _isRunning && _currentIndex < totalReqs
                                  ? 'Running (${_currentIndex + 1}/$totalReqs): ${_requestsToRun[_currentIndex].name}'
                                  : '$completedReqs of $totalReqs completed',
                              style: const TextStyle(
                                  fontSize: 11, color: Colors.grey),
                            ),
                            if (totalAssertions > 0)
                              Text(
                                'Assertions: $passedAssertions / $totalAssertions passed',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: passedAssertions == totalAssertions
                                      ? const Color(0xFF10B981)
                                      : const Color(0xFFEF4444),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              const Divider(height: 1),

              // Results List
              Expanded(
                child: _results.isEmpty
                    ? Center(
                        child: Text(
                          _isRunning
                              ? 'Executing first request...'
                              : 'Press "Run $totalReqs Requests" to execute all tests in this collection.',
                          style: const TextStyle(color: Colors.grey),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemCount: _results.length,
                        separatorBuilder: (_, __) =>
                            Divider(height: 1, color: borderColor),
                        itemBuilder: (context, idx) {
                          final item = _results[idx];
                          final passCount = item.response.assertionResults
                              .where((a) => a.passed)
                              .length;
                          final totalCount =
                              item.response.assertionResults.length;
                          final allPassed =
                              totalCount == 0 || passCount == totalCount;

                          return ExpansionTile(
                            dense: true,
                            leading: Icon(
                              allPassed ? Icons.check_circle : Icons.cancel,
                              color: allPassed
                                  ? const Color(0xFF10B981)
                                  : const Color(0xFFEF4444),
                              size: 18,
                            ),
                            title: Row(
                              children: [
                                MethodChip(
                                  method: item.request.method,
                                  fontSize: 9,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 4, vertical: 1),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    item.request.name,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                StatusBadge(
                                  statusCode: item.response.statusCode,
                                  statusMessage: item.response.statusMessage,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '${item.response.responseTimeMs}ms',
                                  style: const TextStyle(
                                      fontFamily: 'monospace',
                                      fontSize: 11,
                                      color: Colors.grey),
                                ),
                              ],
                            ),
                            subtitle: totalCount > 0
                                ? Text(
                                    '$passCount / $totalCount tests passed',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: allPassed
                                          ? const Color(0xFF10B981)
                                          : const Color(0xFFEF4444),
                                    ),
                                  )
                                : null,
                            children: [
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 8),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'URL: ${item.request.url}',
                                      style: const TextStyle(
                                          fontFamily: 'monospace',
                                          fontSize: 11),
                                    ),
                                    const SizedBox(height: 6),
                                    if (item.response.assertionResults.isNotEmpty)
                                      ...item.response.assertionResults.map((a) {
                                        return Padding(
                                          padding: const EdgeInsets.only(top: 2),
                                          child: Row(
                                            children: [
                                              Icon(
                                                a.passed
                                                    ? Icons.check
                                                    : Icons.close,
                                                size: 14,
                                                color: a.passed
                                                    ? Colors.green
                                                    : Colors.red,
                                              ),
                                              const SizedBox(width: 6),
                                              Expanded(
                                                child: Text(
                                                  a.message,
                                                  style: const TextStyle(
                                                      fontSize: 11),
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                      })
                                    else
                                      const Text(
                                        'No assertions defined for this request.',
                                        style: TextStyle(
                                            fontSize: 11, color: Colors.grey),
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
