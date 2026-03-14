enum ReportType {
  clubPost,
  event,
  forumQuestion,
  comment,
  user
}

enum ReportReason {
  spam,
  harassment,
  inappropriate,
  misinformation,
  other
}

enum ReportStatus {
  pending,
  resolved,
  dismissed
}

class Report {
  final String id;
  final String targetId;
  final ReportType type;
  final ReportReason reason;
  final String description;
  final String reporterId;
  final DateTime timestamp;
  final ReportStatus status;
  final String? resolvedBy;
  final DateTime? resolvedAt;

  // Metadata for display
  final String targetTitle;
  final String targetPreview;

  Report({
    required this.id,
    required this.targetId,
    required this.type,
    required this.reason,
    required this.description,
    required this.reporterId,
    required this.timestamp,
    this.status = ReportStatus.pending,
    this.resolvedBy,
    this.resolvedAt,
    required this.targetTitle,
    required this.targetPreview,
  });

  Report copyWith({
    String? id,
    String? targetId,
    ReportType? type,
    ReportReason? reason,
    String? description,
    String? reporterId,
    DateTime? timestamp,
    ReportStatus? status,
    String? resolvedBy,
    DateTime? resolvedAt,
    String? targetTitle,
    String? targetPreview,
  }) {
    return Report(
      id: id ?? this.id,
      targetId: targetId ?? this.targetId,
      type: type ?? this.type,
      reason: reason ?? this.reason,
      description: description ?? this.description,
      reporterId: reporterId ?? this.reporterId,
      timestamp: timestamp ?? this.timestamp,
      status: status ?? this.status,
      resolvedBy: resolvedBy ?? this.resolvedBy,
      resolvedAt: resolvedAt ?? this.resolvedAt,
      targetTitle: targetTitle ?? this.targetTitle,
      targetPreview: targetPreview ?? this.targetPreview,
    );
  }
}
