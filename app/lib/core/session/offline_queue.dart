import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../session/secure_storage.dart';
import '../enums/app_enums.dart';
import '../../state/connectivity_provider.dart';

/// P4-02: Offline Queue
/// Stores failed API calls locally and replays them when connectivity is restored.
class OfflineQueue {
  static const _storageKey = 'gc_offline_queue';

  /// Queued API call entry
  static Future<void> enqueue(QueuedRequest request) async {
    final existing = await _loadQueue();
    existing.add(request);
    await _saveQueue(existing);
  }

  /// Replay all queued requests
  /// Returns number of successfully replayed requests
  static Future<int> replayAll(Future<bool> Function(QueuedRequest) executor) async {
    final queue = await _loadQueue();
    if (queue.isEmpty) return 0;

    int replayed = 0;
    final remaining = <QueuedRequest>[];

    for (final request in queue) {
      try {
        final success = await executor(request);
        if (success) {
          replayed++;
        } else {
          remaining.add(request);
        }
      } catch (_) {
        remaining.add(request); // Keep for next attempt
      }
    }

    await _saveQueue(remaining);
    return replayed;
  }

  static Future<int> get pendingCount async {
    final queue = await _loadQueue();
    return queue.length;
  }

  static Future<void> clear() async {
    await SecureStorage.saveProfile({}); // Reuse storage for simplicity
  }

  // Internal persistence
  static Future<List<QueuedRequest>> _loadQueue() async {
    try {
      final data = await SecureStorage.loadProfile();
      if (data == null || !data.containsKey('_offlineQueue')) return [];
      final list = data['_offlineQueue'] as List;
      return list.map((e) => QueuedRequest.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> _saveQueue(List<QueuedRequest> queue) async {
    // Store in a dedicated key via secure storage
    // For simplicity we use the profile storage with a special key
    final json = queue.map((q) => q.toJson()).toList();
    await SecureStorage.saveProfile({'_offlineQueue': json});
  }
}

class QueuedRequest {
  final String endpoint;
  final String method;
  final Map<String, dynamic> payload;
  final DateTime createdAt;

  const QueuedRequest({
    required this.endpoint,
    required this.method,
    required this.payload,
    required this.createdAt,
  });

  factory QueuedRequest.fromJson(Map<String, dynamic> json) => QueuedRequest(
    endpoint: json['endpoint'] as String,
    method: json['method'] as String,
    payload: json['payload'] as Map<String, dynamic>,
    createdAt: DateTime.parse(json['createdAt'] as String),
  );

  Map<String, dynamic> toJson() => {
    'endpoint': endpoint,
    'method': method,
    'payload': payload,
    'createdAt': createdAt.toIso8601String(),
  };
}

/// Provider that monitors connectivity and replays queue
class OfflineQueueNotifier extends StateNotifier<int> {
  final Ref _ref;
  OfflineQueueNotifier(this._ref) : super(0) {
    _init();
  }

  Future<void> _init() async {
    state = await OfflineQueue.pendingCount;
  }

  Future<void> enqueueRequest(QueuedRequest request) async {
    await OfflineQueue.enqueue(request);
    state = await OfflineQueue.pendingCount;
  }

  Future<void> replayIfOnline() async {
    final connectivity = _ref.read(connectivityProvider);
    if (connectivity != ConnectivityStatus.online) return;

    await OfflineQueue.replayAll((request) async {
      // In a real app, this would call the actual API
      // For demo, we always succeed
      return true;
    });
    state = await OfflineQueue.pendingCount;
  }
}

final offlineQueueProvider = StateNotifierProvider<OfflineQueueNotifier, int>((ref) {
  return OfflineQueueNotifier(ref);
});
