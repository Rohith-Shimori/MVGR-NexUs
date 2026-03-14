import '../config/supabase_config.dart';
import 'package:flutter/foundation.dart';
import '../core/utils/logger.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Escalation types for faculty review
enum EscalationType { dispute, misconduct, appeal, other }

/// Escalation priority levels
enum EscalationPriority { urgent, high, medium, low }

/// Escalation status
enum EscalationStatus { pending, inProgress, resolved }

/// Escalation model
class Escalation {
  final String id;
  final String title;
  final String description;
  final EscalationType type;
  final EscalationPriority priority;
  final EscalationStatus status;
  final String submittedBy;
  final String? submittedById;
  final String? assignedTo;
  final String? resolution;
  final DateTime createdAt;
  final DateTime? resolvedAt;

  Escalation({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.priority,
    required this.status,
    required this.submittedBy,
    this.submittedById,
    this.assignedTo,
    this.resolution,
    required this.createdAt,
    this.resolvedAt,
  });

  factory Escalation.fromJson(Map<String, dynamic> json) {
    return Escalation(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      type: EscalationType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => EscalationType.other,
      ),
      priority: EscalationPriority.values.firstWhere(
        (e) => e.name == json['priority'],
        orElse: () => EscalationPriority.medium,
      ),
      status: EscalationStatus.values.firstWhere(
        (e) => e.name == (json['status'] ?? 'pending').replaceAll('_', ''),
        orElse: () => EscalationStatus.pending,
      ),
      submittedBy: json['submitted_by'] ?? 'Unknown',
      submittedById: json['submitted_by_id'],
      assignedTo: json['assigned_to'],
      resolution: json['resolution'],
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
      resolvedAt: json['resolved_at'] != null 
          ? DateTime.tryParse(json['resolved_at']) 
          : null,
    );
  }

  Escalation copyWith({
    EscalationStatus? status,
    String? resolution,
    DateTime? resolvedAt,
  }) {
    return Escalation(
      id: id,
      title: title,
      description: description,
      type: type,
      priority: priority,
      status: status ?? this.status,
      submittedBy: submittedBy,
      submittedById: submittedById,
      assignedTo: assignedTo,
      resolution: resolution ?? this.resolution,
      createdAt: createdAt,
      resolvedAt: resolvedAt ?? this.resolvedAt,
    );
  }
}

/// Supabase Escalation Service - Handles faculty escalations
class SupabaseEscalationService extends ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;
  
  List<Escalation> _pendingEscalations = [];
  List<Escalation> _resolvedEscalations = [];
  bool _isLoading = false;
  String? _error;
  
  List<Escalation> get pendingEscalations => _pendingEscalations;
  List<Escalation> get resolvedEscalations => _resolvedEscalations;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Fetch all escalations (pending and resolved)
  Future<void> fetchEscalations() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      final pendingResponse = await _supabase
          .from(SupabaseTables.escalations)
          .select()
          .neq('status', 'resolved')
          .order('created_at', ascending: false);
      
      final resolvedResponse = await _supabase
          .from(SupabaseTables.escalations)
          .select()
          .eq('status', 'resolved')
          .order('resolved_at', ascending: false);
      
      _pendingEscalations = (pendingResponse as List)
          .map((json) => Escalation.fromJson(json))
          .toList();
      
      _resolvedEscalations = (resolvedResponse as List)
          .map((json) => Escalation.fromJson(json))
          .toList();
          
      AppLogger.success(' Fetched ${_pendingEscalations.length} pending, ${_resolvedEscalations.length} resolved escalations');
    } catch (e) {
      _error = e.toString();
      AppLogger.error(' Error fetching escalations: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Submit a new escalation
  Future<bool> submitEscalation({
    required String title,
    required String description,
    required EscalationType type,
    required EscalationPriority priority,
    required String submittedBy,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      
      await _supabase.from(SupabaseTables.escalations).insert({
        'title': title,
        'description': description,
        'type': type.name,
        'priority': priority.name,
        'status': 'pending',
        'submitted_by': submittedBy,
        'submitted_by_id': userId,
        'created_at': DateTime.now().toIso8601String(),
      });
      
      await fetchEscalations();
      AppLogger.success(' Escalation submitted: $title');
      return true;
    } catch (e) {
      AppLogger.error(' Error submitting escalation: $e');
      return false;
    }
  }

  /// Resolve an escalation
  Future<bool> resolveEscalation(String id, String resolution) async {
    try {
      await _supabase.from(SupabaseTables.escalations).update({
        'status': 'resolved',
        'resolution': resolution,
        'resolved_at': DateTime.now().toIso8601String(),
      }).eq('id', id);
      
      await fetchEscalations();
      AppLogger.success(' Escalation resolved: $id');
      return true;
    } catch (e) {
      AppLogger.error(' Error resolving escalation: $e');
      return false;
    }
  }

  /// Assign an escalation to a faculty member
  Future<bool> assignEscalation(String id, String assignedTo) async {
    try {
      await _supabase.from(SupabaseTables.escalations).update({
        'status': 'in_progress',
        'assigned_to': assignedTo,
      }).eq('id', id);
      
      await fetchEscalations();
      AppLogger.success(' Escalation assigned: $id to $assignedTo');
      return true;
    } catch (e) {
      AppLogger.error(' Error assigning escalation: $e');
      return false;
    }
  }
}

/// Singleton instance
final supabaseEscalationService = SupabaseEscalationService();