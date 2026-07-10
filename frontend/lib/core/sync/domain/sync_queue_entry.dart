import 'dart:convert';

enum SyncOperationType { create, update, delete, custom }

enum SyncQueueStatus { pending, syncing, synced, failed }

class SyncQueueEntry {
  SyncQueueEntry({
    required this.id,
    required this.domain,
    required this.operation,
    required this.httpMethod,
    required this.path,
    required this.payload,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.queryParameters = const {},
    this.retryCount = 0,
    this.maxRetryCount = 5,
    this.errorMessage,
    this.errorCode,
    this.lastSyncedAt,
    this.clientUpdatedAt,
    this.idempotencyKey,
  });

  factory SyncQueueEntry.fromMap(Map<String, dynamic> map) {
    return SyncQueueEntry(
      id: map['id'] as String,
      domain: map['domain'] as String,
      operation: SyncOperationType.values.byName(map['operation'] as String),
      httpMethod: map['httpMethod'] as String,
      path: map['path'] as String,
      payload: Map<String, dynamic>.from(
        map['payload'] as Map<dynamic, dynamic>? ?? const {},
      ),
      queryParameters: Map<String, dynamic>.from(
        map['queryParameters'] as Map<dynamic, dynamic>? ?? const {},
      ),
      status: SyncQueueStatus.values.byName(map['status'] as String),
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: DateTime.parse(map['updatedAt'] as String),
      retryCount: map['retryCount'] as int? ?? 0,
      maxRetryCount: map['maxRetryCount'] as int? ?? 5,
      errorMessage: map['errorMessage'] as String?,
      errorCode: map['errorCode'] as String?,
      lastSyncedAt: _parseDateTime(map['lastSyncedAt'] as String?),
      clientUpdatedAt: _parseDateTime(map['clientUpdatedAt'] as String?),
      // #1117: absent on entries persisted before idempotency support — the
      // ``as String?`` cast yields null, which orphan recovery treats as legacy.
      idempotencyKey: map['idempotencyKey'] as String?,
    );
  }

  final String id;
  final String domain;
  final SyncOperationType operation;
  final String httpMethod;
  final String path;
  final Map<String, dynamic> payload;
  final Map<String, dynamic> queryParameters;
  final SyncQueueStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int retryCount;
  final int maxRetryCount;
  final String? errorMessage;
  final String? errorCode;
  final DateTime? lastSyncedAt;
  final DateTime? clientUpdatedAt;

  /// #1117: client-generated ``Idempotency-Key`` sent with the initial request
  /// and re-sent on replay so the server dedupes a write it already committed.
  final String? idempotencyKey;

  bool get isRetryable => retryCount < maxRetryCount;
  String get requestFingerprint =>
      '$httpMethod $path ${jsonEncode(queryParameters)}';

  SyncQueueEntry copyWith({
    SyncOperationType? operation,
    SyncQueueStatus? status,
    Map<String, dynamic>? payload,
    Map<String, dynamic>? queryParameters,
    int? retryCount,
    int? maxRetryCount,
    String? errorMessage,
    String? errorCode,
    DateTime? lastSyncedAt,
    DateTime? clientUpdatedAt,
  }) {
    return SyncQueueEntry(
      id: id,
      domain: domain,
      operation: operation ?? this.operation,
      httpMethod: httpMethod,
      path: path,
      payload: payload ?? this.payload,
      queryParameters: queryParameters ?? this.queryParameters,
      status: status ?? this.status,
      createdAt: createdAt,
      updatedAt: DateTime.now().toUtc(),
      retryCount: retryCount ?? this.retryCount,
      maxRetryCount: maxRetryCount ?? this.maxRetryCount,
      errorMessage: errorMessage,
      errorCode: errorCode,
      lastSyncedAt: lastSyncedAt,
      clientUpdatedAt: clientUpdatedAt ?? this.clientUpdatedAt,
      // Always preserved — the key is immutable for the life of the entry, so
      // status transitions (syncing → pending on orphan recovery) keep it.
      idempotencyKey: idempotencyKey,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'domain': domain,
      'operation': operation.name,
      'httpMethod': httpMethod,
      'path': path,
      'payload': payload,
      'queryParameters': queryParameters,
      'status': status.name,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'retryCount': retryCount,
      'maxRetryCount': maxRetryCount,
      'errorMessage': errorMessage,
      'errorCode': errorCode,
      'lastSyncedAt': lastSyncedAt?.toIso8601String(),
      'clientUpdatedAt': clientUpdatedAt?.toIso8601String(),
      'idempotencyKey': idempotencyKey,
    };
  }

  static DateTime? _parseDateTime(String? raw) {
    if (raw == null || raw.isEmpty) {
      return null;
    }
    return DateTime.tryParse(raw)?.toUtc();
  }
}
