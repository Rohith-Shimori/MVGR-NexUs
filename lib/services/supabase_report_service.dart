/// Report Service
/// Handles content reporting for moderation (clubs, events, forum posts, etc.)
library;

import 'package:flutter/foundation.dart';
import '../core/utils/logger.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Report reason categories
enum ReportReason {
  spam('Spam or misleading'),
  harassment('Harassment or bullying'),
  inappropriateContent('Inappropriate content'),
  violatesGuidelines('Violates community guidelines'),
  impersonation('Impersonation'),
  misinformation('Misinformation'),
  other('Other');

  final String displayName;
  const ReportReason(this.displayName);
}

/// Report status
enum ReportStatus {
  pending('Pending Review'),
  underReview('Under Review'),
  actionTaken('Action Taken'),
  dismissed('Dismissed');

  final String displayName;
  const ReportStatus(this.displayName);
}

/// Content report model
class ContentReport {
  final String id;
  final String reporterId;
  final String contentType; // 'club', 'event', 'forum_post', 'comment', etc.
  final String contentId;
  final ReportReason reason;
  final String? additionalDetails;
  final ReportStatus status;
  final DateTime createdAt;
  final DateTime? reviewedAt;
  final String? reviewerId;
  final String? actionNotes;

  const ContentReport({
    required this.id,
    required this.reporterId,
    required this.contentType,
    required this.contentId,
    required this.reason,
    this.additionalDetails,
    this.status = ReportStatus.pending,
    required this.createdAt,
    this.reviewedAt,
    this.reviewerId,
    this.actionNotes,
  });

  factory ContentReport.fromJson(Map<String, dynamic> json) {
    return ContentReport(
      id: json['id'].toString(),
      reporterId: json['reporter_id']?.toString() ?? '',
      contentType: json['content_type']?.toString() ?? '',
      contentId: json['content_id']?.toString() ?? '',
      reason: _parseReason(json['reason']?.toString() ?? 'other'),
      additionalDetails: json['additional_details']?.toString(),
      status: _parseStatus(json['status']?.toString() ?? 'pending'),
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ?? DateTime.now(),
      reviewedAt: json['reviewed_at'] != null
          ? DateTime.tryParse(json['reviewed_at'].toString())
          : null,
      reviewerId: json['reviewer_id']?.toString(),
      actionNotes: json['action_notes']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'reporter_id': reporterId,
        'content_type': contentType,
        'content_id': contentId,
        'reason': reason.name,
        'additional_details': additionalDetails,
        'status': status.name,
        'created_at': createdAt.toIso8601String(),
        'reviewed_at': reviewedAt?.toIso8601String(),
        'reviewer_id': reviewerId,
        'action_notes': actionNotes,
      };

  static ReportReason _parseReason(String reason) {
    return ReportReason.values.firstWhere(
      (r) => r.name == reason.toLowerCase(),
      orElse: () => ReportReason.other,
    );
  }

  static ReportStatus _parseStatus(String status) {
    return ReportStatus.values.firstWhere(
      (s) => s.name == status.toLowerCase(),
      orElse: () => ReportStatus.pending,
    );
  }
}

/// Supabase Report Service
class SupabaseReportService extends ChangeNotifier {
  static final SupabaseReportService _instance = SupabaseReportService._internal();
  static SupabaseReportService get instance => _instance;

  SupabaseReportService._internal();

  final _client = Supabase.instance.client;
  static const _table = 'content_reports';

  List<ContentReport> _reports = [];
  bool _isLoading = false;
  String? _error;

  List<ContentReport> get reports => List.unmodifiable(_reports);
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Report content (club, event, forum post, etc.)
  Future<bool> reportContent({
    required String reporterId,
    required String contentType,
    required String contentId,
    required ReportReason reason,
    String? additionalDetails,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final report = ContentReport(
        id: '',
        reporterId: reporterId,
        contentType: contentType,
        contentId: contentId,
        reason: reason,
        additionalDetails: additionalDetails,
        createdAt: DateTime.now(),
      );

      await _client.from(_table).insert(report.toJson());
      
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      AppLogger.error(' Error submitting report: $e');
      _error = 'Failed to submit report. Please try again.';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Report a club
  Future<bool> reportClub({
    required String reporterId,
    required String clubId,
    required ReportReason reason,
    String? additionalDetails,
  }) {
    return reportContent(
      reporterId: reporterId,
      contentType: 'club',
      contentId: clubId,
      reason: reason,
      additionalDetails: additionalDetails,
    );
  }

  /// Report an event
  Future<bool> reportEvent({
    required String reporterId,
    required String eventId,
    required ReportReason reason,
    String? additionalDetails,
  }) {
    return reportContent(
      reporterId: reporterId,
      contentType: 'event',
      contentId: eventId,
      reason: reason,
      additionalDetails: additionalDetails,
    );
  }

  /// Report a forum post
  Future<bool> reportForumPost({
    required String reporterId,
    required String postId,
    required ReportReason reason,
    String? additionalDetails,
  }) {
    return reportContent(
      reporterId: reporterId,
      contentType: 'forum_post',
      contentId: postId,
      reason: reason,
      additionalDetails: additionalDetails,
    );
  }

  /// Report a comment/answer
  Future<bool> reportComment({
    required String reporterId,
    required String commentId,
    required ReportReason reason,
    String? additionalDetails,
  }) {
    return reportContent(
      reporterId: reporterId,
      contentType: 'comment',
      contentId: commentId,
      reason: reason,
      additionalDetails: additionalDetails,
    );
  }

  /// Fetch pending reports (admin/council only)
  Future<void> fetchPendingReports() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _client
          .from(_table)
          .select()
          .eq('status', 'pending')
          .order('created_at', ascending: false);

      _reports = (response as List)
          .map((json) => ContentReport.fromJson(json))
          .toList();
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      AppLogger.error(' Error fetching reports: $e');
      _error = 'Failed to load reports.';
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Fetch all reports (admin only)
  Future<void> fetchAllReports() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _client
          .from(_table)
          .select()
          .order('created_at', ascending: false);

      _reports = (response as List)
          .map((json) => ContentReport.fromJson(json))
          .toList();
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      AppLogger.error(' Error fetching all reports: $e');
      _error = 'Failed to load reports.';
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Update report status (admin/council action)
  Future<bool> updateReportStatus({
    required String reportId,
    required ReportStatus newStatus,
    required String reviewerId,
    String? actionNotes,
  }) async {
    try {
      await _client.from(_table).update({
        'status': newStatus.name,
        'reviewed_at': DateTime.now().toIso8601String(),
        'reviewer_id': reviewerId,
        'action_notes': actionNotes,
      }).eq('id', reportId);

      // Update local cache
      final index = _reports.indexWhere((r) => r.id == reportId);
      if (index >= 0) {
        _reports[index] = ContentReport(
          id: reportId,
          reporterId: _reports[index].reporterId,
          contentType: _reports[index].contentType,
          contentId: _reports[index].contentId,
          reason: _reports[index].reason,
          additionalDetails: _reports[index].additionalDetails,
          status: newStatus,
          createdAt: _reports[index].createdAt,
          reviewedAt: DateTime.now(),
          reviewerId: reviewerId,
          actionNotes: actionNotes,
        );
        notifyListeners();
      }

      return true;
    } catch (e) {
      AppLogger.error(' Error updating report: $e');
      return false;
    }
  }

  /// Get reports by content type
  List<ContentReport> getByContentType(String type) {
    return _reports.where((r) => r.contentType == type).toList();
  }

  /// Get pending count (for badges)
  int get pendingCount =>
      _reports.where((r) => r.status == ReportStatus.pending).length;
}
